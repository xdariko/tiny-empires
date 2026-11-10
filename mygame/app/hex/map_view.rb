class MapView
  INSET = 0.94

  TERRAIN_COLORS = {
    water:    { r: 38,  g: 70,  b: 110 },
    plain:    { r: 88,  g: 129, b: 87 },
    hills:    { r: 128, g: 142, b: 82 },
    mountain: { r: 140, g: 134, b: 128 }
  }

  attr_reader :map, :camera

  def initialize map, camera
    @map = map
    @camera = camera
  end

  def render outputs
    map.each_cell_in(camera.viewport) do |cell|
      fill outputs, cell, TERRAIN_COLORS[cell[:terrain]]
    end
  end

  def fill outputs, cell, color
    corners = screen_corners cell, INSET
    first = corners[0]
    1.upto(4) do |i|
      outputs.sprites << { x: first.x, y: first.y,
                           x2: corners[i].x, y2: corners[i].y,
                           x3: corners[i + 1].x, y3: corners[i + 1].y,
                           path: :solid,
                           source_x: 0, source_y: 0,
                           source_x2: 8, source_y2: 0,
                           source_x3: 0, source_y3: 8,
                           r: color.r, g: color.g, b: color.b }
    end
  end

  def outline outputs, cell, color
    corners = screen_corners cell, 1.0
    6.times do |i|
      a = corners[i]
      b = corners[(i + 1) % 6]
      outputs.lines << { x: a.x, y: a.y, x2: b.x, y2: b.y,
                         r: color.r, g: color.g, b: color.b }
    end
  end

  private

  def screen_corners cell, scale
    center = camera.to_screen cell[:x], cell[:y]
    size = map.hex_size * camera.zoom * scale
    Hex::CORNERS.map do |corner|
      { x: center.x + corner.x * size, y: center.y + corner.y * size }
    end
  end
end
