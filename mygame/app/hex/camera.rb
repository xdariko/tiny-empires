class Camera
  SCREEN_W = 1280
  SCREEN_H = 720
  ZOOM_MIN = 0.4
  ZOOM_MAX = 3.0

  attr_accessor :x, :y, :zoom

  def initialize(x:, y:, zoom: 1.0)
    @x = x
    @y = y
    @zoom = zoom
  end

  def to_screen world_x, world_y
    { x: (world_x - x) * zoom + SCREEN_W / 2,
      y: (world_y - y) * zoom + SCREEN_H / 2 }
  end

  def to_world screen_x, screen_y
    { x: (screen_x - SCREEN_W / 2) / zoom + x,
      y: (screen_y - SCREEN_H / 2) / zoom + y }
  end

  def pan dx, dy
    @x += dx / zoom
    @y += dy / zoom
  end

  def zoom_at screen_x, screen_y, factor
    before = to_world screen_x, screen_y
    @zoom = (zoom * factor).clamp(ZOOM_MIN, ZOOM_MAX)
    after = to_world screen_x, screen_y
    @x += before.x - after.x
    @y += before.y - after.y
  end

  def clamp_to rect
    @x = x.clamp(rect.x, rect.x + rect.w)
    @y = y.clamp(rect.y, rect.y + rect.h)
  end

  def viewport
    w = SCREEN_W / zoom
    h = SCREEN_H / zoom
    { x: x - w / 2, y: y - h / 2, w: w, h: h }
  end
end
