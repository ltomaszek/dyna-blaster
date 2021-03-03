require 'world.world_patterns'
require 'world.MapGenerator'

MAX_BOMBS = 20
SPOT_SIZE = 32

BOMB_IMG = love.graphics.newImage("graphics/bomb.png")
FIRE_IMG = love.graphics.newImage("graphics/fire.png")
BONUS_BOMB_IMG = love.graphics.newImage("graphics/bonus_bomb.png")
BONUS_RANGE_IMG = love.graphics.newImage("graphics/bonus_range.png")

NORMAL_BRICK_INDEX = 2
SPOT_TYPE = {[0] = 'empty', empty = 'empty',
             [1] = 'wall', wall = 'wall',
             [2] = 'brick', brick = 'brick', 
             [6] = 'bonusBomb', bonusBomb = 'bonusBomb',
             [7] = 'bonusRange', bonusRange = 'bonusRange',
             [8] = 'bomb', bomb = 'bomb',
             [9] = 'fire', fire = 'fire' }
SPOT_TYPE_NUM = {   ['empty'] = 0,
                    ['wall'] = 1,
                    ['brick'] = 2,
                    ['bonusBomb'] = 6,
                    ['bonusRange'] = 7,
                    ['bomb'] = 8,
                    ['fire'] = 9 }

             
