local TopStack = {}
TopStack.__index = TopStack

local stackWidth = 64
local stackHeight = 64
local stackSpacing = 20

function TopStack.new()
    local self = setmetatable({}, TopStack)
    self.stacks = {} 
    self:initialize()
    return self
end


  -- STACKS
function TopStack:initialize()
    local startX = 300
    local startY = 50
    local spacing = stackWidth + stackSpacing
    
    for i = 1, 4 do
        self.stacks[i] = {
            x = startX + (i-1) * spacing,
            y = startY,
            cards = {},
            suit = nil
        }
    end
end

function TopStack:canAddCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    -- ACE ONLY & CHECKS
    if #stack.cards == 0 then
        return card.val == "A"
    end
    
    if stack.suit and card.suit ~= stack.suit then
        return false
    end
    
    local topCard = stack.cards[#stack.cards]
    
    return isOneValueHigher(card, topCard)
end

function TopStack:addCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    if #stack.cards == 0 then
        stack.suit = card.suit
    end
    
    card.x = stack.x
    card.y = stack.y
    
    table.insert(stack.cards, card)
    card.faceUp = true
    
    if card.val == "K" then
        print("Completed suit: " .. stack.suit)
    end
end

function TopStack:removeTopCard(stackIndex)
    local stack = self.stacks[stackIndex]
    if #stack.cards > 0 then
        local card = table.remove(stack.cards)
        
        if #stack.cards == 0 then
            stack.suit = nil
        end
        
        return card
    end
    return nil
end

-- CREATE STACKS
function TopStack:draw()
    for i, stack in ipairs(self.stacks) do
        love.graphics.setColor(0.2, 0.4, 0.8)
        love.graphics.rectangle("line", stack.x, stack.y, stackWidth, stackHeight)
        
        if stack.suit then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf(stack.suit:sub(1,1):upper(), stack.x + 5, stack.y + 25, stackWidth - 10, "center")
        end
        
        love.graphics.setColor(1, 1, 1)
    end
    
    for i, stack in ipairs(self.stacks) do
        if #stack.cards > 0 then
            local topCard = stack.cards[#stack.cards]
            love.graphics.draw(topCard.image, topCard.x, topCard.y)
        end
    end
end

function TopStack:getStackAtPosition(x, y)
    for i, stack in ipairs(self.stacks) do
        if x >= stack.x and x <= stack.x + stackWidth and
           y >= stack.y and y <= stack.y + stackHeight then
            return i
        end
    end
    return nil
end

function TopStack:getCardAtPosition(x, y)
    for i, stack in ipairs(self.stacks) do
        if #stack.cards > 0 then
            local card = stack.cards[#stack.cards]
            if x >= card.x and x <= card.x + stackWidth and
               y >= card.y and y <= card.y + stackHeight then
                return card, i
            end
        end
    end
    return nil
end

  -- VAL CHECKER
function isOneValueHigher(card1, card2)
    local values = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, 
                     ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
    
    return values[card1.val] == values[card2.val] + 1
end

return TopStack