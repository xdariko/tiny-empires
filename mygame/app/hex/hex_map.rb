class HexMap
  attr_reader :cols, :rows, :hex_size, :cells

  def initialize(cols:, rows:, hex_size:)
    @cols = cols
    @rows = rows
    @hex_size = hex_size
    @cells = Array.new(cols * rows) do |i|
      hex = Hex.from_offset i % cols, i.idiv(cols)
      center = Hex.to_pixel hex, hex_size
      { q: hex.q, r: hex.r, x: center.x, y: center.y, terrain: :plain }
    end
  end

  def in_bounds? hex
    offset = Hex.to_offset hex
    offset.col >= 0 && offset.col < cols && offset.row >= 0 && offset.row < rows
  end

  def at hex
    offset = Hex.to_offset hex
    cell_at offset.col, offset.row
  end

  def cell_at col, row
    return nil if col < 0 || col >= cols || row < 0 || row >= rows
    cells[row * cols + col]
  end

  def neighbors hex
    Hex.neighbors(hex).map { |n| at n }.compact
  end

  def at_pixel x, y
    at Hex.from_pixel(x, y, hex_size)
  end

  def bounds
    @bounds ||= { x: 0,
                  y: 0,
                  w: hex_size * Hex::SQRT3 * (cols - 0.5),
                  h: hex_size * 1.5 * (rows - 1) }
  end

  def each_cell_in rect
    row_h = hex_size * 1.5
    col_w = hex_size * Hex::SQRT3
    row_min = (rect.y / row_h).floor - 1
    row_max = ((rect.y + rect.h) / row_h).ceil + 1
    col_min = (rect.x / col_w).floor - 1
    col_max = ((rect.x + rect.w) / col_w).ceil + 1

    row_min = 0 if row_min < 0
    col_min = 0 if col_min < 0
    row_max = rows - 1 if row_max > rows - 1
    col_max = cols - 1 if col_max > cols - 1

    row = row_min
    while row <= row_max
      col = col_min
      while col <= col_max
        yield cells[row * cols + col]
        col += 1
      end
      row += 1
    end
  end
end
