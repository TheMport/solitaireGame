-- Bottom stacks module for solitaire game
local BottomStack = {}
BottomStack.__index = BottomStack

-- Constants
local stackWidth = 64
local stackHeight = 64
local cardOffset = 20 -- Vertical offset for overlapping cards in a stack

-- Create a new bottom stack manager
function BottomStack.new()
    local self = setmetatable({}, BottomStack)
    self.stacks = {} -- Will hold all 7 stacks
    self:initialize()
    return self
end

-- Initialize the 7 bottom stacks
function BottomStack:initialize()
    local startX = 50
    local startY = 150
    local spacing = stackWidth + 20
    
    -- Create 7 stacks
    for i = 1, 7 do
        self.stacks[i] = {
            x = startX + (i-1) * spacing,
            y = startY,
            cards = {},
            faceUpIndices = {} -- Tracks which cards are face up
        }
    end
end

-- Deal initial cards to the bottom stacks (pyramid style)
function BottomStack:dealInitialCards(deck)
    local deckIndex = 1
    
    -- For each stack (1-7), deal i cards
    for i = 1, 7 do
        for j = 1, i do
            local card = deck[deckIndex]
            if card then
                -- Add the card to this stack
                table.insert(self.stacks[i].cards, card)
                
                -- Position the card (with offset for stacked cards)
                card.x = self.stacks[i].x
                card.y = self.stacks[i].y + (j-1) * cardOffset
                
                -- Only the top card in each stack is face up initially
                card.faceUp = (j == i)
                if card.faceUp then
                    self.stacks[i].faceUpIndices[j] = true
                end
                
                deckIndex = deckIndex + 1
            end
        end
    end
    
    return deckIndex -- Return the next available index in the deck
end

-- Check if a card can be added to a stack
function BottomStack:canAddCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    -- If stack is empty, only kings can be placed
    if #stack.cards == 0 then
        return card.val == "K"
    end
    
    -- Get the top card of the stack
    local topCard = stack.cards[#stack.cards]
    
    -- Check if the card is the opposite color and one value lower
    return isOppositeColor(card, topCard) and isOneValueLower(card, topCard)
end

-- Add a card to a stack
function BottomStack:addCard(stackIndex, card)
    local stack = self.stacks[stackIndex]
    
    -- Position the card
    card.x = stack.x
    card.y = stack.y + #stack.cards * cardOffset
    
    -- Add the card to the stack
    table.insert(stack.cards, card)
    stack.faceUpIndices[#stack.cards] = true
    card.faceUp = true
end

-- Remove the top card from a stack
function BottomStack:removeTopCard(stackIndex)
    local stack = self.stacks[stackIndex]
    if #stack.cards > 0 then
        local card = table.remove(stack.cards)
        stack.faceUpIndices[#stack.cards + 1] = nil
        
        -- If there's still cards in the stack, turn the new top card face up
        if #stack.cards > 0 and not stack.faceUpIndices[#stack.cards] then
            stack.faceUpIndices[#stack.cards] = true
            stack.cards[#stack.cards].faceUp = true
        end
        
        return card
    end
    return nil
end

-- Draw all the bottom stacks
function BottomStack:draw()
    -- Draw empty stack placeholders
    for i, stack in ipairs(self.stacks) do
        love.graphics.setColor(0.2, 0.5, 0.2)
        love.graphics.rectangle("line", stack.x, stack.y, stackWidth, stackHeight)
        love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw the cards in each stack
    for i, stack in ipairs(self.stacks) do
        for j, card in ipairs(stack.cards) do
            if card.faceUp then
                love.graphics.draw(card.image, card.x, card.y)
            else
                -- Draw card back
                love.graphics.setColor(0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", card.x, card.y, stackWidth, stackHeight)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
end

-- Check if mouse is over a specific card in the bottom stacks
function BottomStack:getCardAtPosition(x, y)
    -- Check each stack from top to bottom
    for i = #self.stacks, 1, -1 do
        local stack = self.stacks[i]
        -- Check each card from top to bottom
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

-- Helper functions
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