function newWorld()

    -- get ROWS, COLUMNS, map
    local world = getGeneratedWorld(19, 23) --getWorld(1)       -- +-4

    -- 
    world.bombs = {}
    world.bombCursor = 0 

    world.numBombsToExpire = 0 -- bombs that exploded but still did not expired
    
    -- graphic
    world.imgBricks = love.graphics.newImage("graphics/bricks.png")

    world.bricks = {}
    -- 1 is a brick that can not be destroyed
    world.bricks[1] = love.graphics.newQuad(0, 0, SPOT_SIZE, SPOT_SIZE, world.imgBricks:getDimensions())
    -- 2 brick that can be destroyed with a boms
    world.bricks[2] = love.graphics.newQuad(0, SPOT_SIZE, SPOT_SIZE, SPOT_SIZE, world.imgBricks:getDimensions())
    

    -- returning last layer in spot
    -- '299' -> '9' so its fire
    function world:getSpotType(spotId)
        content = self.map[spotId]

        --love.window.setTitle(tostring(spotId))

        if content >= 10 then
            content = content % 10
        end

        return SPOT_TYPE[content]
        
    end


    -- returns if SPOT_TYPE is on the spot
    -- NOT checking for empty! use function getSpotType instead
    function world:isTypeOnSpot(spotId, spotType)
        content = self.map[spotId]
        --love.window.setTitle(tostring(content))
        while content > 0 do
            if content % 10 == SPOT_TYPE_NUM[spotType] then
                return true
            else
                content = math.floor(content / 10)
            end
        end

        return false
    end


    function world:update(dt)
        self:updateBombs(dt)
    end


    function world:updateBombs(dt)

        for i = 0, MAX_BOMBS do

            bomb = self.bombs[i]
            if bomb == nil then
                goto continue
            end

            bomb:update(dt)
   
            if bomb:isExpired() then
                self.bombs[i] = nil
                self:removeFires(bomb)
                self.numBombsToExpire = self.numBombsToExpire - 1

            elseif bomb:isExploded() and bomb.isFireOnMap == false then
                bomb.isFireOnMap = true
                self:explodeBomb(bomb)
                self.numBombsToExpire = self.numBombsToExpire + 1
            end

            ::continue::
        end

    end


    -- returns a bomb that is on a spot
    function world:getBombForSpotId(spotId) 
        for i = 0, MAX_BOMBS do
            
            bomb = self.bombs[i]
            if bomb == nil then goto continue end

            if bomb.spotId == spotId then
                return bomb
            end

            ::continue::

        end
    end


    function world:draw()

        for spotId = 1, #self.map do

            local spotContent = self.map[spotId]                    -- number on the map

            if spotContent == 0 then
                goto continue
            end

            -- get top left coordinates to draw image correctly
            XY = self:getCornerCoordinatesForSpotId(spotId)
            spotType = self:getSpotType(spotId)

            if spotType == SPOT_TYPE.wall then 
                love.graphics.draw(self.imgBricks, self.bricks[spotContent], XY.X, XY.Y)
            
            elseif spotType == SPOT_TYPE.brick then
                -- check for bonuse with % 10
                love.graphics.draw(self.imgBricks, self.bricks[spotContent % 10], XY.X, XY.Y)

            elseif spotType == SPOT_TYPE.bomb then
                love.graphics.draw(BOMB_IMG, XY.X, XY.Y)
            
            elseif spotType == SPOT_TYPE.fire then                       -- FIRE
                -- check if there is also brick and draw it first
                if self:isTypeOnSpot(spotId, SPOT_TYPE.brick) then
                    love.graphics.draw(self.imgBricks, self.bricks[2], XY.X, XY.Y)
                    
                elseif self:isTypeOnSpot(spotId, SPOT_TYPE.bonusBomb) then
                    love.graphics.draw(BONUS_BOMB_IMG, XY.X, XY.Y)

                elseif self:isTypeOnSpot(spotId, SPOT_TYPE.bonusRange) then
                    love.graphics.draw(BONUS_RANGE_IMG, XY.X, XY.Y)    
                end
            
                love.graphics.draw(FIRE_IMG, XY.X, XY.Y)

            elseif spotType == SPOT_TYPE.bonusBomb then
                love.graphics.draw(BONUS_BOMB_IMG, XY.X, XY.Y)

            elseif spotType == SPOT_TYPE.bonusRange then
                love.graphics.draw(BONUS_RANGE_IMG, XY.X, XY.Y)

            end

            ::continue::
        end
    end


    -- 3 COORDINATES METHODS
    function world:getSpotId(x, y)
        coor = self:getCornerCoordinatesForCoordinates(x , y)
        row = coor.Y / SPOT_SIZE
        column = coor.X / SPOT_SIZE

        return row * self.COLUMNS + column + 1
    end


    function world:getSpotIdForRowColumn(row, column)       -- one based
        return (row - 1) * self.COLUMNS + column
    end


    -- two overloaded methods for getting top left x,y coordinates
    function world:getCornerCoordinatesForSpotId(spotId)
        RC = self:getRowColumnForSpotId(spotId)

        return {X = (RC.COLUMN - 1) * SPOT_SIZE,
                Y = (RC.ROW - 1) * SPOT_SIZE}
    end


    function world:getCornerCoordinatesForCoordinates(x, y)
        x = x - x % SPOT_SIZE
        y = y - y % SPOT_SIZE

        return {X = x, Y = y}
    end


    -- ROWS COLUMNS METHODS
    function world:getRowColumnForSpotId(spotId)          -- 1 based
        row = math.ceil(spotId / self.COLUMNS)
        column = spotId % self.COLUMNS

        if column == 0 then
            column = self.COLUMNS
        end

        return {ROW = row, COLUMN = column}
    end

    function world:getRowColumnForCoordinates(x, y)
        row = math.ceil(coor.Y / SPOT_SIZE) + 1
        column = math.ceil(coor.X / SPOT_SIZE) + 1

        return {ROW = row, COLUMN = column}
    end


    -- BOMBS
    -- ADDING REMOVING BOMBS
    function world:addBomb(spotId, bomb)
        spotType = self:getSpotType(spotId)

        if spotType == SPOT_TYPE.empty then
            self.bombCursor = self.bombCursor + 1
            if self.bombCursor > MAX_BOMBS then
                self.bombCursor = 1
            end
            self.bombs[self.bombCursor] = bomb
            
            -- set bomb spotIf for removing purpose
            bomb:activate(spotId)

            self:setSpot(bomb.spotId, SPOT_TYPE.bomb)
            return true
        end

        return false
    end


    -- add fire when bomb explodes
    function world:explodeBomb(bomb)        -- return a list of spotId of bombs that were hit by fire and should also explode
        if self:getSpotType(bomb.spotId) == SPOT_TYPE.fire then -- was exploded before
            return
        end 
        
        range = bomb.range
        spotId = bomb.spotId
        
        -- remove bomb first
        self:setSpot(spotId, SPOT_TYPE.empty)

        self:addFire(spotId)
        -- add fire in all four directions
        deltas = {-self.COLUMNS, self.COLUMNS, -1, 1}

        bombsToExplode = {}

        for i = 1, #deltas do
            delta = deltas[i]

            for j = 1, range do
                nextSpotId = spotId + j * delta
                nextSpotType = self:getSpotType(nextSpotId)

                if nextSpotType == SPOT_TYPE.empty then
                    self:addFire(nextSpotId)

                elseif nextSpotType == SPOT_TYPE.wall then
                    break 

                elseif nextSpotType == SPOT_TYPE.bomb then
                    bombsToExplode[#bombsToExplode + 1] = self:getBombForSpotId(nextSpotId)
                    break

                elseif self:isTypeOnSpot(nextSpotId, SPOT_TYPE.brick) then               
                    self:addFire(nextSpotId)
                    break

                elseif nextSpotType == SPOT_TYPE.fire or
                    nextSpotType == SPOT_TYPE.bonusBomb or nextSpotType == SPOT_TYPE.bonusRange then
                        self:addFire(nextSpotId)
                end
            end
        end

        -- explode next
        for i = 1, #bombsToExplode do
            bomb = bombsToExplode[i]
            if bomb ~= nil then
                bomb:explode()
                --self:explodeBomb(bombsToExplode[i])
            end
        end
    end


    function world:removeFires(bomb)

        spotId = bomb.spotId

        self:removeFire(spotId)

        -- remove fire in all four directions
        deltas = {-self.COLUMNS, self.COLUMNS, -1, 1}

        for i = 1, #deltas do
            delta = deltas[i]

            for j = 1, bomb.range do
                nextSpotId = spotId + j * delta

                nextSpotType = self:getSpotType(nextSpotId)
                
                if nextSpotType == SPOT_TYPE.wall then
                    break
                
                else if nextSpotType == SPOT_TYPE.fire then
                    self:removeFire(nextSpotId)

                    if self:getSpotType(nextSpotId) ~= SPOT_TYPE.empty then

                        if self:isTypeOnSpot(nextSpotId, SPOT_TYPE.brick) then
                            self:removeType(nextSpotId, SPOT_TYPE.brick)
                            break

                        elseif self:isTypeOnSpot(nextSpotId, SPOT_TYPE.bonusBomb) then
                            self:removeType(nextSpotId, SPOT_TYPE.bonusBomb)
                            self.map[nextSpotId] = 0
                        
                        elseif self:isTypeOnSpot(nextSpotId, SPOT_TYPE.bonusRange) then
                            self:removeType(nextSpotId, SPOT_TYPE.bonusRange)
                            self.map[nextSpotId] = 0
                        end 
                    end
                    end
                end

            end
        end
       
    end

    -- ADDING FIRE
    function world:addFire(spotId)
        self:setSpot(spotId, SPOT_TYPE.fire)
    end

    function world:removeFire(spotId)
        self:setSpot(spotId, SPOT_TYPE.empty)
    end

    -- remove only first found
    function world:removeType(spotId, spotType)
        content = self.map[spotId]
        newContent = 0

        factory = 0

        while content > 0 do
            lastDigit = content % 10
            content = math.floor(content / 10)

            if lastDigit ~= SPOT_TYPE_NUM[spotType] then
                newContent = 10 ^ factory * lastDigit + newContent

                factory = factory + 1
            end
        end
        
        self.map[spotId] = newContent
    end

    -- spot manipulation
    -- setSpot is ADDING one new layer to the spot
    -- '29' + setSpot(type fire) -> '299'
    -- spotType.empty is removing one layer -> '299' will become '29'
    function world:setSpot(spotId, spotType)
        content = self.map[spotId]
        
        if spotType == SPOT_TYPE.empty then
            self.map[spotId] = math.floor(content / 10)
        else
            self.map[spotId] = content * 10 + SPOT_TYPE_NUM[spotType]
            --love.window.setTitle(tostring(self.map[spotId]))
        end

    end

    -- returns nil if not found
    function world:getBonusOnSpot(spotId)
        spotType = self:getSpotType(spotId)

        if spotType == SPOT_TYPE.bonusBomb or spotType == SPOT_TYPE.bonusRange then
            return spotType
        else
            return nil
        end
    end

    -- INIT 
    function world:getStartPosition(playerNumber)   -- brick index
        startPos = 0

        if playerNumber == 1 then
            startPos = self:getSpotIdForRowColumn(2, 2)
        elseif playerNumber == 2 then
            startPos = self:getSpotIdForRowColumn(self.ROWS - 1, self.COLUMNS - 1)
        elseif playerNumber == 3 then
            startPos = self:getSpotIdForRowColumn(2, self.COLUMNS - 1)
        elseif playerNumber == 4 then
            startPos = self:getSpotIdForRowColumn(self.ROWS - 1, 2)
        end

        return startPos
    end


    -- communication with CollisionDetector
    function world:isFireOnMap()
        return self.numBombsToExpire > 0
    end


    return world
        
end