if not TicTacToe then TicTacToe = {} end

function TicTacToe.OnEvent(wtfisthis, event, arg1, arg2)
    if arg1 == "TicTacToe" then
        SLASH_TicTacToe1, SLASH_TicTacToe2 = "/TicTacToe", "/tic"
        SlashCmdList["TicTacToe"] = TicTacToe.ChatCommandHandler
        TicTacToe.SavedVars()
        TicTacToe.Initialize()
    end
end

function TicTacToe.GetSub(msg)
     if msg then
         local a,b,c=strfind(msg, "(%S+)")
         if a then
             return c, strsub(msg, b+2)
         else
             return ""
         end
     end
 end

function TicTacToe.StartGame(player)
    for i, v in ipairs(TicTacToe["challengers"]) do
        if v and strlower(v) == strlower(player) then
            table.remove(TicTacToe["challengers"], i)
            local startString = "start "
            local onMove = random(0,1)
            startString=startString..onMove
            if onMove == 0 then
                onMove = true
            else
                onMove = false
            end
            TicTacToe.SendAddonMessage(startString,"WHISPER",player)
            TicTacToe.Opponent = v
            if not TicTacToeSV["alts"][v] then
                TicTacToeSV["alts"][v] = v
            end
            TicTacToe.SendAddonMessage("altsrequest","WHISPER",v)
            local main = TicTacToeSV["alts"][v]
            if not TicTacToeSV["score"][main] then TicTacToeSV["score"][main] = {} end
            if not TicTacToeSV["score"][main]["W"] then TicTacToeSV["score"][main]["W"] = 0 end
            if not TicTacToeSV["score"][main]["L"] then TicTacToeSV["score"][main]["L"] = 0 end
            TicTacToe.ShowPlayground()
            TicTacToe.ShowNick(v)
            TicTacToe.SetOnMove(onMove)
            TicTacToe.Reset(false,false)
            TicTacToe["playing"] = 1
            TicTacToe.Lobby.popup = nil
            if TicTacToe.Lobby.ChannelId then
                TicTacToe.Lobby.Leave(true)
            end
            break
        end
    end
    TicTacToe.SendAddonMessage("version "..TicTacToe.version, "WHISPER", player) -- sync versions
    TicTacToe["challengers"] = { }
end
 
function TicTacToe.ChatCommandHandler(msg)
    if not msg or msg =="" then
        return
    end
    msg = TicTacToe.GetSub(msg)
    if strlower(msg) == strlower(UnitName("player")) then
        local main = "TicTacToe Bot"
        TicTacToe.Opponent = main
        if not TicTacToeSV["alts"][main] then TicTacToeSV["alts"][main] = main end
        if not TicTacToeSV["score"][main] then TicTacToeSV["score"][main] = {} end
        if not TicTacToeSV["score"][main]["W"] then TicTacToeSV["score"][main]["W"] = 0 end
        if not TicTacToeSV["score"][main]["L"] then TicTacToeSV["score"][main]["L"] = 0 end
        TicTacToe.ShowPlayground()
        TicTacToe.ShowNick(main)
        TicTacToe.SetOnMove(true)
        TicTacToe.Reset(false,false)
        TicTacToe.BotAI.Init()
        TicTacToe["playing"] = 1
        return
    end
    TicTacToe.StartGame(msg)
    local start = strsub(msg,1,1)
    local rest = strsub(msg,2)
    start = strupper(start)
    rest = strlower(rest)
    msg = start..rest
    TicTacToe.print("Challenge request has been sent to "..msg..".")
    TicTacToe.SendAddonMessage("init","WHISPER",msg)
end

