#!/usr/bin/env ruby

require 'json'
require 'find'

def find_claude_settings_files(root_dir)
  settings_files = []
  
  Find.find(root_dir) do |path|
    if File.basename(path) == 'settings.local.json' && File.dirname(path).end_with?('.claude')
      settings_files << path
    end
  end
  
  settings_files
end

def extract_allow_deny_lists(file_path)
  begin
    content = File.read(file_path)
    data = JSON.parse(content)
    
    permissions = data['permissions'] || {}
    {
      'allow' => permissions['allow'] || [],
      'deny' => permissions['deny'] || []
    }
  rescue JSON::ParserError, Errno::ENOENT => e
    STDERR.puts "Error reading #{file_path}: #{e.message}"
    { 'allow' => [], 'deny' => [] }
  end
end

def merge_lists(all_settings)
  allow_set = {}
  deny_set = {}
  allow_list = []
  deny_list = []
  
  all_settings.each do |settings|
    settings['allow'].each do |item|
      unless allow_set[item]
        allow_set[item] = true
        allow_list << item
      end
    end
    
    settings['deny'].each do |item|
      unless deny_set[item]
        deny_set[item] = true
        deny_list << item
      end
    end
  end
  
  {
    'allow' => allow_list.sort,
    'deny' => deny_list.sort
  }
end

def main
  # Parse command line arguments
  debug_mode = false
  search_dir = '.'
  
  ARGV.each do |arg|
    if arg == '--debug' || arg == '-d'
      debug_mode = true
    else
      search_dir = arg
    end
  end
  
  # Find all .claude/settings.local.json files
  settings_files = find_claude_settings_files(search_dir)
  
  if debug_mode
    STDERR.puts "Debug mode: Found #{settings_files.length} settings.local.json files:"
    settings_files.each do |file_path|
      STDERR.puts "  - #{file_path}"
    end
    STDERR.puts ""
  end
  
  if settings_files.empty?
    puts JSON.pretty_generate({ 'permissions' => { 'allow' => [], 'deny' => [] } })
    return
  end
  
  # Extract allow and deny lists from each file
  all_settings = settings_files.map { |file_path| extract_allow_deny_lists(file_path) }
  
  # Merge all lists
  merged = merge_lists(all_settings)
  
  # Output as JSON with correct structure
  output = {
    'permissions' => merged
  }
  puts JSON.pretty_generate(output)
end

main if __FILE__ == $0