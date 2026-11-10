require 'app/hex/hex.rb'
require 'app/hex/hex_map.rb'
require 'app/hex/camera.rb'
require 'app/hex/map_view.rb'

class Game
  attr_dr

  PAN_SPEED = 12
  ZOOM_STEP = 1.1

  HOVER_COLOR    = { r: 163, g: 177, b: 138 }
  LINE_COLOR     = { r: 214, g: 162, b: 76 }
  SELECTED_COLOR = { r: 244, g: 211, b: 94 }
  TEXT_COLOR     = { r: 230, g: 230, b: 230 }

  def initialize
    @map = HexMap.new cols: 40, rows: 25, hex_size: 32
    @camera = Camera.new x: @map.bounds.w / 2, y: @map.bounds.h / 2
    @view = MapView.new @map, @camera
  end

  def tick
    input
    render
  end

  def input
    mouse = inputs.mouse

    @camera.pan inputs.left_right * PAN_SPEED, inputs.up_down * PAN_SPEED
    if mouse.button_right && @last_mouse
      @camera.pan @last_mouse.x - mouse.x, @last_mouse.y - mouse.y
    end
    @last_mouse = { x: mouse.x, y: mouse.y }

    @camera.zoom_at mouse.x, mouse.y, ZOOM_STEP**mouse.wheel.y if mouse.wheel
    @camera.clamp_to @map.bounds

    point = @camera.to_world mouse.x, mouse.y
    @hovered = @map.at_pixel point.x, point.y
    @selected = @hovered if mouse.key_down.left
  end

  def render
    outputs.background_color = [20, 24, 32]
    @view.render outputs

    if @selected && @hovered
      Hex.line(@selected, @hovered).each do |hex|
        cell = @map.at hex
        @view.fill outputs, cell, LINE_COLOR if cell
      end
    elsif @hovered
      @view.fill outputs, @hovered, HOVER_COLOR
    end

    if @selected
      @view.fill outputs, @selected, SELECTED_COLOR
      @view.outline outputs, @selected, SELECTED_COLOR
    end

    render_info
  end

  def render_info
    lines = []
    if @hovered
      offset = Hex.to_offset @hovered
      lines << "hex q=#{@hovered.q} r=#{@hovered.r}   col=#{offset.col} row=#{offset.row}"
      lines << "distance from selected: #{Hex.distance @selected, @hovered}" if @selected
    end
    lines << "zoom x#{@camera.zoom.round(2)}"

    outputs.primitives << { x: 0, y: 720 - 16 - lines.length * 24, w: 420, h: 16 + lines.length * 24,
                            path: :solid, r: 0, g: 0, b: 0, a: 160 }
    lines.each_with_index do |text, i|
      outputs.primitives << { x: 12, y: 720 - 8 - i * 24, text: text, size_px: 18, **TEXT_COLOR }
    end

    outputs.primitives << { x: 0, y: 0, w: 560, h: 36, path: :solid, r: 0, g: 0, b: 0, a: 160 }
    outputs.primitives << { x: 12, y: 28, size_px: 16, **TEXT_COLOR,
                            text: "WASD / arrows / right mouse drag: pan    wheel: zoom    left click: select" }
  end
end

module Main
  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end
end
