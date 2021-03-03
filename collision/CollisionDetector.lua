require 'world.World'

function newCollisionDetector(world)

    local cd = {}

    cd.world = world
    cd.diagonalDis = (SPOT_SIZE^2 * SPOT_SIZE^2) ^ 0.5

    function cd:isCollidingWithFire(character)

        spotId = self.world:getSpotId(character.x + PHS, character.y + PHS)
        spotType = self.world:getSpotType(spotId)

        if spotType == SPOT_TYPE.fire then
            return true;
        else
            return false
        end
    end

    function cd:isCollidingWithGhost(player, ghost)

        if math.abs(player.x - ghost.x) < SPOT_SIZE - 10 and
            math.abs(player.y - ghost.y) < SPOT_SIZE - 10 then
                return true
        end
        
        return false
    end

    -- returns 1st possible collision 
    -- returns player, ghost, time of the collision
    function cd:calculatePossibleCollision(players, ghosts)             -- its not perfect !! probably calculating it to fast

        if #players == 0 or #ghosts == 0 then
            return {time = 100000}
        end

        whoDis = nil     -- who and fistance

        for p = 1, #players do
            if players[p].isAlive == false then
                goto nextPlayer
            end

            for g = 1, #ghosts do
                if ghosts[g].isAlive == false then
                    goto nextMonster
                end

                distance = self:calculateDistance(players[p], ghosts[g])

                if whoDis == nil then
                    whoDis = {player = players[p], ghost = ghosts[g], dis = distance}
                else
                    -- check if new distance is shorter
                    if distance < whoDis.dis then
                        whoDis = {player = players[p], ghost = ghosts[g], dis = distance}
                    end
                end

                ::nextMonster::
            end

            ::nextPlayer::
        end

        if whoDis == nil then
            return {time = 100000}
        end

        -- calculate time of the collision
        time = TOTAL_TIME + (whoDis.dis / (whoDis.player.speed + whoDis.ghost.speed))   -- adding total time
       
        return {player = whoDis.player, ghost = whoDis.ghost, time = time}

    end

    function cd:calculateDistance(player, ghost)
        xDis = math.abs(player.x - ghost.x)
        yDis = math.abs(player.y - ghost.y)

        totalDis = math.sqrt( math.pow(xDis, 2) + math.pow(yDis, 2) )
        return totalDis
    end

    return cd

end