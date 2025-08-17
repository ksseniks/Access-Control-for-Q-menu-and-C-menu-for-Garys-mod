---------------------------------ACCES TABLE---------------------------------
local allowedPlayersQ = allowedPlayersQ or {}
local allowedPlayersC = allowedPlayersC or {}
---------------------------------END ACCES TABLE---------------------------------
--==========================================================================================================--
---------------------------------CHECKING FOR AUTISM---------------------------------
if SERVER then
    ---------------------------------ADD NETWORK STRING---------------------------------
    util.AddNetworkString("OpenAccessMenu")
    util.AddNetworkString("ToggleAccess")
    util.AddNetworkString("UpdateAllowedList")
    ---------------------------------END ADD NETWORK STRING---------------------------------
    --==========================================================================================================--
    ---------------------------------LOAD ACCESS DATA---------------------------------
    local saveFile = "Access Menus.json"
    local function LoadAccessData()
        if file.Exists(saveFile, "DATA") then
            local content = file.Read(saveFile, "DATA")
            local data = util.JSONToTable(content)
            if (data) then
                allowedPlayersQ = data.Q or {}
                allowedPlayersC = data.C or {}
            end
        end
    end
    ---------------------------------END LOAD ACCESS DATA---------------------------------
    --==========================================================================================================--
    ---------------------------------LOAD ON START LUA---------------------------------
    LoadAccessData()
    ---------------------------------END LOAD ON START LUA---------------------------------
    --==========================================================================================================--
    ---------------------------------CONCOMMAND OPEN ACCES MENU---------------------------------
    concommand.Add("ks_accessMenu", function(onlineplayers)
        if (!onlineplayers:IsAdmin()) then return end

        net.Start("OpenAccessMenu")
        net.WriteTable(player.GetAll())
        net.Send(onlineplayers)

        net.Start("UpdateAllowedList")
        net.WriteTable({Q = allowedPlayersQ, C = allowedPlayersC})
        net.Send(onlineplayers)
    end)
    ---------------------------------END CONCOMMAND OPEN ACCES MENU---------------------------------
    --==========================================================================================================--
    ---------------------------------GET PALYER BY SID---------------------------------
    function GetPlayerBySID(sid64)
        for id, onlinePlayers in ipairs(player.GetAll()) do
            if (onlinePlayers:SteamID64() == sid64) then
                return onlinePlayers
            end
        end
        return NULL
    end
    ---------------------------------END GET PALYER BY SID---------------------------------
    --==========================================================================================================--
    ---------------------------------TOGGLE ACESS---------------------------------
    net.Receive("ToggleAccess", function(_, onlineplayers)
        if (!onlineplayers:IsAdmin()) then return end

        local sid = net.ReadString()
        local menuType = net.ReadString()
        local newState = net.ReadBool()

        if (GetPlayerBySID(sid):IsValid()) then
            if menuType == "Q" then
                allowedPlayersQ[sid] = newState
                print("[ACCESS] " .. GetPlayerBySID(sid):Nick() .. " Q menu set to " .. tostring(newState))
            elseif menuType == "C" then
                allowedPlayersC[sid] = newState
                print("[ACCESS] " .. GetPlayerBySID(sid):Nick() .. " C menu set to " .. tostring(newState))
            end
        else
            print("Игрок не найден !")
        end

        local data = {Q = allowedPlayersQ, C = allowedPlayersC}
        file.Write(saveFile, util.TableToJSON(data, true))

        net.Start("UpdateAllowedList")
        net.WriteTable({Q = allowedPlayersQ, C = allowedPlayersC})
        net.Broadcast()
    end)
    ---------------------------------END TOGGLE ACESS---------------------------------
