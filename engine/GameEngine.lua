require 'world.World'
require 'player.Player'
require 'settings.settings'
require 'collision.CollisionDetector'
require 'monster.StoneMonster'
require 'monster.SlimeMonster'
require 'monster.MonsterGenerator'

NUM_PLAYERS = 2
NUM_BONUSES_PER_PLAYER = 16

TOTAL_TIME = 0

MONSTER_TYPE = {stoneMonster = 'stone_monster', slideMonster = 'slide_monster'}

function newGameEngine()

    local engine = {}

    engine.numPlayers = NUM_PLAYERS

    engine.numTypeMosters = { [MONSTER_TYPE.stoneMonster] = 1,
                              [MONSTER_TYPE.slideMonster] = 16 }
    
    -- count total number of monsters
    engine.numMonsters = engine.numTypeMosters[MONSTER_TYPE.stoneMonster] +
                         engine.numTypeMosters[MONSTER_TYPE.slideMonster]

    engine.world = {}

    engine.players = {}

    engine.monsters = {}

    engine.cd = {}          -- collision detector

    engine.possibleCollision = nil  -- player, ghost, time (possible collision time)

    engine.status = 'winner'  -- 'winner'

    -- LOAD / NEW GAME

    function engine:newGame()
        -- load world and collision detector
        self.world = newWorld()

        -- generate random bricks and extras for world
        generateBricks(self.world, 64, NUM_PLAYERS * NUM_BONUSES_PER_PLAYER)                    

        self.cd = newCollisionDetector(self.world)

        -- load players and copy current wins
        for i = 1, self.numPlayers do
            if self.players[i] ~= nil then 
                wins = self.players[i].wins
            end
            self.players[i] = newPlayer(self.world, i)

            if wins ~= nil then
                self.players[i].wins = wins
            end
        end

        -- generate monsters
        self.monsters = {}
        generateMonsters(self.world, self.monsters, self.numTypeMosters)

        -- calculate possibleCollision
        self.possibleCollision = self.cd:calculatePossibleCollision(self.players, self.monsters)

        -- game status
        self.status = 'play'
    end

    function engine:load()
        self:newGame()
        self.status = 'load'
    end

    -- UPDATE

    function engine:update(dt)

        -- 'winner' status
        if self.status ~= 'play' then
            if self.status == 'winner' and love.keyboard.isDown('return') then
                self:newGame()

            elseif self.status == 'load' and love.keyboard.isDown('return') then
                self.status = 'play'
            end
            return
        end

        -- 'play' status
        TOTAL_TIME = TOTAL_TIME + dt
        --love.window.setTitle(tostring(TOTAL_TIME - self.possibleCollision.time))

        if TOTAL_TIME >= self.possibleCollision.time - 0.1 then
            -- check if the collision really happened
            local player = self.possibleCollision.player
            if self.cd:isCollidingWithGhost(player, self.possibleCollision.ghost) then
                player.isAlive = false
                player.deathTime = TOTAL_TIME
                player.img = DEAD_PLAYER_IMG
            end

            if TOTAL_TIME >= self.possibleCollision.time then
                self.possibleCollision = self.cd:calculatePossibleCollision(self.players, self.monsters)
            end
        end


        self.world:update(dt)
        
        -- update players
        for i = 1, self.numPlayers do
            if self.players[i].isAlive then
                self.players[i]:update(dt)
            end
        end


        -- update monsters
        for i = #self.monsters, 1, -1 do
            if self.monsters[i].isAlive then
                self.monsters[i]:update(dt)
            else
                if self.monsters[i].deathTime + 3 <= TOTAL_TIME then
                    -- remove monster from list 3 seconds after its death
                    self:removeMonster(i)
                end
            end
        end


        -- check for fire on map
        if self.world:isFireOnMap() then
            
            -- check for fire collisions PLAYERS
            for i = 1, self.numPlayers do
                if self.cd:isCollidingWithFire(self.players[i]) then
                    self.players[i].isAlive = false
                    self.players[i].deathTime = TOTAL_TIME
                    self.players[i].img = DEAD_PLAYER_IMG
                end
            end

            -- check for fire collisions MONSTERS
            -- stone monster can not be destroyed so start checking from index 
            -- engine.numTypeMosters[MONSTER_TYPE.stoneMonster] + 1
            for i = #self.monsters, self.numTypeMosters[MONSTER_TYPE.stoneMonster] + 1, -1 do
                if self.monsters[i].isAlive and self.cd:isCollidingWithFire(self.monsters[i]) then
                    self.monsters[i].isAlive = false
                    self.monsters[i].deathTime = TOTAL_TIME
                    self.monsters[i].img = DEAD_MONSTER_IMG
                end
            end
        end




        -- check if someone won
        count = 0
        winner = nil
        for i = 1, self.numPlayers do
            if self.players[i].isAlive then
                count = count + 1
                winner = self.players[i]
            end
        end

        if count <= 1 then
            self.status = 'winner'
            if count == 1 then
            winner.wins = winner.wins + 1
            end
        end

    end

    -- helpter function
    function engine:removeMonster(posInList)
        -- remove the monster by moving all from right to left by one position
        table.remove(self.monsters, posInList)
    end

    -- DRAW

    function engine:draw()

        self.world:draw()
        
        for i = 1, self.numPlayers do
            if self.players[i].isAlive or self.players[i].deathTime + 3 > TOTAL_TIME  then
                self.players[i]:draw(dt)
            end
        end

        -- draw monsters
        for i = 1, #self.monsters do
            self.monsters[i]:draw()
        end

        if self.status == 'winner' or self.status == 'load' then
            self:showWinner()
            return
        end
    end

    -- SHOW WINNER WAIT FOR NEXT GAME

    function engine:showWinner()

        startX = self.world.COLUMNS * SPOT_SIZE + SPOT_SIZE
        startY = 7 * SPOT_SIZE
        
        love.graphics.print("PLAYER   |   WINS ", startX, startY)

        winner = "NO ONE"

        count = 0
        for i = 1, self.numPlayers do
            if self.players[i].isAlive then
                count = count + 1
                winner = i
            end

            love.graphics.print("     " .. tostring(i) .. "       :      " .. tostring(self.players[i].wins), startX, startY + i * SPOT_SIZE)
        end

        if count <= 1 then
            love.graphics.print("Round Winner:", startX, startY - SPOT_SIZE * 3)
            love.graphics.print(" Player no. " .. winner, startX, startY - 2 * SPOT_SIZE)
        end

        love.graphics.print("Press Enter to play...", startX, startY + (NUM_PLAYERS + 2)  * SPOT_SIZE)

    end

    return engine
end