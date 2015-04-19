
{graphics: g, audio: a} = love

import Bin, HList, VList, Label, Border from require "lovekit.ui"

import Metronome from require "ui"
import Track from require "track"
import HitEmitter, ThreshEmitter from require "emitters"

import Face, Tongue from require "face"

class TrackField extends Box
  w: 200
  h: 200

  min_delta: 120
  
  thresholds: {
    {20, "great"}
    {60, "good"}
    {120, "meh"}
  }

  pixels_per_beat: 50

  chain: 0
  hits: 0

  new: (@game, @track, ...) =>
    super ...
    @notes_played = {}
    @vib_seq = nil

    @particles = DrawList!
    @face = Face @track, 10, 10

  on_hit_note: (note) =>
    @hits += 1
    @chain += 1

    nx, ny = @note_position note

    @particles\add HitEmitter @, nx, ny

    thresh = @threshold_for_delta note.hit_delta
    @particles\add ThreshEmitter thresh, @, nx,ny

    @game\on_hit_note note

  -- note might be nil if it was a mis-press
  on_miss_note: (note, from_hit) =>
    @chain = 0

    if from_hit and note
      nx, ny = @note_position note
      @particles\add ThreshEmitter "miss", @, nx,ny

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

    g.push!
    g.translate @x, @y

    scale = GAME_CONFIG.scale
    g.setScissor @x * scale, @y * scale, @w * scale, @h * scale

    upper, lower = @get_bounds!
    @current_top = upper

    for note in @track.notes\each_note upper, lower
      note\draw @note_position note

    g.setScissor!

    @face\draw!
    @particles\draw!

    g.pop!

  -- get the bottom and top in beats
  get_bounds: =>
    b, q = @track\get_beat!
    b += q

    _, offset_top = @face\eye_offset!

    upper = b - (offset_top / @pixels_per_beat)
    lower = b + (@h - offset_top) / @pixels_per_beat
    upper, lower

  update: (dt) =>
    @particles\update dt
    return true unless @track.playing

    local note, delta, pressed

    if @vib_seq
      @vib_seq\update dt

    if CONTROLLER\downed "one"
      pressed = true
      @face\hit_eye 1
      note, delta = @find_hit_note 1

    if CONTROLLER\downed "two"
      pressed = true
      @face\hit_eye 2
      note, delta = @find_hit_note 2

    if note
      note.hit_delta = delta
      @on_hit_note note
    elseif pressed and not delta
      @on_miss_note nil

    @mark_missed_notes!

    @face\update dt

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
      @on_miss_note min_note, true
      return nil, true

    min_note, delta

  -- relative to viewport
  note_position: (note) =>
    x = @face.eyes[note.col]\center!
    y = (note.beat - @current_top) * @pixels_per_beat
    x, y

  threshold_for_delta: (delta) =>
    for {t, name} in *@thresholds
      if delta < t
        return name

    @thresholds[#@thresholds][2]

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
    @append_hit note.hit_delta

  append_hit: (delta) =>
    table.insert @hit_list.items, 1, Label "#{math.floor delta}"
    @hit_list.items[11] = nil

  draw: =>
    @viewport\apply!
    @ui\draw!

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

        @field = TrackField @, @track, 0,0
        table.insert @list.items, @field

  mousepressed: (mx,my) =>
    return unless @field
    mx, my = @viewport\unproject mx, my
    -- @field.face.tongue\move mx - @field.x, my - @field.y

{ :Game }
