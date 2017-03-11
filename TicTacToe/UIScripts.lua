if not TicTacToe then TicTacToe = {} end

function TicTacToe.ClickButton(f,button,down)
    if TicTacToe.finished == true then
        return
    end
    if TicTacToe.OnMove == false then
        return
    end
    if f.texture:GetTexture() ~= TicTacToe.tile then
        return
    end
    if TicTacToe.lastO then
        TicTacToe.lastO:SetTexture(TicTacToe.O)
    end
    TicTacToe.lastO = nil
    f.texture:SetTexture(TicTacToe.lx)
    TicTacToe.lastX = f.texture
    TicTacToe.SetOnMove(false)
    TicTacToe.DetectVictory(f)
    TicTacToe.SendAddonMessage(f:GetName(),"WHISPER",TicTacToe.Opponent)
end

function TicTacToe.ActivateButton(button)
    if TicTacToe.finished == true then
        return
    end
    local f = _G[button]
    if f.texture:GetTexture() ~= TicTacToe.tile then
    end
    if TicTacToe.lastX then
        TicTacToe.lastX:SetTexture(TicTacToe.X)
    end
    TicTacToe.lastX = nil
    f.texture:SetTexture(TicTacToe.lo)
    TicTacToe.lastO = f.texture
    TicTacToe.SetOnMove(true)
    TicTacToe.DetectVictory(f)
end

function TicTacToe.ShowPlayground()
    TicTacToe["playground"]:Show()
end

function TicTacToe.CloseFrame()
    TicTacToe["playground"]:Hide()
    TicTacToe["playing"] = 0
    if TicTacToe.finished == false then
        TicTacToeSV["score"][TicTacToe.Opponent]["L"] = TicTacToeSV["score"][TicTacToe.Opponent]["L"] + 1
        TicTacToe.print("You have left the game."..TicTacToe.GetScore())
        TicTacToe.SendAddonMessage("close","WHISPER",TicTacToe.Opponent)
        TicTacToe.finished = true
        TicTacToe.Opponent = "N/A"
        TicTacToe.Lobby.Challenger = nil
        TicTacToe.Lobby.popup = nil
    end
    TicTacToe.ClearPlayground()
    TicTacToe.lastX = nil
    TicTacToe.lastO = nil
end

function TicTacToe.ClearPlayground()
    for x=1,20 do for y=1,20 do
        f = TicTacToe["buttons"][x][y].texture:SetTexture(TicTacToe.tile)
    end end
    if TicTacToe.OnMove == true then
        TicTacToe["turn"].texture:SetTexture(TicTacToe.urturn)
    else
        TicTacToe["turn"].texture:SetTexture(TicTacToe.opturn)
    end
end

function TicTacToe.print(text)
    print("|cffdfff00TicTacToe: "..text)
end

function TicTacToe.MoveFrame()
    TicTacToe["playground"]:StartMoving()
end

function TicTacToe.StopMoveFrame()
    TicTacToe["playground"]:StopMovingOrSizing()
end

function TicTacToe.ShowNick(nick)
    local main = TicTacToeSV["alts"][nick]
    TicTacToe["NickFrame"]:SetText(nick.."\n"..TicTacToeSV["score"][main]["W"].." : "..TicTacToeSV["score"][main]["L"])
end

function TicTacToe.DragIcon()
    local xpos,ypos = GetCursorPosition()
    local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()
    xpos = xmin-xpos/UIParent:GetScale()+70
    ypos = ypos/UIParent:GetScale()-ymin-70
    TicTacToeSV["minimap"] = math.deg(math.atan2(ypos,xpos))
    TTTMinimap:SetPoint("TOPLEFT",52-(80*cos(TicTacToeSV["minimap"])),(80*sin(TicTacToeSV["minimap"]))-52)
end

function TicTacToe.ToggleVisibility()
    local p = TicTacToe["playground"]
    if p:IsVisible() then
        p:Hide()
    else
        if TicTacToe["playing"] == 1 then
            p:Show()
        else
            TicTacToe.print("You are not playing any game.\ntype \"/tic nick\" to challenge someone or accept their challenge\nIn case you challenge \"yourself\" you play against bot\nTo connect into lobby right click minimap icon")
        end
    end
end

function TicTacToe.HandleMouseClick(_, ButtonId)
    if (ButtonId == "RightButton") then
		TicTacToe.Lobby.HandlePopup()
	    return
    end
	TicTacToe.ToggleVisibility()
end
