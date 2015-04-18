{graphics: g, audio: a} = love

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


{ :Metronome }
