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
end
--setup is readable
function love.update(dt)
    grabber:update(Card.getDeck(), bottomStacks, topStacks, gameDeck)
    
    if gameState.cardsDealt and not gameState.gameWon then
        if checkWinCondition() then
            gameState.gameWon = true
            print("Congratulations! You've won!")
        end
    end
end
--very simple update, is clean but also makes me wonder where all the code is
function love.draw()
    bottomStacks:draw()
    
    topStacks:draw()
    
    gameDeck:draw()
    
    if grabber.heldObject then
        love.graphics.draw(grabber.heldObject.image, grabber.heldObject.x, grabber.heldObject.y)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Click deck to draw cards", 10, 10)
    
    if gameState.gameWon then
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Congratulations! You've won!", 0, 300, love.graphics.getWidth(), "center")
    end
    
    love.graphics.setColor(1, 1, 1)
end
--I feel that draw should be reserved for drawing functions exclusively
function love.mousepressed(x, y, button)
    if button == 1 then 
        
        if gameDeck:isOverStockPile(x, y) then
            gameDeck:drawThreeCards()
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
--probably shouldn't hard code these functions into generic classes like grabber
function checkWinCondition()
    for i, stack in ipairs(topStacks.stacks) do
        if #stack.cards == 0 or stack.cards[#stack.cards].val ~= "K" then
            return false
        end
    end
    return true
end
--this is a good example of what the professor is likely asking for: modularization in the main function for gameplay functionality