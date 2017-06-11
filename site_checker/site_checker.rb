#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'socket'
require 'mechanize'
require 'logger'
require 'dotenv'
require 'optparse'

class SiteChecker
  def initialize(interval: 60, log_path: nil)
    @sites = {}
    @last_results = {}
    @interval = interval
    @log_path = log_path
  end

  def logger
    @logger ||=
      begin
        logdev = @log_path ? open(@log_path, 'a') : $stdout
        logdev.sync = 1
        Logger.new(logdev)
      end
  end

  def revision
    @revision ||=
      begin
        File.exist?('REVISION') ? File.read('REVISION') : 'unknown'
      end
  end

  def slack_webhook_uri
    ENV['SLACK_WEBHOOK']
  end

  def slack_post(str)
    if slack_webhook_uri
      payload = { 'text' => str }.to_json
      Net::HTTP.post_form URI(slack_webhook_uri), 'payload' => payload
    else
      logger.info "slack: #{str.inspect}"
      logger.warn 'Cannot post to slack because $SLACK_WEBHOOK does not set'
    end
  end

  # exponential backoff
  def retry_eb
    [2, 4, 8, 16].each do |t|
      begin
        return yield
      rescue
        logger.warn "retrying after #{t} sec."
        sleep t
      end
    end
    yield
  end

  def add_site(name:, uri:, &block)
    @sites[name] = { uri: uri, block: block }
  end

  def crawl_sites(agent)
    @sites.each do |name, site|
      crawl_site agent, name, site
    end
  end

  def crawl_site(agent, name, site)
    page = retry_eb { agent.get site[:uri] }
    result = site[:block].call page
    last_result = @last_results[name]
    if result != last_result
      msg = "[#{name}] #{last_result.inspect} -> #{result.inspect}\n#{site[:uri]}"
      slack_post msg
      logger.info msg
      @last_results[name] = result
    else
      logger.debug "[#{name}] #{result.inspect} (not changed)"
    end
  rescue => e
    msg = "#{e} (#{e.class}):\n  #{e.backtrace.join("\n  ")}"
    logger.error msg
    slack_post "[error] #{msg}"
  end

  def start
    slack_post "Started #{$0} at #{Socket.gethostname}, pid=##{Process.pid}, revision=#{revision}"
    agent = Mechanize.new
    loop do
      crawl_sites agent
      sleep @interval
    end

  rescue => e
    msg = "#{e} (#{e.class}):\n  #{e.backtrace.join("\n  ")}"
    logger.error msg
    slack_post "[error] #{msg}"
  end
end

Dotenv.load

options = { interval: 60 }
OptionParser.new do |o|
  o.banner = "Usage: #{$0} [options]"

  o.on('-o PATH', 'path to a log file') do |path|
    options[:log_path] = path
  end
  o.on('-i INTERVAL', 'interval') do |interval|
    options[:interval] = interval.to_i
  end
  o.on('-h', '--help', 'show usage') do
    puts o
    exit
  end
end.parse!

checker = SiteChecker.new options

checker.add_site(name: 'yodobashi スプラトゥーン2セット', uri: 'http://www.yodobashi.com/product/100000001003570628/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').text
end
checker.add_site(name: 'yodobashi ネオン', uri: 'http://www.yodobashi.com/product/100000001003431566/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').text
end
checker.add_site(name: 'yodobashi グレー', uri: 'http://www.yodobashi.com/product/100000001003431565/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').text
end
checker.add_site(name: 'My Nintendo カスタム本体', uri: 'https://store.nintendo.co.jp/customize.html') do |page|
  stock = nil
  page.css('.items').each do |item|
    k, v = item.text.split('/')
    if k == 'HAC_S_KAYAA'
      stock = v
      break
    end
  end
  "在庫: #{stock}"
end
#checker.add_site(name: 'joshinweb グレー', uri: 'http://joshinweb.jp/game/40518/4902370535709.html') do |page|
#  page.css('form[name="cart_button"]').text
#end
#checker.add_site(name: 'joshinweb ネオン', uri: 'http://joshinweb.jp/game/40518/4902370535716.html') do |page|
#  page.css('form[name="cart_button"]').text
#end
checker.add_site(name: '7net スプラトゥーン2セット', uri: 'http://7net.omni7.jp/detail/2110599526') do |page|
  page.css('.cartBtn input[type="submit"]')&.first&.attr('value')
end
checker.add_site(name: '7net グレー', uri: 'http://7net.omni7.jp/detail/2110596901') do |page|
  page.css('.cartBtn input[type="submit"]')&.first&.attr('value')
end
checker.add_site(name: '7net ネオン', uri: 'http://7net.omni7.jp/detail/2110595637') do |page|
  page.css('.cartBtn input[type="submit"]')&.first&.attr('value')
end
checker.start
