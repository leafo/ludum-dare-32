
{graphics: g, audio: a} = love

import Bin, HList, VList from require "lovekit.ui"

import Metronome from require "ui"
import Track from require "track"

class TrackField extends Box
  socket_w: 20
  socket_h: 10
  pixels_per_beat: 50

  socket_offset: 50
  socket_spacing: 50

  socket_fade: 0.2

  new: (@track, ...) =>
    super ...
    @notes_played = {}
    print "Created field"

  draw: =>
    return unless @track.playing

    g.rectangle "line", @unpack!

    scale = GAME_CONFIG.scale
    g.setScissor @x * scale, @y * scale, @w * scale, @h * scale

    g.push!
    g.translate @x, @y

    -- draw sockets
    @draw_socket 0, @one_time
    @draw_socket @socket_spacing, @two_time

    b, q = @track\get_beat!
    b += q

    upper = b - (@socket_offset / @pixels_per_beat)
    lower = b + @h / @pixels_per_beat

    for note in @track.notes\each_note upper, lower
      COLOR\push unpack note.color
      g.rectangle "fill", (note.col - 1) * @socket_spacing,
        (note.beat - upper) * @pixels_per_beat, 10, 10
      COLOR\pop!

    g.pop!
    g.setScissor!

  draw_socket: (x, push_time) =>
    time = love.timer.getTime!
    y,w,h = @socket_offset - @socket_h / 2, @socket_w, @socket_h

    g.rectangle "line", x,y,w,h

    if push_time and time - push_time < @socket_fade
      a = 1 - (time - push_time) / @socket_fade
      COLOR\pusha math.floor a * 255
      g.rectangle "fill", x,y,w,h
      COLOR\pop!

  update: (dt) =>
    if CONTROLLER\tapped "one"
      @one_time = love.timer.getTime!
      note, bd = @find_hit_note 1
      print "one", note, bd

    if CONTROLLER\tapped "two"
      @two_time = love.timer.getTime!
      note, bd = @find_hit_note 1
      print "two", note, bd

    true

  find_hit_note: (col) =>
    b, q = @track\get_beat!
    local min_note, min_d

    bq = b + q
    for note in @track.notes\each_note b - 1, b + 1
      continue unless not col or note.col == col

      if min_note
        delta = math.abs note.beat - bq
        if delta < min_d
          min_note = note
          min_d = delta
      else
        min_note = note
        min_d = math.abs note.beat - bq

    min_note, min_d

class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = EntityList!

    @metronome = Metronome!
    @list = VList { @metronome }
    @ui = Bin 0, 0, @viewport.w, @viewport.h, @list

  draw: =>
    @viewport\apply!
    @ui\draw!

    if notes = @track and @track.notes
      notes\draw!

    @viewport\pop!

  update: (dt) =>
    @ui\update dt
    @entities\update dt

    if CONTROLLER\tapped "confirm"
      unless @track
        print "Queue track"
        @track = Track "beat"
        @track\prepare!
        @entities\add @track
        @metronome\set_track @track

        @field = TrackField @track, 0,0, 200, 180
        table.insert @list.items, @field

{ :Game }
