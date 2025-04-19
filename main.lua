

--  local Game = require "game"
local Card = require "cards"
local GrabberClass = require 'grabber'

local grabber 

--local game


function love.load()

love.window.setTitle('Solitaire')

love.graphics.setBackgroundColor(0,200,0)

Card.load()

grabber =GrabberClass:new()
  
  
end


function love.update(dt)
  
grabber:update(Card.getDeck())

end

function love.draw(dt)
  
  
  Card.draw()
  
end


