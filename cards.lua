local Card = {}
Card.__index = Card

local cardWidth = 64
local cardHeight = 64

local deck = {}
local suits = {'hearts', 'diamonds', 'clubs', 'spades'}
local vals = {'A','2','3','4','5','6','7','8','9','10','J','Q','K'}

function Card.load()
    deck = {} 
    
    for _, suit in ipairs(suits) do 
        for _, val in ipairs(vals) do
            local card = setmetatable({}, Card)
            card.suit = suit
            card.val = val
            card.faceUp = false
            
            local path = string.format('sprites/cards/%s%s.png', suit, val)
            card.image = love.graphics.newImage(path)
            
            card.x = 0
            card.y = 0
            
            table.insert(deck, card)
        end
    end
    
    Card.shuffle()
end



function Card.shuffle()
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

--  DRAW CARDS
function Card.draw()
    for _, card in ipairs(deck) do
        if card.faceUp then
            love.graphics.draw(card.image, card.x, card.y)
        else
            love.graphics.setColor(0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", card.x, card.y, cardWidth, cardHeight)
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function Card.getDeck()
    return deck
end

function Card.moveCard(card, x, y)
    card.x = x
    card.y = y
end

  --  COMPATABILITY CHECK
function Card.canStackInTableau(topCard, bottomCard)
    local topCardColor = Card.getColor(topCard)
    local bottomCardColor = Card.getColor(bottomCard)
    
    if topCardColor == bottomCardColor then
        return false
    end
    
    local values = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, 
                     ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
    
    return values[topCard.val] == values[bottomCard.val] - 1
end

function Card.canStackInFoundation(bottomCard, topCard)
    if bottomCard.suit ~= topCard.suit then
        return false
    end
    
    local values = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, 
                     ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
    
    return values[bottomCard.val] + 1 == values[topCard.val]
end

function Card.getColor(card)
    if card.suit == "hearts" or card.suit == "diamonds" then
        return "red"
    else
        return "black"
    end
end

function Card.getValue(card)
    local values = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, 
                   ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
    return values[card.val]
end

function Card.isAce(card)
    return card.val == "A"
end

function Card.isKing(card)
    return card.val == "K"
end

return Card