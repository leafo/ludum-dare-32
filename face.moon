
{graphics: g} = love

class Tongue
  approx_h: 80

  sway_w: 40

  shake_x: 0
  shake_y: 0

  new: (@track, @x, @y) =>
    @target_x = @x
    @target_y = @y - @approx_h

    @default_x, @default_y = @target_x, @target_y

    @time = 0
    @update_shake!

    @seq = nil
    @lerp = 0

  move: (@target_x, @target_y) =>
    print "move", @target_x, @target_y
    @seq = Sequence ->
      tween @, 0.02, lerp: 1
      tween @, 0.2, lerp: 0
      @seq = nil

  draw: =>
    path = CatmullRomPath!

    tx, ty = lerp(@default_x, @target_x, @lerp), lerp(@default_y, @target_y, @lerp)

    -- pre base point
    bx = @x + (@x - tx) * 2
    by = @y - @approx_h / 3

    path\add bx, by
    path\add @x, @y

    mx, my = lerp(@x, tx, 0.6), lerp(@y, ty, 0.2)

    path\add mx + @shake_x, my + @shake_y

    path\add tx, ty
    path\add tx, ty - @approx_h / 2

    z = 0
    segs = [{x,y} for x, y in path\each_pt 0.5]
    seg_count = #segs

    for {x, y} in *segs
      g.push!

      g.translate x,y
      g.scale lerp(30, 15, z/seg_count), 10

      c = lerp(100, 255, z/seg_count)
      COLOR\push c,c,c
      g.circle "fill", 0, 0, 1, 8
      COLOR\push 220,220,220
      g.circle "fill", 0,0, 0.8, 8
      COLOR\pop!
      COLOR\pop!

      g.pop!
      z += 1

    COLOR\push 255,100,100
    g.setPointSize 10
    g.point @x, @y
    COLOR\pop!

  update: (dt) =>
    @time += dt
    @update_shake!
    @seq\update dt if @seq
    true

  update_shake: =>
    @shake_x = math.sin(@time * 2 + 9) * 5
    @shake_y = math.cos(@time * 5) * 5

    b, p = @track\get_beat!
    if b
      odd = b % 2 == 1
      p = 1 - p if odd
    else
      b = 0
      p = 0

    -- dx = smoothstep -1, 1, p
    dx = lerp -1, 1, cubic_bez 0.17, 0.44, 0.81, 0.56, p

    @default_x = @x + dx * @sway_w
    @default_y = @y - @approx_h

class Eye extends Box
  w: 50
  h: 20

  flash_a: 0

  flash: =>
    @seq = Sequence ->
      @flash_a = 1
      tween @, 0.2, flash_a: 0
      @seq = nil

  draw: =>
    g.rectangle "line", @unpack!
    if @flash_a > 0
      COLOR\pusha math.floor @flash_a * 255
      g.rectangle "fill", @unpack!
      COLOR\pop!

  update: (dt) =>
    @seq\update dt if @seq
    true

class Face extends Box
  eye_w: 20
  eye_h: 10

  eye_y: 50

  w: 120
  h: 180

  new: (@track, ...) =>
    super ...

    @eyes = {
      Eye 10, @eye_y
      Eye 80, @eye_y
    }

    cx = @center!
    @tongue = Tongue @track, cx, @y + 160

  hit_eye: (col) =>
    eye = @eyes[col]
    eye\flash!
    @tongue\move eye\center!

  eye_offset: (col=1) =>
    @eyes[col]\center!

  draw: =>
    g.rectangle "line", @unpack!

    for eye in *@eyes
      eye\draw!

    @tongue\draw!

  update: (dt) =>
    @tongue\update dt
    for eye in *@eyes
      eye\update dt


{ :Face, :Tongue }
