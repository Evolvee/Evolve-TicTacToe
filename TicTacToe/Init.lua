if not TicTacToe then TicTacToe = {} end
TicTacToe.version = "2.2"

function TicTacToe.Initialize()
    TicTacToe["playing"] = 0
    TicTacToe.Opponent = "N/A"
    TicTacToe["challengers"] = {}
    local path = "Interface\\AddOns\\TicTacToe\\graphics\\"
    TicTacToe.tile = path.."tile"
    TicTacToe.bg = path.."rbd"
    TicTacToe.X = path.."X"
    TicTacToe.O = path.."O"
    TicTacToe.exit = path.."exit"
    TicTacToe.min = path.."min"
    TicTacToe.ff = path.."forfeit"
    TicTacToe.reset = path.."restart"
    TicTacToe.opturn = path.."opturn"
    TicTacToe.urturn = path.."urturn"
    TicTacToe.lost = path.."lost"
    TicTacToe.won = path.."won"
    TicTacToe.lo = path.."lastO"
    TicTacToe.lx = path.."lastX"
    TicTacToe.free = path.."free"
    TicTacToe.font = path.."Play-Bold.TTF"
    TicTacToe.icn = path.."icon"
    TicTacToe["playground"] = CreateFrame("Frame","TTTPG",UIParent)
    local pg = TicTacToe["playground"]
    TicTacToe["header"] = CreateFrame("Button",nil,pg)
    local f = TicTacToe["header"]
    pg:SetMovable(true)
    f:EnableMouse(true)
    TicTacToe["HeaderText"] = CreateFrame("Frame",nil,f)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", TicTacToe.MoveFrame)
    f:SetScript("OnDragStop", TicTacToe.StopMoveFrame)
    TicTacToe["close"] = CreateFrame("Button",nil,pg)
    TicTacToe["minimize"] = CreateFrame("Button",nil,pg)
    TicTacToe["forfeit"] = CreateFrame("Button",nil,pg)
    TicTacToe["buttons"] = {}
    TicTacToe["restart"] = CreateFrame("Button",nil,pg)
    TicTacToe["turn"] = CreateFrame("Button",nil,pg)
    TicTacToe["NickFrame"] = CreateFrame("Frame",nil,pg,UIPanelButtonTemplate)
    TicTacToe["icon"] = CreateFrame("Frame",nil,pg)
    TicTacToe.OnMove = true
    TicTacToe.CanReset = false
    TicTacToe.finished = false
    for i = 1,20 do
        TicTacToe["buttons"][i] = {}
        for j = 1,20 do
            local ButtonName = ""
            if i < 10 then ButtonName = ButtonName.."0" end
            ButtonName = ButtonName..i
            if j < 10 then ButtonName = ButtonName.."0" end
            ButtonName = ButtonName..j
            TicTacToe["buttons"][i][j] = CreateFrame("Button",ButtonName,pg)
        end
    end
    TicTacToe.InitPlayground()
    local angle = 30
    if TicTacToeSV["minimap"] then
        angle = TicTacToeSV["minimap"]
    end
    TTTMinimap:SetPoint("TOPLEFT",52-(80*cos(angle)),(80*sin(angle))-52)
    LeaveChannelByName("Evolve_TicTacToe_AddOn")
end

function TicTacToe.SavedVars()
    local _,ver = GetBuildInfo()
    if tonumber(ver)> 12340 then
        RegisterAddonMessagePrefix("TicTacToe")
    end
    if not TicTacToeSV or not TicTacToeSV["version"] then
        TicTacToeSV = {}
        TicTacToeSV["version"] = tonumber(TicTacToe.version)
    elseif TicTacToeSV["version"] < 0.5 then
        TicTacToeSV = {}
    elseif TicTacToeSV["version"] < 1.1 then
        TicTacToeSV["score"] = {}
        for key,val in pairs(TicTacToeSV) do
            if key ~= "version" and key ~= "score" then
                TicTacToeSV["score"][key] = {}
                TicTacToeSV["score"][key]["W"] = TicTacToeSV[key]["W"]
                TicTacToeSV["score"][key]["L"] = TicTacToeSV[key]["L"]
                TicTacToeSV[key] = nil
            end
        end
    end
    if not TicTacToeSV["score"] then TicTacToeSV["score"] = {} end
    if not TicTacToeSV["alts"] then TicTacToeSV["alts"] = {} end
    if not TicTacToeSV["chars"] then TicTacToeSV["chars"] = {} end
    local nick = UnitName("player")
    TicTacToeSV["chars"][nick] = true
    if TicTacToeSV["version"] < tonumber(TicTacToe.version) then
        TicTacToeSV["version"] = tonumber(TicTacToe.version)
    end
