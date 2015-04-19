{graphics: g, audio: a} = love

import VList, Label, Border, Bin from require "lovekit.ui"

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
  w: 140

  new: =>
    @bar = Bar 0,0, 140, 10

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

class StatsSummary
  fields: {
    "chain"
    "hits"
    "max_chain"
    "misses"
    "hit_great"
    "hit_good"
    "hit_meh"
  }

  new: (@track_field) =>
    @stats = {f, @track_field[f] for f in *@fields}
    @stats.total_notes = #@track_field.track.notes.all_notes
    @stats.time_lasted = love.timer.getTime! - @track_field.track.last_start_time

    list = VList {
      Label "hits: #{@stats.hits}"
      Label "misses: #{@stats.misses}"
      Label "max chain: #{@stats.max_chain}"
      Label "completion: #{math.floor @stats.hits/@stats.total_notes}%"
      Label "--"
      Label "greats: #{@stats.hit_great}"
      Label "good: #{@stats.hit_good}"
      Label "meh: #{@stats.hit_meh}"
    }

    container = Border list, { padding: 10, border: false, background: {0,0,0,180}}
    @ui = Bin 0, 0, DISPATCHER.viewport.w, DISPATCHER.viewport.h, container

    @main_seq = Sequence ->
      wait 1.0
      wait_until -> CONTROLLER\tapped "confirm"
      error "go back to menu"
      @main_seq = nil

  update: (dt) =>
    @ui\update dt
    @main_seq\update dt if @main_seq

  draw: =>
    DISPATCHER\parent!\draw!
    COLOR\push 40, 40, 70, 100
    g.rectangle "fill", DISPATCHER.viewport\unpack!
    COLOR\pop!

    @ui\draw!

{ :Metronome, :VisibilityMeter, :StatsSummary }
