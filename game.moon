
{graphics: g, audio: a} = love

import Bin from require "lovekit.ui"

class Metronome extends Box
  x: 0
  y: 0
  w: 200
  h: 20

  dot_w: 20

  odd: false

  new: =>

  set_track: (@track) =>
    @last_q = -1

  draw: =>
    g.rectangle "line", @unpack!

    if @track
      q, p = @track\get_quad!

      if q != @last_q
        @odd = not @odd
        @last_q = q

      if q
        available_w = @w - @dot_w
        offset = p * available_w
        offset = available_w - offset if @odd

        COLOR\push 255,100,100
        g.rectangle "fill", @x + offset, @y, @dot_w, @h
        COLOR\pop!

  update: (dt) =>
    true

class Track
  prepared: false
  playing: false

  new: (package) =>
    @data = require "midi.#{package}"
    @audio_fname = "midi/#{package}.ogg"
    @source = assert a.newSource(@audio_fname, "stream"), "failed to load source"

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
    @last_beat = -1

  stop: =>
    @start_time = nil
    @source\stop!
    @playing = false

  get_beat: (time) =>
    return unless @start_time
    offset = time - @start_time
    bps = @data.bpm / 60
    offset / bps

  -- 4 beat
  get_quad: (time=love.timer.getTime!) =>
    return nil unless @playing
    beat = @get_beat time
    quad = beat * 4
    math.floor(quad), math.fmod(quad, 1)

  -- in seconds
  duration: =>
    beats = @data.beats_per_measure * @data.measures
    bps = 60 / @data.bpm
    bps * beats

  loop_if_necessary: =>
    if @source\tell("seconds") > @duration!
      print "Restart"
      @start!

  update_last_beat: =>
    time = love.timer.getTime!
    active_beat = math.floor @get_beat time
    if active_beat != @last_beat
      @last_beat = active_beat
      print "  Entering beat: #{@last_beat}"

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
    @update_last_beat!

    if CONTROLLER\tapped "confirm"
      print @get_quad love.timer.getTime!

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
