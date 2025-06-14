require 'date'
require 'json'
require 'faraday'
require 'dotenv/load'

module Annicter
  class Error < StandardError; end
end

require_relative 'annicter/version'
require_relative 'annicter/season'
require_relative 'annicter/work'
require_relative 'annicter/client'