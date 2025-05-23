local Card = require "cards"

local GameDeck = {}
GameDeck.__index = GameDeck


local deckWidth = 64
local deckHeight = 64
local deckSpacing = 20

function GameDeck.new()
    local self = setmetatable({}, GameDeck)
    
    self.stockPile = {
        x = 50,
        y = 50,
        cards = {}
    }
    
    self.wastePile = {
        x = 50 + deckWidth + deckSpacing,
        y = 50,
        cards = {}
    }
    
    return self
end

function GameDeck:initialize(cards)
    self.stockPile.cards = cards
    
    for _, card in ipairs(self.stockPile.cards) do
        card.faceUp = false
        card.x = self.stockPile.x
        card.y = self.stockPile.y
        card.originalPile = "stock" -- Track which pile the card belongs to
    end
end

function GameDeck:drawCard()
    if #self.stockPile.cards > 0 then
        local card = table.remove(self.stockPile.cards)
        
        card.faceUp = true
        card.x = self.wastePile.x
        card.y = self.wastePile.y
        card.originalPile = "waste" -- updates pile for the card
        
        table.insert(self.wastePile.cards, card)
        
        return card
    else
        self:recycleWastePile()
    end
end

function GameDeck:drawThreeCards()
    for i = 1, 3 do
        if #self.stockPile.cards > 0 then
            self:drawCard()
        else
            break
        end
    end
    
    self:arrangeWastePile()
end

function GameDeck:arrangeWastePile()
    if #self.wastePile.cards == 0 then
        return
    end

    local offset = 15 
    local count = #self.wastePile.cards


    local startIdx = math.max(1, count - 2)

    for i = startIdx, count do
        local card = self.wastePile.cards[i]
        local displayPos = i - startIdx
        card.x = self.wastePile.x + (displayPos * offset)
        card.y = self.wastePile.y
    end
end


function GameDeck:recycleWastePile()
    if #self.wastePile.cards == 0 then
        return
    end
    
    while #self.wastePile.cards > 0 do
        local card = table.remove(self.wastePile.cards)
        card.faceUp = false
        card.x = self.stockPile.x
        card.y = self.stockPile.y
        card.originalPile = "stock" 
        table.insert(self.stockPile.cards, card)
    end
end

function GameDeck:getTopWasteCard()
    if #self.wastePile.cards > 0 then
        return self.wastePile.cards[#self.wastePile.cards]
    end
    return nil
end

function GameDeck:removeTopWasteCard()
    if #self.wastePile.cards > 0 then
        local card = table.remove(self.wastePile.cards)
        self:arrangeWastePile()
        return card
    end
    return nil
end

function GameDeck:isOverStockPile(x, y)
    return x >= self.stockPile.x and x <= self.stockPile.x + deckWidth and
           y >= self.stockPile.y and y <= self.stockPile.y + deckHeight
end

function GameDeck:isOverWastePile(x, y)
    local count = #self.wastePile.cards
    if count == 0 then
        return false
    end
    

    local startIdx = math.max(1, count - 2)
    for i = startIdx, count do
        local card = self.wastePile.cards[i]
        if x >= card.x and x <= card.x + deckWidth and
           y >= card.y and y <= card.y + deckHeight then
            -- only allows picking the top card
            if i == count then
                return true
            end
        end
    end
    
    return false
end

function GameDeck:getCardAtPosition(x, y)
    -- only return the top card when clicked
    if self:isOverWastePile(x, y) and #self.wastePile.cards > 0 then
        return self.wastePile.cards[#self.wastePile.cards]
    end
    return nil
end

function GameDeck:returnCardToOriginalPosition(card)
    if card.originalPile == "waste" then
        card.x = self.wastePile.x
        card.y = self.wastePile.y
        table.insert(self.wastePile.cards, card)
        self:arrangeWastePile()
        return true
    end
    return false
end

function GameDeck:isOverDeckArea(x, y)
    return self:isOverStockPile(x, y) or self:isOverWastePile(x, y)
end

function GameDeck:draw()

    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.rectangle("line", self.stockPile.x, self.stockPile.y, deckWidth, deckHeight)
    
    if #self.stockPile.cards > 0 then
        love.graphics.setColor(0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", self.stockPile.x, self.stockPile.y, deckWidth, deckHeight)
    end
    
    if #self.stockPile.cards == 0 and #self.wastePile.cards > 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.circle("line", self.stockPile.x + deckWidth/2, self.stockPile.y + deckHeight/2, 15)
        love.graphics.print("↻", self.stockPile.x + deckWidth/2 - 5, self.stockPile.y + deckHeight/2 - 10)
    end
    

    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.rectangle("line", self.wastePile.x, self.wastePile.y, deckWidth, deckHeight)
    

    love.graphics.setColor(1, 1, 1)
    local count = #self.wastePile.cards
    local startIdx = math.max(1, count - 2)
    
    for i = startIdx, count do
        local card = self.wastePile.cards[i]
        love.graphics.draw(card.image, card.x, card.y)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return GameDeck