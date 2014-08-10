if myHero.charName ~= "Sona" then return end
--[Libs]--
require 'VPrediction'
require 'SOW' 
require 'AoE_Skillshot_Position'
--[AutoUpdate]--
local version = 1.00
local AUTOUPDATE = true
local SCRIPT_NAME = "snOw_Sona"
--========--
local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	 SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/snOwPGC/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/snOwPGC/BoL/master/version/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:add("AoE_Skillshot_Position", "https://raw.github.com/snOwPGC/BoL/master/AoE_Skillshot_Position.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end
--========--

--[OnLoad]--
function OnLoad()
	--[Target]--
	targetselq = TargetSelector(TARGET_LESS_CAST_PRIORITY, 650, DAMAGE_MAGIC)
	targetselr = TargetSelector(TARGET_LESS_CAST_PRIORITY, 900, DAMAGE_MAGIC)
--	chasetotarget = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_MAGIC)
	
	_scriptMenu()
	PrintChat("<font color=\"#ff99ff\">Sona by snOw v<b>"..version.."</b> loaded </font>")	
end

--[OnDraw]--
function OnDraw()
_draw()
end

--[OnTick]--
function OnTick()
	if myHero.dead then return end
	
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	--[Target update]--
	if QREADY then targetselq:update() end
--	if EREADY then chasetotarget:update() end
	if RREADY then targetselr:update() end
	
	if Menu.miscs.healme then
		_healme()
	end
	if Menu.hotkeys.flee then
		_flee()
	end
	if Menu.hotkeys.harass then
		_harass()
	end
	if Menu.ult.autoult then
		_autoR(targetselr.target)
	end
	if Menu.hotkeys.combo then 
		_combo()
	end
	if RREADY and Menu.ult.useult then
	_comboR(targetselr.target)
	end
	if Menu.stream.overlay then
		DisableOverlay()
	else
		EnableOverlay()
	end
	if Menu.stream.chat then
	_G.PrintChat = function() end 
	end
end

