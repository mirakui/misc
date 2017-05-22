#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'socket'
require 'mechanize'
require 'logger'

class SiteChecker
  def initialize(interval: 60)
    @sites = {}
    @last_results = {}
    @interval = interval
  end

  def logger
    @logger ||=
      begin
        $stdout.sync = 1
        Logger.new($stdout)
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
    if last_result && result != last_result
      slack_post "#{name} #{result}"
      logger.info "[#{name}] #{last_result} -> #{result}"
      @last_results[name] = result
    else
      logger.debug "[#{name}] #{result} (not changed)"
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

checker = SiteChecker.new interval: 60

checker.add_site(name: 'yodobashi スプラトゥーン2セット', uri: 'http://www.yodobashi.com/product/100000001003570628/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').first.text
end
checker.add_site(name: 'yodobashi ネオン', uri: 'http://www.yodobashi.com/product/100000001003431566/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').first.text
end
checker.add_site(name: 'yodobashi グレー', uri: 'http://www.yodobashi.com/product/100000001003431565/') do |page|
  page.css('#js_buyBoxMain .salesInfo p').first.text
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
checker.start
