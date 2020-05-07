#!/usr/bin/env ruby

require 'optparse'
require 'pathname'
require 'json'
require 'logger'

class Main
  ERROR_FILE_NAME = 'errors.txt'

  def initialize(scan_dirs:, out_dir:)
    @error_file_path = File.join(out_dir, ERROR_FILE_NAME)
    @scan_dirs = scan_dirs
    @out_dir = out_dir
    @logger = Logger.new($stdout)
  end

  def start
    @logger.info 'Start'
    error_file = File.open(@error_file_path, 'w+')
    @scan_dirs.each do |dir|
      begin
        @logger.info "Scanning directory: #{dir}"
        out_file_path = File.join(@out_dir, "list.txt")
        out_file = File.open(out_file_path, 'w+')
        files = scan_dir(dir, out_file, error_file)
        @logger.info "Scanned #{files.length} files"
      rescue => e
        @logger.error e.full_message(highlight: false)
        next
      end
    end
    @logger.info 'Finished'

  end

  def scan_dir(dir, out_file, error_file)
    files = []
    Dir.each_child(dir) do |child_basename|
      begin
        child_path = Pathname.new(File.join(dir, child_basename))
        file_attrs = {}
        file_attrs['dir'] = dir
        file_attrs['name'] = child_basename

        if child_path.directory?
          file_attrs['is_dir'] = 1
          child_files = scan_dir(child_path.to_s, out_file, error_file)
          child_size = child_files.sum {|f| f['size']}
          file_attrs['size'] = child_size
        else
          file_attrs['is_dir'] = 0
          file_attrs['size'] = child_path.size
        end
        out_file.puts file_attrs.to_json
        files << file_attrs
      rescue => e
        error = {
          'dir' => dir,
          'name' => child_basename,
          'error' => e.full_message(highlight: false),
        }
        error_file.puts error
        error_file.flush
        next
      end
    end

    files
  end

end

scan_dirs = nil
out_dir = nil

opt = OptionParser.new
opt.on('-s dirs', 'directories to scan, separated by ","') {|s| scan_dirs = s.split(',') }
opt.on('-o dir', 'out directory') {|o| out_dir = o }
opt.parse!(ARGV)

unless scan_dirs && out_dir
  $stderr.puts opt.help
  exit 1
end

main = Main.new(scan_dirs: scan_dirs, out_dir: out_dir)
main.start
