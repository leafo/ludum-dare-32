
{graphics: g, audio: a} = love

import Bin, HList, VList, Label, Border from require "lovekit.ui"

import Metronome, VisibilityMeter from require "ui"
import Track from require "track"
import BreakEmitter, SparkEmitter, ThreshEmitter from require "emitters"

import Face, Tongue from require "face"

class TrackField extends Box
  w: 140
  h: 240

  lazy bg: -> imgfy "images/seat.png"

  min_delta: 120

  thresholds: {
    {20, "great"}
    {60, "good"}
    {120, "meh"}
  }

  pixels_per_beat: 50

  chain: 0
  max_chain: 0

  hits: 0
  misses: 0

  hit_great: 0
  hit_good: 0
  hit_meh: 0

  new: (@game, @track, ...) =>
    super ...
    @notes_played = {}
    @vib_seq = nil

    @particles = DrawList!
    @face = Face @track, 0, 0

    @pixels_per_beat = @track.data.pixels_per_beat
    print "setting pixels per beat to #{@pixels_per_beat}"

    @main_seq = Sequence ->
      wait_until -> @track.finished
      import StatsSummary from require "ui"
      DISPATCHER\push StatsSummary @

  on_game_over: =>
    print "entering game over"
    @track\stop!
    @track.finished = true

  on_hit_note: (note) =>
    @hits += 1
    @chain += 1
    @max_chain = math.max @max_chain, @chain

    nx, ny = @note_position note

    @eat_note note

    thresh = @threshold_for_delta note.hit_delta
    -- moonscript bug
    @["hit_#{thresh}"] = @["hit_#{thresh}"] + 1
    @particles\add ThreshEmitter thresh, @, nx,ny

    @game\on_hit_note note

  eat_note: (note) =>
    nx, ny = @note_position note

    spark = @particles\add SparkEmitter @, nx, ny

    local sprite
    seq = Sequence ->
      tween sprite, 0.2, x: @face.tongue.x, y: @face.tongue.y
      tween sprite, 0.1, a: 0

    sprite = {
      a: 1
      x: nx, y: ny

      update: (dt) =>
        with seq\update dt
          spark.x = @x
          spark.y = @y

      draw: =>
        COLOR\pusha 255 * @a
        note.sprite\draw note.quad, @x + note.ox, @y + note.oy
        COLOR\pop!

    }
    @particles\add sprite

  -- note might be nil if it was a mis-press
  on_miss_note: (note, from_hit) =>
    @chain = 0

    if note
      nx, ny = @note_position note
      @particles\add BreakEmitter note, @, nx,ny
      @misses += 1

      @face\on_eye_pain note.col

      if from_hit
        @particles\add ThreshEmitter "miss", @, nx,ny

    @shake!

    if from_hit
      AUDIO\play "miss"

    @game\on_miss_note note, from_hit

  shake: =>
    @game.viewport\shake!

    -- if joystick = CONTROLLER.joystick
    --   @vib_seq = Sequence ->
    --     print "vibrate start"
    --     joystick\setVibration 0.5, 0.5
    --     wait 0.1
    --     print "vibrate stop"
    --     joystick\setVibration!
    --     @vib_seq = nil

  draw: =>
    return unless @track.playing or @track.finished

    @bg\draw 10, @game.viewport.h - 140 + 2 * @track\sync_sin!

    if DEBUG
      g.rectangle "line", @unpack!

    g.push!
    g.translate @x, @y

    @face\draw!

    unless @track.finished
      upper, lower = @get_bounds!
      @current_top = upper

      for note in @track.notes\each_note upper, lower
        note\draw @note_position note

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

  can_input:  =>
    return false unless @track.playing
    -- wait a moment
    return false if love.timer.getTime! - @track.start_time < 0.2
    true

  update: (dt) =>
    @particles\update dt
    @main_seq\update dt if @main_seq
    @face\update dt

    return true unless @track.playing or @track.finished

    local note, delta, pressed

    if @vib_seq
      @vib_seq\update dt

    if @can_input!
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
        @on_miss_note nil, true

      -- note: we may have entered game over here from the miss note call above
      @mark_missed_notes!

    true

  mark_missed_notes: =>
    b, q = @track\get_beat!
    return unless b

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
    return unless b

    local min_note, min_d, early

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
          early = note.beat > bq
      else
        min_note = note
        min_d = math.abs note.beat - bq
        early = note.beat > bq

    return unless min_note

    delta = @track\beat_to_ms min_d
    if delta > @min_delta
      min_note.missed = true
      @on_miss_note min_note, true
      return nil, true

    -- print early and "hit early" or "hit late"
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
  new: (@stage) =>
    @viewport = DISPATCHER.viewport
    @entities = EntityList!
    @particles = DrawList!

    @metronome = Metronome!
    @visibility = VisibilityMeter!

    @list = VList {
      @visibility
      VList {
        with Label "game over if this goes to 0"
          .color = {255,255,255, 100}

        Label ""
        Label "press -1- to start"
        Label ""
        Label "use -1- and -2- to flick tongue"
      }
    }
    @hit_list = VList {}

    @ui = Bin 0, 0, @viewport.w, @viewport.h, HList {
      @list
      -- VList {
      --   Border VList({
      --     Label -> "score: 0"
      --     Label -> "chain: #{@field and @field.chain or 0}"
      --     Label -> "hits: #{@field and @field.hits or 0}"
      --   }), padding: 5
      --   @hit_list
      -- }
    }

  on_hit_note: (note) =>
    @append_hit note.hit_delta
    @visibility\increment!

  on_miss_note: (note, from_hit) =>
    @visibility\decrement!

    if @visibility.p <= 0
      @field\on_game_over!

  append_hit: (delta) =>
    table.insert @hit_list.items, 1, Label "#{math.floor delta}"
    @hit_list.items[11] = nil

  draw: =>
    @ui\draw!
    -- debug notes
    -- if notes = @track and @track.notes
    --   notes\draw!

  on_key: (key) =>
    if @field and @track and CONTROLLER\is_down("quit")
      @field\on_game_over!
      return true

  update: (dt) =>
    @ui\update dt
    @entities\update dt
    @particles\update dt

    if CONTROLLER\downed "confirm", "1"
      unless @track
        print "Queue track"
        @track = Track @stage.module
        @track\prepare!
        @entities\add @track
        @metronome\set_track @track

        @field = TrackField @, @track, 0,0

        @list.items[2] = @field

{ :Game, :TrackField }
