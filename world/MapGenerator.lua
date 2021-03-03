-- static method for random generating exploadable bricks
function generateBricks(world, numBricks, numBonuses)   -- bonuses are : bombs, fire power
    math.randomseed(os.time())

    numBricks = math.floor(numBricks / 4)       -- equally for all squares
    numBonuses = math.floor(numBonuses / 4)

    -- generate random but fair for all four squares of world
    -- 1st square
    fromRow = 1
    toRow = (world.ROWS + 1) / 2
    fromColumn = 1
    toColumn = (world.COLUMNS + 1) / 2
    local list = getEmptySpacesList(world, fromRow, toRow, fromColumn, toColumn)
    shuffle(list)
    setBricksAndBonuses(world, list, numBricks, numBonuses, 1)
    
    -- 2nd square
    fromColumn = toColumn
    toColumn = world.COLUMNS
    local list = getEmptySpacesList(world, fromRow, toRow, fromColumn, toColumn)
    shuffle(list)
    setBricksAndBonuses(world, list, numBricks, numBonuses, 3)
    
    -- 4rd square
    fromRow = toRow
    toRow = world.ROWS
    local list = getEmptySpacesList(world, fromRow, toRow, fromColumn, toColumn)
    shuffle(list)
    setBricksAndBonuses(world, list, numBricks, numBonuses, 2)
    
    -- 3rd square
    fromColumn = 1
    toColumn = (world.COLUMNS + 1) / 2
    local list = getEmptySpacesList(world, fromRow, toRow, fromColumn, toColumn)
    shuffle(list)
    setBricksAndBonuses(world, list, numBricks, numBonuses, 4)
 
end

function getEmptySpacesList(world, fromRow, toRow, fromColumn, toColumn)
    local list = {}
    count = 1

    for r = fromRow, toRow
    do

        for c = fromColumn, toColumn
        do
            spotId = world:getSpotIdForRowColumn(r, c)

            if world.map[spotId] == 0 then
                list[count] = spotId
                count = count + 1
            end
        end

    end

    return list

end

function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i - 1)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function setBricksAndBonuses(world, list, numBricks, numBonuses, playerIndex) 
    local playerPos = world:getStartPosition(playerIndex)

    local bonusIx = 1 -- 1 for bonus bomb , 2 for bonus range
    local bonusTypes = { SPOT_TYPE.bonusBomb, SPOT_TYPE.bonusRange }

    local i = 1
    local till = numBricks
    while i <= till
    do
        local addBrickAndBonus = true

        -- skip to next if it's in corner or one next
        local spotId = list[i]
        RC = world:getRowColumnForSpotId(spotId)

        if (spotId == playerPos or spotId == playerPos - 1 or spotId == playerPos + 1 or
            spotId == playerPos - world.COLUMNS or spotId == playerPos + world.COLUMNS) then
            
                addBrickAndBonus = false
        
        -- if the spot is exactly in column middle or row middle then randomly add only
        -- every second brick cause this area is used twice so often when checking for
        -- empty spots
        elseif RC.ROW == math.ceil(world.ROWS / 2) or RC.COLUMN == math.ceil(world.COLUMNS / 2) then
            randomNum = math.random(2)
            if randomNum % 2 == 0 or world:getSpotType(spotId) ~= SPOT_TYPE.empty then
                addBrickAndBonus = false
            end
        end

        -- add brick and bonus or skip to next
        contentToAdd = 0

        if addBrickAndBonus == true then
            -- set bonus on map
            if numBonuses > 0 then
                contentToAdd = SPOT_TYPE_NUM[ bonusTypes[bonusIx] ]
                world.map[spotId] = contentToAdd

                numBonuses = numBonuses - 1

                -- increase index
                if bonusIx == #bonusTypes then
                    bonusIx = 1
                else
                    bonusIx = bonusIx + 1
                end
            end
            -- set brick on map
            world.map[spotId] = contentToAdd * 10 + SPOT_TYPE_NUM['brick']
        else
            till = till + 1
        end

        i = i + 1
    end
end