end
---------------------------------END CHECKING FOR AUTISM---------------------------------
--==========================================================================================================--
---------------------------------CHECKING FOR AUTISM---------------------------------
if CLIENT then
    ---------------------------------LANGUAGE FUNCTION---------------------------------
    function GetLanguedge()
        local languedge = GetConVar("gmod_language"):GetString()
        if (LanguageBase[languedge] == nil) then
            languedge = "en"
        end
        return languedge
    end
    ---------------------------------END LANGUAGE FUNCTION---------------------------------
    --==========================================================================================================--
    ---------------------------------ACCESS TO MENU---------------------------------
    hook.Add("SpawnMenuOpen", "AccessToSpawnMenu", function()
        return allowedPlayersQ[LocalPlayer():SteamID64()] or false
    end)

    hook.Add("ContextMenuOpen", "AccessToContextMenu", function()
        return allowedPlayersC[LocalPlayer():SteamID64()] or false
    end)
    ---------------------------------END ACCESS TO MENU---------------------------------
    --==========================================================================================================--
    ---------------------------------UPDATE ALLOWED LIST---------------------------------
    net.Receive("UpdateAllowedList", function()
        local tbl = net.ReadTable()
        allowedPlayersQ = tbl.Q or {}
        allowedPlayersC = tbl.C or {}
    end)
    --------------------------------END UPDATE ALLOWED LIST---------------------------------
    --==========================================================================================================--
    ---------------------------------OPEN ACCESS MENU---------------------------------
    net.Receive("OpenAccessMenu", function()
        local players = net.ReadTable()
        local lang = GetLanguedge()
        local L = LanguageBase[lang]

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 500)
        frame:Center()
        frame:SetTitle(LanguageBase[GetLanguedge()].access_menu_title)
        frame:MakePopup()

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)

        for id, onlineplayers in ipairs(players) do
            local sid = onlineplayers:SteamID64()

            --------------------------------BUTTON NICK AND AVATAR--------------------------------
            local btnPlayer = vgui.Create("DButton", scroll)
            btnPlayer:Dock(TOP)
            btnPlayer:SetTall(60)
            btnPlayer:DockMargin(0, 0, 0, 5)
            btnPlayer:SetText(onlineplayers:Nick())
            btnPlayer:SetFont("DermaDefaultBold")
            btnPlayer:SetColor(Color(255, 255, 255))
            btnPlayer:SetCursor("hand")
            btnPlayer.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(50, 50, 50))
                if self:IsHovered() then
                    draw.RoundedBox(8, 0, 0, w, h, Color(70, 130, 180))
                end
            end

            local avatar = vgui.Create("AvatarImage", btnPlayer)
            avatar:SetSize(48, 48)
            avatar:SetPos(5, 6)
            avatar:SetPlayer(onlineplayers, 64)

            local sub = vgui.Create("DPanel", scroll)
            sub:Dock(TOP)
            sub:SetTall(0)
            sub.Paint = nil
            sub:SetVisible(false)

            --------------------------------BUTTON Q--------------------------------
            local btnQ = vgui.Create("DButton", sub)
            btnQ:Dock(TOP)
            btnQ:DockMargin(5,5,5,2)
            btnQ:SetTall(30)
            btnQ:SetText("")
            btnQ:SetAlpha(0)
            btnQ.DoClick = function()
                local val = not (allowedPlayersQ[sid] or false)
                allowedPlayersQ[sid] = val

                net.Start("ToggleAccess")
                net.WriteString(sid)
                net.WriteString("Q")
                net.WriteBool(val)
                net.SendToServer()
            end
            btnQ.Paint = function(self, w, h)
                local bg = allowedPlayersQ[sid] and Color(34, 139, 34) or Color(178, 34, 34)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                local text = allowedPlayersQ[sid] and LanguageBase[GetLanguedge()].allow_q_yes or LanguageBase[GetLanguedge()].allow_q_no
                draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            --------------------------------BUTTON C--------------------------------
            local btnC = vgui.Create("DButton", sub)
            btnC:Dock(TOP)
            btnC:DockMargin(5,2,5,5)
            btnC:SetTall(30)
            btnC:SetText("")
            btnC:SetAlpha(0)
            btnC.DoClick = function()
                local val = not (allowedPlayersC[sid] or false)
                allowedPlayersC[sid] = val

                net.Start("ToggleAccess")
                net.WriteString(sid)
                net.WriteString("C")
                net.WriteBool(val)
                net.SendToServer()
            end
            btnC.Paint = function(self, w, h)
                local bg = allowedPlayersC[sid] and Color(34, 139, 34) or Color(178, 34, 34)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                local text = allowedPlayersC[sid] and LanguageBase[GetLanguedge()].allow_c_yes or LanguageBase[GetLanguedge()].allow_c_no
                draw.SimpleText(text, "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local expanded = false
            btnPlayer.DoClick = function()
                expanded = not expanded
                if expanded then
                    sub:SetVisible(true)
                    sub:SizeTo(0, 78, 0.2, 0, 0.3)
                    btnQ:AlphaTo(255, 0.25, 0.1)
                    btnC:AlphaTo(255, 0.25, 0.1)
                else
                    btnQ:AlphaTo(0, 0.2, 0)
                    btnC:AlphaTo(0, 0.2, 0)
                    sub:SizeTo(0, 0, 0.2, 0, 0.3, function()
                        sub:SetVisible(false)
                    end)
                end
            end
        end
    end)
    ---------------------------------END OPEN ACCESS MENU---------------------------------

end
---------------------------------END CHECKING FOR AUTISM---------------------------------