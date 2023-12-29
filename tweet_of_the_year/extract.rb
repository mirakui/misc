require_relative './lib/likes_response'
require 'csv'

OUT_DIR = File.expand_path("../out", __FILE__)
YEAR = 2023

json_files = Dir.glob("#{OUT_DIR}/*.json")

CSV do |csv|
  csv << %w[screen_name name url favorite_count created_at full_text]
  json_files.each do |json_file|
    likes_response = LikesResponse.from_file(json_file)
    likes_response.entries.each do |entry|
      tweet = Tweet.new(entry)
      if tweet.is_normal_tweet? &&
         tweet.created_at.year == YEAR &&
         tweet.user_followed_by? &&
         !tweet.is_quote_status? &&
         tweet.full_text !~ /^@/ &&
         !tweet.has_in_reply_to_status_id? &&
         !tweet.user_protected? &&
         true
        csv << [
          tweet.user_screen_name,
          tweet.user_name,
          tweet.permalink_url,
          tweet.favorite_count,
          tweet.created_at,
          tweet.full_text,
        ]
      end
    end
  end
end
