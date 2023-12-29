require 'time'
require 'json'

class Tweet
  def initialize(entry)
    @entry = entry
  end

  def is_normal_tweet?
    @entry["content"]["entryType"] == "TimelineTimelineItem" &&
      @entry["content"]["itemContent"]["itemType"] == "TimelineTweet" &&
      @entry["content"]["itemContent"]["tweet_results"]["result"].key?("legacy") &&
      @entry["content"]["itemContent"]["tweet_results"]["result"]["legacy"]["created_at"]
  end

  def tweet_result
    @entry["content"]["itemContent"]["tweet_results"]["result"]
  end

  def full_text
    tweet_result["legacy"]["full_text"]
  end

  def favorite_count
    tweet_result["legacy"]["favorite_count"].to_i
  end

  def permalink_url
    "https://twitter.com/#{user_screen_name}/status/#{tweet_result["legacy"]["id_str"]}"
  end

  def created_at
    Time.parse tweet_result["legacy"]["created_at"]
  end

  def is_quote_status?
    tweet_result["legacy"]["is_quote_status"]
  end

  def has_in_reply_to_status_id?
    tweet_result["legacy"].key?("in_reply_to_status_id")
  end

  def user_result
    @entry["content"]["itemContent"]["tweet_results"]["result"]["core"]["user_results"]["result"]
  end

  def user_screen_name
    user_result["legacy"]["screen_name"]
  end

  def user_name
    user_result["legacy"]["name"]
  end

  def user_followed_by?
    user_result["legacy"]["followed_by"]
  end

  def user_following?
    user_result["legacy"]["following"]
  end

  def user_protected?
    user_result["legacy"]["protected"]
  end
end
