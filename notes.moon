
{graphics: g, audio: a} = love

class Note
  new: (@beat) =>

class Note1 extends Note
  color: {100, 255, 100}
  col: 1

class Note2 extends Note
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

      beat_offset += @track.data.beats_per_measure

    @dump_notes!

  dump_notes: =>
    for b=1,@beats
      group = @timeline[b]
      continue unless group
      for note in *group
        print " * [#{note.beat}] #{note.type}"

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

  parse_notes: (str, rate=1, offset=0) =>
    beat = offset
    notes = for t in str\gmatch "."
      note = if cls = @types[t]
        cls beat

      beat += 1 / rate
      continue unless note
      note

    notes

{ :TrackNotes }