function _scriptMenu()
	Menu = scriptConfig("Sona by snOw", "sona")
	--[Hotkeys]--
	Menu:addSubMenu("Combate hotkeys", "hotkeys")
	Menu.hotkeys:addParam("combo", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.hotkeys:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 67)
	Menu.hotkeys:addParam("flee", "Flee using E", SCRIPT_PARAM_ONKEYDOWN, false, 71)
	--[Combo settings]--
	Menu:addSubMenu("Combo settings", "comboconfig")
	Menu.comboconfig:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Menu.comboconfig:addParam("useE", "Use E to chase", SCRIPT_PARAM_ONOFF, true)
	--[Harass settings]--
	Menu:addSubMenu("Harass setiings", "harassconfig")
	Menu.harassconfig:addParam("useQ2", "Use Q", SCRIPT_PARAM_ONOFF, true)
	--[Drawings]--
	Menu:addSubMenu("Draw settings", "draws")
	Menu.draws:addParam("drw", "Always draw", SCRIPT_PARAM_ONOFF, false)
	Menu.draws:addParam("drawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	Menu.draws:addParam("drawW", "Draw W range", SCRIPT_PARAM_ONOFF, true)
	Menu.draws:addParam("drawE", "Draw E range", SCRIPT_PARAM_ONOFF, true)
	Menu.draws:addParam("drawR", "Draw R range", SCRIPT_PARAM_ONOFF, true)
	--[Ult Settings]--
	Menu:addSubMenu("Ultimate settings", "ult")
	Menu.ult:addParam("useult", "Use ult in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.ult:addParam("ultifx", "hit x enemys:", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)	
	Menu.ult:addParam("autouseult", "Auto use ult if hit x enemys", SCRIPT_PARAM_ONOFF, true)
	Menu.ult:addParam("autoult","hit x enemys", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	--[Other settings]--
	Menu:addSubMenu("Other settings", "miscs")
	Menu.miscs:addParam("packt", "Use packets(VIP)", SCRIPT_PARAM_ONOFF, false)
	Menu.miscs:addParam("healme", "Auto heal me", SCRIPT_PARAM_ONOFF, true)
	Menu.miscs:addParam("healratio", "Auto heal ratio", SCRIPT_PARAM_SLICE, 0.15, 0 ,1 ,2)
--	Menu.miscs:addParam("healallies", "Auto heal allies", SCRIPT_PARAM_ONOFF, true)
--	Menu.miscs:addParam("healalliesratio", "Auto heal allies ratio", SCRIPT_PARAM_SLICE, 0.15, 0 ,1 ,2)	
	--[Stream mode]--
	Menu:addSubMenu("Stream mode", "stream")
	Menu.stream:addParam("overlay","Disable overlay",SCRIPT_PARAM_ONKEYTOGGLE,false, 20)
	Menu.stream:addParam("chat", "Disable chat", SCRIPT_PARAM_ONOFF, false)
	--[Orbwalking]--
	local VP
	VP = VPrediction()
	OW = SOW(VP)
	Menu:addSubMenu("Orbwalking", "Orbwalking")
	OW:LoadToMenu(Menu.Orbwalking)
	--[Perma show]--
	Menu.hotkeys:permaShow("combo")
	Menu.hotkeys:permaShow("harass")
	Menu.hotkeys:permaShow("flee")
end

function _draw()
	--[Range skils draw]--
	if Menu.draws.drw then
		DrawCircle(myHero.x, myHero.y, myHero.z, 650, 0x05E1FA)
		DrawCircle(myHero.x, myHero.y , myHero.z, 1000, 0x05FA36)
		DrawCircle(myHero.x, myHero.y, myHero.z, 360, 0xFA05FA)
		DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0xFFFB00)
	else
		if Menu.draws.drawQ then
			if myHero:CanUseSpell(_Q) == READY then
				DrawCircle(myHero.x, myHero.y, myHero.z, 650, 0x05E1FA)
			end
		end
	
		if Menu.draws.drawW then
			if myHero:CanUseSpell(_W) == READY then
				DrawCircle(myHero.x, myHero.y , myHero.z, 1000, 0x05FA36)
			end
		end
		if Menu.draws.drawE then
			if myHero:CanUseSpell(_E) == READY then
				DrawCircle(myHero.x, myHero.y, myHero.z, 360, 0xFA05FA)
			end
		end
	
		if Menu.draws.drawR then
			if myHero:CanUseSpell(_R) == READY then
				DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0xFFFB00)
			end
		end	
	end
end
	
function _harass() --Done
	if ValidTarget(targetselq.target) then
		if QREADY and Menu.harassconfig.useQ2 and GetDistance(targetselq.target) <= 650 then
			if Menu.miscs.packt then
				Packet("S_CAST", {spellId = _Q}):send()
			else
				CastSpell(_Q)
			end
		end
	end			
end

function _combo()
	for i=1, heroManager.iCount do
		local target = heroManager:GetHero(i)
		--if ValidTarget(targetselr.target) then _comboR(targetselr.target)end
			if ValidTarget(target, 1100) then
				if GetDistance(target) <=650 then
					if QREADY and Menu.comboconfig.useQ then
						if Menu.miscs.packt then
							Packet("S_CAST", {spellId = _Q}):send()
						else
							CastSpell(_Q)
						end
					end
				else -- if distance => 650
					if EREADY and Menu.comboconfig.useE then
						if Menu.miscs.packt then
							Packet("S_CAST", {spellId = _E}):send()
						else
							CastSpell(_E)
						end
					end
				end
			end
		
	end	
	
end

function _healme() -- Done
		if WREADY and (player.health / player.maxHealth < Menu.miscs.healratio) then
			if Menu.miscs.packt then
				Packet("S_CAST", {spellId = _W}):send()
			else
				CastSpell(_W)
			end
		end
end

function healallies()
	allies = GetAllyHeroes()
	
end

function _flee() --Done
	if EREADY then
		if Menu.miscs.packt then
			Packet("S_CAST", {spellId = _E}):send()
		else
			CastSpell(_E)
		end
	end
end


--[Functions relat. to ultimate]--
function CountEnemies(point, range)
        local ChampCount = 0
        for j = 1, heroManager.iCount, 1 do
                local enemyhero = heroManager:getHero(j)
                if myHero.team ~= enemyhero.team and ValidTarget(enemyhero, 900+150) then
                        if GetDistance(enemyhero, point) <= range then
                                ChampCount = ChampCount + 1
                        end
                end
        end            
        return ChampCount
end

function _autoR(target)
        if Menu.ult.autouseult and RREADY and ValidTarget(targetselr.target) then
                local ultPos = GetAoESpellPosition(240, target, 200)
                if ultPos and GetDistance(ultPos) <= 900-240    then
                        if CountEnemies(ultPos, 240) >= Menu.ult.autoult then
                                CastSpell(_R, ultPos.x, ultPos.z)
                        end
                end
        end
end

function _comboR(target)
        if Menu.hotkeys.combo and RREADY and ValidTarget(targetselr.target) then
                local ultPos = GetAoESpellPosition(240, target, 200)
                if ultPos and GetDistance(ultPos) <= 900-240    then
                        if CountEnemies(ultPos, 240) >= Menu.ult.ultifx then
                                CastSpell(_R, ultPos.x, ultPos.z)
                        end
                end
        end
end

function _enemisAround(range)
	local playersCount = 0
	for i=1, heroManager.iCount do
		local target = heroManager:GetHero(i)
		if ValidTarget(target, range) then
			playersCount = playersCount + 1
		end
	end
	return playersCount
end
