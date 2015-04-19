
class HitParticle extends PixelParticle
  new: (...) =>
    super ...
    @size = rand 2, 6

  draw: =>
    alpha = math.floor @fade_out! * 255

    if alpha != 255
      COLOR\pusha alpha

    super!

    if alpha != 255
      COLOR\pop!


class HitEmitter extends Emitter
  accel: Vec2d 0, 300
  count: 5

  make_particle: (x,y) =>
    x += rand -10, 10
    y += rand -10, 10

    vr = (random_normal! - 0.5) * 2

    vel = Vec2d(0,-100  + -80 * vr)\random_heading 30
    HitParticle x,y, vel, @accel

{ :HitEmitter }
