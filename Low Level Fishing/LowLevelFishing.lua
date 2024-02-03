local API = require("api")
local startTime, afk = os.time(), os.time()

-- ========GUI stuff========
local startXp = API.GetSkillXP("FISHING")
local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- Format script elapsed time to [hh:mm:ss]
local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

local function calcProgressPercentage(skill, currentExp)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    if currentLevel == 120 then
        return 100
    end
    local nextLevelExp = XPForLevel(currentLevel + 1)
    local currentLevelExp = XPForLevel(currentLevel)
    local progressPercentage = (currentExp - currentLevelExp) / (nextLevelExp - currentLevelExp) * 100
    return math.floor(progressPercentage)
end

local function printProgressReport(final)
    local skill = "FISHING"
    local currentXp = API.GetSkillXP(skill)
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    IGP.radius = calcProgressPercentage(skill, API.GetSkillXP(skill)) / 100
    IGP.string_value = time .. " | " .. string.lower(skill):gsub("^%l", string.upper) .. ": " .. currentLevel ..
                           " | XP/H: " .. formatNumber(xpPH) .. " | XP: " .. formatNumber(diffXp)
end

local function setupGUI()
    IGP = API.CreateIG_answer()
    IGP.box_start = FFPOINT.new(5, 5, 0)
    IGP.box_name = "PROGRESSBAR"
    IGP.colour = ImColor.new(6, 82, 221);
    IGP.string_value = "FISHING"
end

local function drawGUI()
    DrawProgressBar(IGP)
end

setupGUI()

-- ========GUI stuff========

-- ========IDLE========
local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((10 * 60) * 0.6, (10 * 60) * 0.9)

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

while API.Read_LoopyLoop() do
    idleCheck()
    drawGUI()
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
            API.WaitUntilMovingEnds()
        else
            print("No fishing spots around")
            API.Write_LoopyLoop(false)
        end
    end

    printProgressReport()
    API.RandomSleep2(600, 100, 200)

end
