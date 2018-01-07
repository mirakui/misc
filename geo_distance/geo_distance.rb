require 'geocoder'

def geo_search(addr)
  @geo_cache ||= {}
  @geo_cache[addr] ||= Geocoder.search(addr)
end

def calc_distance(addr0, addr1)
  locs = []
  locs[0] = geo_search addr0
  locs[1] = geo_search addr1
  latlngs = locs.map do |l|
    geo = l.first.geometry['location']
    [geo['lat'], geo['lng']]
  end
  Geocoder::Calculations.distance_between *latlngs, units: :km
end

def main
  while line=gets
    addrs = line.chomp.split("\t")
    puts calc_distance(*addrs)
  end
end

main
