if  not TicTacToe then TicTacToe = {} end
if not TicTacToe.BotAI then TicTacToe.BotAI = {} end
if not TicTacToe.BotAI.Data then TicTacToe.BotAI.Data = {} end
local BotAI = TicTacToe.BotAI
local bot = TicTacToe.BotAI.Data
TicTacToe.botGame = false

function BotAI.Init()
    TicTacToe.botGame = true
    BotAI.ResetPrio()
    bot["checked"] = {}
end

function BotAI.ClearData()
    TicTacToe.botGame = false
    bot["prio"] = nil
    bot["checked"] = nil
end

function BotAI.ResetPrio()
    bot["prio"] = {}
    for i = 2,5,0.5 do
        bot["prio"][i] = {}
    end
end

function BotAI.RcvMsg(message)
    if message == "close" then
        BotAI.ClearData()
    elseif message == "tryreset" then
	    TicTacToe.ClearPlayground()
        TicTacToe.Reset(false,false)
        if TicTacToe.OnMove == false then
            BotAI.MakeFirstMove()
        end
		TicTacToe.print("The game has been restarted.")
    elseif tonumber(message) and strlen(message) == 4 then
	    BotAI.AddCheckedTiles(message)
        BotAI.DetectMove()
    end
end

function BotAI.AddCheckedTiles(tile)
    x,y = TicTacToe.GetButtonXY(tile)
    for X=x-2,x+2 do for Y=y-2,y+2 do
        if X < 21 and X > 0 and Y < 21 and Y > 0 then
            local strx,stry
            strx = TicTacToe.NormCoord(X)
            stry = TicTacToe.NormCoord(Y)
            local current = _G[strx..stry]
            if current.texture:GetTexture() == TicTacToe.tile then
                bot["checked"][current] = true
            end
        end
    end end
    bot["checked"][_G[tile]] = nil
end

function BotAI.DetectMove()
    local p = bot["prio"]
    if BotAI.CheckPossibleMoves() == true then
    BotAI.MakeMove(p[5])
        return
    end
    local selKey
    local selVal = 0
    local found = false
    for i = 5,3,-0.5 do
        for key,val in pairs(p[i]) do
            found = true
            if val > selVal then
                selKey = {} -- found higher prio, reset selected
                table.insert(selKey,key)
                selVal = val
            elseif val == selVal then
                table.insert(selKey,key)
            end
        end
        if found then
            if selKey[2] == nil then
                BotAI.MakeMove(selKey[1])
                return
            end
            found = false
            local final = {}
            for j=i-0.5,2.5,-0.5 do
                local k = 1
                while(selKey[k]) do
                    if p[j][selKey[k]] then
                        table.insert(final,selKey[k])
                        found = true
                    end
                    k=k+1
                if found == true then break end
                end
            end
            if found == true then
                BotAI.MakeMove(BotAI.SelectPrefMove(final))
                return
            else
                BotAI.MakeMove(BotAI.SelectPrefMove(selKey))
                return
            end
        end
    end
    local tmpArr = {}
    for i=2.5,2,-0.5 do
        for key,val in pairs(p[i]) do
            if not tmpArr[key] then
                tmpArr[key] = val
            else
                tmpArr[key] = tmpArr[key] + val
            end
        end
    end
    selVal = 0 -- defined above as local var, does not need to be redefined
    selKey = {}
    for key,val in pairs(tmpArr) do
        if val > selVal then
            selKey = {}
            selVal = val
            table.insert(selKey,key)
        elseif val == selVal then
            table.insert(selKey,key)
        end
    end
    if #selKey > 0 then
        BotAI.MakeMove(BotAI.SelectPrefMove(selKey))
        return
    end
    BotAI.MakeFirstMove()
end

function BotAI.CheckPossibleMoves()
    for key,val in pairs(bot["checked"]) do
        if BotAI.CheckTile(key) == true then
            return true
        end
    end
    return false
end

function BotAI.CheckTile(tile)
    if tile.texture:GetTexture() ~= TicTacToe.tile then -- is not empty -> do not check
        return
    end
    local shape1,shape2
    for i = 1,2 do
        if i == 1 then
          shape1,shape2 = TicTacToe.O,TicTacToe.lo
        else
          shape1,shape2 = TicTacToe.X,TicTacToe.lx
        end
        for x=-1,1 do
            if BotAI.SubCheckTile(tile,x,1,shape1,shape2) == true then
                return true
            end
        end
        if BotAI.SubCheckTile(tile,1,0,shape1,shape2) == true then
            return true
        end
    end
    return false
end

