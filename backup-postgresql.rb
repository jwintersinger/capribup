#!/usr/bin/env ruby
# To provide access to appropriate backup user, run following query as postgres (or whatever
# system user is): GRANT SELECT ON <table1>, <table2>, <sequence1>, ... TO backup;
require File.join(File.dirname(__FILE__), 'backup')

class Task
  def initialize
    @prefix, @extension = 'postgresql-', '.sql.bz2'
    raise ArgumentError.new("Usage: #$0 [pgpassfile] [destination_dir]") unless ARGV.size == 2 &&
      File.exists?(ARGV.first) && File.directory?(ARGV.last)
    @pgpassfile, @destination_dir = *ARGV
  end

  def run
    determine_targets(@pgpassfile) do |target|
      filename_format = FilenameFormat.new("#{@prefix}#{target[:database]}-", @extension, @destination_dir)
      PostgresqlBackup.new(target.merge(:pgpassfile => @pgpassfile)).dump(filename_format.timestamped_filename)
      remove_old_backups filename_format
    end
  end

private
  def determine_targets(pgpassfile)
    File.read(pgpassfile).split("\n").map { |line| line.split(':') }.each do |database|
      yield({:host     => database[0],
             :port     => database[1],
             :database => database[2], 
             :username => database[3]})
    end
  end

  def remove_old_backups(filename_format)
    manager = DirectoryManager.new(filename_format.prefix, filename_format.suffix, filename_format.directory)
    DirectoryManagerPreset.new(manager).sensible
    manager.delete_excess
  end
end

# MySQL command: mysqldump --host="#{@hostname}" --user="#{@username}" --password="#{@password}" --complete-insert --quote-names "#{@db_name}"

class PostgresqlBackup
  def initialize(options={})
    options.each { |k, v| instance_variable_set("@#{k}".to_sym, v) }
  end

  def dump(filename)
    command = %{PGPASSFILE="#@pgpassfile" pg_dump --host="#@host" --port="#@port" -U "#@username" #@database | } +
      %{bzip2 --stdout > "#{filename}"}
    status = IO.popen(command)
    status.read
    status.close
  end
end

Task.new.run
