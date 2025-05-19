
local BottomStack = {}
BottomStack.__index = BottomStack

-- Constants
local stackWidth = 64
local stackHeight = 64
local cardOffset = 20 -- make stacked cards visible 


function BottomStack.new()
    local self = setmetatable({}, BottomStack)
    self.stacks = {} -- the bottom 7 stacks
    self:initialize()
    return self
end


function BottomStack:initialize()
    local startX = 50
    local startY = 150
    local spacing = stackWidth + 20
    

    for i = 1, 7 do
        self.stacks[i] = {
            x = startX + (i-1) * spacing,
            y = startY,
            cards = {},
            faceUpIndices = {} -- Track face up cards
        }
    end
end


function BottomStack:dealInitialCards(deck)
    local deckIndex = 1
    

    for i = 1, 7 do
        for j = 1, i do
            local card = deck[deckIndex]
            if card then

                table.insert(self.stacks[i].cards, card)
                

                card.x = self.stacks[i].x
                card.y = self.stacks[i].y + (j-1) * cardOffset
                

                card.faceUp = (j == i)
                if card.faceUp then
                    self.stacks[i].faceUpIndices[j] = true
                end
                
                deckIndex = deckIndex + 1
            end
        end
    end
    
    return deckIndex -- Returns next following card
end

-- Check if possible for the card to stack
function BottomStack:canAddCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    -- king only if stack is 0
    if #stack.cards == 0 then
        return card.val == "K"
    end
    

    local topCard = stack.cards[#stack.cards]
    
    -- Check if possible
    return isOppositeColor(card, topCard) and isOneValueLower(card, topCard)
end


function BottomStack:addCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    card.x = stack.x
    card.y = stack.y + #stack.cards * cardOffset
    

    table.insert(stack.cards, card)
    stack.faceUpIndices[#stack.cards] = true
    card.faceUp = true
end


function BottomStack:removeTopCard(stackIndex)
    local stack = self.stacks[stackIndex]
    if #stack.cards > 0 then
        local card = table.remove(stack.cards)
        stack.faceUpIndices[#stack.cards + 1] = nil
        

        if #stack.cards > 0 and not stack.faceUpIndices[#stack.cards] then
            stack.faceUpIndices[#stack.cards] = true
            stack.cards[#stack.cards].faceUp = true
        end
        
        return card
    end
    return nil
end


function BottomStack:draw()

    for i, stack in ipairs(self.stacks) do
        love.graphics.setColor(0.2, 0.5, 0.2)
        love.graphics.rectangle("line", stack.x, stack.y, stackWidth, stackHeight)
        love.graphics.setColor(1, 1, 1)
    end
    

    for i, stack in ipairs(self.stacks) do
        for j, card in ipairs(stack.cards) do
            if card.faceUp then
                love.graphics.draw(card.image, card.x, card.y)
            else
                -- back of the cards
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", card.x, card.y, stackWidth, stackHeight)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

--  checks stacks top to bottom
function BottomStack:getCardAtPosition(x, y)

    for i = #self.stacks, 1, -1 do
        local stack = self.stacks[i]

        for j = #stack.cards, 1, -1 do
            local card = stack.cards[j]
            if card.faceUp then
                if x >= card.x and x <= card.x + stackWidth and
                   y >= card.y and y <= card.y + stackHeight then
                    return card, i, j
                end
            end
        end
    end
    return nil
end

-- ensures correct positioning
function BottomStack:updatePositions()
    for stackIndex, stack in ipairs(self.stacks) do
        for cardIndex, card in ipairs(stack.cards) do
            card.x = stack.x
            card.y = stack.y + (cardIndex - 1) * cardOffset
        end
    end
end


function isOppositeColor(card1, card2)
    local card1Color = getCardColor(card1.suit)
    local card2Color = getCardColor(card2.suit)
    return card1Color ~= card2Color
end

function getCardColor(suit)
    if suit == "hearts" or suit == "diamonds" then
        return "red"
    else
        return "black"
    end
end

function isOneValueLower(card1, card2)
    local values = {A=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7, 
                     ["8"]=8, ["9"]=9, ["10"]=10, J=11, Q=12, K=13}
    return values[card1.val] == values[card2.val] - 1
end

return BottomStack