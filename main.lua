local lastworld = GetWorld().name
local posx, posy = math.floor(GetLocal().pos.x / 32), math.floor(GetLocal().pos.y / 32)
local itemid = 5640
local mag = {x = 0, y = 0}
local clovers = 528
local webhook = "url_webhook"
local webhook_buf = webhook

local settings_file = "bfg_settings.txt"
function sendWebhook(msg)
    if not webhook or webhook == "" then return end
    if not webhook:find("^https://") then 
        LogToConsole("`4Invalid webhook URL")
        return 
    end
    webhook = webhook:gsub("%s+", "")

    local payload = string.format('{"content":"%s"}', msg:gsub('"','\\"'))

    local ok, err = pcall(function()
        MakeRequest(
            webhook,
            "POST",
            {["Content-Type"] = "application/json"},
            payload
        )
    end)
end

function saveSettings()
    local f = io.open(settings_file, "w")
    if not f then return end
    f:write(itemid .. "\n")
    f:write(mag.x .. "\n")
    f:write(mag.y .. "\n")
    f:write(webhook .. "\n")
    f:close()
    LogToConsole("`2Settings saved.")
end

function loadSettings()
    local f = io.open(settings_file, "r")
    if not f then 
        LogToConsole("`4No settings file found.")
        return 
    end

    local lines = {}
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()

    itemid = tonumber(lines[1]) or itemid
    mag.x  = tonumber(lines[2]) or mag.x
    mag.y  = tonumber(lines[3]) or mag.y

    if lines[4] then
        webhook = lines[4]:gsub("%s+", "")
        webhook_buf = webhook
    end

    LogToConsole("`2Settings loaded.")
end

function cheat(itemid)
    RunThread(function()
        if not GetLocal() then return end
        SendPacket(2, "action|input\n|text|/cheats")
        Sleep(2000)
        SendPacket(2, "action|dialog_return\ndialog_name|cheats\nautofarm_item|"..itemid.."\ncheat_fastdrop|0\ncheat_fastcollect|1\ncheat_autofarm|1\ncheat_antidamage|0\ncheat_superspeed|0\ncheat_megajump|0\ncheat_doublejump|0\nautofarm_delay|100")
    end)
end
    
function SteFindPath(tx, ty)
        local me = GetLocal()
        if not me then return end
        local cx = math.floor(me.pos.x / 32)
        local cy = math.floor(me.pos.y / 32)
        local world = GetWorld()
        if not world then return end
        if cy == ty then
            while cx ~= tx do
                if cx > tx then cx = cx - 1 else cx = cx + 1 end
                FindPath(cx, cy)
                Sleep(1)
            end
            return
        end
        local leftX = 0
        local rightX = world.width - 1
        local edgeX
        if math.abs(cx - leftX) < math.abs(cx - rightX) then
            edgeX = leftX
        else
            edgeX = rightX
        end
        
        while cx ~= edgeX do
            if cx > edgeX then cx = cx - 1 else cx = cx + 1 end
            FindPath(cx, cy)
            Sleep(1)
        end
        while cy ~= ty do
            if cy > ty then cy = cy - 1 else cy = cy + 1 end
            FindPath(cx, cy)
            Sleep(1)
        end
        while cx ~= tx do
            if cx > tx then cx = cx - 1 else cx = cx + 1 end
            FindPath(cx, cy)
            Sleep(1)
        end
end

function warp(world)
    SendPacket(3, "action|join_request\nname|"..world.."\ninvitedWorld|0")
end

function wrench(x, y)
        if not GetLocal() then return end
        SendPacketRaw(false, {
            type = 3,
            int_data = 32,
            int_x = x,
            int_y = y,
            pos_x = x * 32,
            pos_y = y * 32
        })
end

function takeremote(x, y)
        if not GetLocal() then return end
        if GetItemCount(5640) > 0 then
            warp("exit")
            Sleep(3500)
            warp(lastworld)
            Sleep(3500)
            SteFindPath(x, y - 1)
            wrench(x, y)
        else
            SteFindPath(x, y - 1)
            wrench(x, y)
        end
end
local magtext = ""
function listmag()
    local text = ""
    for _, tile in pairs(GetTiles()) do
        if not GetLocal() then return end
        if tile.fg == 5638 or tile.fg == 16268 then
            text = text..GetItemByIDSafe(tile.fg).name.." ("..tile.x..", "..tile.y..")\n"
        end
    end
    magtext = text
