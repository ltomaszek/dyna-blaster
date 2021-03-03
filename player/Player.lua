require 'settings.settings'
require 'weapon.Bomb'

PLAYER_SIZE = 32
PHS = PLAYER_SIZE / 2 -- player half size


PLAYERS_IMG = love.graphics.newImage("graphics/players.png")
DEAD_PLAYER_IMG = love.graphics.newQuad(0 * PLAYER_SIZE, PLAYER_SIZE, PLAYER_SIZE, PLAYER_SIZE, PLAYERS_IMG)

function newPlayer(world, playerId)
    local player = {}

    player.world = world
    
    player.id = playerId
    player.img = love.graphics.newQuad((player.id - 1) * PLAYER_SIZE, 0, PLAYER_SIZE, PLAYER_SIZE, PLAYERS_IMG)

    local XY = world:getCornerCoordinatesForSpotId( world:getStartPosition(player.id) )
    player.x = XY.X  
    player.y = XY.Y

    player.speed = PLAYER_SPEED     -- update it in the game
 
    player.direction = 'u'    -- d, l, r

    -- bomb properties
    player.bombRange = 1
    player.currBombId = 1                       -- from 1 to #bombs
    player.bombs = {}
    player.bombs[1] = newBomb(player.bombRange)

    player.isAlive = true
    player.deathTime = 0
    player.wins = 0
    
    -- bomb updates is in the world class
    function player:update(dt)

        if love.keyboard.isDown(PLAYER_KEYS[self.id].up) then
            self:goUp(dt)
        elseif love.keyboard.isDown(PLAYER_KEYS[self.id].down) then
            self:goDown(dt)
        elseif love.keyboard.isDown(PLAYER_KEYS[self.id].left) then
            self:goLeft(dt)
        elseif love.keyboard.isDown(PLAYER_KEYS[self.id].right) then
            self:goRight(dt) 
        end
       
        -- check for bonuses
        self:checkForBonuses()

        -- place bomb when space is empty
        if love.keyboard.isDown(PLAYER_KEYS[self.id].bomb) then
            bomb = self.bombs[self.currBombId]
            
            -- if exploded remove and add new
            if bomb:isExploded() then
                self.bombs[self.currBombId] = newBomb(self.bombRange)
            end

            -- check if next bomb available and try to activate it (the world decides if its possible)
            if bomb:isPlaced() == false then

                spotId = self.world:getSpotId(self.x + PHS, self.y + PHS)
                
                if self.world:addBomb(spotId, bomb) then
                    self.currBombId = self.currBombId + 1
                    if self.currBombId > #self.bombs then
                        self.currBombId = 1
                    end
                end
            end
        end
    end

    function player:checkForBonuses()
        spotId = self.world:getSpotId(self.x + PHS, self.y + PHS)
        bonus = self.world:getBonusOnSpot(spotId)

        if bonus == nil then
            return
        end

        -- remove bonuses from map
        self.world:removeType(spotId, bonus)
        
        if bonus == SPOT_TYPE.bonusBomb then
            -- move all bombs from position currBombIt to the right
            for i = #self.bombs, self.currBombId, -1 do
                self.bombs[i + 1] = self.bombs[i]
            end

            -- add new bomb at position currBombId
            self.bombs[self.currBombId] = newBomb(self.bombRange)


        elseif bonus == SPOT_TYPE.bonusRange then
            -- increase range
            self.bombRange = self.bombRange + 1

            -- update all bombs range
            for i = 1, #self.bombs do
                self.bombs[i].range = self.bombRange
            end
        end



    end

    function player:canMoveTo(x, y)
        newSpotId = self.world:getSpotId(x, y)
        spotType = self.world:getSpotType( newSpotId )
        
        if spotType == SPOT_TYPE.empty then
            return true 

        elseif spotType == SPOT_TYPE.fire then 
            if self.world:isTypeOnSpot(newSpotId, SPOT_TYPE.brick) then
                return false
            else
                return true
            end
        -- check if your current posision is the same as the new one
        -- if so you can still walk on the bomb if not you can not
        elseif spotType == SPOT_TYPE.bomb then
            currSpotId = self.world:getSpotId(self.x + PHS, self.y + PHS)
            if currSpotId == newSpotId then
                return true
            end

        elseif spotType == SPOT_TYPE.bonusBomb or spotType == SPOT_TYPE.bonusRange then
            return true
        end

    
    end

    -- movement
    function player:goUp(dt)
        local newY = self.y - self.speed * dt
        
        if self:canMoveTo(self.x + PHS, newY) then
            if self:haveToAdjustPosition('u') then
                self:adjustPositionX()
            end
            self.y = newY
            self.direction = 'u'
        elseif self.direction == 'u' then
            self:adjustPositionY()  -- must be adjusted otherwise ghost will not really touch wall completely
        end
    end

    function player:goDown(dt)
        local newY = self.y + self.speed * dt
        
        if self:canMoveTo(self.x + PHS, newY + PLAYER_SIZE) then
            if self:haveToAdjustPosition('d') then
                self:adjustPositionX()
            end
            self.y = newY
            self.direction = 'd'
        elseif self.direction == 'd' then
            self:adjustPositionY() 
        end
    end

    function player:goLeft(dt)
        local newX = self.x - self.speed * dt
        
        if self:canMoveTo(newX, self.y + PHS) then
            if self:haveToAdjustPosition('l') then
                self:adjustPositionY()
            end
            self.x = newX
            self.direction = 'l'
        elseif self.direction == 'l' then
            self:adjustPositionX() 
        end
    end

    function player:goRight(dt)
        local newX = self.x + self.speed * dt
        
        if self:canMoveTo(newX + PLAYER_SIZE, self.y + PHS) then
            if self:haveToAdjustPosition('r') then
                self:adjustPositionY()
            end
            self.x = newX
            self.direction = 'r'
        elseif self.direction == 'r' then
            self:adjustPositionX() 
        end
    end

    -- adjust coordinates x before moving up/down 
    function player:adjustPositionX()
        local mod = self.x % SPOT_SIZE
        if mod > SPOT_SIZE/ 2 then            -- move to right
            self.x = self.x + SPOT_SIZE- mod
        else 
            self.x = self.x - mod
        end
    end

    -- check if coordinates must be adjusted
    function player:haveToAdjustPosition(newDirection)
        if self.direction == newDirection then          -- happens most often
            return false;
        end

        if (self.direction == 'u' or self.direction == 'd') and
            (newDirection == 'u' or newDirection == 'd') then
            return false
        end

        if (self.direction == 'l' or self.direction == 'r') and
            (newDirection == 'l' or newDirection == 'r') then
            return false
        end

        return true
    end

    -- adjust coordinates y before moving left/right 
    function player:adjustPositionY()
        local mod = self.y % SPOT_SIZE
        if mod > SPOT_SIZE / 2 then            -- move to right
            self.y = self.y + SPOT_SIZE- mod
        else 
            self.y = self.y - mod
        end
    end

    function player:draw()
        love.graphics.draw(PLAYERS_IMG, self.img, self.x, self.y)
    end

    return player

end