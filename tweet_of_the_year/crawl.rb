require 'uri'
require 'net/http'
require_relative './lib/likes_response'

OUT_DIR = File.expand_path("../out", __FILE__)
USER_ID = 6022992
YEAR = 2023
PER_PAGE = 20
FETCH_INTERVAL_SEC = 1

VARIABLES = {
  "userId" => USER_ID.to_s,
  "count" => PER_PAGE,
  "includePromotedContent" => false,
  "withClientEventToken" => false,
  "withBirdwatchNotes" => false,
  "withVoice" => true,
  "withV2Timeline" => true,
}

FEATURES = {
  "responsive_web_graphql_exclude_directive_enabled" => true,
  "verified_phone_label_enabled" => false,
  "creator_subscriptions_tweet_preview_api_enabled" => true,
  "responsive_web_graphql_timeline_navigation_enabled" => true,
  "responsive_web_graphql_skip_user_profile_image_extensions_enabled" => false,
  "c9s_tweet_anatomy_moderator_badge_enabled" => true,
  "tweetypie_unmention_optimization_enabled" => true,
  "responsive_web_edit_tweet_api_enabled" => true,
  "graphql_is_translatable_rweb_tweet_is_translatable_enabled" => true,
  "view_counts_everywhere_api_enabled" => true,
  "longform_notetweets_consumption_enabled" => true,
  "responsive_web_twitter_article_tweet_consumption_enabled" => false,
  "tweet_awards_web_tipping_enabled" => false,
  "freedom_of_speech_not_reach_fetch_enabled" => true,
  "standardized_nudges_misinfo" => true,
  "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled" => true,
  "rweb_video_timestamps_enabled" => true,
  "longform_notetweets_rich_text_read_enabled" => true,
  "longform_notetweets_inline_media_enabled" => true,
  "responsive_web_media_download_video_enabled" => false,
  "responsive_web_enhance_cards_enabled" => false,
}

class CurlCommand
  attr_reader :uri, :headers, :last_response

  def initialize(uri, headers={})
    @uri = URI(uri)
    @headers = headers
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

    new(uri, Hash[headers])
  end

  def to_s
    "curl '#{@uri}' #{@headers}"
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
    response = curl_cmd.do_get_request
    response
  end

  def build_uri(cursor)
    variables = VARIABLES
    variables.merge!("cursor" => cursor) if cursor
    uri = @base_curl_cmd.uri
    uri.query = URI.encode_www_form({"variables" => variables.to_json, "features" => FEATURES.to_json})
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

start_cursor = ARGV.shift
base_curl_cmd = CurlCommand.parse(ARGF.read)

crawler = Crawler.new(base_curl_cmd)
crawler.start start_cursor