end
    
function main()
    RunThread(function()
        sendWebhook("Trying BFG")
        takeremote(mag.x, mag.y)
        Sleep(1000)
        SteFindPath(posx, posy)
        Sleep(500)
        cheat(itemid)
    end)
end

AddHook("OnVariant", "zax", function(var)
    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|itemsucker") then
        local x, y = var[1]:match("embed_data|tilex|(%d+)"), var[1]:match("embed_data|tiley|(%d+)")
        SendPacket(2, "action|dialog_return\ndialog_name|itemsucker\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|getplantationdevice\nchk_enablesucking|1")
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|cheats") then
        return true
    end
end)

AddHook('OnDraw', 'ZaXploitMenu', function(deltatime)
    if not GetLocal() then return end
    if ImGui.Begin('ZaXploit Menu') then
        

        ImGui.TextColored(ImVec4(0,1,0,1), "CHEAT SETTINGS")
        ImGui.Separator()
        local info = GetItemByIDSafe(itemid)
        if info ~= nil then
            ImGui.Text("Selected Item: " .. info.name)
        else
            ImGui.Text("ItemID not found")
        end
        local changed, newItemID = ImGui.InputInt("ItemID", itemid)
        if changed then itemid = newItemID end
        if ImGui.Button("Start BFG") then
            main()
        end
        ImGui.SameLine()
        if ImGui.Button("Save Settings") then
            if not GetLocal() or not GetWorld() then
                LogToConsole("`4Cannot save: not in world")
            else
                sendWebhook("Config Saved")
                saveSettings()
            end
        end
        ImGui.SameLine()
        if ImGui.Button("Load Settings") then
            sendWebhook("Config Loaded")
            loadSettings()
        end

        ImGui.Separator()
        ImGui.TextColored(ImVec4(0,0.7,1,1), "MAG CONTROL")
        local changedX, newX = ImGui.InputInt("Mag X", mag.x)
        if changedX then mag.x = newX end
        local changedY, newY = ImGui.InputInt("Mag Y", mag.y)
        if changedY then mag.y = newY end
        if ImGui.Button("Take Remote") then
            RunThread(function()
                takeremote(mag.x, mag.y)
            end)
        end
        ImGui.Text("Current Mag: (" .. mag.x .. ", " .. mag.y .. ")")
        ImGui.Separator()

        local changedUrl, newUrl = ImGui.InputText("URL_WEBHOOK", webhook_buf, 256)
        if changedUrl then
            webhook_buf = newUrl:gsub("%s+", "")
            webhook = webhook_buf
        end

        ImGui.Separator()
        ImGui.TextColored(ImVec4(1,0.8,0,1), "MAG LIST")
        ImGui.BeginChild("MagList", 400, 200, true)
        ImGui.TextWrapped(magtext)
        ImGui.EndChild()

    end
    ImGui.End()
end)

RunThread(function()
    while true do
        if GetLocal() then
            listmag()
        else
            Sleep(5000)
            warp(lastworld)
            Sleep(10000)
            if GetLocal() then 
                takeremote(mag.x, mag.y)
                Sleep(1000)
                SteFindPath(posx, posy)
                Sleep(500)
                cheat(itemid)
            end
        end
        Sleep(10000)
    end
end)
AddHook("OnVariant", "CLOVER", function(var)
    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|popup") then
        if var[1]:find("add_label_with_icon|small|`wLucky!``") then
            RunThread(function()
                Sleep(100)
            end)
        else
            RunThread(function()
                if GetItemCount(clovers) > 0 then
                    sendWebhook("Eating "..GetItemByIDSafe(clovers).name)
                    SendPacketRaw(false, {
                        type = 3,
                        int_data = clovers,
                        int_x = math.floor(GetLocal().pos.x / 32),
                        int_y = math.floor(GetLocal().pos.y / 32),
                        pos_x = GetLocal().pos.x,
                        pos_y = GetLocal().pos.y
                    })
                    Sleep(3000)
                else
                    sendWebhook("Clovers not found")
                    Sleep(10000)
                end
            end)
        end
        return true
    end
    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|daily_event_close") then
        return true
    end
end)

RunThread(function()
    while true do
        if not GetLocal() then Sleep(100) 
        else
            SendPacket(2, "action|wrench\n|netid|"..GetLocal().netid)
            Sleep(10000)    
        end
    end
end)
