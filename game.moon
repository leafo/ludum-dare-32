
{graphics: g, audio: a} = love

import Bin, HList, VList, Label, Border from require "lovekit.ui"

import Metronome from require "ui"
import Track from require "track"
import HitEmitter from require "emitters"

class TrackField extends Box
  min_delta: 120

  socket_w: 20
  socket_h: 10
  pixels_per_beat: 50

  socket_offset: 50
  socket_spacing: 50

  socket_fade: 0.2

  chain: 0
  hits: 0

  new: (@game, @track, ...) =>
    super ...
    @notes_played = {}
    print "Created field"
    @vib_seq = nil

  on_hit_note: (note) =>
    @hits += 1
    @chain += 1
    @game\on_hit_note note

  -- note might be nil if it was a mis-press
  on_miss_note: (note) =>
    @chain = 0
    if joystick = CONTROLLER.joystick
      @vib_seq = Sequence ->
        print "vibrate start"
        joystick\setVibration 0.5, 0.5
        wait 0.1
        print "vibrate stop"
        joystick\setVibration!
        @vib_seq = nil

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

    upper, lower = @get_bounds!

    @current_top = upper

    for note in @track.notes\each_note upper, lower
      note\draw (note.col - 1) * @socket_spacing + @socket_w / 2,
        (note.beat - upper) * @pixels_per_beat

    g.pop!
    g.setScissor!

  -- get the bottom and top in beats
  get_bounds: =>
    b, q = @track\get_beat!
    b += q

    upper = b - (@socket_offset / @pixels_per_beat)
    lower = b + @h / @pixels_per_beat
    upper, lower

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
    return unless @track.playing

    local note, delta, pressed

    if @vib_seq
      @vib_seq\update dt

    if CONTROLLER\downed "one"
      pressed = true
      @one_time = love.timer.getTime!
      note, delta = @find_hit_note 1

    if CONTROLLER\downed "two"
      pressed = true
      @two_time = love.timer.getTime!
      note, delta = @find_hit_note 2

    if note
      note.hit_delta = delta
      @on_hit_note note
    elseif pressed
      @on_miss_note nil

    @mark_missed_notes!

    true


  mark_missed_notes: =>
    b, q = @track\get_beat!
    b += q

    for note in @track.notes\each_note @get_bounds!
      continue if note.hit_delta
      continue if note.missed

      beat_delta = b - note.beat
      if beat_delta > 0
        delta = @track\beat_to_ms beat_delta
        if delta > @min_delta
          note.missed = true
          @on_miss_note note

  -- returns note, delta is ms
  find_hit_note: (col) =>
    b, q = @track\get_beat!
    local min_note, min_d

    bq = b + q
    for note in @track.notes\each_note b - 1, b + 1
      continue unless not col or note.col == col
      continue if note.hit_delta
      continue if note.missed

      if min_note
        delta = math.abs note.beat - bq
        if delta < min_d
          min_note = note
          min_d = delta
      else
        min_note = note
        min_d = math.abs note.beat - bq


    return unless min_note

    delta = @track\beat_to_ms min_d
    if delta > @min_delta
      min_note.missed = true
      @on_miss_note min_note
      return

    min_note, delta

  -- relative to viewport
  note_position: (note) =>
    x = @x + (note.col - 1) * @socket_spacing + @socket_w / 2

    upper = @current_top
    y = @y + (note.beat - upper) * @pixels_per_beat

    x,y


class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = EntityList!
    @particles = DrawList!

    @metronome = Metronome!

    @list = VList { @metronome }
    @hit_list = VList {}

    @ui = Bin 0, 0, @viewport.w, @viewport.h, HList {
      @list
      VList {
        Border VList({
          Label -> "score: 0"
          Label -> "chain: #{@field and @field.chain or 0}"
          Label -> "hits: #{@field and @field.hits or 0}"
        }), padding: 5
        @hit_list
      }
    }

  on_hit_note: (note) =>
    x, y = @field\note_position note
    @particles\add HitEmitter @, x,y
    @append_hit note.hit_delta

  append_hit: (delta) =>
    table.insert @hit_list.items, 1, Label "#{math.floor delta}"
    @hit_list.items[11] = nil

  draw: =>
    @viewport\apply!
    @ui\draw!
    @particles\draw!

    if notes = @track and @track.notes
      notes\draw!

    @viewport\pop!

  update: (dt) =>
    @ui\update dt
    @entities\update dt
    @particles\update dt

    if CONTROLLER\downed "confirm"
      unless @track
        print "Queue track"
        @track = Track "beat"
        @track\prepare!
        @entities\add @track
        @metronome\set_track @track

        @field = TrackField @, @track, 0,0, 200, 180
        table.insert @list.items, @field

{ :Game }
