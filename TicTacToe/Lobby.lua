local flobby = CreateFrame("Frame");
TicTacToe.Lobby = { }
function TicTacToe.Lobby.Join(quiet)
    JoinTemporaryChannel("Evolve_TicTacToe_AddOn")
	TicTacToe.Lobby.ChannelId = GetChannelName("Evolve_TicTacToe_AddOn")
    flobby:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
    flobby:RegisterEvent("CHAT_MSG_CHANNEL")
    flobby:SetScript("OnEvent", TicTacToe.HandleLobby)
    if not quiet then
        TicTacToe.print("Joining lobby...")
    end
end

function TicTacToe.Lobby.Leave(quiet)
	flobby:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
    flobby:UnregisterEvent("CHAT_MSG_CHANNEL")
    LeaveChannelByName("Evolve_TicTacToe_AddOn")
    TicTacToe.Lobby.ChannelId = nil
    if not quiet then
        TicTacToe.print("Leaving lobby...")
    end
end

function TicTacToe.Lobby.Reconnect()
    SendChatMessage("r" , "CHANNEL", nil, TicTacToe.Lobby.ChannelId); 
end

function TicTacToe.HandleLobby(self, event, message, player,_,_,_,_,_,channelId)
    if TicTacToe["playing"] == 1 then
        return
    end

    if event == "CHAT_MSG_CHANNEL_JOIN" or (message == "r" and player ~= UnitName("player")) then
        if channelId == TicTacToe.Lobby.ChannelId and not TicTacToe.Lobby.Challenger then
            TicTacToe.SendAddonMessage("lobby","WHISPER", player)
        end
    end
end

function TicTacToe.Lobby.AcceptPopup(player)
   StaticPopupDialogs["TicTacToe_Lobby_Accept"] = 
   {
        text = "Your TicTacToe game is ready!",
        button1 = "Enter Game",
        button2 = "Leave queue",
        OnAccept = function()
            table.insert(TicTacToe["challengers"], player)
            TicTacToe.SendAddonMessage("lobbyaccept","WHISPER", player)
        end,
        OnCancel = function()
            TicTacToe.SendAddonMessage("lobbydecline","WHISPER", player)
            TicTacToe.print("You have been removed from queue.")
            TicTacToe.Lobby.Leave()
            TicTacToe.Lobby.Challenger = nil
            TicTacToe.Lobby.popup = nil
        end,
        timeout = 30,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
    }
    StaticPopup_Show("TicTacToe_Lobby_Accept")
end

function TicTacToe.Lobby.HandlePopup()
    local txt
    if TicTacToe.Lobby.ChannelId then
        txt = "Do you want to leave que for TicTacToe Game?"
    else
        txt = "Do you want to queue up for TicTacToe Game?"
    end
   StaticPopupDialogs["TicTacToe_Lobby"] = 
   {
        text = txt,
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if TicTacToe.Lobby.ChannelId then
                TicTacToe.Lobby.Leave()
            else
                TicTacToe.Lobby.Join()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
    }
    StaticPopup_Show("TicTacToe_Lobby")
end