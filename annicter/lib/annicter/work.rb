module Annicter
  class Work
    attr_reader :id, :title, :title_en, :season_name, :season_name_text,
                :episodes_count, :watchers_count, :reviews_count, :no_episodes

    def initialize(data)
      @id = data['id']
      @title = data['title']
      @title_en = data['title_en']
      @season_name = data['season_name']
      @season_name_text = data['season_name_text']
      @episodes_count = data['episodes_count']
      @watchers_count = data['watchers_count']
      @reviews_count = data['reviews_count']
      @no_episodes = data['no_episodes']
    end

    def display_title
      return title if title_en.nil? || title_en.empty?
      "#{title} (#{title_en})"
    end

    def episode_info
      return 'エピソードなし' if no_episodes
      return '話数不明' if episodes_count.nil?
      "全#{episodes_count}話"
    end

    def to_s
      lines = [display_title]
      lines << "  シーズン: #{season_name_text || season_name}"
      lines << "  話数: #{episode_info}"
      lines << "  視聴者数: #{watchers_count || 0}人"
      lines << "  レビュー数: #{reviews_count || 0}件"
      lines.join("\n")
    end

    class << self
      def from_api_response(response)
        works = response['works'] || []
        works.map { |work_data| new(work_data) }
      end
    end
  end
end