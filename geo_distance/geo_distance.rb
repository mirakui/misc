require 'geocoder'
require 'yaml'
require 'dotenv'

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

class GeoSearcher
  def initialize
    @geo_cache = GeoCache.new
    Dotenv.load
    ::Geocoder.configure(
      use_https: true,
      api_key: ENV['GOOGLE_MAPS_API_KEY']
    )
  end

  def search(addr)
    cached_geom = @geo_cache.get(addr)
    if cached_geom
      cached_geom
    else
      result = Geocoder.search(addr)
      raise "Not Found: #{addr}" if result.empty?
      geom = result.first.geometry
      @geo_cache.set addr, geom
      geom
    end
  end

  def calc_distance(addr0, addr1)
    geoms = []
    geoms[0] = search addr0
    geoms[1] = search addr1
    latlngs = geoms.map do |l|
      geo = l['location']
      [geo['lat'], geo['lng']]
    end
    Geocoder::Calculations.distance_between *latlngs, units: :km
  end

end

def main
  searcher = GeoSearcher.new
  while line=gets
    addrs = line.chomp.split("\t")
    break if addrs.empty?
    puts searcher.calc_distance(*addrs)
    $stdout.flush
  end
end

main
