
{graphics: g, audio: a} = love

import Bin, HList, VList from require "lovekit.ui"

import Metronome from require "ui"
import Track from require "track"

class TrackField extends Box
  socket_w: 20
  socket_h: 10
  pixels_per_beat: 100

  socket_offset: 50
  socket_spacing: 50

  new: (@track, ...) =>
    super ...
    @notes_played = {}
    print "Created field"

  draw: =>
    return unless @track.playing
    g.rectangle "line", @unpack!

    g.push!
    g.translate @x, @y

    -- draw sockets
    g.rectangle "line", 0, @socket_offset, @socket_w, @socket_h
    g.rectangle "line", 50, @socket_offset, @socket_w, @socket_h

    b, q = @track\get_beat!
    b += q

    upper = b - (@socket_offset / @pixels_per_beat)
    lower = b + @h / @pixels_per_beat

    for note in @track.notes\each_notes upper, lower
      COLOR\push unpack note.color
      g.rectangle "fill", (note.col - 1) * @socket_spacing,
        (note.beat - upper) * @pixels_per_beat, 10, 10
      COLOR\pop!

    g.pop!

  update: (dt) =>
    true

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
