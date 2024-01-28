--[[
    Description: Basic woodcuting script to get easy xp

    Author: Nocturnal
    Version: 1.0
    Release Date: 28/01/2024
]]


local API = require("api")
local startTime, afk = os.time(), os.time()
local runScript = false
local targetNotFoundCount = 0
local itemToGather = "None"


-- #region Config
local maxIdleMinutes = 10
local actionSpots = {"Tree", "Oak", "Willow", "Maple Tree", "Yew"}
local logIds = {1511, 1521, 1519, 1517, 1515}
-- #endregion


--========GUI stuff========
-- Progress bars by @higgins
local startXp = API.GetSkillXP("WOODCUTTING")
local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

local function formatNumber(num)
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
    if currentLevel == 120 then return 100 end
    local nextLevelExp = XPForLevel(currentLevel + 1)
    local currentLevelExp = XPForLevel(currentLevel)
    local progressPercentage = (currentExp - currentLevelExp) / (nextLevelExp - currentLevelExp) * 100
    return math.floor(progressPercentage)
end

local function printProgressReport(final)
    local skill = "WOODCUTTING"
    local currentXp = API.GetSkillXP(skill)
    local elapsedMinutes = (os.time() - startTime) / 60
    local diffXp = math.abs(currentXp - startXp);
    local xpPH = round((diffXp * 60) / elapsedMinutes);
    local time = formatElapsedTime(startTime)
    local currentLevel = API.XPLevelTable(API.GetSkillXP(skill))
    IGP.radius = calcProgressPercentage(skill, API.GetSkillXP(skill)) / 100
    IGP.string_value = time ..
    " | " ..
    string.lower(skill):gsub("^%l", string.upper) ..
    ": " .. currentLevel .. " | XP/H: " .. formatNumber(xpPH) .. " | XP: " .. formatNumber(diffXp)
end

local function setupGUI()
    IGP = API.CreateIG_answer()
    IGP.box_start = FFPOINT.new(5, 5, 0)
    IGP.box_name = "PROGRESSBAR"
    IGP.colour = ImColor.new(74,103,65);
    IGP.string_value = "WOODCUTTING"
end

setupGUI()


-- #region Imgui Setup - made by @Dead
local imguiBackground = API.CreateIG_answer();
imguiBackground.box_name = "imguiBackground";
imguiBackground.box_start = FFPOINT.new(5, 50, 0);
imguiBackground.box_size = FFPOINT.new(280, 130, 0)

local getTargetBtn = API.CreateIG_answer();
getTargetBtn.box_name = "Get";
getTargetBtn.box_start = FFPOINT.new(5, 50, 0);
getTargetBtn.box_size = FFPOINT.new(50, 30, 0);
getTargetBtn.tooltip_text = "Populate tree list"

local setTargetBtn = API.CreateIG_answer();
setTargetBtn.box_name = "Set";
setTargetBtn.box_start = FFPOINT.new(50, 50, 0);
setTargetBtn.box_size = FFPOINT.new(50, 30, 0);
setTargetBtn.tooltip_text = "The script will chop this tree"

local imguicombo = API.CreateIG_answer()
imguicombo.box_name = "Trees"
imguicombo.box_start = FFPOINT.new(90, 50, 0)
imguicombo.stringsArr = {"a", "b"}
imguicombo.tooltip_text = "Available tree to target"

local imguiCurrentTarget = API.CreateIG_answer();
imguiCurrentTarget.box_name = "Current Target:";
imguiCurrentTarget.box_start = FFPOINT.new(20, 80, 0);

local imguiAction = API.CreateIG_answer();
imguiAction.box_name = "CHOP";
imguiAction.box_start = FFPOINT.new(8, 90, 0);
imguiAction.box_size = FFPOINT.new(80, 30, 0);
imguiAction.tooltip_text = "Start/Stop chopping"

local imguiTerminate = API.CreateIG_answer();
imguiTerminate.box_name = "Stop Script";
imguiTerminate.box_start = FFPOINT.new(90, 90, 0);
imguiTerminate.box_size = FFPOINT.new(100, 30, 0);
imguiTerminate.tooltip_text = "Exit the script"

API.DrawComboBox(imguicombo, false)


local COLORS = {
    BACKGROUND = ImColor.new(10, 13, 29),
    TARGET_UNSET = ImColor.new(189, 185, 167),
    TARGET_SET = ImColor.new(70, 143, 126),
    ACTION = ImColor.new(84, 166, 102),
    PAUSED = ImColor.new(238, 59, 83),
    RUNTIME = ImColor.new(198, 120, 102)
}

imguiBackground.colour = COLORS.BACKGROUND
imguiCurrentTarget.colour = COLORS.TARGET_UNSET
-- #endregion

