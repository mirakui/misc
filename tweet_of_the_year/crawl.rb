require 'uri'
require 'net/http'
require 'optparse'
require 'fileutils'
require_relative './lib/likes_response'

OUT_DIR = File.expand_path("../out", __FILE__)
FileUtils.mkdir_p(OUT_DIR) unless Dir.exist?(OUT_DIR)

FETCH_INTERVAL_SEC = 1

class CurlCommand
  attr_reader :uri, :headers, :query, :last_response

  def initialize(uri, headers={}, query={})
    @uri = URI(uri)
    @headers = headers
    @query = query
    @last_response = nil
  end

  def self.parse(cmd_txt)
    uri = headers = nil
    if cmd_txt =~ /^curl [^']*'(?<uri>[^']+)'/
      uri = $~[:uri]
    else
      raise "Invalid curl command"
    end
    matched_header_lines = cmd_txt.scan(/-H '(?<header>[^']+)'/)
    headers = matched_header_lines.map do |header_line|
      header_line[0].split(/: /)
    end

    query = parse_query(URI(uri).query)
    new(uri, Hash[headers], query)
  end

  def self.parse_query(query_str)
    URI.decode_www_form(query_str).map do |k, v|
      [k, JSON.parse(v)]
    end.to_h
  end

  def to_s
    "curl '#{@uri}' \\\n#{@headers.map { |k, v| "  -H '#{k}: #{v}' \\" }.join("\n")}"
  end

  def do_get_request
    request = Net::HTTP::Get.new(@uri.request_uri)
    @headers.each do |k, v|
      request[k] = v
    end
    @last_response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    @last_response
  end
end

class RateLimit
  attr_reader :limit, :remaining, :reset

  def initialize(limit, remaining, reset)
    @limit = limit
    @remaining = remaining
    @reset = reset
  end

  def self.from_http_response(http_response)
    limit = http_response["x-rate-limit-limit"].to_i
    remaining = http_response["x-rate-limit-remaining"].to_i
    reset = Time.at(http_response["x-rate-limit-reset"].to_i)
    RateLimit.new limit, remaining, reset
  end
end

class Crawler
  def initialize(base_curl_cmd)
    @base_curl_cmd = base_curl_cmd
  end

  def start(cursor=nil)
    loop do
      puts "---"
      puts "Cursor: #{cursor.inspect}"
      path = out_path(cursor)

      if already_fetched?(cursor)
        puts "Already fetched #{cursor.inspect}"
        cursor = LikesResponse.from_file(path).next_cursor
        puts "Next cursor: #{cursor.inspect}"
        next
      end

      puts "Fetching cursor=#{cursor.inspect}"
      response = fetch(cursor)

      case response.code
      when "200"
        likes_response = LikesResponse.new(response.body)
        likes_response.save(path)
        puts "Saved #{path}"
        cursor = likes_response.next_cursor
        oldest_tweet_created_at = likes_response.oldest_tweet_created_at
        puts "Oldest tweet: #{oldest_tweet_created_at}"
        if likes_response.all_tweets_are_old?
          puts "All tweets are old. Stopping."
          break
        end
        puts "Next cursor: #{cursor}"
      else
        abort "Error response code: #{response.code}"
      end

      rate_limit = RateLimit.from_http_response(response)
      puts "Rate limit: #{rate_limit.remaining}/#{rate_limit.limit} (reset at #{rate_limit.reset})"

      if rate_limit.remaining == 0
        puts "Sleeping until #{rate_limit.reset} (#{rate_limit.reset - Time.now} seconds)"
        sleep rate_limit.reset - Time.now
      else
        sleep FETCH_INTERVAL_SEC
      end
    end
  end

  def already_fetched?(cursor)
    File.exist? out_path(cursor)
  end

  def fetch(cursor)
    uri = build_uri(cursor)
    curl_cmd = CurlCommand.new(uri, @base_curl_cmd.headers)
    puts curl_cmd.to_s if ENV["DEBUG"]
    response = curl_cmd.do_get_request
    response
  end

  def build_uri(cursor)
    uri = @base_curl_cmd.uri
    variables = @base_curl_cmd.query["variables"]
    features = @base_curl_cmd.query["features"]
    variables.merge!("cursor" => cursor) if cursor

    uri.query = URI.encode_www_form({"variables" => variables.to_json, "features" => features.to_json})
    uri
  end

  def out_path(cursor)
    name = cursor.nil? ? "initial" : cursor
    File.join(OUT_DIR, "likes-#{name}.json")
  end

  def likes_response_from_file(cursor)
    body = File.read(out_path(cursor))
    LikesResponse.new(body)
  end
end

options = {}
OptionParser.new do |opts|
  opts.on('--cursor CURSOR', 'Starting cursor') do |cursor|
    options[:cursor] = cursor
  end
end.parse!

base_curl_cmd = CurlCommand.parse(ARGF.read)

crawler = Crawler.new(base_curl_cmd)
crawler.start options[:cursor]
