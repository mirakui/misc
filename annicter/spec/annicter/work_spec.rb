require 'spec_helper'

RSpec.describe Annicter::Work do
  let(:work_data) do
    {
      'id' => 12345,
      'title' => 'ぼっち・ざ・ろっく！',
      'title_en' => 'BOCCHI THE ROCK!',
      'season_name' => '2022-autumn',
      'season_name_text' => '2022年秋',
      'episodes_count' => 12,
      'watchers_count' => 5000,
      'reviews_count' => 100,
      'no_episodes' => false
    }
  end

  let(:work) { described_class.new(work_data) }

  describe '#initialize' do
    it 'sets attributes from data hash' do
      expect(work.id).to eq(12345)
      expect(work.title).to eq('ぼっち・ざ・ろっく！')
      expect(work.title_en).to eq('BOCCHI THE ROCK!')
      expect(work.season_name).to eq('2022-autumn')
      expect(work.season_name_text).to eq('2022年秋')
      expect(work.episodes_count).to eq(12)
      expect(work.watchers_count).to eq(5000)
      expect(work.reviews_count).to eq(100)
      expect(work.no_episodes).to eq(false)
    end

    context 'with missing optional fields' do
      let(:minimal_data) do
        {
          'id' => 999,
          'title' => 'Test Anime',
          'season_name' => '2024-winter'
        }
      end

      let(:minimal_work) { described_class.new(minimal_data) }

      it 'handles missing fields gracefully' do
        expect(minimal_work.id).to eq(999)
        expect(minimal_work.title).to eq('Test Anime')
        expect(minimal_work.title_en).to be_nil
        expect(minimal_work.episodes_count).to be_nil
        expect(minimal_work.watchers_count).to be_nil
        expect(minimal_work.reviews_count).to be_nil
        expect(minimal_work.no_episodes).to be_nil
      end
    end
  end

  describe '#display_title' do
    context 'when both Japanese and English titles exist' do
      it 'returns formatted title with both languages' do
        expect(work.display_title).to eq('ぼっち・ざ・ろっく！ (BOCCHI THE ROCK!)')
      end
    end

    context 'when only Japanese title exists' do
      let(:work_data) do
        {
          'id' => 123,
          'title' => '日本語タイトル',
          'title_en' => nil
        }
      end

      it 'returns only Japanese title' do
        expect(work.display_title).to eq('日本語タイトル')
      end
    end

    context 'when English title is empty string' do
      let(:work_data) do
        {
          'id' => 123,
          'title' => '日本語タイトル',
          'title_en' => ''
        }
      end

      it 'returns only Japanese title' do
        expect(work.display_title).to eq('日本語タイトル')
      end
    end
  end

  describe '#episode_info' do
    context 'when episodes_count exists' do
      it 'returns episode count information' do
        expect(work.episode_info).to eq('全12話')
      end
    end

    context 'when episodes_count is nil' do
      let(:work_data) do
        {
          'id' => 123,
          'title' => 'Test',
          'episodes_count' => nil
        }
      end

      it 'returns unknown message' do
        expect(work.episode_info).to eq('話数不明')
      end
    end

    context 'when no_episodes is true' do
      let(:work_data) do
        {
          'id' => 123,
          'title' => 'Test',
          'no_episodes' => true
        }
      end

      it 'returns no episodes message' do
        expect(work.episode_info).to eq('エピソードなし')
      end
    end
  end

  describe '#to_s' do
    it 'returns formatted string representation' do
      expected = "ぼっち・ざ・ろっく！ (BOCCHI THE ROCK!)\n" \
                 "  シーズン: 2022年秋\n" \
                 "  話数: 全12話\n" \
                 "  視聴者数: 5000人\n" \
                 "  レビュー数: 100件"
      expect(work.to_s).to eq(expected)
    end

    context 'with minimal data' do
      let(:work_data) do
        {
          'id' => 999,
          'title' => 'Test Anime',
          'season_name' => '2024-winter',
          'season_name_text' => nil
        }
      end

      it 'handles missing fields in string representation' do
        expected = "Test Anime\n" \
                   "  シーズン: 2024-winter\n" \
                   "  話数: 話数不明\n" \
                   "  視聴者数: 0人\n" \
                   "  レビュー数: 0件"
        expect(work.to_s).to eq(expected)
      end
    end
  end

  describe '.from_api_response' do
    let(:api_response) do
      {
        'works' => [
          {
            'id' => 1,
            'title' => 'Anime 1',
            'season_name' => '2024-winter'
          },
          {
            'id' => 2,
            'title' => 'Anime 2',
            'season_name' => '2024-winter'
          }
        ]
      }
    end

    it 'creates Work instances from API response' do
      works = described_class.from_api_response(api_response)
      
      expect(works).to be_an(Array)
      expect(works.size).to eq(2)
      expect(works.all? { |w| w.is_a?(described_class) }).to be true
      expect(works[0].title).to eq('Anime 1')
      expect(works[1].title).to eq('Anime 2')
    end

    context 'with empty works array' do
      let(:api_response) { { 'works' => [] } }

      it 'returns empty array' do
        works = described_class.from_api_response(api_response)
        expect(works).to eq([])
      end
    end

    context 'with missing works key' do
      let(:api_response) { {} }

      it 'returns empty array' do
        works = described_class.from_api_response(api_response)
        expect(works).to eq([])
      end
    end
  end
end