TIMER = 3 -- 3 seconds to explode

function newBomb(range)

    local bomb = {}

    bomb.spotId = 0
    bomb.range = range
    bomb.timer = 0
    bomb.status = 0     -- 0 : new, 1 : placed, 2 - exploded, 3 - expired
    bomb.isFireOnMap = false    -- must be set to true if world is setting fire on map 


    function bomb:isPlaced() 
        return self.status >= 1
    end


    function bomb:isExploded()
        return self.status >= 2
    end


    -- isExpired when isExploded and timer will show < 0 - the fire will then disappear
    function bomb:isExpired()
        return self.status == 3
    end


    function bomb:setTimer(time)
        self.timer = time
    end

    
    function bomb:activate(spotId)
        self.spotId = spotId
        self.status = 1
        self:setTimer(TIMER)
    end


    function bomb:explode()
        self.status = 2
        self:setTimer(TIMER / 2)
    end


    function bomb:expire()
        self.status = 3
    end


    function bomb:update(dt)
        if self:isPlaced() == false or self:isExpired() then        -- do nothing
            return
        end

        self.timer = self.timer - dt            -- decrease timer

        -- change status from placed to exploded and from exploded to expired
        if self.timer < 0 then
            if self:isExploded() then
                self:expire()
            elseif self:isPlaced() then
                self:explode()
            end
        end
    end

    
    return bomb
end