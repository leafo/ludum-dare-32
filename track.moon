{graphics: g, audio: a} = love

class Track
  prepared: false
  playing: false

  new: (package) =>
    @data = require "midi.#{package}"
    @audio_fname = "midi/#{package}.ogg"
    @source = assert a.newSource(@audio_fname, "stream"), "failed to load source"

    import TrackNotes from require "notes"
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
    @finished = false

    @start_time = love.timer.getTime!
    @source\setLooping false
    @source\rewind!
    @source\setVolume 1
    @last_measure = -1

  stop: =>
    @last_start_time = @start_time
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

  beat_to_seconds: (beat) =>
    minutes = beat / @data.bpm
    minutes * 60

  beat_to_ms: (beat) =>
    @beat_to_seconds(beat) * 1000

  -- in seconds
  duration: =>
    bps = 60 / @data.bpm
    bps * @duration_in_beats!

  duration_in_beats: =>
    @data.beats_per_measure * @data.measures

  duration_in_measures: =>
    @data.measures

  check_finished: =>
    if love.timer.getTime! - @start_time > @duration!
      @stop!
      @finished = true
      -- for looping
      -- @notes\reset!
      -- @start!

  update_last_measure: =>
    time = love.timer.getTime!
    active_beat = math.floor @get_measure time
    if active_beat != @last_measure
      @last_measure = active_beat
      print "  Entering measure: #{@last_measure}"

  -- synchronize time in seconds to beat
  sync_sin: (time=love.timer.getTime!) =>
    b, q = @get_beat time
    return 0 unless b
    math.sin (b + q) * math.pi

  update: (dt) =>
    return if @finished

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

    @check_finished!
    @update_last_measure!

    true

{ :Track }