local function gameStateChecks()
    local gameState = API.GetGameState()
    if (gameState ~= 3) then
        print('Not ingame with state:', gameState)
        API.Write_LoopyLoop(false)
        return
    end
    if targetNotFoundCount > 30 then
        imguiAction.box_name = "CHOP CHOP"
        runScript = false;
        API.Write_LoopyLoop(false)
    end
end

local function terminate()
    runScript = false
    API.Write_LoopyLoop(false)
end
local function getDistinctValues(inputTable)
    local distinctValues = {}
    local seenValues = {}
  
    for _, value in ipairs(inputTable) do
        if not seenValues[value] then
            table.insert(distinctValues, value)
            seenValues[value] = true
        end
    end
    return distinctValues
  end

local function populateDropdown()
    local allNPCS = API.ReadAllObjectsArray(false, 0)
    local objects = {}
    if #allNPCS > 0 then
        for _, a in pairs(allNPCS) do
            local distance = API.Math_DistanceF(a.Tile_XYZ, API.PlayerCoordfloat())
            a.Distance = distance;
            if a.Id ~= 0 and distance < 50 and a.Name ~= "" then
                for _, v in pairs(actionSpots) do
                    if v == a.Name then
                        table.insert(objects, a.Name)
                    end
                end
            end
        end
        local distinct = getDistinctValues(objects)
        if #distinct > 0 then
            table.sort(distinct)
            imguicombo.stringsArr = distinct
        end
    end
end

local function setTree()
    local currentMob = itemToGather;
    local selected = imguicombo.stringsArr[imguicombo.int_value + 1]
    if currentMob ~= selected then
        itemToGather = selected;
    end
    imguiCurrentTarget.colour = COLORS.TARGET_SET
    setTargetBtn.return_click = false;
end

local function pauseAction()
    runScript = false
    imguiAction.return_click = false
    imguiCurrentTarget.colour = COLORS.PAUSED
    imguiAction.box_name = "CHOP"
end

local function startAction()
    runScript = true;
    imguiCurrentTarget.colour = COLORS.ACTION
    imguiAction.box_name = "Pause"
end

local function drawGUI()
    if imguiTerminate.return_click then
        terminate()
    end
    if imguiAction.return_click then
        if not runScript then
            startAction()
        end
    else
        if runScript then
            pauseAction()
        end
    end
    if getTargetBtn.return_click then
        populateDropdown()
        getTargetBtn.return_click = false
    end
    if not runScript and setTargetBtn.return_click then
        setTree()
    end
    API.DrawSquareFilled(imguiBackground)
    API.DrawBox(setTargetBtn)
    API.DrawBox(getTargetBtn)
    imguiCurrentTarget.string_value = "Current target:" .. itemToGather
    API.DrawBox(imguiAction)
    API.DrawBox(imguiTerminate)
    API.DrawTextAt(imguiCurrentTarget)
    DrawProgressBar(IGP)
end

populateDropdown()


-- #endregion
--========GUI stuff========

--========IDLE========
local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((10 * 60) * 0.6, (10 * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end
--========IDLE========

local function cutNearestTree()
    if itemToGather == "None" then
        print('No target selected, stopping chopping');
        pauseAction()
        return true
    end
    local trees = API.GetAllObjArrayInteract_str({itemToGather}, 50, 12)

    for _, tree in ipairs(trees) do
        if API.DoAction_Object_valid2(0x3B, 0, { tree.Id }, 50, WPOINT.new(tree.TileX / 512, tree.TileY / 512, 1), true) then
            API.RandomSleep2(1200, 100, 200)
            API.WaitUntilMovingEnds()
            return true
        end
    end

    return false
end

local function dropInventory()
    print("inventory full, trying to drop logs")
    local i = 0
    for _, item in ipairs(API.ReadInvArrays33()) do
        for _, v in pairs(logIds) do
            if (item.itemid1 == v) then
                API.DoAction_Interface(0x24, item.itemid1, 8, 1473, 5, i, API.OFF_ACT_GeneralInterface_route2)
                i = i + 1
                API.RandomSleep2(200, 100, 200)
            end
        end
    end
    API.RandomSleep2(1200, 100, 200)
end

local function chopChop()
    if not API.CheckAnim(20) then
        if API.InvFull_() then
            dropInventory()
        end
        if not cutNearestTree() then
            print("No chopable tree found. Terminating...")
            API.Write_LoopyLoop(false)
        end
    end
end

while (API.Read_LoopyLoop()) do 
    API.DoRandomEvents()
    gameStateChecks()
    drawGUI()
    idleCheck()
    if runScript then
        chopChop()
    end
    printProgressReport()
    API.RandomSleep2(600, 200, 3000)
end 