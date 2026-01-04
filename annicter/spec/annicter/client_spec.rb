require 'spec_helper'

RSpec.describe Annicter::Client do
  let(:access_token) { 'test_token_123' }
  let(:client) { described_class.new(access_token) }

  describe '#initialize' do
    it 'sets the access token' do
      expect(client.instance_variable_get(:@access_token)).to eq(access_token)
    end

    it 'initializes Faraday connection' do
      expect(client.instance_variable_get(:@conn)).to be_a(Faraday::Connection)
    end

    context 'without access token' do
      it 'raises ArgumentError' do
        expect { described_class.new(nil) }.to raise_error(ArgumentError, /Access token is required/)
        expect { described_class.new('') }.to raise_error(ArgumentError, /Access token is required/)
      end
    end
  end

  describe '#watched_works' do
    let(:api_response) do
      {
        'works' => [
          {
            'id' => 1,
            'title' => 'Test Anime 1',
            'season_name' => '2024-winter'
          },
          {
            'id' => 2,
            'title' => 'Test Anime 2',
            'season_name' => '2024-winter'
          }
        ],
        'total_count' => 2,
        'next_page' => nil,
        'prev_page' => nil
      }
    end

    before do
      stub_request(:get, 'https://api.annict.com/v1/me/works')
        .with(
          query: hash_including(
            'filter_status' => 'watched',
            'filter_season' => '2024-winter',
            'per_page' => '50'
          ),
          headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: api_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fetches watched works for the specified season' do
      works = client.watched_works('2024-winter')
      
      expect(works).to be_an(Array)
      expect(works.size).to eq(2)
      expect(works.all? { |w| w.is_a?(Annicter::Work) }).to be true
    end

    context 'without season parameter' do
      before do
        allow(Annicter::Season).to receive(:current).and_return('2024-spring')
        
        stub_request(:get, 'https://api.annict.com/v1/me/works')
          .with(
            query: hash_including(
              'filter_status' => 'watched',
              'filter_season' => '2024-spring',
              'per_page' => '50'
            ),
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'uses current season by default' do
        works = client.watched_works
        expect(works).to be_an(Array)
      end
    end

    context 'with pagination' do
      let(:page1_response) do
        {
          'works' => Array.new(50) { |i| { 'id' => i, 'title' => "Anime #{i}" } },
          'total_count' => 75,
          'next_page' => 2,
          'prev_page' => nil
        }
      end

      let(:page2_response) do
        {
          'works' => Array.new(25) { |i| { 'id' => i + 50, 'title' => "Anime #{i + 50}" } },
          'total_count' => 75,
          'next_page' => nil,
          'prev_page' => 1
        }
      end

      before do
        stub_request(:get, 'https://api.annict.com/v1/me/works')
          .with(
            query: hash_including(
              'filter_status' => 'watched',
              'filter_season' => '2024-winter',
              'per_page' => '50',
              'page' => '1'
            ),
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: page1_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, 'https://api.annict.com/v1/me/works')
          .with(
            query: hash_including(
              'filter_status' => 'watched',
              'filter_season' => '2024-winter',
              'per_page' => '50',
              'page' => '2'
            ),
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: page2_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches all pages' do
        works = client.watched_works('2024-winter')
        expect(works.size).to eq(75)
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, 'https://api.annict.com/v1/me/works')
          .with(query: hash_including('filter_season' => '2024-winter'))
          .to_return(status: 401, body: { error: 'Unauthorized' }.to_json)
      end

      it 'raises an error' do
        expect { client.watched_works('2024-winter') }.to raise_error(Annicter::Error, /API request failed/)
      end
    end

    context 'with network error' do
      before do
        stub_request(:get, 'https://api.annict.com/v1/me/works')
          .with(query: hash_including('filter_season' => '2024-winter'))
          .to_timeout
      end

      it 'raises an error' do
        expect { client.watched_works('2024-winter') }.to raise_error(Annicter::Error, /Network error/)
      end
    end
  end

  describe '#test_connection' do
    context 'with valid token' do
      before do
        stub_request(:get, 'https://api.annict.com/v1/me')
          .with(
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { id: 123, username: 'testuser' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns true' do
        expect(client.test_connection).to be true
      end
    end

    context 'with invalid token' do
      before do
        stub_request(:get, 'https://api.annict.com/v1/me')
          .with(
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 401,
            body: { error: 'Unauthorized' }.to_json
          )
      end

      it 'returns false' do
        expect(client.test_connection).to be false
      end
    end
  end
end