function BotAI.SubCheckTile(tile,x,y,shape1,shape2)
    local tmp = BotAI.CheckTileInDirection(tile,x,y,shape1,shape2)
    if tmp[1] > 1.5 then
        if tmp[1] > 3 and tmp[3] == true and shape1 == TicTacToe.X then
            return false -- never try to play on tile with space to def against 3+ tiles
        end
        if tmp[1] < 2.5 and tmp[3] == true then
            return false
        end
        if tmp[1] >= 5 and shape1 == TicTacToe.O and tmp[3] == false then
            bot["prio"][5] = tmp[2]
            return true
        end
        if tmp[1] >= 4 and tmp[3] == true then tmp[1] = 3 end
        local tbl = bot["prio"][tmp[1]]
        if not tbl[tmp[2]] then
            tbl[tmp[2]] = 1
        else
            tbl[tmp[2]] = tbl[tmp[2]] + 1
        end
    end
    return false
end

function BotAI.CheckTileInDirection(tile,x,y,shape1,shape2)
    if BotAI.CanLandFive(tile,x,y,shape1,shape2) == false then
        return {0}
    end
    tile = tile:GetName()
    if x == 0 and y == 0 then
        return {0}
    end
    local tx,ty = TicTacToe.GetButtonXY(tile)
    local ix,iy = 0,0
    local seq = 1
    local blocked = 0
    local way = true
    local space = false
    local skipCheck
    while(true) do
        skipCheck = false
        if way == true then
            ix = ix + x
            iy = iy + y
        else
            ix = ix - x
            iy = iy - y
        end
        if abs(ix) >= 5 or abs(iy) >= 5 then
            if way == true then
                way = false
                if t ~= shape1 and t ~= shape2 and t ~= TicTacToe.tile then
                    blocked = 1.5
                end
                ix = 0
                iy = 0
                skipCheck = true
            else
                if seq > 4 then blocked = 0 end
                return {seq-blocked,tile,space}
            end
        end
        if ix+tx > 20 or ix+tx < 1 or iy+ty > 20 or iy+ty < 1 then
            if way == true then
                way = false
                ix = 0
                iy = 0
                blocked = 1.5
                skipCheck = true
            else
                if seq > 4 then blocked = 0 end
                return {seq-blocked,tile,space}
            end
        end
        if skipCheck == false then
            local t = TicTacToe["buttons"][tx+ix][ty+iy].texture:GetTexture()
            local skip = false
            if t == shape1 or t == shape2 then
                seq = seq + 1
                if seq == 5 then
                    return {seq,tile,space}
                end
                skip = true
            elseif space == false and t == TicTacToe.tile then
                local X,Y = tx+ix,ty+iy
                if way == true then
                    X = X+x
                    Y = Y+y
                else
                    X = X-x
                    Y = Y-y
                end 
                if X > 20 or Y > 20 or X < 1 or Y < 1 then
                else
                    X = TicTacToe.NormCoord(X)
                    Y = TicTacToe.NormCoord(Y)
                    local t = _G[X..Y]
                    t = t.texture:GetTexture()
                    if t == shape1 or t == shape2 then
                        space = true
                        skip = true
                    end
                end
            end
            if skip == false then
                if t ~= TicTacToe.tile then
                    blocked = 1.5 -- if blocked from one side, just decrease by one
                end
                if way == true then -- check the opposite side
                    way = false
                    ix = 0
                    iy = 0
                else
                    if seq > 4 then blocked = 0 end
                    return {seq-blocked,tile,space}
                end
            end
        end
    end
end

function BotAI.CanLandFive(tile,x,y,shape1,shape2)
    tile = tile:GetName()
    if x == 0 and y == 0 then
        return false
    end
    local tx,ty = TicTacToe.GetButtonXY(tile)
    local ix,iy = 0,0
    local seq = 1
    local way = true
    local skipCheck
    while(true) do
        skipCheck = false
        if way == true then
            ix = ix + x
            iy = iy + y
        else
            ix = ix - x
            iy = iy - y
        end
        if ix+tx > 20 or ix+tx < 1 or iy+ty > 20 or iy+ty < 1 then
            if way == true then
                way = false
                ix = 0
                iy = 0
                skipCheck = true
            else
                return false
            end
        end
        if skipCheck == false then
            local t = TicTacToe["buttons"][tx+ix][ty+iy].texture:GetTexture()
            if t == shape1 or t == shape2 or t == TicTacToe.tile then
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
end

function BotAI.SelectPrefMove(array)
    local own = {}
    for key,val in pairs(array) do
        local t = _G[val].texture:GetTexture()
       if t == TicTacToe.O or t == TicTacToe.lo then
            table.insert(own,val)
        end
    end
    if #own > 0 then
        return own[random(1,#own)]
    end
    return array[random(1,#array)]
end

function BotAI.MakeFirstMove()
    local x,y = random(7,13),random(7,13)
    x = TicTacToe.NormCoord(x)
    y = TicTacToe.NormCoord(y)
    BotAI.MakeMove(x..y)
end

function BotAI.MakeMove(tile)
    BotAI.AddCheckedTiles(tile)
    TicTacToe.ActivateButton(tile)
    BotAI.ResetPrio()
end
