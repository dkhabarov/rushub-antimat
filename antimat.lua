local sPath = Core.sScriptsDir
_TRACEBACK = debug.traceback
tCfg = {
	sBot = "",
	sReplWord = "[censored]",-- Cлово для замены мата
	iMatMode = 0, -- Режимы контроля мата (0 - тихая заглушка сообщения с матом, 1 - подмена слова-мата на sReplWord (из предыдущей переменной), 2 - подмена сообщения случайной фразой из таблицы tPhrases, 3 - антимат отключен)
	tMatProfiles = {		-- У кого фильтруем мат (1 - да, 0 - нет)
		[0]  = 1,    
		[1]  = 1,     
		[2]  = 1,
		[3]  = 1,
		[-1] = 1,
	},
	Filters = sPath.."antimat/Filter.txt",	-- файл запретов(матов) и исключений
	Phrases = sPath.."antimat/Phrases.txt", -- файл с подменными фразами
	bMatFile= true
}
--/*********************************************************************/
function OnStartup()
	if tCfg.sBot == "" then
		tCfg.sBot = Config.sHubBot
	end
	local _,e = loadfile (tCfg.Filters)
	if e then 
		error(e)
	else
		dofile(tCfg.Filters)
		print(tCfg.Filters.." load ")
	end
	local _,e = loadfile (tCfg.Phrases)
	if e then 
		error(e)
	else
		dofile(tCfg.Phrases)
		print(tCfg.Phrases.." load ")
	end
end


function Ext(data, t)
    for i in ipairs(t) do
        if data:match(t[i]) then
            return nil
        end
    end
    return true
end

function AntiMat(data, dataorig, nick, ip, mode)
	local msg = data:match("^%b<>%s+(.*)$")
	local bMat = false
	if (msg ~= nil) then
		for i,v in pairs(tFilter) do
			if msg:match(i) and Ext(msg, v) then
				msg = msg:gsub(i, tCfg.sReplWord)
				bMat = true
			end
		end
		if bMat then
			if mode == 0 then -- тихая заглушка
				Core.SendToUser(nick, dataorig)
				Core.SendToProfile({0,1},("<%s> OPs: Юзер с IP: ( %s ) попытка нецензурного выражения!\n\t: %s"):format(tCfg.sBot, ip, dataorig))
			elseif mode == 1 then -- подмена слова-мата на [цензоред]
				Core.SendToAll(("<%s> %s"):format(nick, msg))
				Core.SendToProfile({0,1},("<%s> OPs: Юзер с IP: ( %s ) попытка нецензурного выражения!\n\t: %s"):format(tCfg.sBot, ip, dataorig))
			elseif mode == 2 then -- подмена сообщения фразой из таблицы
				Core.SendToAll("<"..nick.."> "..tPhrases[math.random(iPhrases)].."   •••")
				Core.SendToUser(nick,"\""..dataorig.."\" - Мат на хабе запрещён!",tCfg.sBot,tCfg.sBot)
				Core.SendToProfile({0,1},("<%s> OPs: Юзер с IP: ( %s ) попытка нецензурного выражения!\n\t: %s"):format(tCfg.sBot, ip, dataorig))
			end
			collectgarbage()
			return true
		end
	end
	return bMat
end


function OnChat(UID,sData)
	if tCfg.tMatProfiles[UID.iProfile] == 1 and tCfg.iMatMode ~= 3 then 	-- Если антимат не отключен
		if tCfg.bMatFile then
			bMat = AntiMat(sData, sData, UID.sNick, UID.sIP, tCfg.iMatMode)	--  Вход в АнтиМат
		else
			bMat = false
		end
		if bMat then
			return true
		end
	end
end

function OnError(msg)
	print(msg)
	Core.SendToProfile(0,msg,tCfg.sBot)
	return true
end
