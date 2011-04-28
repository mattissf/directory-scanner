require 'digest/md5'

class DirectoryScanner
  def initialize
    @verbose = false
  end

  def set_verbose
    @verbose = true
  end

  def print_duplicates_of dir
    (collect_files_from dir).each do |computed_identifier, file_matches|
      if file_matches.count > 1
        files_ordered_by_checksum = Hash.new

        file_matches.each do |file_match|
          file_path = file_match[:path]
          current_file_checksum = compute_checksum_of File.open file_path

          if(files_ordered_by_checksum.has_key? current_file_checksum)
            files_ordered_by_checksum[current_file_checksum].push file_path
          else
            files_ordered_by_checksum[current_file_checksum] = [file_path]
          end
        end

        files_ordered_by_checksum.each do |checksum, paths|
          if paths.count > 1
            puts "These files are duplicates of each other:"
            paths.each do |path|
              puts "\t#{path}"
            end
          end
        end
      end
    end
  end

  def collect_files_from dir, data_on_files = Hash.new
    dir.each do |item|
      next if item == '.' || item == '..'

      item_path = File.join(dir.path, item)

      if File.readable? item_path
        if File.symlink? item_path
          puts "#{item_path} is a symlink, skipping" if @verbose
        else
          if File.directory? item_path
            subdir = Dir.open item_path
            collect_files_from subdir, data_on_files
          elsif File.file? item_path
            file = File.open(item_path)

            current_file_identifier = compute_identifier_of file

            if data_on_files.has_key? current_file_identifier
              data_on_files[current_file_identifier].push(
                {
                  :path => item_path
                }
              )
            else
              data_on_files[current_file_identifier] = [
                {
                  :path => item_path
                }
              ]
            end
          end
        end
      else
        puts "Could not read #{item_path}" if @verbose
      end
    end

    data_on_files
  end

  def compute_identifier_of file
    "#{File.basename file.path}_#{file.stat.size}"
  end

  def compute_checksum_of file
    Digest::MD5.hexdigest(file.read)
  end
end