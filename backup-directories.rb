#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'backup')

class Task
  def initialize
    @prefix, @extension = 'dir-', '.tar.bz2'
    raise ArgumentError.new("Usage: #$0 [destination dir] [directory to backup]...") unless ARGV.size >= 2 &&
      all_directories?(*ARGV)
    @destination_dir, @targets = ARGV.first, ARGV[1..-1]
  end

  def run
    @targets.each do |dir|
      filename_format = FilenameFormat.new("#{@prefix}#{File.basename(dir)}-", @extension, @destination_dir)
      DirectoryBackup.new(dir).dump(filename_format.timestamped_filename)
      remove_old_backups(filename_format)
    end
  end

private
  def remove_old_backups(filename_format)
    manager = DirectoryManager.new(filename_format.prefix, filename_format.suffix, filename_format.directory)
    DirectoryManagerPreset.new(manager).sensible
    manager.delete_excess
  end

  def all_directories?(*targets)
    targets.each { |target| return false unless File.directory?(target) }
    true
  end
end

class DirectoryBackup
  def initialize(target)
    @target = target
  end

  def dump(archive_filename)
    # Direct STDERR to /dev/null when running command in order to suppress "Removing leading '/' from membeeer names"
    # message.
    command = %{tar cvjf "#{archive_filename}" "#{@target}" 2> /dev/null}
    Dir.chdir(@target) do
      status = IO.popen(command)
      status.read
      status.close
    end
  end
end

Task.new.run
