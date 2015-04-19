
{graphics: g, audio: a} = love

class Note
  w: 10
  h: 10

  new: (@beat) =>

  draw: (@x, @y) =>
    faded = @hit_delta or @missed

    if @hit_delta
      g.print "#{math.floor @hit_delta}", @x + @w, @y

    return if faded

    @sprite\draw @quad, @x + @ox, @y + @oy

    if DEBUG
      g.rectangle "line",
        @x - @w/2, @y - @h/2,
        @w, @h


class Note1 extends Note
  lazy sprite: => Spriter "images/candy1.png"
  ox: -13
  oy: -7

  quad: "8,5,23,17"

  debris: {
    w: 9
    h:10
    "8,25,9,10"
    "24,24,9,10"
    "24,24,9,10"
    "17,34,9,10"
  }

  color: {100, 255, 100}
  col: 1

class Note2 extends Note
  lazy sprite: => Spriter "images/candy2.png"
  quad: "5,4,23,14"

  ox: -12
  oy: -5

  debris: {
    w: 8
    h: 10
    "5,19,8,10"
    "14,26,8,10"
    "24,20,8,10"
  }

  color: {100, 100, 255}
  col: 2

class TrackNotes
  types: {
    ["1"]: Note1
    ["2"]: Note2
  }

  new: (@track) =>
    assert @track.data.notes, "no measure groups for tracks"

    @timeline = {}
    @all_notes = {}
    @beats = @track\duration_in_beats!

    beat_offset = 1
    for mid=1,@track\duration_in_measures!
      if measure = @track.data.notes[mid]
        if type(measure) == "string"
          measure = assert @track.data.notes[measure],
            "failed to find measure named `#{measure}`"

        rate = measure.rate or 1
        notes = assert measure[1], "no notes in measure"

        for note in *@parse_notes notes, rate, beat_offset
          root_beat = math.floor note.beat
          @timeline[root_beat] or= {}
          table.insert @timeline[root_beat], note
          table.insert @all_notes, note

      beat_offset += @track.data.beats_per_measure

    @dump_notes!

  dump_notes: =>
    for note in *@all_notes
      print " * [#{note.beat}] #{note.__class.__name}"

  each_note: (start, stop) =>
    start = math.floor start
    stop = math.floor stop

    coroutine.wrap ->
      for i=start,stop
        if group = @timeline[i]
          for note in *group
            coroutine.yield note

  draw: (x=0, y=0, time) =>
    px = 10
    py = 5

    bw = 2
    bh = 2
    padding = 1

    g.push!
    g.translate x, y

    -- draw the line
    cur_beat, beat_frac = @track\get_beat!
    if cur_beat
      cur_beat += beat_frac
      g.rectangle "fill", 0, py + (cur_beat - 1) * (bh + padding),
        px * 2 + 2,1


    for b=1,@beats
      group = @timeline[b]
      continue unless group
      for note in *group
        x = px + (note.col - 1) * 3

        COLOR\push unpack note.color
        g.rectangle "fill", x,
          py + (note.beat - 1) * (bh + padding),
          bw, bh

        COLOR\pop!

    g.pop!

  update: (dt) =>
    true

  reset: =>
    for note in *@all_notes
      note.hit_delta = nil
      note.missed = nil

  parse_notes: (str, rate=1, offset=0) =>
    beat = offset
    notes = for t in str\gmatch "."
      note = if cls = @types[t]
        cls beat

      beat += 1 / rate
      continue unless note
      note

    notes

{ :TrackNotes, :Note, :Note1, :Note2 }
