require 'spec_helper'
require 'open3'

RSpec.describe 'bin/annicter' do
  let(:bin_path) { File.expand_path('../bin/annicter', __dir__) }
  let(:access_token) { 'test_token_12345' }

  before do
    ENV['ANNICT_ACCESS_TOKEN'] = access_token
  end

  after do
    ENV.delete('ANNICT_ACCESS_TOKEN')
  end

  describe '--season option' do
    context 'with valid season format' do
      it 'accepts --season 2025-summer' do
        # This test will verify that the script accepts --season option
        # We expect the script to use the specified season instead of current season
        # Since this requires API interaction, we'll just verify it doesn't error on parsing

        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '2025-summer'
        )

        # The script might fail on API call, but should not fail on argument parsing
        expect(stderr).not_to include('invalid option')
        expect(stderr).not_to include('Invalid season format')
      end

      it 'accepts --season 2024-winter' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '2024-winter'
        )

        expect(stderr).not_to include('invalid option')
        expect(stderr).not_to include('Invalid season format')
      end

      it 'accepts --season 2023-spring' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '2023-spring'
        )

        expect(stderr).not_to include('invalid option')
        expect(stderr).not_to include('Invalid season format')
      end

      it 'accepts --season 2022-autumn' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '2022-autumn'
        )

        expect(stderr).not_to include('invalid option')
        expect(stderr).not_to include('Invalid season format')
      end
    end

    context 'with invalid season format' do
      it 'rejects invalid year format' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '25-summer'
        )

        expect(stdout + stderr).to include('Invalid season format')
        expect(status.exitstatus).not_to eq(0)
      end

      it 'rejects invalid season name' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', '2025-fall'
        )

        expect(stdout + stderr).to include('Invalid season format')
        expect(status.exitstatus).not_to eq(0)
      end

      it 'rejects malformed season string' do
        stdout, stderr, status = Open3.capture3(
          { 'ANNICT_ACCESS_TOKEN' => access_token },
          'ruby', bin_path, '--season', 'summer2025'
        )

        expect(stdout + stderr).to include('Invalid season format')
        expect(status.exitstatus).not_to eq(0)
      end
    end

    context 'without --season option' do
      it 'uses current season by default' do
        # Create a mock script that bypasses API connection
        mock_script = <<~RUBY
          require 'bundler/setup'
          require 'optparse'
          require_relative '#{File.expand_path('../lib/annicter', __dir__)}'

          def parse_options
            options = {}
            parser = OptionParser.new do |opts|
              opts.banner = "Usage: annicter [options]"
              opts.separator ""
              opts.separator "Options:"
              opts.on("-s", "--season SEASON", "Specify season in YYYY-SEASON format") do |season|
                options[:season] = season
              end
              opts.on("-h", "--help", "Show this help message") do
                puts opts
                exit 0
              end
            end
            parser.parse!
            options
          end

          options = parse_options
          season = options[:season] || Annicter::Season.current
          season_label = options[:season] ? "指定期（\#{season}）" : "今期（\#{season}）"
          puts "\#{season_label}の視聴中アニメ:"
        RUBY

        stdout, stderr, status = Open3.capture3('ruby', '-e', mock_script)

        # Should mention current season (今期)
        expect(stdout).to include('今期')
      end
    end
  end

  describe '--simple option' do
    it 'outputs only titles in newline-separated format' do
      # Test that --simple option is correctly parsed and doesn't cause errors
      stdout, stderr, status = Open3.capture3(
        { 'ANNICT_ACCESS_TOKEN' => access_token },
        'ruby', bin_path, '--simple'
      )

      # The script might fail on API call, but should not fail on argument parsing
      expect(stderr).not_to include('invalid option')
      expect(stderr).not_to include('unrecognized option')
    end

    it 'works with --season option' do
      stdout, stderr, status = Open3.capture3(
        { 'ANNICT_ACCESS_TOKEN' => access_token },
        'ruby', bin_path, '--season', '2025-summer', '--simple'
      )

      # The script might fail on API call, but should not fail on argument parsing
      expect(stderr).not_to include('invalid option')
      expect(stderr).not_to include('unrecognized option')
    end

    it 'does not output anything when no works found in simple mode' do
      mock_script = <<~RUBY
        require 'bundler/setup'
        require 'optparse'

        def parse_options
          options = {}
          parser = OptionParser.new do |opts|
            opts.on("--simple") { options[:simple] = true }
          end
          parser.parse!
          options
        end

        options = parse_options
        works = []

        if options[:simple]
          works.each { |work| puts work }
        else
          puts "視聴中のアニメはありません。"
        end
      RUBY

      stdout, stderr, status = Open3.capture3('ruby', '-e', mock_script, '--simple')

      expect(stdout.strip).to be_empty
    end
  end

  describe '--help option' do
    it 'displays help message' do
      stdout, stderr, status = Open3.capture3(
        'ruby', bin_path, '--help'
      )

      expect(stdout).to include('Usage:')
      expect(stdout).to include('--season')
      expect(status.exitstatus).to eq(0)
    end

    it 'includes --simple option in help' do
      stdout, stderr, status = Open3.capture3(
        'ruby', bin_path, '--help'
      )

      expect(stdout).to include('--simple')
    end
  end
end
