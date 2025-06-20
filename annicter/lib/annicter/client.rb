module Annicter
  class Client
    BASE_URL = 'https://api.annict.com'.freeze
    API_VERSION = 'v1'.freeze

    def initialize(access_token)
      raise ArgumentError, 'Access token is required' if access_token.nil? || access_token.empty?
      
      @access_token = access_token
      @conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = "Bearer #{@access_token}"
        faraday.headers['Content-Type'] = 'application/json'
      end
    end

    def watching_works(season = nil)
      season ||= Season.current
      
      works = []
      page = 1
      
      loop do
        response = fetch_watching_works(season, page)
        page_works = Work.from_api_response(response)
        works.concat(page_works)
        
        break unless response['next_page']
        page = response['next_page']
      end
      
      works
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise Error, "Network error: #{e.message}"
    end

    def test_connection
      response = @conn.get("/#{API_VERSION}/me")
      response.success?
    rescue StandardError
      false
    end

    private

    def fetch_watching_works(season, page)
      response = @conn.get("/#{API_VERSION}/me/works") do |req|
        req.params['filter_status'] = 'watching'
        req.params['filter_season'] = season
        req.params['per_page'] = 50
        req.params['page'] = page
      end

      unless response.success?
        raise Error, "API request failed with status #{response.status}: #{response.body}"
      end

      response.body
    end
  end
end