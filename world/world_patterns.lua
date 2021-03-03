function getGeneratedWorld(ROWS, COLUMNS)

    local world = {}

    world.ROWS = ROWS
    world.COLUMNS = COLUMNS

    world.map = {}

    totalSpots = ROWS * COLUMNS
    row = 1

    for i = 1, totalSpots do
        if i <= COLUMNS or i > (totalSpots - COLUMNS) or 
            i % COLUMNS == 0 or i % COLUMNS == 1 or
            (row % 2 == 1 and i % 2 == 1  )then
                world.map[i] = 1

                if i % COLUMNS == 0 then
                    row = row + 1
                end

        else
            world.map[i] = 0
        end
    end

    return world
end

function getWorld(index)

    local world = {}

    if index == 1 then
        
        world.ROWS = 15   
        world.COLUMNS = 15

        world.map = {
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
            1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
        }

    end

    return world
    
end