FFMPEG_PATH = 'ffmpeg'
FFMPEG_ENCODE_OPTIONS = '-movflags faststart -vcodec libx264'

def usage
  $stderr.puts "USAGE: #{$0} <src_file...> <dst_dir>"
end

def encode(src_file, dst_path)
  dst_file = File.join(dst_path, "#{File.basename(src_file).gsub(/#{File.extname(src_file)}/, '')}.mp4")
  if File.exist?(dst_file)
    $stderr.puts "Output path #{dst_file} already exists."
    exit 1
  end

  identified = `#{FFMPEG_PATH} -i #{src_file} 2>&1`
  creation_time_line = identified.match(/creation_time\s+:\s+([\d\-T:]+)\./)
  if creation_time_line
    creation_time = creation_time_line[1]
  else
    creation_time = File.mtime(src_file).strftime("%Y-%m-%dT%H:%M:%S")
    #$stderr.puts "Cannot extract creation_time from #{src_file}:\n\n#{identified}"
    #exit 1
  end

  cmd = "#{FFMPEG_PATH} -i #{src_file} #{FFMPEG_ENCODE_OPTIONS} -metadata creation_time=\"#{creation_time}\" #{dst_file}"
  puts cmd
  system cmd

  dst_file
end

def main
  dst_path = ARGV.pop
  src_files = ARGV

  unless dst_path && src_files
    usage
    exit 1
  end
  unless File.directory?(dst_path)
    $stderr.puts "<dst_dir> must be a directory."
    usage
    exit 1
  end

  src_files.each_with_index do |src_file, i|
    puts "[#{i+1}/#{src_files.length}] Processing #{src_file}"
    dst_file = encode(src_file, dst_path)
    puts "Encoded: #{dst_file}"
  end

  puts "Finished."
end
main
