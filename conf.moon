export GAME_CONFIG = {
  scale: 3
  keys: {
    confirm: { "x", " ", "1", joystick: {1,3,5} }
    cancel: { "c", joystick: 2 }

    quit: { "escape" }

    one: { "1", "left", joystick: {1, 3, 5} }
    two: { "2", "right", joystick: {2, 4, 6} }

    up: "up"
    down: "down"
    left: "left"
    right: "right"
  }
}

love.conf = (t) ->
  t.window.width = 200 * GAME_CONFIG.scale
  t.window.height = 280 * GAME_CONFIG.scale

  t.title = "the game"
  t.author = "leafo"
