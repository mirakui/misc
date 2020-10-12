class LastLayer
  UNICODE_SQUARE = "\u25A0"
  UNICODE_SQUARE_WHITE = "\u25A1"
  UNICODE_SQUARE_LEFT = "\u25E7"
  UNICODE_SQUARE_RIGHT = "\u25E8"
  UNICODE_SQUARE_TOP = "\u2B12"
  UNICODE_SQUARE_BOTTOM = "\u2B13"
  ANSI_COLOR_BLACK = 30
  ANSI_COLOR_WHITE = 37
  ANSI_COLOR_YELLOW = 33

  def initialize(cells)
    @cells = cells
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
        next color(ANSI_COLOR_WHITE, UNICODE_SQUARE_WHITE) unless cell
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

  def rotate_y
    LastLayer.new([6, 7, 0, 1, 2, 3, 4, 5, 17, 18, 19, 8, 9, 10, 11, 12, 13, 14, 15, 16].map{|i| @cells[i] })
  end

  private
  def color(col, str)
    "\u001b[#{col}m#{str}\u001b[0m"
  end
end

layer = LastLayer.new([
nil,
nil,
nil,
1,
1,
1,
nil,
nil,
1,
1,
nil,
1,
nil,
nil,
nil,
nil,
nil,
1,
1,
nil,
])

puts layer
puts
puts layer.rotate_y
puts
puts layer.rotate_y.rotate_y
