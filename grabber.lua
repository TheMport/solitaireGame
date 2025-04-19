local Vector = require "Vector"

--  Worked with partner in section

local GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  setmetatable(grabber, {__index = GrabberClass})

  grabber.currentMousePos = Vector(0, 0)
  grabber.grabPos = nil
  grabber.heldObject = nil

  return grabber
end

function GrabberClass:update(deck)
  self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())

  -- Grab on mouse down
  if love.mouse.isDown(1) then
    if self.heldObject == nil then
      self:grab(deck)
    else
      -- drag while holding
      self.heldObject.x = self.currentMousePos.x - 32
      self.heldObject.y = self.currentMousePos.y - 32
    end
  else
    if self.heldObject ~= nil then
      self:release()
    end
  end
end

function GrabberClass:grab(deck)
  self.grabPos = self.currentMousePos

  for _, card in ipairs(deck) do
    if self:isMouseOver(card) then
      self.heldObject = card
      break
    end
  end
end

function GrabberClass:release()
  self.heldObject = nil
  self.grabPos = nil
end

function GrabberClass:isMouseOver(card)
  local mx, my = self.currentMousePos.x, self.currentMousePos.y
  return mx >= card.x and mx <= card.x + 64 and
         my >= card.y and my <= card.y + 64
end

return GrabberClass
