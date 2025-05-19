local Card = require "cards"
local GrabberClass = require 'grabber'
local BottomStack = require 'bottomStacks'
local TopStack = require 'topStacks'
local GameDeck = require 'deck'


local grabber
local bottomStacks
local topStacks
local gameDeck
local gameState = {
    cardsDealt = false,
    gameWon = false
}

-- Initialize global move history
_G.moveHistory = {}


local undoButton = {
    x = 700,
    y = 10,
    width = 80,
    height = 30,
    text = "UNDO"
}

function love.load()
    love.window.setTitle('Solitaire')
    love.graphics.setBackgroundColor(0, 0.5, 0)
    
    -- RNG
    math.randomseed(os.time())
    
    Card.load()
    local allCards = Card.getDeck()
    
    bottomStacks = BottomStack.new()
    topStacks = TopStack.new()
    gameDeck = GameDeck.new()
    
    local usedCardIndex = bottomStacks:dealInitialCards(allCards)
    
    local remainingCards = {}
    for i = usedCardIndex, #allCards do
        table.insert(remainingCards, allCards[i])
    end
    gameDeck:initialize(remainingCards)
    
    grabber = GrabberClass:new()
    
    gameState.cardsDealt = true
    
    -- Clear move history
    _G.moveHistory = {}
end

function love.update(dt)
    grabber:update(Card.getDeck(), bottomStacks, topStacks, gameDeck)
    
    if gameState.cardsDealt and not gameState.gameWon then
        if checkWinCondition() then
            gameState.gameWon = true
            print("Congratulations! You've won!")
        end
    end
end

function love.draw()
    bottomStacks:draw()
    
    topStacks:draw()
    
    gameDeck:draw()
    
    if grabber.heldObject then

        local yOffset = 0
        
        -- Draw all held cards with proper vertical spacing
        for i, card in ipairs(grabber.heldCards) do
            love.graphics.draw(card.image, grabber.heldObject.x, grabber.heldObject.y + yOffset)
            yOffset = yOffset + 20 
        end
    end
    
    --  create top left text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Click deck to draw cards", 10, 10)
    
    --create undo button
    love.graphics.setColor(0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", undoButton.x, undoButton.y, undoButton.width, undoButton.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(undoButton.text, undoButton.x, undoButton.y + 7, undoButton.width, "center")
    
    if #_G.moveHistory == 0 then

        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", undoButton.x, undoButton.y, undoButton.width, undoButton.height)
    end
    
    --  game winnder screen
    if gameState.gameWon then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Congratulations! You've won!", 0, 300, love.graphics.getWidth(), "center")
    end
    
    love.graphics.setColor(1, 1, 1)
end

function love.mousepressed(x, y, button)
    if button == 1 then 
        

        if isMouseOverButton(x, y, undoButton) and #_G.moveHistory > 0 then
            undoLastMove()
            return
        end
        
if gameDeck:isOverStockPile(x, y) then

    if #gameDeck.stockPile.cards == 0 then
        gameDeck:recycleWastePile()
    else
        -- Record draw move for undo
        local drawMove = {
            moveType = "draw",
            previousWastePile = tableCopy(gameDeck.wastePile.cards),
            previousStockPile = tableCopy(gameDeck.stockPile)
        }
        table.insert(_G.moveHistory, drawMove)

        gameDeck:drawThreeCards()
    end
    return
end

        
        grabber:onMousePressed(x, y, bottomStacks, topStacks, gameDeck)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then -- Left mouse button
        grabber:onMouseReleased(x, y, bottomStacks, topStacks, gameDeck)
    end
end

function isMouseOverButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function checkWinCondition()
    for i, stack in ipairs(topStacks.stacks) do
        if #stack.cards == 0 or stack.cards[#stack.cards].val ~= "K" then
            return false
        end
    end
    return true
end

-- Dupe table 
function tableCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = tableCopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

-- Undo the last move
function undoLastMove()
    if #_G.moveHistory == 0 then
        return -- Starts history of moves at nil
    end
    
    local lastMove = table.remove(_G.moveHistory)
    
    if lastMove.moveType == "draw" then
        gameDeck.wastePile.cards = lastMove.previousWastePile
        gameDeck.stockPile = lastMove.previousStockPile
        gameDeck:arrangeWastePile()
        
    elseif lastMove.moveType == "add_to_tableau" then
        -- Remove cards from target stack
        for i = 1, #lastMove.cardStack do
            table.remove(bottomStacks.stacks[lastMove.targetStack].cards)
        end
        
        -- Return cards to source
        if lastMove.sourceType == "bottom" then
            for i, card in ipairs(lastMove.cardStack) do
                table.insert(bottomStacks.stacks[lastMove.sourceStack].cards, card)
            end
            
            -- Update positions after returning cards ( a check)
            bottomStacks:updatePositions()
            
        elseif lastMove.sourceType == "top" then
            -- Add card back to top
            table.insert(topStacks.stacks[lastMove.sourceStack].cards, lastMove.cardMoved)
            
        elseif lastMove.sourceType == "waste" then

            table.insert(gameDeck.wastePile.cards, lastMove.cardMoved)
            gameDeck:arrangeWastePile()
        end
        
    elseif lastMove.moveType == "add_to_foundation" then
        -- Remove card from top
        topStacks:removeTopCard(lastMove.targetStack)
        
        -- Return card to source
        if lastMove.sourceType == "bottom" then
            table.insert(bottomStacks.stacks[lastMove.sourceStack].cards, lastMove.cardMoved)
            bottomStacks:updatePositions()
            
        elseif lastMove.sourceType == "top" then
            table.insert(topStacks.stacks[lastMove.sourceStack].cards, lastMove.cardMoved)
            
        elseif lastMove.sourceType == "waste" then
            table.insert(gameDeck.wastePile.cards, lastMove.cardMoved)
            gameDeck:arrangeWastePile()
        end
    end
end

    -- bottom check
if not BottomStack.updatePositions then
    function BottomStack:updatePositions()
        for stackIndex, stack in ipairs(self.stacks) do
            for cardIndex, card in ipairs(stack.cards) do
                card.x = stack.x
                card.y = stack.y + (cardIndex - 1) * 20
            end
        end
    end
end