
class ThreshEmitter extends TextEmitter
  accel: Vec2d 0, 300
  colors: {
    "good": {241, 216,82}
    "great": {180, 255, 180}
    "miss": {180, 180, 180}
  }

  make_particle: (...) =>
    with p = TextParticle @str, ...
      p.dscale = 1
      p.dspin = math.random!

      vr = (random_normal! - 0.5) * 2
      p.vel = Vec2d(0,-100  + -80 * vr)\random_heading 30
      p.accel = @accel
      p.color = @colors[@str]

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

{ :HitEmitter, :ThreshEmitter }