function TicTacToe.RcvMsg(self, event, prefix, message, channel, sender)
    if prefix ~= "TicTacToe" then
        return
    end
    local submsg
    message,submsg = TicTacToe.GetSub(message)
    if message == "altsreply" then
        TicTacToe.InsertAlts(submsg)
    elseif message == "altsrequest" then
        TicTacToe.SendAlts(sender)
    elseif message == "version" then
        if tonumber(submsg) > tonumber(TicTacToe.version) then
            TicTacToe.print("Your version is out of date!")
            TicTacToe.print("Download last version at")
            TicTacToe.print("https://github.com/Evolvee/Evolve-TicTacToe")
        end
    elseif TicTacToe["playing"] == 0 then
        if message == "lobbyaccept" then
            if TicTacToe.Lobby.ChannelId then
                if sender == TicTacToe.Lobby.Challenger then
                    TicTacToe.StartGame(sender)
                end
            end
        elseif message == "lobbydecline" then
            if sender == TicTacToe.Lobby.Challenger and TicTacToe.Lobby.ChannelId then
                TicTacToe.Lobby.Challenger = nil
                TicTacToe.Lobby.popup = nil
                StaticPopup_Hide("TicTacToe_Lobby_Accept")
                TicTacToe.print("Your opponent refused the game.")
                TicTacToe.Lobby.Reconnect()
            end
        elseif message == "lobbylate" then -- /cry, sent request too late (someone was faster)
            for i, v in ipairs(TicTacToe["challengers"]) do
                if v and strlower(v) == strlower(sender) then
                    table.remove(TicTacToe["challengers"], i)
                end
            end
        elseif message == "lobby" then
            if TicTacToe.Lobby.Challenger == nil then
                TicTacToe.Lobby.Challenger = sender
                TicTacToe.SendAddonMessage("lobby","WHISPER", sender)
            elseif TicTacToe.Lobby.Challenger == sender and not TicTacToe.Lobby.popup then
                TicTacToe.Lobby.popup = 1
                TicTacToe.SendAddonMessage("lobby","WHISPER", sender)
                TicTacToe.Lobby.AcceptPopup(sender)
            else
                TicTacToe.SendAddonMessage("lobbylate", "WHISPER", sender)
            end
        elseif message == "init" then
            TicTacToe.print(sender.." has challenged you for a game.")
            TicTacToe.print('type in "/TicTacToe '..sender..'".')
            table.insert(TicTacToe["challengers"], sender)
        elseif message == "start" then
            TicTacToe.Opponent = sender
            if tonumber(submsg) == 1 then
                TicTacToe.SetOnMove(true)
            else
                TicTacToe.SetOnMove(false)
            end
            TicTacToe["playing"] = 1
            if not TicTacToeSV["alts"][sender] then
                TicTacToeSV["alts"][sender] = sender
            end
            TicTacToe.SendAddonMessage("altsrequest","WHISPER",sender)
            local main = TicTacToeSV["alts"][sender]
            if not TicTacToeSV["score"][main] then TicTacToeSV["score"][main] = {} end
            if not TicTacToeSV["score"][main]["W"] then TicTacToeSV["score"][main]["W"] = 0 end
            if not TicTacToeSV["score"][main]["L"] then TicTacToeSV["score"][main]["L"] = 0 end
            TicTacToe.Reset(false,false)
            TicTacToe.ShowPlayground()
            TicTacToe.ShowNick(sender)
            TicTacToe["challengers"] = { }
            if TicTacToe.Lobby.ChannelId then
                TicTacToe.Lobby.Leave(true)
            end
        elseif message == "busy" then
            TicTacToe.print(sender.." is busy playing another game.")
        end
    else
        if sender ~= TicTacToe.Opponent then
            if message == "init" or message == "start" then
                TicTacToe.SendAddonMessage("busy","WHISPER",sender)
            end
            return
        elseif message == "busy" or message == "init" then
            --why should it do anything if player is already playing the game?
        elseif message == "reset" then
            TicTacToe.print("The game has been restarted.")
            TicTacToe.Reset(false,false)
            TicTacToe.ClearPlayground()
        elseif message == "tryreset" then
            TicTacToe.print(sender.." wants to restart the game.")
            TicTacToe.CanReset = true
        elseif message == "forfeit" then
            TicTacToe.ModifyScore("W")
            TicTacToe["turn"].texture:SetTexture(TicTacToe.won)
            TicTacToe.print(sender.." gave up."..TicTacToe.GetScore())
            TicTacToe.Reset(false,true)
        elseif message == "close" then
            if TicTacToe.finished == false then
                TicTacToe.ModifyScore("W")
                TicTacToe["turn"].texture:SetTexture(TicTacToe.won)
            end
            TicTacToe.print(sender.." closed the game. "..TicTacToe.GetScore())
            TicTacToe["playing"] = 0
            TicTacToe.Reset(false,true)
            TicTacToe.Opponent = "N/A"
            TicTacToe.ClearPlayground()
        elseif strlen(message) == 4 then
            TicTacToe.ActivateButton(message)
        end
    end
