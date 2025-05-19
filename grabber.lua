local Vector = require "Vector"

local GrabberClass = {}
GrabberClass.__index = GrabberClass

function GrabberClass:new()
    local grabber = setmetatable({}, GrabberClass)
    grabber.currentMousePos = Vector(0, 0)
    grabber.grabOffset = Vector(0, 0)
    grabber.heldObject = nil
    grabber.heldCards = {} -- when holding multiple cards
    grabber.sourceType = nil  -- "bottom", "top", or "waste"
    grabber.sourceStack = nil
    grabber.sourceIndex = nil
    return grabber
end

function GrabberClass:update(deck, bottomStacks, topStacks, gameDeck)
    self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())
    
    -- UPDATE POSITION of held object and all held cards
    if self.heldObject then
        self.heldObject.x = self.currentMousePos.x - self.grabOffset.x
        self.heldObject.y = self.currentMousePos.y - self.grabOffset.y
        
        -- Update all held cards to maintain proper stack 
        for i, card in ipairs(self.heldCards) do
            card.x = self.heldObject.x
            card.y = self.heldObject.y + (i-1) * 20 -- spaced out
        end
    end
end

function GrabberClass:onMousePressed(x, y, bottomStacks, topStacks, gameDeck)
    self.currentMousePos = Vector(x, y)
    
    -- Check waste pile first
    local wasteCard = gameDeck:getCardAtPosition(x, y)
    
if wasteCard then
    -- Remove the card from the waste pile to prevent dups
    gameDeck:removeTopWasteCard()

    self.heldObject = wasteCard
    self.heldCards = {wasteCard}
    self.sourceType = "waste"
    self.grabOffset = Vector(x - wasteCard.x, y - wasteCard.y)
    return
end
    
    -- Check top foundation stacks
    local topCard, topStackIndex = topStacks:getCardAtPosition(x, y)
    
    if topCard then
        self.heldObject = topCard
        self.heldCards = {topCard} -- Single card
        self.sourceType = "top"
        self.sourceStack = topStackIndex
        self.sourceIndex = #topStacks.stacks[topStackIndex].cards
        
        self.grabOffset = Vector(x - topCard.x, y - topCard.y)
        return
    end
    
    -- Check bottom stacks
    local bottomCard, bottomStackIndex, cardIndex = bottomStacks:getCardAtPosition(x, y)
    
    if bottomCard and bottomCard.faceUp then
        self.heldObject = bottomCard
        self.sourceType = "bottom"
        self.sourceStack = bottomStackIndex
        self.sourceIndex = cardIndex
        
        -- Grab all cards from cardIndex to the end of the stack
        self.heldCards = {}
        local stack = bottomStacks.stacks[bottomStackIndex].cards
        for i = cardIndex, #stack do
            table.insert(self.heldCards, stack[i])
        end
        
        self.grabOffset = Vector(x - bottomCard.x, y - bottomCard.y)
    end
end

function GrabberClass:onMouseReleased(x, y, bottomStacks, topStacks, gameDeck)
    if not self.heldObject then return end
    
    local placed = false
    
    -- Check top foundation stacks first
    local topStackIndex = topStacks:getStackAtPosition(x, y)
    
    if topStackIndex then
        -- Only single cards can go to top stacks
        if #self.heldCards == 1 and topStacks:canAddCard(topStackIndex, self.heldObject) then
            -- Record move for undo
            recordMove({
                moveType = "add_to_foundation",
                cardMoved = self.heldObject,
                sourceType = self.sourceType,
                sourceStack = self.sourceStack,
                sourceIndex = self.sourceIndex,
                targetStack = topStackIndex,
                cardStack = self.heldCards
            })
            
            self:removeFromSource(bottomStacks, topStacks, gameDeck)
            
            topStacks:addCard(topStackIndex, self.heldObject)
            placed = true
        end
    end
    
    -- Check bottom stacks if not placed on top
    if not placed then
        local targetStackIndex = nil
        
        for i, stack in ipairs(bottomStacks.stacks) do

            if x >= stack.x and x <= stack.x + 64 and
               y >= stack.y and y <= stack.y + 300 then
                targetStackIndex = i
                break
            end
        end
        
        if targetStackIndex and bottomStacks:canAddCard(targetStackIndex, self.heldObject) then
            -- Record move for undo
            recordMove({
                moveType = "add_to_tableau",
                cardMoved = self.heldObject,
                sourceType = self.sourceType,
                sourceStack = self.sourceStack,
                sourceIndex = self.sourceIndex,
                targetStack = targetStackIndex,
                cardStack = self.heldCards
            })
            
            self:removeFromSource(bottomStacks, topStacks, gameDeck)
            
            -- Add all held cards to the destination stack
            for j, card in ipairs(self.heldCards) do
                bottomStacks:addCard(targetStackIndex, card)
            end
            
            -- Update positions
            bottomStacks:updatePositions()
            placed = true
        end
    end
    
    -- Return cards to source if not placed
    if not placed then
        self:returnToSource(bottomStacks, topStacks, gameDeck)
    end
    
    -- Reset grabber 
    self.heldObject = nil
    self.heldCards = {}
    self.sourceType = nil
    self.sourceStack = nil
    self.sourceIndex = nil
end

function GrabberClass:removeFromSource(bottomStacks, topStacks, gameDeck)
    if self.sourceType == "bottom" then

        local cardsToRemove = #bottomStacks.stacks[self.sourceStack].cards - self.sourceIndex + 1
        for i = 1, cardsToRemove do
            table.remove(bottomStacks.stacks[self.sourceStack].cards, self.sourceIndex)
        end
        
        -- Turn over the new top card if needed
        if self.sourceIndex > 1 and #bottomStacks.stacks[self.sourceStack].cards >= self.sourceIndex - 1 then
            local newTopIndex = self.sourceIndex - 1
            if bottomStacks.stacks[self.sourceStack].cards[newTopIndex] then
                bottomStacks.stacks[self.sourceStack].cards[newTopIndex].faceUp = true
            end
        end
    elseif self.sourceType == "top" then
        topStacks:removeTopCard(self.sourceStack)
    elseif self.sourceType == "waste" then
        gameDeck:removeTopWasteCard()
    end
end

function GrabberClass:returnToSource(bottomStacks, topStacks, gameDeck)
    if self.sourceType == "bottom" then
        local stack = bottomStacks.stacks[self.sourceStack]
        

        while #stack.cards >= self.sourceIndex do
            table.remove(stack.cards)
        end

        -- Restore held cards to original position
        for i, card in ipairs(self.heldCards) do
            table.insert(stack.cards, card)
        end

        -- update positions
        bottomStacks:updatePositions()

    elseif self.sourceType == "top" then
        local stack = topStacks.stacks[self.sourceStack]
        table.insert(stack.cards, self.heldObject)
        self.heldObject.x = stack.x
        self.heldObject.y = stack.y

    elseif self.sourceType == "waste" then
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

-- Record moves
function recordMove(moveData)
    if not _G.moveHistory then
        _G.moveHistory = {}
    end
    
    table.insert(_G.moveHistory, moveData)
    

    if #_G.moveHistory > 100 then
        table.remove(_G.moveHistory, 1)
    end
end

return GrabberClass