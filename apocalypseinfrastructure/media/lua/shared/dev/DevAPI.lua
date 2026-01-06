-- Developer-only helpers for Apocalypse Infrastructure.
--
-- CRITICAL RULE (PZ):
-- Shared files load in undefined order. Do not touch AI.Runtime at file load.
-- Register dev helpers only after the engine lifecycle is ready.
-- NOTE (PZ/Kahlua):
-- Logger methods expect strings. Always tostring() non-strings
-- before concatenation or logging.
local Runtime = require("infra/Runtime")
local RainBarrelConnector = require("flow/Water/RainBarrelConnector")
local GenericWaterConsumer = require("flow/Water/GenericWaterConsumer")
local log = Runtime.Logger

_G.AI = _G.AI or {}
----------------------------------------------------------------
-- Lifecycle-safe registration
----------------------------------------------------------------

Events.OnGameStart.Add(function()

    local AI = _G.AI
    AI.spawn = AI.spawn or {}
    AI.test  = AI.test  or {}

    -- Runtime is guaranteed by now

    if not Runtime then
        print("[Apocalypse Infrastructure][DevAPI][ERROR] Runtime missing at OnGameStart")
        return
    end

    


    if not Runtime.Settings or not Runtime.Settings.devEnabled then
        log.error("[DevAPI] devEnabled=false; DevAPI disabled (devEnabled="
            .. tostring(Runtime.Settings and Runtime.Settings.devEnabled) .. ")")
        return
    end

    log.debug("[DevAPI] Registering dev helpers")

    ------------------------------------------------------------
    -- Tests
    ------------------------------------------------------------

    function AI.test.test1()
        log.debug("[DevAPI] Running Layer 1 Logic Tests")
        local Layer1 = require("testing/Layer1_Logic")
        Layer1.runAll()
    end

    function AI.test.dumpRegistry()
        log.debug("[DevAPI] Dumping registry state")
        local Registry = require("topology/net/Registry")
        if Registry and Registry.debugDump then
            Registry.debugDump()
        else
            log.error("[DevAPI] Registry.debugDump unavailable")
        end
    end

    ------------------------------------------------------------
    -- Spawners
    ------------------------------------------------------------

    function AI.spawn.RainBarrelConnector()
        local player = getPlayer()
        if not player then
            log.error("[DevAPI] No player available")
            return
        end

        local sq = player:getSquare()
        if not sq then
            log.error("[DevAPI] No square under player")
            return
        end

        local barrel = nil
        for i = 0, sq:getObjects():size() - 1 do
            local obj = sq:getObjects():get(i)
            if instanceof(obj, "IsoRainCollectorBarrel") then
                barrel = obj
                break
            end
        end

        if not barrel then
            log.error("[DevAPI] No rain barrel found on this square")
            return
        end



        if not RainBarrelConnector then
            log.error("[DevAPI] RainBarrelConnector not available (value="
                .. tostring(RainBarrelConnector) .. ")")
            return
        end

        local rb = RainBarrelConnector.new({
            id = "rb-dev-1",
            object = barrel,
            position = {
                x = sq:getX(),
                y = sq:getY(),
                z = sq:getZ(),
            }
        })

        rb:attach()
        log.debug("[DevAPI] RainBarrelConnector connector attached")
        AI.test.dumpRegistry()
    end

    function AI.spawn.GenericWaterConsumer()
        local player = getPlayer()
        if not player then
            log.error("[DevAPI] No player available")
            return
        end

        local sq = player:getSquare()
        if not sq then
            log.error("[DevAPI] No square under player")
            return
        end

        if not GenericWaterConsumer then
            log.error("[DevAPI] GenericWaterConsumer not available (value="
                .. tostring(GenericWaterConsumer) .. ")")
            return
        end

        -- Use the first object on the square as a stable anchor
        local anchor = nil
        for i = 0, sq:getObjects():size() - 1 do
            anchor = sq:getObjects():get(i)
            if anchor then break end
        end

        if not anchor then
            log.error("[DevAPI] No anchor object available for GenericWaterConsumer")
            return
        end

        local c = GenericWaterConsumer.new({
            id = "gwc-dev-1",
            object = anchor,
            position = {
                x = sq:getX(),
                y = sq:getY(),
                z = sq:getZ(),
            }
        })

        c:attach()
        log.debug("[DevAPI] GenericWaterConsumer attached")
        AI.test.dumpRegistry()
    end

        ------------------------------------------------------------
    -- Test 2: Full end-to-end setup (spawn + connect)
    ------------------------------------------------------------

    function AI.test.fullWaterSetup()
        log.debug("[DevAPI] Running test2_fullWaterSetup")

        local player = getPlayer()
        if not player then
            log.error("[DevAPI] No player available")
            return
        end

        local sq = player:getSquare()
        if not sq then
            log.error("[DevAPI] No square under player")
            return
        end

        local x, y, z = sq:getX(), sq:getY(), sq:getZ()

        --------------------------------------------------------
        -- Step 1: Spawn a rain collector barrel
        --------------------------------------------------------

        log.debug("[DevAPI] Spawning rain collector barrel")

        -- Spawn a rain barrel using a generic IsoObject (Lua-safe)
        local barrel = IsoObject.new(
            sq,
            getSprite("crafted_01_16") -- vanilla rain barrel sprite
        )

        barrel:setName("Rain Collector Barrel")

        -- Optional: initialize water properties for realism (not required for connectors)
        if barrel.setWaterMax then
            barrel:setWaterMax(400)
            barrel:setWaterAmount(0)
        end

        sq:AddSpecialObject(barrel)
        barrel:transmitCompleteItemToServer()

        --------------------------------------------------------
        -- Step 2: Attach RainBarrelConnector connector
        --------------------------------------------------------

        if not RainBarrelConnector then
            log.error("[DevAPI] RainBarrelConnector connector not available")
            return
        end

        -- Use a stable, object-derived id for the connector
        local barrelId =
            tostring(barrel:getObjectIndex())
            .. "@"
            .. x .. "," .. y .. "," .. z

        local rb = RainBarrelConnector.new({
            id = "rb-" .. barrelId,
            object = barrel,
            position = { x = x, y = y, z = z }
        })

        rb:attach()
        log.debug("[DevAPI] RainBarrelConnector connector attached")

        --------------------------------------------------------
        -- Step 3: Attach GenericWaterConsumer
        --------------------------------------------------------
        if not GenericWaterConsumer then
            log.error("[DevAPI] GenericWaterConsumer not available")
            return
        end

        -- Attach GenericWaterConsumer (requires observed world object)
        local c = GenericWaterConsumer.new({
            id = "gwc@" .. x .. "," .. y .. "," .. z,
            position = { x = x, y = y, z = z },
            object = barrel  -- anchor to satisfy BaseConnector invariant
        })

        c:attach()
        log.debug("[DevAPI] GenericWaterConsumer attached")

        --------------------------------------------------------
        -- Step 4: Dump registry
        --------------------------------------------------------

        AI.test.dumpRegistry()
        log.debug("[DevAPI] test2_fullWaterSetup complete")
    end

    log.debug("[DevAPI] Loaded")
end)