local API = require("api")
local startTime os.time()
local afk = os.time()


-- ========IDLE========
local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((5 * 60) * 0.6, (5 * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end
-- ========IDLE========

local function dropInventory()
    print("inventory full, trying to drop Fishes")
    for _, item in ipairs(API.ReadInvArrays33()) do
        for _, v in pairs({13435, 335, 331}) do
            if (item.itemid1 == v) then
                API.DoAction_Interface(0x24,0x14f,8,1473,5,item.index, API.OFF_ACT_GeneralInterface_route2)
                API.RandomSleep2(200, 100, 200)
            end
        end
    end
    API.RandomSleep2(1200, 100, 200)
end
local function gameStateChecks()
    local gameState = API.GetGameState2()
    if (gameState ~= 3) then
        print('Not ingame with state:', gameState)
        API.Write_LoopyLoop(false)
        return
    end
end

API.SetDrawTrackedSkills(true)
API.ScriptRuntimeString()
API.GetTrackedSkills()

while API.Read_LoopyLoop() do
    idleCheck()
    gameStateChecks()
    
    if not API.CheckAnim(20) then
        if API.InvFull_() then
            dropInventory()
        end
        local spots = API.GetAllObjArrayInteract_str({"Fishing spot"}, 50, 1)
        if #spots > 0 then
            if spots[1].Action == "Lure" and API.InvStackSize(314) < 1 then
                API.Write_LoopyLoop(false)
                print("No more feathers")
                break
            end

            API.DoAction_NPC_str(0x3c, API.OFF_ACT_InteractNPC_route, {"Fishing spot"}, 50)
            API.RandomSleep2(1200, 100, 200)
            API.WaitUntilMovingandAnimEnds()
        else
            print("No fishing spots around")
            API.Write_LoopyLoop(false)
        end
    end

    API.RandomSleep2(600, 100, 200)

end

API.SetDrawTrackedSkills(false)
