
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

    path\draw!

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

{ :Tongue }
