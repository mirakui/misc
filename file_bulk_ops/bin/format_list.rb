#!/usr/bin/env ruby

require 'json'
require 'optparse'

def format_list(file, prefix:'', directories_only: '')
  open(file, 'r') do |f|
    while !f.eof?
      line_str = f.gets
      line = JSON.parse(line_str)
      if directories_only
        next if line["is_dir"] == 0
      else
        next if line["is_dir"] == 1
      end
      dir = line["dir"].delete_prefix(prefix)
      path = "#{dir}/#{line['name']}".unicode_normalize
      puts [path, line['size']].join("\t")
    end
  end
end

params = {}
opt = OptionParser.new
opt.banner = "Usage: #{$0} [options] file"
opt.on('--prefix prefix', 'directory prefix in file') {|v| v }
opt.on('--directories_only', 'filter files') {|v| v }
opt.parse!(ARGV, into: params)

file = ARGV.shift
format_list(file, **params)
