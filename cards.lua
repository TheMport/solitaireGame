
local Card = {}

Card.__index = Card

--  establish decks, suits, and cards
local deck = {}
local suits = {'hearts'}
--local vals = {'A','1','2','3','4','5','6','7','8','9','10','J','Q','K'}
local vals = {'A'}

local cardWidth = 64
local cardHeight = 64


function Card.load()
  
-- End result is to be able to drag playable cards in game

for _, suit in ipairs (suits) do 
    
  for _, val in ipairs (vals) do
    
    local card = setmetatable({},Card)
    card.suit = suit
    card.val = val
    
    local path = string.format('sprites/cards/%s%s.png',suit,val)
    card.image = love.graphics.newImage(path)
    
    card.x = 100 + (#deck % 13) * (cardWidth + 5)
    card.y = 100 + math.floor(#deck / 13) * (cardHeight + 5)
    table.insert(deck,card)
    
    end
  end
end



function Card.draw()

for _, card in ipairs(deck)
  do 
    love.graphics.draw(card.image,card.x,card.y)
  end
end

function Card.getDeck()
  return deck
  
end


return Card

