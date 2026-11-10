require 'app/hex/hex.rb'
require 'app/hex/hex_map.rb'
require 'app/hex/camera.rb'

def test_neighbors_are_at_distance_one args, assert
  center = { q: 3, r: -2 }
  neighbors = Hex.neighbors center
  assert.equal! neighbors.length, 6
  assert.equal! neighbors.uniq.length, 6
  neighbors.each { |n| assert.equal! Hex.distance(center, n), 1 }
end

def test_distance args, assert
  assert.equal! Hex.distance({ q: 0, r: 0 }, { q: 0, r: 0 }), 0
  assert.equal! Hex.distance({ q: 0, r: 0 }, { q: 3, r: -1 }), 3
  assert.equal! Hex.distance({ q: 0, r: 0 }, { q: 2, r: 2 }), 4
  assert.equal! Hex.distance({ q: -2, r: 5 }, { q: 4, r: -3 }), 8
  assert.equal! Hex.distance({ q: 4, r: -3 }, { q: -2, r: 5 }), 8
end

def test_ring args, assert
  center = { q: 1, r: 1 }
  assert.equal! Hex.ring(center, 0), [center]
  (1..4).each do |radius|
    ring = Hex.ring center, radius
    assert.equal! ring.length, 6 * radius
    assert.equal! ring.uniq.length, 6 * radius
    ring.each { |hex| assert.equal! Hex.distance(center, hex), radius }
  end
end

def test_ring_is_walkable args, assert
  ring = Hex.ring({ q: 0, r: 0 }, 3)
  ring.each_with_index do |hex, i|
    assert.equal! Hex.distance(hex, ring[(i + 1) % ring.length]), 1
  end
end

def test_spiral args, assert
  spiral = Hex.spiral({ q: 0, r: 0 }, 3)
  assert.equal! spiral.length, 1 + 6 + 12 + 18
  assert.equal! spiral.uniq.length, spiral.length
  assert.equal! spiral.first, { q: 0, r: 0 }
end

def test_line args, assert
  a = { q: -3, r: 1 }
  b = { q: 4, r: -5 }
  line = Hex.line a, b
  assert.equal! line.length, Hex.distance(a, b) + 1
  assert.equal! line.first, a
  assert.equal! line.last, b
  line.each_cons(2) { |from, to| assert.equal! Hex.distance(from, to), 1 }
  assert.equal! Hex.line(a, a), [a]
end

def test_pixel_round_trip args, assert
  [16, 32, 47.5].each do |size|
    Hex.spiral({ q: 0, r: 0 }, 6).each do |hex|
      center = Hex.to_pixel hex, size
      assert.equal! Hex.from_pixel(center.x, center.y, size), hex
    end
  end
end

def test_from_pixel_inside_hex args, assert
  size = 32
  hex = { q: 2, r: -3 }
  center = Hex.to_pixel hex, size
  Hex::CORNERS.each do |corner|
    x = center.x + corner.x * size * 0.95
    y = center.y + corner.y * size * 0.95
    assert.equal! Hex.from_pixel(x, y, size), hex
  end
end

def test_from_pixel_outside_hex args, assert
  size = 32
  hex = { q: 2, r: -3 }
  center = Hex.to_pixel hex, size
  Hex::CORNERS.each do |corner|
    x = center.x + corner.x * size * 1.05
    y = center.y + corner.y * size * 1.05
    assert.true! Hex.from_pixel(x, y, size) != hex
  end
end

def test_neighbor_directions_on_screen args, assert
  east = Hex.to_pixel Hex.neighbor({ q: 0, r: 0 }, 0), 10
  assert.true! east.x > 0
  assert.equal! east.y, 0
  north_east = Hex.to_pixel Hex.neighbor({ q: 0, r: 0 }, 1), 10
  assert.true! north_east.x > 0
  assert.true! north_east.y > 0
end

def test_offset_round_trip args, assert
  (-4..4).each do |row|
    (-4..4).each do |col|
      hex = Hex.from_offset col, row
      assert.equal! Hex.to_offset(hex), { col: col, row: row }
    end
  end
end

def test_coordinates_stay_integer args, assert
  hex = Hex.from_offset 5, 3
  assert.true! hex.q.is_a?(Integer)
  assert.true! Hex.to_offset(hex).col.is_a?(Integer)
  assert.true! Hex.distance(hex, { q: 0, r: 0 }).is_a?(Integer)
  assert.true! Hex.from_pixel(100.5, 40.2, 32).q.is_a?(Integer)
end

def test_offset_rows_are_horizontal args, assert
  y = Hex.to_pixel(Hex.from_offset(0, 3), 32).y
  (1..5).each do |col|
    hex = Hex.from_offset col, 3
    assert.equal! Hex.to_pixel(hex, 32).y, y
    assert.equal! Hex.distance(hex, Hex.from_offset(col - 1, 3)), 1
  end
end

def test_map_lookup args, assert
  map = HexMap.new cols: 8, rows: 5, hex_size: 32
  assert.equal! map.cells.length, 40
  map.cells.each do |cell|
    assert.true! map.in_bounds?(cell)
    assert.true! map.at(cell).equal?(cell)
    assert.true! map.at_pixel(cell.x, cell.y).equal?(cell)
  end
end

def test_map_bounds args, assert
  map = HexMap.new cols: 8, rows: 5, hex_size: 32
  assert.equal! map.at({ q: -1, r: 0 }), nil
  assert.equal! map.at({ q: 0, r: -1 }), nil
  assert.equal! map.at(Hex.from_offset(8, 0)), nil
  assert.equal! map.at(Hex.from_offset(0, 5)), nil
  assert.equal! map.neighbors(Hex.from_offset(0, 0)).length, 2
  assert.equal! map.neighbors(Hex.from_offset(3, 2)).length, 6
end

def test_map_cells_in_rect args, assert
  map = HexMap.new cols: 20, rows: 20, hex_size: 32
  rect = { x: 200, y: 150, w: 300, h: 200 }
  found = []
  map.each_cell_in(rect) { |cell| found << cell }
  assert.true! found.length < map.cells.length
  map.cells.each do |cell|
    inside = cell.x >= rect.x && cell.x <= rect.x + rect.w &&
             cell.y >= rect.y && cell.y <= rect.y + rect.h
    assert.true! found.include?(cell) if inside
  end
end

def test_camera_round_trip args, assert
  camera = Camera.new x: 300, y: -120, zoom: 1.7
  screen = camera.to_screen 512, 64
  world = camera.to_world screen.x, screen.y
  assert.true! (world.x - 512).abs < 1e-6
  assert.true! (world.y - 64).abs < 1e-6
end

def test_camera_zoom_keeps_point_under_cursor args, assert
  camera = Camera.new x: 300, y: 200
  before = camera.to_world 900, 100
  camera.zoom_at 900, 100, 1.5
  after = camera.to_world 900, 100
  assert.equal! camera.zoom, 1.5
  assert.true! (before.x - after.x).abs < 1e-6
  assert.true! (before.y - after.y).abs < 1e-6
end

def test_camera_zoom_is_limited args, assert
  camera = Camera.new x: 0, y: 0
  camera.zoom_at 640, 360, 100
  assert.equal! camera.zoom, Camera::ZOOM_MAX
  camera.zoom_at 640, 360, 0.0001
  assert.equal! camera.zoom, Camera::ZOOM_MIN
end