end

function TicTacToe.InitButton(f,w,h,texture,s)
    if not s then
        f:SetFrameStrata("LOW")
    else
        f:SetFrameStrata(s)
    end
    f:SetWidth(w)
    f:SetHeight(h)
    t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture(texture)
    t:SetAllPoints(f)
    f.texture = t
    f:SetAlpha(.775)
end

function TicTacToe.InitPlayground()
    local f = TicTacToe["playground"]
    f:SetFrameStrata("BACKGROUND")
    f:SetWidth(600)
    f:SetHeight(420)
    local t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture(TicTacToe.bg)
    t:SetAllPoints(f)
    f.texture = t
    f:SetPoint("CENTER",0,0)
    f:Hide()
    for x=1,20 do for y=1,20 do
        f = TicTacToe["buttons"][x][y]
        TicTacToe.InitButton(f,20,20,TicTacToe.tile)
        f:SetPoint("BOTTOMLEFT",(x-1)*20,(y-1)*20)
        f:SetScript("OnClick", TicTacToe.ClickButton)
    end end
    f = TicTacToe["close"]
    TicTacToe.InitButton(f,20,20,TicTacToe.exit,"MEDIUM")
    f:SetPoint("TOPRIGHT")
    f:SetScript("OnClick", TicTacToe.CloseFrame)

    f = TicTacToe["minimize"]
    TicTacToe.InitButton(f,20,20,TicTacToe.min,"MEDIUM")
    f:SetPoint("TOPRIGHT",-20,0)
    f:SetScript("OnClick", TicTacToe.HandleMouseClick)

    f = TicTacToe["header"]
    TicTacToe.InitButton(f,600,20,nil)
    f:SetPoint("TOP")

    f = TicTacToe["HeaderText"]
    TicTacToe.InitButton(f,300,18,TicTacToe.title)
    f:SetPoint("CENTER")
    f:SetAlpha(1)
    
    f = TicTacToe["forfeit"]
    TicTacToe.InitButton(f,75,30,TicTacToe.ff)
    f:SetPoint("BOTTOMRIGHT",-5,5)
    f:SetScript("OnClick", TicTacToe.ForfeitGame)
    
    f = TicTacToe["restart"]
    TicTacToe.InitButton(f,75,30,TicTacToe.reset)
    f:SetPoint("BOTTOMRIGHT",-5,40)
    f:SetScript("OnClick", TicTacToe.TryRestart)

    f = TicTacToe["turn"]
    TicTacToe.InitButton(f,150,40,TicTacToe.urturn)
    f:SetPoint("TOPRIGHT",-5,-25)
    
    f = TicTacToe["NickFrame"]
    TicTacToe.InitButton(f,150,60,TicTacToe.free,"MEDIUM")
    f:SetPoint("TOPRIGHT",-5,-70)
    f = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetTextColor(255,255,255,0.75)
    f:SetShadowColor(0,0,0,0.5)
    f:SetShadowOffset(2,-2)
    f:SetFont(TicTacToe.font, 14, "OUTLINE")
    f:SetSpacing(6)
    f:SetPoint("CENTER")
    TicTacToe["NickFrame"] = f

    f = TicTacToe["icon"]
    TicTacToe.InitButton(f,20,20,TicTacToe.icn,"MEDIUM")
    f:SetPoint("TOPLEFT")
end

local freg = CreateFrame("Frame")
freg:RegisterEvent("ADDON_LOADED")
freg:SetScript("OnEvent", TicTacToe.OnEvent)
local fmsg = CreateFrame("Frame")
fmsg:RegisterEvent("CHAT_MSG_ADDON")
fmsg:SetScript("OnEvent", TicTacToe.RcvMsg)