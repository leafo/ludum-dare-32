

class Tongue
  approx_h: 80

  shake_x: 0
  shake_y: 0

  new: (@x, @y) =>
    @target_x = @x
    @target_y = @y - @approx_h
    @time = 0
    @update_shake!

  move: (@target_x, @target_y) =>

  draw: =>
    path = CatmullRomPath!

    -- pre base point
    bx = @x + (@x - @target_x) * 2
    by = @y - @approx_h / 3

    path\add bx, by
    path\add @x, @y

    mx, my = lerp(@x, @target_x, 0.6), lerp(@y, @target_y, 0.2)

    print @shake_x, @shake_y

    path\add mx + @shake_x, my + @shake_y

    path\add @target_x, @target_y
    path\add @target_x, @target_y - @approx_h / 2

    path\draw!

  update: (dt) =>
    @time += dt
    @update_shake!
    true

  update_shake: =>
    @shake_x = math.sin(@time * 2 + 9) * 5
    @shake_y = math.cos(@time * 5) * 5


{ :Tongue }
