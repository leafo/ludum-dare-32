
{graphics: g} = love

class Game
  new: =>
    @viewport = Viewport scale: GAME_CONFIG.scale

  draw: =>
    @viewport\apply!
    g.print "hello world", 10, 10
    @viewport\pop!

  update: (dt) =>


{ :Game }
