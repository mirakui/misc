OLL_TRANSISIONS_FILE = 'data/oll_transitions.csv'
OLL_STATES_FILE = 'data/oll_states.csv'

class LastLayer
  SOLVED = [1, 1, 1, 1, 1, 1, 1, 1].freeze
  UNICODE_SQUARE = "\u25A0"
  UNICODE_SQUARE_WHITE = "\u25A1"
  UNICODE_SQUARE_LEFT = "\u25E7"
  UNICODE_SQUARE_RIGHT = "\u25E8"
  UNICODE_SQUARE_TOP = "\u2B12"
  UNICODE_SQUARE_BOTTOM = "\u2B13"
  ANSI_COLOR_BLACK = 30
  ANSI_COLOR_WHITE = 37
  ANSI_COLOR_YELLOW = 33

  attr_reader :cells

  def initialize(cells)
    @cells = Array.new(20, 0)
    cells.each_with_index {|c, i| @cells[i] = c if c }
    raise ArgumentError, "Unexpected cells=#{@cells.inspect}" if @cells.length > 20 || @cells.sum != 8
  end

  def to_s
    [
      [nil, 8, 9, 10, nil],
      [19, 0, 1, 2, 11],
      [18, 7, -1, 3, 12],
      [17, 6, 5, 4, 13],
      [nil, 16, 15, 14, nil],
    ].map do |line|
      line.map do |i|
        next color(ANSI_COLOR_YELLOW, UNICODE_SQUARE) if i == -1
        next color(ANSI_COLOR_BLACK, UNICODE_SQUARE) if i == nil
        cell = i ? @cells[i] : nil
        next color(ANSI_COLOR_WHITE, UNICODE_SQUARE_WHITE) if cell == nil || cell == 0
        color(ANSI_COLOR_YELLOW,
          case i
          when 8..10
            UNICODE_SQUARE_BOTTOM
          when 11..13
            UNICODE_SQUARE_LEFT
          when 14..16
            UNICODE_SQUARE_TOP
          when 17..18
            UNICODE_SQUARE_RIGHT
          else
            UNICODE_SQUARE
          end
        )
      end.join(' ')
    end.join("\n")
  end

  def ==(other)
    @cells == other.cells
  end

  private
  def color(col, str)
    "\u001b[#{col}m#{str}\u001b[0m"
  end
end

class Transition
  ROTATE_Y = [6, 7, 0, 1, 2, 3, 4, 5, 17, 18, 19, 8, 9, 10, 11, 12, 13, 14, 15, 16].freeze
  NONE = (0..19).to_a.freeze

  attr_reader :moves

  def initialize(moves)
    raise ArgumentError, "Unexpected moves=#{moves.inspect}" if moves.sort != NONE
    @moves = moves.dup
  end

  def apply(layer)
    LastLayer.new(@moves.map{|i| layer.cells[i] })
  end
end

class OLLStates
  attr_reader :states

  def initialize(file)
    @states = [File.read(file).chomp.split("\n").map{|line| LastLayer.new(line.split(',').map(&:to_i)) }]
    rotate_y = Transition.new(Transition::ROTATE_Y)
    3.times { @states << @states.last.map {|_| rotate_y.apply(_) } }
  end

  def find_index(layer)
    @states.each do |_states|
      idx = _states.find_index(layer)
      return idx if idx
    end
    nil
  end

  def [](idx)
    @states[0][idx]
  end
end

class OLLTransitions
  def initialize(file)
    @transitions = File.read(file).chomp.split("\n").map{|line| Transition.new(line.split(',').map(&:to_i)) }
  end

  def [](idx)
    @transitions[idx]
  end
end


layer = LastLayer.new(LastLayer::SOLVED)

rotate_y = Transition.new(Transition::ROTATE_Y)
olls = OLLTransitions.new(OLL_TRANSISIONS_FILE)
oll_states = OLLStates.new(OLL_STATES_FILE)

puts layer
puts oll_states.find_index(layer).inspect
puts layer = olls[1].apply(layer)
puts oll_states.find_index(layer).inspect
puts layer = rotate_y.apply(layer)
puts oll_states.find_index(layer).inspect
puts layer = rotate_y.apply(layer)
puts oll_states.find_index(layer).inspect
puts layer = olls[2].apply(layer)
puts oll_states.find_index(layer).inspect
