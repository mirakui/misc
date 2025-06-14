require 'spec_helper'

RSpec.describe Annicter::Season do
  describe '.current' do
    context 'when in January' do
      it 'returns winter season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 1, 15))
        expect(described_class.current).to eq('2024-winter')
      end
    end

    context 'when in February' do
      it 'returns winter season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 2, 28))
        expect(described_class.current).to eq('2024-winter')
      end
    end

    context 'when in March' do
      it 'returns winter season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 3, 31))
        expect(described_class.current).to eq('2024-winter')
      end
    end

    context 'when in April' do
      it 'returns spring season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 4, 1))
        expect(described_class.current).to eq('2024-spring')
      end
    end

    context 'when in May' do
      it 'returns spring season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 5, 15))
        expect(described_class.current).to eq('2024-spring')
      end
    end

    context 'when in June' do
      it 'returns spring season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 6, 30))
        expect(described_class.current).to eq('2024-spring')
      end
    end

    context 'when in July' do
      it 'returns summer season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 7, 1))
        expect(described_class.current).to eq('2024-summer')
      end
    end

    context 'when in August' do
      it 'returns summer season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 8, 15))
        expect(described_class.current).to eq('2024-summer')
      end
    end

    context 'when in September' do
      it 'returns summer season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 9, 30))
        expect(described_class.current).to eq('2024-summer')
      end
    end

    context 'when in October' do
      it 'returns autumn season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 10, 1))
        expect(described_class.current).to eq('2024-autumn')
      end
    end

    context 'when in November' do
      it 'returns autumn season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 11, 15))
        expect(described_class.current).to eq('2024-autumn')
      end
    end

    context 'when in December' do
      it 'returns autumn season' do
        allow(Date).to receive(:today).and_return(Date.new(2024, 12, 31))
        expect(described_class.current).to eq('2024-autumn')
      end
    end
  end

  describe '.from_date' do
    it 'returns correct season for a given date' do
      expect(described_class.from_date(Date.new(2023, 1, 1))).to eq('2023-winter')
      expect(described_class.from_date(Date.new(2023, 4, 15))).to eq('2023-spring')
      expect(described_class.from_date(Date.new(2023, 7, 31))).to eq('2023-summer')
      expect(described_class.from_date(Date.new(2023, 10, 10))).to eq('2023-autumn')
    end
  end

  describe '.parse' do
    context 'with valid season string' do
      it 'returns year and season name' do
        expect(described_class.parse('2024-winter')).to eq([2024, 'winter'])
        expect(described_class.parse('2023-spring')).to eq([2023, 'spring'])
        expect(described_class.parse('2022-summer')).to eq([2022, 'summer'])
        expect(described_class.parse('2021-autumn')).to eq([2021, 'autumn'])
      end
    end

    context 'with invalid season string' do
      it 'raises ArgumentError' do
        expect { described_class.parse('2024-invalid') }.to raise_error(ArgumentError, /Invalid season format/)
        expect { described_class.parse('winter-2024') }.to raise_error(ArgumentError, /Invalid season format/)
        expect { described_class.parse('2024') }.to raise_error(ArgumentError, /Invalid season format/)
      end
    end
  end

  describe '.valid?' do
    it 'returns true for valid season strings' do
      expect(described_class.valid?('2024-winter')).to be true
      expect(described_class.valid?('2024-spring')).to be true
      expect(described_class.valid?('2024-summer')).to be true
      expect(described_class.valid?('2024-autumn')).to be true
    end

    it 'returns false for invalid season strings' do
      expect(described_class.valid?('2024-fall')).to be false
      expect(described_class.valid?('2024-invalid')).to be false
      expect(described_class.valid?('winter')).to be false
      expect(described_class.valid?('')).to be false
      expect(described_class.valid?(nil)).to be false
    end
  end
end