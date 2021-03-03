require 'settings.monster_settings'

local MONSTER_IMG = love.graphics.newImage("graphics/stone_monster.png")

MONSTER_SIZE = 32
HS = MONSTER_SIZE / 2 -- player half size

DIRECTION_DELTAS = {
    ['u'] = {0, -1}, 
    ['d'] = {0, 1}, 
    ['l'] = {-1, 0}, 
    ['r'] = {1, 0}}
DIRECTIONS = {'u', 'd', 'l', 'r'}

function newStoneMonster(world)

    local monster = {}

    monster.world = world
    monster.speed = DEFAULT_MONSTER_SPEED

    monster.x = 0         -- call self:load()
    monster.y = 0 

    monster.desX = 0        -- destination coordinates
    monster.desY = 0

    monster.direction = 'r'   -- ;u', 'd', 'l', 'r'
    
    monster.nextMoveDecision = 0  -- in seconds

    monster.isAlive = true
    monster.deathTime = 0

    function monster:load()
        self.x = math.floor(monster.world.COLUMNS / 2) * SPOT_SIZE
        self.y = math.floor(monster.world.ROWS / 2 ) * SPOT_SIZE
    end

    function monster:update(dt)
        self:move(dt)
    end

    function monster:move(dt)
        if TOTAL_TIME > monster.nextMoveDecision then
            -- decide where to move next
            self:decideWhereToMove(dt)
            return
        end

        -- move 
        delta = self.speed * dt

        self.x = self.x + DIRECTION_DELTAS[self.direction][1] * delta
        self.y = self.y + DIRECTION_DELTAS[self.direction][2] * delta
    end

    function monster:adjustCoordinates()
        coor = self.world:getCornerCoordinatesForCoordinates(self.x + HS, self.y + HS)
        self.x = coor.X
        self.y = coor.Y
    end

    function monster:decideWhereToMove(dt)
        self:adjustCoordinates()

        spotsToBorder = 0

        while spotsToBorder < 2 do
            -- choose direction
            dir = math.random(4)

            self.direction = DIRECTIONS[dir]

            -- check how far you can go in that direction
            RC = self.world:getRowColumnForCoordinates(self.x + HS, self.y + HS)

            if self.direction == 'u' then      spotsToBorder = RC.ROW - 1
            elseif self.direction == 'd' then  spotsToBorder = self.world.ROWS - RC.ROW
            elseif self.direction == 'l' then  spotsToBorder = RC.COLUMN - 1
            elseif self.direction == 'r' then  spotsToBorder = self.world.COLUMNS - RC.COLUMN
            end
        end

        randomNum = math.random(2, spotsToBorder)        --  must be factory of 2 so the monster will not move on stable walls
    
        if randomNum % 2 == 1 then
            randomNum = randomNum - 1
        end

        length = randomNum * SPOT_SIZE 

        -- set desination X and Y depending on random length / dir
        self.desX = self.x + DIRECTION_DELTAS[self.direction][1] * length
        self.desY = self.y + DIRECTION_DELTAS[self.direction][2] * length

        -- set timer when to decide for next move
        distance = self:distanceToDes()
        self.nextMoveDecision = TOTAL_TIME + distance / (self.speed)
        
  
  end

    function monster:distanceToDes()
        return math.abs(self.x - self.desX + self.y - self.desY)
    end

    function monster:draw()
        dir = 1
        sx = 0
        if self.direction == 'l' then
            dir = -1
            sx = 32
        end
        
        love.graphics.draw(MONSTER_IMG, self.x, self.y, 0, dir, 1, sx)
    end
    
    return monster

end