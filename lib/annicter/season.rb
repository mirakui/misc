module Annicter
  class Season
    SEASONS = {
      1..3 => 'winter',
      4..6 => 'spring',
      7..9 => 'summer',
      10..12 => 'autumn'
    }.freeze

    VALID_SEASONS = %w[winter spring summer autumn].freeze

    class << self
      def current
        from_date(Date.today)
      end

      def from_date(date)
        year = date.year
        season = season_for_month(date.month)
        "#{year}-#{season}"
      end

      def parse(season_string)
        raise ArgumentError, "Invalid season format: #{season_string}" unless valid?(season_string)
        
        parts = season_string.split('-')
        [parts[0].to_i, parts[1]]
      end

      def valid?(season_string)
        return false if season_string.nil? || season_string.empty?
        
        parts = season_string.split('-')
        return false unless parts.length == 2
        
        year_part, season_part = parts
        year_part.match?(/^\d{4}$/) && VALID_SEASONS.include?(season_part)
      end

      private

      def season_for_month(month)
        SEASONS.each do |range, season|
          return season if range.include?(month)
        end
      end
    end
  end
end