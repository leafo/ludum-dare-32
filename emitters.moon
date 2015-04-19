
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

class HitEmitter extends Emitter
  accel: Vec2d 0, 300
  count: 5

  new: (@note, ...) =>
    super ...

  make_particle: (x,y) =>
    x += rand -10, 10
    y += rand -10, 10
    vr = (random_normal! - 0.5) * 2

    with ImageParticle x, y
      .accel = @accel
      .vel = Vec2d(0, -130  + -80 * vr)\random_heading 30
      .sprite = @note.sprite
      .quad = pick_one unpack @note.debris
      .w = @note.debris.w
      .h = @note.debris.h
      .dspin = (random_normal! - 0.5) * 5
      .dscale = random_normal!


{ :HitEmitter, :ThreshEmitter }
