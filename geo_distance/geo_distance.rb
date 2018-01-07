require 'geocoder'
require 'yaml'

class GeoCache
  CACHE_PATH = '.geocoder_cache'

  def initialize
    unless @cache
      if File.exist?(CACHE_PATH)
        @cache = YAML.load(open(CACHE_PATH).read)
      else
        @cache = {}
      end
    end
  end

  def save
    open(CACHE_PATH, 'w+') do |f|
      f.write @cache.to_yaml
    end
  end

  def set(addr, geometry)
    @cache[addr] = geometry
    save
  end

  def get(addr)
    @cache[addr]
  end
end

def geo_search(addr)
  @geo_cache ||= GeoCache.new
  cached_geom = @geo_cache.get(addr)
  if cached_geom
    cached_geom
  else
    geom = Geocoder.search(addr).first.geometry
    @geo_cache.set addr, geom
    geom
  end
end

def calc_distance(addr0, addr1)
  geoms = []
  geoms[0] = geo_search addr0
  geoms[1] = geo_search addr1
  latlngs = geoms.map do |l|
    geo = l['location']
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
