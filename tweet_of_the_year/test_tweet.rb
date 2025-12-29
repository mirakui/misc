require_relative './lib/tweet'

def assert_equal(expected, actual, msg = nil)
  if expected != actual
    raise "Assertion failed: #{msg}\nExpected: #{expected.inspect}\nActual: #{actual.inspect}"
  end
  puts "  PASS: #{msg || 'assertion'}"
end

def test(name)
  print "Running: #{name}... "
  begin
    yield
    puts "OK"
  rescue => e
    puts "FAIL"
    puts e.message
    puts e.backtrace.first(5).join("\n")
    return false
  end
  true
end

results = []

results << test("is_normal_tweet? returns falsy when result is nil") do
  entry = {
    "content" => {
      "entryType" => "TimelineTimelineItem",
      "itemContent" => {
        "itemType" => "TimelineTweet",
        "tweet_results" => {}
      }
    }
  }
  tweet = Tweet.new(entry)
  assert_equal(false, !!tweet.is_normal_tweet?, "should return falsy for empty tweet_results")
end

results << test("is_normal_tweet? returns falsy for TweetWithVisibilityResults") do
  entry = {
    "content" => {
      "entryType" => "TimelineTimelineItem",
      "itemContent" => {
        "itemType" => "TimelineTweet",
        "tweet_results" => {
          "result" => {
            "__typename" => "TweetWithVisibilityResults",
            "tweet" => {
              "legacy" => {
                "created_at" => "Sun Jan 19 09:52:29 +0000 2025"
              }
            }
          }
        }
      }
    }
  }
  tweet = Tweet.new(entry)
  assert_equal(false, !!tweet.is_normal_tweet?, "should return falsy for TweetWithVisibilityResults")
end

results << test("is_normal_tweet? returns truthy for normal tweet") do
  entry = {
    "content" => {
      "entryType" => "TimelineTimelineItem",
      "itemContent" => {
        "itemType" => "TimelineTweet",
        "tweet_results" => {
          "result" => {
            "legacy" => {
              "created_at" => "Sun Jan 19 09:52:29 +0000 2025"
            }
          }
        }
      }
    }
  }
  tweet = Tweet.new(entry)
  assert_equal(true, !!tweet.is_normal_tweet?, "should return truthy for normal tweet")
end

puts "\n---"
passed = results.count(true)
total = results.length
puts "#{passed}/#{total} tests passed"
exit(passed == total ? 0 : 1)
