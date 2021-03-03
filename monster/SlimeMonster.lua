require 'settings.monster_settings'

local MONSTER_IMG = love.graphics.newImage("graphics/slime_monster.png")
DEAD_MONSTER_IMG = love.graphics.newImage("graphics/dead_slime_monster.png")

GHOST_SIZE = 32
HS = GHOST_SIZE / 2 -- player half size

DIRECTION_DELTAS = {
    ['u'] = {0, -1}, 
    ['d'] = {0, 1}, 
    ['l'] = {-1, 0}, 
    ['r'] = {1, 0}}
DIRECTIONS = {'u', 'd', 'l', 'r'}


function newSlimeMonster(world)

    local ghost = {}

    ghost.world = world
    ghost.speed = DEFAULT_MONSTER_SPEED

    ghost.x = 0         -- call self:load()
    ghost.y = 0 

    ghost.desX = 0        -- destination coordinates
    ghost.desY = 0

    ghost.direction = 'x'   -- ;u', 'd', 'l', 'r'
    
    ghost.nextMoveDecision = 0  -- in seconds

    ghost.img = MONSTER_IMG

    ghost.isAlive = true
    ghost.deathTime = 0

    function ghost:load()
        self.x = math.floor(ghost.world.COLUMNS / 2) * SPOT_SIZE
        self.y = math.floor(ghost.world.ROWS / 2 ) * SPOT_SIZE
    end

    function ghost:update(dt)
        self:move(dt)
    end

    function ghost:move(dt)
        -- when monster can not move return
        if self.direction == 'x' and TOTAL_TIME < self.nextMoveDecision then
            return
        end

        -- zalozenie  
        if TOTAL_TIME >= self.nextMoveDecision then
            -- decide where to move next
            self:decideWhereToMove(dt)

            if self.direction == 'x' then
                return 
            end
        end

        -- check if you can really move 
        
        delta = DEFAULT_MONSTER_SPEED * dt

        newX = self.x + DIRECTION_DELTAS[self.direction][1] * delta
        newY = self.y + DIRECTION_DELTAS[self.direction][2] * delta

        xToCheck = newX
        yToCheck = newY

        if self.direction == 'u' then

        elseif self.direction == 'd' then
            yToCheck = yToCheck + GHOST_SIZE
        elseif self.direction == 'l' then

        elseif self.direction == 'r' then
            xToCheck = xToCheck + GHOST_SIZE
        end

        if self:canMoveTo(xToCheck, yToCheck) then
            self.x = newX
            self.y = newY
        else
            self:adjustCoordinates()
            self:decideWhereToMove(dt)
        end
    end

    function ghost:adjustCoordinates()
        coor = self.world:getCornerCoordinatesForCoordinates(self.x + HS, self.y + HS)
        self.x = coor.X
        self.y = coor.Y
    end

    function ghost:decideWhereToMove(dt)
        if self.direction ~= 'x' then
            self:adjustCoordinates()
        end

        openDir = {}    -- directions where monster can go
        
        for i = 1, #DIRECTIONS do
            dir = DIRECTIONS[i]

            plusX = 0
            plusY = 0

            if dir == 'u' then plusY = -HS
            elseif dir == 'd' then plusY = GHOST_SIZE + HS
            elseif dir == 'r' then plusX = GHOST_SIZE + HS
            elseif dir == 'l' then plusX = -HS 
            end

            tempX = self.x + plusX
            tempY = self.y + plusY

            -- add direction where you can move
            if self:canMoveTo(tempX, tempY) then
                openDir[#openDir + 1] = dir
            end
        end

        -- if no open slots stay where you are for 1 seconds and check again
        if #openDir == 0 then
            self.direction = 'x'
            self.nextMoveDecision = TOTAL_TIME + 3
            return
        end

        -- randomly decide which direction to go
        randomNum = math.random(1, #openDir)
        self.direction = openDir[randomNum]

        -- check how many spots are empty in chosen direction
        spotDelta = DIRECTION_DELTAS[self.direction][1] * 1 + DIRECTION_DELTAS[self.direction][2] * self.world.COLUMNS 

        countOpenSpots = 1
        spotId = self.world:getSpotId(self.x, self.y)
        spotId = spotId + 2 * spotDelta
        spotType = self.world:getSpotType(spotId)
        
        while spotType == SPOT_TYPE.empty or spotType == SPOT_TYPE.fire or spotType == SPOT_TYPE.bomb 
                or spotType == SPOT_TYPE.bonusBomb or spotType == SPOT_TYPE.bonusRange 
        do
            countOpenSpots = countOpenSpots + 1
            spotId = spotId + spotDelta
            spotType = self.world:getSpotType(spotId)
        end
    
        -- decide how far to go
        randomNum = math.random(1, countOpenSpots)
        length = randomNum * SPOT_SIZE 

        -- set desination X and Y depending on random length / dir
        self.desX = self.x + DIRECTION_DELTAS[self.direction][1] * length
        self.desY = self.y + DIRECTION_DELTAS[self.direction][2] * length

        -- set timer when to decide for next move
        distance = self:distanceToDes()
        self.nextMoveDecision = TOTAL_TIME + distance / (DEFAULT_MONSTER_SPEED)
    end

    function ghost:distanceToDes()
        return math.abs(self.x - self.desX + self.y - self.desY)
    end

    -- the same function as with player
    function ghost:canMoveTo(x, y)
        newSpotId = self.world:getSpotId(x, y)
        if newSpotId == nil then return false end;
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

    function ghost:draw()
        dir = 1
        sx = 0

        if self.direction == 'r' then
            dir = -1
            sx = 32
        end
        
        love.graphics.draw(self.img, self.x, self.y, 0, dir, 1, sx)
    end
    
    return ghost
end