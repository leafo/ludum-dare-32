
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
      p.scale = 1.5

      vr = (random_normal! - 0.5) * 2
      p.vel = Vec2d(0,-100  + -80 * vr)\random_heading 30
      p.accel = @accel
      p.color = @colors[@str]

class BreakEmitter extends Emitter
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

class SparkEmitter extends Emitter
  count: 10
  accel: Vec2d 0, 300
  color: {255,255,255}

  make_particle: (x,y) =>
    with PixelParticle x, y
      .color = @color
      .accel = @accel
      .vel = Vec2d(0, rand(-120, -150))\random_heading 40
      .size = rand 2,6

{ :BreakEmitter, :SparkEmitter, :ThreshEmitter }
