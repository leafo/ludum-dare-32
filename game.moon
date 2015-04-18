
{graphics: g, audio: a} = love

import Bin from require "lovekit.ui"

import Metronome from require "ui"
import Track from require "track"

class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale
    @entities = EntityList!

    @metronome = Metronome!
    @ui = Bin 0, 0, @viewport.w, @viewport.h, @metronome

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

{ :Game }
