
{graphics: g, audio: a} = love

import Bin from require "lovekit.ui"

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

class TrackNotes
  new: (@track) =>
    assert @track.data.notes, "no measure groups for tracks"

    @timeline = {}
    @beats = @track\duration_in_beats!

    beat_offset = 1
    for mid=1,@track\duration_in_measures!
      print "Adding measure #{mid}"
      if measure = @track.data.notes[mid]
        print "  Name: #{measure}"
        if type(measure) == "string"
          measure = assert @track.data.notes[measure],
            "failed to find measure named `#{measure}`"

        rate = measure.rate or 1
        assert measure.hits, "no hits in measure"

        for hit in *@parse_hits measure.hits, rate, beat_offset
          root_beat = math.floor hit.beat
          print "Adding hit to beat #{root_beat}", require("moon").dump hit
          @timeline[root_beat] or= {}
          table.insert @timeline[root_beat], hit

      beat_offset += @track.data.beats_per_measure

    draw: (x,y, time) =>

    update: (dt) =>
      true

  parse_hits: (str, rate=1, offset=0) =>
    beat = offset
    hits = for t in str\gmatch "."
      hit = if t == "x"
        { type: t, :beat }

      beat += 1 / rate
      continue unless hit
      hit

    hits

class Track
  prepared: false
  playing: false

  new: (package) =>
    @data = require "midi.#{package}"
    @audio_fname = "midi/#{package}.ogg"
    @source = assert a.newSource(@audio_fname, "stream"), "failed to load source"

    @notes = TrackNotes @

  prepare: =>
    print "Preparing #{@audio_fname}"
    @prepared = false
    @preparing = true
    @prepare_time = love.timer.getTime!

    -- play the source at volume 0 to warm it up
    @source\setLooping true
    @source\setVolume 0
    @source\play!

  check_prepared: =>
    assert @preparing, "not currently preparing audio"
    if @source\tell("seconds") > 0
      @prepared = true
      @preparing = false

  start: =>
    @preparing = false
    @playing = true

    @start_time = love.timer.getTime!
    @source\rewind!
    @source\setVolume 1
    @last_measure = -1

  stop: =>
    @start_time = nil
    @source\stop!
    @playing = false

  get_measure: (time=love.timer.getTime!) =>
    return unless @start_time
    offset = time - @start_time
    bps = @data.bpm / 60
    offset * bps / @data.beats_per_measure + 1

  -- get beat? or measure
  get_beat: (time=love.timer.getTime!) =>
    return unless @start_time
    offset = time - @start_time
    bps = @data.bpm / 60
    beat = offset * bps
    math.floor(beat) + 1, math.fmod(beat, 1)

  -- in seconds
  duration: =>
    bps = 60 / @data.bpm
    bps * @duration_in_beats!

  duration_in_beats: =>
    @data.beats_per_measure * @data.measures

  duration_in_measures: =>
    @data.measures

  loop_if_necessary: =>
    if @source\tell("seconds") > @duration!
      print "Restart"
      @start!

  update_last_measure: =>
    time = love.timer.getTime!
    active_beat = math.floor @get_measure time
    if active_beat != @last_measure
      @last_measure = active_beat
      print "  Entering measure: #{@last_measure}"

  update: (dt) =>
    unless @prepared
      if @preparing
        @check_prepared!
      else
        @prepare!

      -- we need to start playing on the next frame for whatever reason
      return true

    unless @playing
      print "Starting [#{@duration!}s]"
      @start!
      return true

    @loop_if_necessary!
    @update_last_measure!

    if CONTROLLER\tapped "confirm"
      print @get_beat!

    true

class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = EntityList!

    @metronome = Metronome!
    @ui = Bin 0, 0, @viewport.w, @viewport.h, @metronome

  draw: =>
    @viewport\apply!
    g.print "hello world", 10, 10
    @ui\draw!
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

{ :Game }
