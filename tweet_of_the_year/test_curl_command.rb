require_relative './crawl'

def assert_equal(expected, actual, msg = nil)
  if expected != actual
    raise "Assertion failed: #{msg}\nExpected: #{expected.inspect}\nActual: #{actual.inspect}"
  end
  puts "  PASS: #{msg || 'assertion'}"
end

def assert_nil(actual, msg = nil)
  if !actual.nil?
    raise "Assertion failed: #{msg}\nExpected: nil\nActual: #{actual.inspect}"
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

results << test("parse extracts cookies from -b option") do
  curl_txt = <<~CURL
    curl 'https://x.com/api/test?variables=%7B%22userId%22%3A%221234%22%7D' \\
      -H 'accept: */*' \\
      -H 'content-type: application/json' \\
      -b 'auth_token=abc123; ct0=xyz789; session_id=sess001'
  CURL

  cmd = CurlCommand.parse(curl_txt)

  assert_equal('auth_token=abc123; ct0=xyz789; session_id=sess001', cmd.headers['Cookie'], 'Cookie header')
end

results << test("parse extracts headers") do
  curl_txt = <<~CURL
    curl 'https://x.com/api/test?variables=%7B%22userId%22%3A%221234%22%7D' \\
      -H 'accept: */*' \\
      -H 'authorization: Bearer TOKEN123'
  CURL

  cmd = CurlCommand.parse(curl_txt)

  assert_equal('*/*', cmd.headers['accept'], 'accept header')
  assert_equal('Bearer TOKEN123', cmd.headers['authorization'], 'authorization header')
end

results << test("parse handles curl without cookies") do
  curl_txt = <<~CURL
    curl 'https://x.com/api/test?variables=%7B%22userId%22%3A%221234%22%7D' \\
      -H 'accept: */*'
  CURL

  cmd = CurlCommand.parse(curl_txt)

  assert_nil(cmd.headers['Cookie'], 'Cookie header should be nil')
end

puts "\n---"
passed = results.count(true)
total = results.length
puts "#{passed}/#{total} tests passed"
exit(passed == total ? 0 : 1)
