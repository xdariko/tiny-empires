module Hex
  SQRT3 = Math.sqrt(3)

  DIRECTIONS = [
    { q: 1, r: 0 }, { q: 0, r: 1 }, { q: -1, r: 1 },
    { q: -1, r: 0 }, { q: 0, r: -1 }, { q: 1, r: -1 }
  ]

  CORNERS = 6.times.map do |i|
    angle = Math::PI / 180 * (60 * i + 30)
    { x: Math.cos(angle), y: Math.sin(angle) }
  end

  class << self
    def neighbor hex, direction
      d = DIRECTIONS[direction % 6]
      { q: hex.q + d.q, r: hex.r + d.r }
    end

    def neighbors hex
      DIRECTIONS.map { |d| { q: hex.q + d.q, r: hex.r + d.r } }
    end

    def distance a, b
      dq = a.q - b.q
      dr = a.r - b.r
      (dq.abs + dr.abs + (dq + dr).abs).idiv 2
    end

    def ring center, radius
      return [center] if radius == 0

      hex = { q: center.q + DIRECTIONS[4].q * radius,
              r: center.r + DIRECTIONS[4].r * radius }
      result = []
      6.times do |direction|
        radius.times do
          result << hex
          hex = neighbor hex, direction
        end
      end
      result
    end

    def spiral center, radius
      (0..radius).flat_map { |k| ring center, k }
    end

    def round fq, fr
      fs = -fq - fr
      q = fq.round
      r = fr.round
      s = fs.round
      dq = (q - fq).abs
      dr = (r - fr).abs
      ds = (s - fs).abs

      if dq > dr && dq > ds
        q = -r - s
      elsif dr > ds
        r = -q - s
      end

      { q: q, r: r }
    end

    def line a, b
      n = distance a, b
      return [a] if n == 0

      aq = a.q + 1e-6
      ar = a.r + 2e-6
      (0..n).map do |i|
        t = i.fdiv n
        round aq + (b.q - a.q) * t, ar + (b.r - a.r) * t
      end
    end

    def to_pixel hex, size
      { x: size * SQRT3 * (hex.q + hex.r / 2.0),
        y: size * 1.5 * hex.r }
    end

    def from_pixel x, y, size
      fr = y / (size * 1.5)
      fq = x / (size * SQRT3) - fr / 2.0
      round fq, fr
    end

    def to_offset hex
      { col: hex.q + (hex.r - (hex.r & 1)).idiv(2), row: hex.r }
    end

    def from_offset col, row
      { q: col - (row - (row & 1)).idiv(2), r: row }
    end
  end
end