end

function TicTacToe.CheckDirection(x,y,initx,inity,shape,shape2)
    local ix,iy = 0,0
    local seq = 1
    local way = true
    while(true) do
        if way == true then
            ix = ix + initx
            iy = iy + inity
        else
            ix = ix - initx
            iy = iy - inity
        end
        if ix+x > 20 or ix+x < 1 or iy+y > 20 or iy+y < 1 then
            if way == true then
                way = false
                ix = 0
                iy = 0
                seq = seq - 1
            else
                return false
            end
        end
        local t = TicTacToe["buttons"][x+ix][y+iy].texture:GetTexture()
        if t == shape or t == shape2 then
            seq = seq + 1
            if seq == 5 then
                return true
            end
        elseif way == true then -- check the opposite side
            way = false
            ix = 0
            iy = 0
        else
            return false
        end
    end
end

function TicTacToe.DetectVictoryWay(x,y,i,j,shape)
    local shape2
    if shape == TicTacToe.lx then
        shape2 = TicTacToe.X
    else
        shape2 = TicTacToe.O
    end
    if TicTacToe.CheckDirection(x,y,i,j,shape,shape2) == true then
        if TicTacToe.OnMove == true then
            TicTacToe.ModifyScore("L")
            TicTacToe["turn"].texture:SetTexture(TicTacToe.lost)
            TicTacToe.print(TicTacToe.Opponent.." has won the game."..TicTacToe.GetScore())
        else
            TicTacToe.ModifyScore("W")
            TicTacToe["turn"].texture:SetTexture(TicTacToe.won)
            TicTacToe.print("You have won the game."..TicTacToe.GetScore())
        end
        TicTacToe.Reset(TicTacToe.CanReset,true)
        return true
    end
    return false
end

function TicTacToe.DetectVictory(f) -- f = last button
    local shape = f.texture:GetTexture()
    local x,y = TicTacToe.GetButtonXY(f)
    for i = -1,1 do
        if TicTacToe.DetectVictoryWay(x,y,i,1,shape) == true then
            return
        end
    end
    TicTacToe.DetectVictoryWay(x,y,1,0,shape)
end

function TicTacToe.ForfeitGame()
    if TicTacToe.finished == true then
        TicTacToe.print("You can't forfeit finished game.")
        return
    end
    TicTacToe.SendAddonMessage("forfeit","WHISPER",TicTacToe.Opponent)
    TicTacToe.ModifyScore("L")
    TicTacToe["turn"].texture:SetTexture(TicTacToe.lost)
    TicTacToe.Reset(false,true)
    TicTacToe.print("You have forfeited the game."..TicTacToe.GetScore())
end

function TicTacToe.GetScore()
    local main = TicTacToeSV["alts"][TicTacToe.Opponent]
    return " ("..TicTacToeSV["score"][main]["W"].."W/"..TicTacToeSV["score"][main]["L"].."L)"
end

