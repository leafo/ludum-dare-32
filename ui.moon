{graphics: g, audio: a} = love

import VList, Label from require "lovekit.ui"

class Metronome extends Box
  x: 0
  y: 0
  w: 200
  h: 20

  dot_w: 20

  new: =>

  set_track: (@track) =>

  draw: =>
    g.rectangle "line", @unpack!

    if @track
      b, p = @track\get_beat!
      if b
        available_w = @w - @dot_w
        offset = p * available_w
        odd = b % 2 == 1
        offset = available_w - offset if odd

        COLOR\push 255,100,100
        g.rectangle "fill", @x + offset, @y, @dot_w, @h
        COLOR\pop!

  update: (dt) =>
    true


class Bar extends Box
  padding: 2
  p: 0.5
  draw_p: 0

  draw: =>
    g.rectangle "line", @unpack!

    COLOR\push 255, 100, 100, 200
    g.rectangle "fill", @x + @padding, @y + @padding,
      (@w - 2 * @padding) * @draw_p, @h - 2 * @padding
    COLOR\pop!

  update: (dt) =>
    @draw_p = smooth_approach @draw_p, @p, dt
    true

class VisibilityMeter extends VList
  p: 0.5

  new: =>
    @bar = Bar 0,0, 200, 10

    super {
      Label "visibility"
      @bar
    }

  update: (dt) =>
    @bar.p = @p
    super dt

  increment: =>
    @p = math.min 1, @p + 0.05

  decrement: =>
    @p = math.max 0, @p - 0.1

{ :Metronome, :VisibilityMeter }
