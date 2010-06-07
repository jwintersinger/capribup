class FilenameFormat
  attr_reader :prefix, :suffix, :directory

  def initialize(prefix, suffix, directory)
    @prefix, @suffix, @directory = prefix, suffix, directory
  end

  def timestamped_filename
    File.join(@directory, "#{@prefix}#{Time.now.strftime '%Y%m%d'}#{@suffix}")
  end
end

class DirectoryManager
  def initialize(prefix, suffix, directory)
    @prefix, @suffix, @directory = prefix, suffix, directory
    @keep_most_recent, @keep_age = 0, []
  end

  # Keep most recent +number+ files.
  def keep_most_recent(number)
    @keep_most_recent = number
  end

  # Keep file which is closest to +seconds_ago+ old. Will select file which is closest match, regardless of whether
  # it is older or newer than the given age.
  def keep_age(seconds_ago)
    @keep_age << seconds_ago
  end

  def delete_excess
    to_delete = list_contents_sorted_by_mtime
    preserve_most_recent to_delete
    preserve_by_age      to_delete
    File.delete *to_delete.map { |f| f.path }
  end

private
  def list_contents_sorted_by_mtime
    Dir.open(@directory) do |dir|
      dir.entries.find_all { |file| file =~ /\A#{Regexp.escape @prefix}.*#{Regexp.escape @suffix}\Z/ }.
        map { |filename| File.new(File.join(@directory, filename)) }.
        sort_by { |f| f.mtime }
    end
  end

  def preserve_most_recent(to_delete)
    @keep_most_recent.times { to_delete.pop }
  end

  def preserve_by_age(to_delete)
    now = Time.now
    # Reverse sort @keep_age so we preserve files matching oldest target ages first. Consider scenario in which
    # we wantto preserve a 5 month old and 6 month old file. If 8 month file exists and we check 5 month scenario
    # first, the 8-month-old file will be considered closest match and removed from deletion pool, when in fact it
    # would more closely match the 6 month criterion.
    @keep_age.sort.reverse.each do |age|
      # Remove file from deletion pool which comes closest to desired age. If we had to deal with files with
      # legitimate mtimes that are > now, we should call (now - file.mtime).abs instead of just (now - file.mtime) to
      # get the closest match possible. Since such files are likely abnormalities, we don't call it, thus enlarging
      # the delta and reducing the chance that the file will be seen as the best candidate to be plucked from the
      # deletion pool.
      to_delete.delete to_delete.sort_by { |file| ((now - file.mtime) - age).abs }.first
    end
  end
end

class DirectoryManagerPreset
  def initialize(manager)
    @manager = manager
  end

  def sensible
    @manager.keep_most_recent 6
    @manager.keep_age 60*60*24*7    # 1 week
    @manager.keep_age 60*60*24*14   # 2 weeks
    @manager.keep_age 60*60*24*30   # 1 month
    @manager.keep_age 60*60*24*30*3 # 3 months
    @manager.keep_age 60*60*24*30*6 # 6 months
  end

  def keep_only_most_recent
    @manager.keep_most_recent 1
  end
end