function TicTacToe.TryRestart()
    if TicTacToe.CanReset == true then
        TicTacToe.ClearPlayground()
        TicTacToe.Reset(false,false)
        TicTacToe.print("The game has been restarted.")
        TicTacToe.SendAddonMessage("reset","WHISPER",TicTacToe.Opponent)
    else
        TicTacToe.print("Restart request sent.")
        TicTacToe.SendAddonMessage("tryreset","WHISPER",TicTacToe.Opponent)
    end
end

function TicTacToe.Reset(CanReset,finished)
    TicTacToe.CanReset = CanReset
    TicTacToe.finished = finished
    TicTacToe.lastO = nil
    TicTacToe.lastX = nil
    if finished == true then
        TicTacToe.Lobby.Challenger = nil
        TicTacToe.Lobby.popup = nil
    end
    if not TicTacToe.Opponent or TicTacToe.Opponent == "N/A" then
        return
    end
    TicTacToe.ShowNick(TicTacToe.Opponent)
end

function TicTacToe.SetOnMove(playing)
    TicTacToe.OnMove = playing
    local texture
    if playing == true then
        texture = TicTacToe.urturn
    else
        texture = TicTacToe.opturn
    end
    TicTacToe["turn"].texture:SetTexture(texture)
end

function TicTacToe.ModifyScore(type,ammout)
    if not ammout then ammout = 1 end
    local main = TicTacToeSV["alts"][TicTacToe.Opponent]
    TicTacToeSV["score"][main][type] = TicTacToeSV["score"][main][type] + ammout
end

function TicTacToe.InsertAlts(alts)
    rememberme = alts
    local current, rest = TicTacToe.GetSub(alts)
    local tmpArr = {}
    while(rest) do
        table.insert(tmpArr, current)
        current, rest = TicTacToe.GetSub(rest)
    end
    table.insert(tmpArr,current)
    local i = 1
    local found = false
    local main
    while (tmpArr[i]) do
    local curr = tmpArr[i]
        if TicTacToeSV["alts"][tmpArr[i]] == tmpArr[i] then
            if found == true then
                TicTacToeSV["alts"][curr] = mainChar
                if TicTacToeSV["score"][curr] then
                    TicTacToe.ModifyScore("W",TicTacToeSV["score"][curr]["W"])
                    TicTacToe.ModifyScore("L",TicTacToeSV["score"][curr]["L"])
                    TicTacToeSV["score"][curr] = nil
                end
            else
                main = curr
                TicTacToeSV["alts"][TicTacToe.Opponent] = curr
                if TicTacToeSV["score"][TicTacToe.Opponent] then
                    if TicTacToe.Opponent ~= main then
                        TicTacToe.ModifyScore("W",TicTacToeSV["score"][TicTacToe.Opponent]["W"])
                        TicTacToe.ModifyScore("L",TicTacToeSV["score"][TicTacToe.Opponent]["L"])
                        TicTacToeSV["score"][TicTacToe.Opponent] = nil
                    end
                end
                found = true
            end
        end
        i=i+1
        if found == false then
            TicTacToeSV["alts"][TicTacToe.Opponent] = TicTacToe.Opponent
        end
    end
    TicTacToe.ShowNick(TicTacToe.Opponent)
end

function TicTacToe.SendAlts(requester)
    local alts = ""
    for key,val in pairs(TicTacToeSV["chars"]) do
        alts = alts..key.." "
    end
    TicTacToe.SendAddonMessage("altsreply "..alts,"WHISPER",requester)
end

function TicTacToe.SendAddonMessage(message,channel,target)
    if TicTacToe.botGame == true then
        TicTacToe.BotAI.RcvMsg(message)
        return
    end
    SendAddonMessage("TicTacToe",message,channel,target)
end

function TicTacToe.GetButtonXY(button)
    if type(button) == 'string' then
        local n = button
        return tonumber(strsub(n,1,2)), tonumber(strsub(n,3,4))
    end
    local n = button:GetName()
    return tonumber(strsub(n,1,2)), tonumber(strsub(n,3,4))
end

function TicTacToe.NormCoord(coord)
    if coord < 10 then coord = "0"..coord end
    return coord
end