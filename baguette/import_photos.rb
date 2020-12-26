#!/usr/bin/env ruby
require 'fileutils'
require 'json'
require 'net/http'
require 'logger'

SRC_DIR = '/mnt/sd'
DST_DIR = "#{ENV['HOME']}/share/photos"
FILE_TYPES = %w[JPG MP4 MOV RAF RAW]
DAYS_LIMIT = 30

def logger
  @logger ||= Logger.new($stdout)
end

def slack_webhook_uri
  ENV['SLACK_WEBHOOK']
end

def slack_post(str)
  logger.info "slack: #{str.inspect}"
  if slack_webhook_uri
    payload = { 'text' => str }.to_json
    Net::HTTP.post_form URI(slack_webhook_uri), 'payload' => payload
  else
    logger.warn 'Cannot post to slack because $SLACK_WEBHOOK does not set'
  end
end

def copy_all
  slack_post('Started copying photos')
  files_skipped = 0
  files_copied = 0
  now = Time.now

  files = Dir.glob("#{SRC_DIR}/**/*.{#{FILE_TYPES.join(',')}}")
  files.each do |src_path|
    ctime = File.ctime(src_path)
    ctime_fmt = ctime.strftime('%Y-%m-%d')

    if (now - ctime) / (60 * 60 * 24).to_f > DAYS_LIMIT.to_f
      files_skipped += 1
      logger.info "Skipping (old): #{src_path}"
      next
    end

    dst_dir  = "#{DST_DIR}/#{ctime_fmt}"
    FileUtils.mkdir_p(dst_dir) unless Dir.exist?(dst_dir)
    dst_path = "#{dst_dir}/#{File.basename(src_path)}"

    if File.exist?(dst_path)
      files_skipped += 1
      logger.info "Skipping (exists): #{src_path}"
      next
    end

    files_copied += 1
    logger.info "copying #{src_path} -> #{dst_path}"
    FileUtils.cp  src_path, dst_path
  end

  slack_post("Finished: #{files_copied} copied, #{files_skipped} skipped, #{files.length} total")
rescue => e
  slack_post("Got an exception: #{e.full_message}")
  raise e
end

copy_all

