local Vector = require "Vector"

local GrabberClass = {}
GrabberClass.__index = GrabberClass

function GrabberClass:new()
    local grabber = setmetatable({}, GrabberClass)
    grabber.currentMousePos = Vector(0, 0)
    grabber.grabOffset = Vector(0, 0)
    grabber.heldObject = nil
    grabber.sourceType = nil  -- "bottom", "top", or "waste"
    grabber.sourceStack = nil
    grabber.sourceIndex = nil
    return grabber
end

function GrabberClass:update(deck, bottomStacks, topStacks, gameDeck)
    self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())
    
    -- UPDATE POSITION
    if self.heldObject then
        self.heldObject.x = self.currentMousePos.x - self.grabOffset.x
        self.heldObject.y = self.currentMousePos.y - self.grabOffset.y
    end
end

function GrabberClass:onMousePressed(x, y, bottomStacks, topStacks, gameDeck)
    self.currentMousePos = Vector(x, y)
    
    local wasteCard = gameDeck:getCardAtPosition(x, y)
    
    if wasteCard then
        self.heldObject = wasteCard
        self.sourceType = "waste"
        
        self.grabOffset = Vector(x - wasteCard.x, y - wasteCard.y)
        return
    end
    
    -- CHECK TO PLACE STACKS
    local topCard, topStackIndex = topStacks:getCardAtPosition(x, y)
    
    if topCard then
        self.heldObject = topCard
        self.sourceType = "top"
        self.sourceStack = topStackIndex
        self.sourceIndex = #topStacks.stacks[topStackIndex].cards
        
        self.grabOffset = Vector(x - topCard.x, y - topCard.y)
        return
    end
    
    local bottomCard, bottomStackIndex, cardIndex = bottomStacks:getCardAtPosition(x, y)
    
    if bottomCard and bottomCard.faceUp then
        self.heldObject = bottomCard
        self.sourceType = "bottom"
        self.sourceStack = bottomStackIndex
        self.sourceIndex = cardIndex
        
        
        self.grabOffset = Vector(x - bottomCard.x, y - bottomCard.y)
    end
end

function GrabberClass:onMouseReleased(x, y, bottomStacks, topStacks, gameDeck)
    if not self.heldObject then return end
    
    local placed = false
    
    -- CHECKS TO SEE IF CARD PLACEMENT IS POSSIBLE
    local topStackIndex = topStacks:getStackAtPosition(x, y)
    
    if topStackIndex then
        if topStacks:canAddCard(topStackIndex, self.heldObject) then
            self:removeFromSource(bottomStacks, topStacks, gameDeck)
            
            topStacks:addCard(topStackIndex, self.heldObject)
            placed = true
            
            -- CHECK WIN CON
        end
    end
    
    -- CARD PLACEMENT 
    if not placed then
        for i, stack in ipairs(bottomStacks.stacks) do
            -- Check if mouse is over this stack
            if x >= stack.x and x <= stack.x + 64 and
               y >= stack.y and y <= stack.y + 64 + (#stack.cards * 20) then
                
                if bottomStacks:canAddCard(i, self.heldObject) then
                    self:removeFromSource(bottomStacks, topStacks, gameDeck)
                    
                    bottomStacks:addCard(i, self.heldObject)
                    placed = true
                    break
                end
            end
        end
    end
    
    -- RETURN
    if not placed then
        self:returnToSource(bottomStacks, topStacks, gameDeck)
    end
    
    self.heldObject = nil
    self.sourceType = nil
    self.sourceStack = nil
    self.sourceIndex = nil
end

function GrabberClass:removeFromSource(bottomStacks, topStacks, gameDeck)
    if self.sourceType == "bottom" then
        table.remove(bottomStacks.stacks[self.sourceStack].cards, self.sourceIndex)
        
        -- FACE UP UPDATE
        if self.sourceIndex > 1 and #bottomStacks.stacks[self.sourceStack].cards >= self.sourceIndex - 1 then
            local newTopIndex = self.sourceIndex - 1
            if bottomStacks.stacks[self.sourceStack].cards[newTopIndex] then
                bottomStacks.stacks[self.sourceStack].cards[newTopIndex].faceUp = true
                bottomStacks.stacks[self.sourceStack].faceUpIndices[newTopIndex] = true
            end
        end
    elseif self.sourceType == "top" then
        
        topStacks:removeTopCard(self.sourceStack)
    elseif self.sourceType == "waste" then
        gameDeck:removeTopWasteCard()
    end
end

-- RETURN BACK
function GrabberClass:returnToSource(bottomStacks, topStacks, gameDeck)
    if self.sourceType == "bottom" then
        local stack = bottomStacks.stacks[self.sourceStack]
        
        if self.sourceIndex > #stack.cards then
            table.insert(stack.cards, self.heldObject)
        else
            stack.cards[self.sourceIndex] = self.heldObject
        end
        
        self.heldObject.x = stack.x
        self.heldObject.y = stack.y + (self.sourceIndex - 1) * 20
    elseif self.sourceType == "top" then
        local stack = topStacks.stacks[self.sourceStack]
        
        -- TO THE TOP
        table.insert(stack.cards, self.heldObject)
        
        self.heldObject.x = stack.x
        self.heldObject.y = stack.y
    elseif self.sourceType == "waste" then
        -- Add back to waste pile
        table.insert(gameDeck.wastePile.cards, self.heldObject)
        gameDeck:arrangeWastePile()
    end
end


function GrabberClass:isMouseOver(card)
    if not card then return false end
    
    local mx, my = self.currentMousePos.x, self.currentMousePos.y
    return mx >= card.x and mx <= card.x + 64 and
           my >= card.y and my <= card.y + 64
end

return GrabberClass