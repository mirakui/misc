require_relative './tweet'

class LikesResponse
  YEAR = Time.now.year.freeze

  attr_reader :body_str, :json

  def initialize(body_str)
    @body_str = body_str
    @json = JSON.parse(body_str)
  end

  def self.from_file(path)
    body = File.read(path)
    LikesResponse.new(body)
  end

  def save(path)
    open(path, "w+") do |f|
      f.write(body_str)
    end
  end

  def entries
    @entries ||= @json["data"]["user"]["result"]["timeline_v2"]["timeline"]["instructions"][0]["entries"]
  end

  def next_cursor
    entry = entries.find do |entry|
      entry["content"]["entryType"] == "TimelineTimelineCursor" && entry["content"]["cursorType"] == "Bottom"
    end
    entry["content"]["value"]
  end

  def oldest_tweet_created_at
    entries.map {|entry|
      Tweet.new(entry)
    }.select {|tweet|
      tweet.is_normal_tweet?
    }.map {|tweet|
      tweet.created_at
    }.min
  end

  def all_tweets_are_old?
    entries.map {|entry|
      Tweet.new(entry)
    }.select {|tweet|
      tweet.is_normal_tweet?
    }.all? {|tweet|
      tweet.created_at.year < YEAR
    }
  end
end
