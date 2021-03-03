MONSTER_TYPE = {'stone_monster', 'slide_monster',
                stoneMonster = 'stone_monster', slideMonster = 'slide_monster'}


function generateMonsters(world, monsters, numTypeMosters)          -- monsters is a tablo to put monsters into
    numMonsters = numTypeMosters[MONSTER_TYPE.stoneMonster]
    generatStoneMonsters(world, monsters, numMonsters)

    numMonsters = numTypeMosters[MONSTER_TYPE.slideMonster]
    generateSlideMonsters(world, monsters, numMonsters)
end


function generatStoneMonsters(world, monsters, numMonsters)
    for i = 1, numMonsters do
        monsters[i] = newStoneMonster(world)
        monsters[i]:load();
    end
end


function generateSlideMonsters(world, monsters, numMonsters)
    -- generate the monster not in the center but somewhere on the middle X Y axes
    
    middleSpot = math.ceil(world.ROWS * world.COLUMNS / 2) 
    spotDeltas = {world.COLUMNS, -world.COLUMNS, -1, 1}
    startSpot  = {math.ceil(world.COLUMNS / 2), world.ROWS * world.COLUMNS - math.floor(world.COLUMNS/ 2),
                    middleSpot + math.floor(world.COLUMNS / 2), middleSpot - math.floor(world.COLUMNS / 2)}

    deltaIx = 1

    for i = #monsters + 1, #monsters + numMonsters do
        monster = newSlimeMonster(world)
        monster:load()
        monsters[i] = monster
        
        -- find open spot and put the change monster coordinates to there
        spotId = startSpot[deltaIx]        

        -- is in map range
        for i = 1, math.floor(world.COLUMNS / 2) do
            spotId = spotId + spotDeltas[deltaIx]

            -- put the monster here
            if world:getSpotType(spotId) == SPOT_TYPE.empty then
                XY = world:getCornerCoordinatesForSpotId(spotId)
                monster.x = XY.X
                monster.y = XY.Y

                break
            end
        end

        -- update delta coursor
        deltaIx = deltaIx + 1
        if deltaIx == 5 then
            deltaIx = 1
        end
    end
end