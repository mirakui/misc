require 'json'

json_str = open('home/detected.json') do |f|
  f.read
end

json = JSON.parse(json_str)
puts %w(file yatta ren0 tsumo0 ren1 tsumo1).join("\t")
json['frames'].each do |f|
  pl = f['players']
  puts [f['file'], f['yatta'], pl[0]['ren'], pl[0]['tsumo'], pl[1]['ren'], pl[1]['tsumo']].join("\t")
end
