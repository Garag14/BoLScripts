local version = "1.001"

--[[

	 _______           _______  _______    _______  _        ______     _______          _________ _        _______    __       _______ 
	(  ____ )|\     /|/ ___   )(  ____ \  (  ___  )( (    /|(  __  \   (  ____ \|\     /|\__   __/( (    /|(  ____ \  /  \     (  __   )
	| (    )|( \   / )\/   )  || (    \/  | (   ) ||  \  ( || (  \  )  | (    \/| )   ( |   ) (   |  \  ( || (    \/  \/) )    | (  )  |
	| (____)| \ (_) /     /   )| (__      | (___) ||   \ | || |   ) |  | (_____ | (___) |   | |   |   \ | || (__        | |    | | /   |
	|     __)  \   /     /   / |  __)     |  ___  || (\ \) || |   | |  (_____  )|  ___  |   | |   | (\ \) ||  __)       | |    | (/ /) |
	| (\ (      ) (     /   /  | (        | (   ) || | \   || |   ) |        ) || (   ) |   | |   | | \   || (          | |    |   / | |
	| ) \ \__   | |    /   (_/\| (____/\  | )   ( || )  \  || (__/  )  /\____) || )   ( |___) (___| )  \  || (____/\  __) (_ _ |  (__) |
	|/   \__/   \_/   (_______/(_______/  |/     \||/    )_)(______/   \_______)|/     \|\_______/|/    )_)(_______/  \____/(_)(_______)

	Script by Garag - Based on Katarina - Sinister Blade by Skeem and Roach
	
	Changelog:
			0.100 - 	PreAlpha-Release
			0.101 - 	Alpha-Release after Bugfixing
			0.102 - 	Fixed Combo from Q-E-R-W to Q-R-E-W-Q
						Fixed AutoW
						Fixed E + Q Harass
			0.103 -		Optimized Killsteal
						Saw that AutoUpdate is not working yet :( Disabled until I get it fixed!
			0.104 - 	Tried to fix AutoUpdate
			0.105 -		Fixed a Bug for text on Champions... have to test it
			0.106 -		Added AutoAttack-Farming (Interrupted by Orbwalker, try to fix this later)
						Fixed Target-Slector to Priority-Mode
			0.107 -		Again worked on Autoupdate, hope it works fine now
			0.108 -		Another Bugfixing-Update
						AA-Clear and Farm disabled, to buggy
						Autoupdate still don't work :(
			0.109 - 	Fixed Orbwalker, Autoattack to enemy Heros and Minions working now
						Jungle-Clear added as own Submenu, but not working yet, dont know if you realy need it...
			1.000		Completely Rewrote the Script, cause since Patch 4.11 it was broken
						First Remake Release
			1.001 General Bugfixing after first Release of Remake
						
]]--

-- / Hero Name Check / --
if myHero.charName ~= "Ryze" then
	return 
end
-- / Hero Name Check / --
_G.Ryze_Autoupdate = true

-- / Lib Auto-Update Function / --
local lib_Required = {
	["SOW"]			= "https://raw.githubusercontent.com/Hellsing/BoL/master/Common/SOW.lua",
	["VPrediction"]	= "https://raw.githubusercontent.com/Hellsing/BoL/master/Common/VPrediction.lua"
}

local lib_downloadNeeded, lib_downloadCount = false, 0

function AfterDownload()
	lib_downloadCount = lib_downloadCount - 1
	if lib_downloadCount == 0 then
		lib_downloadNeeded = false
		print("<font color=\"#FF0000\">Ryze and Shine:</font> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
	end
end

for lib_downloadName, lib_downloadUrl in pairs(lib_Required) do
	local lib_fileName = LIB_PATH .. lib_downloadName .. ".lua"

	if FileExist(lib_fileName) then
		require(lib_downloadName)
	else
		lib_downloadNeeded = true
		lib_downloadCount = lib_downloadCount and lib_downloadCount + 1 or 1
		DownloadFile(lib_downloadUrl, lib_fileName, function() AfterDownload() end)
	end
end

if lib_downloadNeeded then return end
-- / Lib Auto-Update Function / --

-- / Auto-Update Function / --
local script_downloadName = "Ryze and Shine"
local script_downloadHost = "raw.githubusercontent.com"
local script_downloadPath = "/Garag14/BoLScripts/Private/RyzeAndShine.lua" .. "?rand=" .. math.random(1, 10000)
local script_downloadUrl = "https://" .. script_downloadHost .. script_downloadPath
local script_filePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME

function script_Messager(msg) print("<font color=\"#FF0000\">" .. script_downloadName .. ":</font> <font color=\"#FFFFFF\">" .. msg .. ".</font>") end

if _G.Ryze_Autoupdate then
	local script_webResult = GetWebResult(script_downloadHost, script_downloadPath)
	if script_webResult then
		local script_serverVersion = string.match(script_webResult, "local%s+version%s+=%s+\"%d+.%d+\"")
		
		if script_serverVersion then
			script_serverVersion = tonumber(string.match(script_serverVersion or "", "%d+%.?%d*"))

			if not script_serverVersion then
				script_Messager("Please contact the developer of the script \"" .. script_downloadName .. "\", since the auto updater returned an invalid version.")
				return
			end

			if tonumber(version) < script_serverVersion then
				script_Messager("New version available: " .. script_serverVersion)
				script_Messager("Updating, please don't press F9")
				DelayAction(function () DownloadFile(script_downloadUrl, script_filePath, function() script_Messager("Successfully updated the script, please reload!") end) end, 2)
			else
				script_Messager("You've got the latest version: " .. script_serverVersion)
			end
		end
	else
		script_Messager("Error downloading server version!")
	end
end
-- / Auto-Update Function / --

-- / Loading Function / --
function OnLoad()
	Variables()
	RyzeMenu()
end
-- / Loading Function / --

-- / Tick Function / --
function OnTick()
	Checks()
	DamageCalculation()
	UseConsumables()

	if Target then
		if RyzeMenu.harass.qharass then 
			CastQ(Target) 
		end
		if RyzeMenu.combo.autoW then 
			CastW(Target) 
		end
		if RyzeMenu.killsteal.Ignite then 
			AutoIgnite(Target)
		end
	end
		
	ComboKey =	 RyzeMenu.combo.comboKey
	FarmingKey =   RyzeMenu.farming.farmKey
	HarassKey =	RyzeMenu.harass.harassKey
	ClearKey =	 RyzeMenu.clear.clearKey
	if ComboKey then
		FullCombo()
	end
	if HarassKey then
		HarassCombo()
	end
	if FarmingKey and not ComboKey then
		Farm()
	end
	if ClearKey then
		MixedClear()
	end	
	if RyzeMenu.killsteal.smartKS then
		KillSteal()
	end
	if RyzeMenu.misc.AutoLevelSkills == 1 then
		if myHero.level == 6 or myHero.level == 11 or myHero.level == 16 then
			LevelSpell(_R)
		end
	else
		autoLevelSetSequence(levelSequence[RyzeMenu.misc.AutoLevelSkills-1])
	end
end
-- / Tick Function / --

-- / Variables Function / --
function Variables()
	SkillQ =	{range = 625, name = "Overload",		ready = false,	color = ARGB(255,178, 0 , 0 )	}
	SkillW =	{range = 600, name = "Rune Prison",		ready = false,	color = ARGB(255, 32,178,170)	}
	SkillE =	{range = 600, name = "Spell Flux",		ready = false,	color = ARGB(255,128, 0 ,128)	}
	SkillR =	{range = 1, name = "Desperate Power",	ready = false,	}
	SkillWard = {range = 600, itemSlot = nil	}
	Items =
	{
		HealthPot		= {ready = false},
		ManaPot			= {ready = false},
		FlaskPot		= {ready = false}
	}
	vPred = VPrediction()
	kSOW = SOW(vPred)
	TManager =
	{
		onTick	= TickManager(20),
		onDraw	= TickManager(80),
		onSpell	= TickManager(15)
	}
	if VIP_USER then
		_G.oldDrawCircle = rawget(_G, 'DrawCircle')
		_G.DrawCircle = DrawCircle2
	end
	TextList = {"Harass him", "Q = Kill", "W = Kill", "E = Kill!", "Q+W = Kill", "Q+E = Kill", "E+W = Kill", "Q+E+W = Kill", "Q+E+W+Itm = Kill", "Q+W+E+R: ", "Need CDs"}
	KillText = {}
	colorText = ARGB(255,255,204,0)
	levelSequence = {
		{ 1,2,3,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
		{ 3,2,1,3,3,4,3,1,3,1,4,1,1,2,2,4,2,2 }
	}
	UsingHPot = false
	UsingMPot = false
	gameState = GetGame()
	if gameState.map.shortName == "twistedTreeline" then
		TTMAP = true
	else
		TTMAP = false
	end
	allyHeroes = GetAllyHeroes()
	enemyHeroes = GetEnemyHeroes()
	enemyMinions = minionManager(MINION_ENEMY, SkillE.range, player, MINION_SORT_HEALTH_ASC)
	allyMinions = minionManager(MINION_ALLY, SkillE.range, player, MINION_SORT_HEALTH_ASC)
	JungleMobs = {}
	JungleFocusMobs = {}
	priorityTable = {
		AP = {
			"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
			"Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
			"Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra"
		},
		Support = {
			"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean"
		},
		Tank = {
			"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Nautilus", "Shen", "Singed", "Skarner", "Volibear",
			"Warwick", "Yorick", "Zac"
		},
		AD_Carry = {
			"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "KogMaw", "Lucian", "MasterYi", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
			"Talon","Tryndamere", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Yasuo","Zed"
		},
		Bruiser = {
			"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy",
			"Renekton", "Rengar", "Riven", "Rumble", "Shyvana", "Trundle", "Udyr", "Vi", "MonkeyKing", "XinZhao"
		}
	}
	if TTMAP then --
		FocusJungleNames = {
			["TT_NWraith1.1.1"] = true,
			["TT_NGolem2.1.1"] = true,
			["TT_NWolf3.1.1"] = true,
			["TT_NWraith4.1.1"] = true,
			["TT_NGolem5.1.1"] = true,
			["TT_NWolf6.1.1"] = true,
			["TT_Spiderboss8.1.1"] = true
		}		
		JungleMobNames = {
			["TT_NWraith21.1.2"] = true,
			["TT_NWraith21.1.3"] = true,
			["TT_NGolem22.1.2"] = true,
			["TT_NWolf23.1.2"] = true,
			["TT_NWolf23.1.3"] = true,
			["TT_NWraith24.1.2"] = true,
			["TT_NWraith24.1.3"] = true,
			["TT_NGolem25.1.1"] = true,
			["TT_NWolf26.1.2"] = true,
			["TT_NWolf26.1.3"] = true
		}
	else 
		JungleMobNames = { 
			["Wolf8.1.2"] = true,
			["Wolf8.1.3"] = true,
			["YoungLizard7.1.2"] = true,
			["YoungLizard7.1.3"] = true,
			["LesserWraith9.1.3"] = true,
			["LesserWraith9.1.2"] = true,
			["LesserWraith9.1.4"] = true,
			["YoungLizard10.1.2"] = true,
			["YoungLizard10.1.3"] = true,
			["SmallGolem11.1.1"] = true,
			["Wolf2.1.2"] = true,
			["Wolf2.1.3"] = true,
			["YoungLizard1.1.2"] = true,
			["YoungLizard1.1.3"] = true,
			["LesserWraith3.1.3"] = true,
			["LesserWraith3.1.2"] = true,
			["LesserWraith3.1.4"] = true,
			["YoungLizard4.1.2"] = true,
			["YoungLizard4.1.3"] = true,
			["SmallGolem5.1.1"] = true
		}
		FocusJungleNames = {
			["Dragon6.1.1"] = true,
			["Worm12.1.1"] = true,
			["GiantWolf8.1.1"] = true,
			["AncientGolem7.1.1"] = true,
			["Wraith9.1.1"] = true,
			["LizardElder10.1.1"] = true,
			["Golem11.1.2"] = true,
			["GiantWolf2.1.1"] = true,
			["AncientGolem1.1.1"] = true,
 			["Wraith3.1.1"] = true,
			["LizardElder4.1.1"] = true,
			["Golem5.1.2"] = true,
			["GreatWraith13.1.1"] = true,
			["GreatWraith14.1.1"] = true
		}
	end
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.valid and not object.dead then
			if FocusJungleNames[object.name] then
				JungleFocusMobs[#JungleFocusMobs+1] = object
			elseif JungleMobNames[object.name] then
				JungleMobs[#JungleMobs+1] = object
			end
		end
	end
end
-- / Variables Function / --

-- / Menu Function / --
function RyzeMenu()
	RyzeMenu = scriptConfig("Ryze and Shine", "Ryze")
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Combo Settings]", "combo")
			RyzeMenu.combo:addParam("comboKey", "Full Combo Key (SBTW)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			RyzeMenu.combo:addParam("autoW", "Auto W if in " .. SkillR.name .. " (W) Range", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.combo:permaShow("comboKey")
			RyzeMenu.combo:permaShow("autoW")
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Harass Settings]", "harass")
			RyzeMenu.harass:addParam("harassKey", "Harass Hotkey (C)", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('C'))
			RyzeMenu.harass:addParam("hMode", "Harass Mode", SCRIPT_PARAM_LIST, 1, { "E+Q+W", "E+Q" })
			RyzeMenu.harass:addParam("qharass", "Always " .. SkillQ.name .. " (Q)", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.harass:permaShow("harassKey")
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Farming Settings]", "farming")
			RyzeMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, 90)
			RyzeMenu.farming:addParam("qFarm", "Farm with " .. SkillQ.name .. " (Q)", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.farming:addParam("wFarm", "Farm with " .. SkillW.name .. " (W)", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.farming:addParam("eFarm", "Farm with " .. SkillE.name .. " (E)", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.farming:addParam("aaFarm", "Lasthit by attack (AA)", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.farming:permaShow("farmKey")
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Clear Settings]", "clear")
			RyzeMenu.clear:addParam("clearKey", "Jungle/Lane Clear Key (V)", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('V'))
			RyzeMenu.clear:addParam("JungleFarm", "Use Skills to Farm Jungle", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.clear:addParam("ClearLane", "Use Skills to Clear Lane", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.clear:addParam("clearQ", "Clear with " .. SkillQ.name .. " (Q)", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.clear:addParam("clearW", "Clear with " .. SkillW.name .. " (W)", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.clear:addParam("clearE", "Clear with " .. SkillE.name .. " (E)", SCRIPT_PARAM_ONOFF, true)
			--RyzeMenu.clear:addParam("clearR", "Clear with " .. SkillR.name .. " (R)", SCRIPT_PARAM_ONOFF, true)
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - KillSteal Settings]", "killsteal")
			RyzeMenu.killsteal:addParam("smartKS", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.killsteal:addParam("itemsKS", "Use Items to KS", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.killsteal:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.killsteal:permaShow("smartKS")
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Drawing Settings]", "drawing")
			if VIP_USER then
				RyzeMenu.drawing:addSubMenu("[" .. myHero.charName .. " - LFC Settings]", "lfc")
					RyzeMenu.drawing.lfc:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
					RyzeMenu.drawing.lfc:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 300, 75, 2000, 0)
					RyzeMenu.drawing.lfc:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
			end
			RyzeMenu.drawing:addParam("disableAll", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.drawing:addParam("drawText", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.drawing:addParam("drawTargetText", "Draw Who I'm Targetting", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.drawing:addParam("drawQ", "Draw (Q) Range", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.drawing:addParam("drawW", "Draw (W) Range", SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.drawing:addParam("drawE", "Draw (E) Range", SCRIPT_PARAM_ONOFF, false)
		RyzeMenu:addSubMenu("[" .. myHero.charName .. " - Misc Settings]", "misc")
			RyzeMenu.misc:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.misc:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
			RyzeMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			RyzeMenu.misc:addParam("aMP", "Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
			RyzeMenu.misc:addParam("MPMana", "Min % for Mana Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			RyzeMenu.misc:addParam("uTM", "Use Tick Manager/FPS Improver",SCRIPT_PARAM_ONOFF, false)
			RyzeMenu.misc:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_LIST, 1, { "No", "Prioritise Q", "Prioritise E"  })
		RyzeMenu:addSubMenu("[" .. myHero.charName .. "] - Orbwalking Settings", "Orbwalking")
			kSOW:LoadToMenu(RyzeMenu.Orbwalking)
		RyzeMenu:addParam("RyzeVer", "Version: ", SCRIPT_PARAM_INFO, version)
			TargetSelector = TargetSelector(TARGET_PRIORITY, SkillQ.range, DAMAGE_MAGIC, true)
			TargetSelector.name = "Ryze"
			RyzeMenu:addTS(TargetSelector)
			if heroManager.iCount < 10 then
	   			script_Messager("Too few champions to arrange priority!")
			elseif heroManager.iCount == 6 and TTMAP then
				ArrangeTTPriorities()
			else
				ArrangePriorities()
			end
end
-- / Menu Function / --

-- / Full Combo Function / --
function FullCombo()
	if ValidTarget(Target) and Target ~= nil then
		if RyzeMenu.combo.comboItems then
			UseItems(Target)
		end
		CastQ(Target)
		CastR()
		CastE(Target)
		CastW(Target)
		CastQ(Target)
	end
end
-- / Full Combo Function / --

-- / Harass Combo Function / --
function HarassCombo()
	if ValidTarget(Target) and Target ~= nil then
		if RyzeMenu.harass.hMode == 1 then
			CastE(Target)
			CastQ(Target)
			CastW(Target)
		end
		if RyzeMenu.harass.hMode == 2 then
			CastE(Target)
			CastQ(Target)
		end
	end
end
-- / Harass Combo Function / --

-- / Farm Function / --
function Farm()
	for _, minion in pairs(enemyMinions.objects) do
		local qMinionDmg = getDmg("Q", minion, myHero)
		local eMinionDmg = getDmg("E", minion, myHero)
		local aaMinionDmg = getDmg("AD", minion, myHero)
		local qFarmKey = RyzeMenu.farming.qFarm
		local eFarmKey = RyzeMenu.farming.eFarm
		local aaFarmKey = RyzeMenu.farming.aaFarm
		if ValidTarget(minion) and minion ~= nil then
			if GetDistanceSqr(minion) <= SkillW.range*SkillW.range then
				if qFarmKey and EFarmKey then
					if SkillQ.ready and SkillE.ready then
						if minion.health <= (qMinionDmg + eMinionDmg) and minion.health > qMinionDmg then
							CastQ(minion)
							CastW(minion)
						end
					elseif SkillQ.ready then
						if minion.health <= (qMinionDmg) then
							CastQ(minion)
						end
					elseif SkillE.ready and not SkillQ.ready then
						if minion.health <= (eMinionDmg) then
							CastE(minion)
						end
					end
				elseif qFarmKey and not EFarmKey then
					if SkillQ.ready then
						if minion.health <= (qMinionDmg) then
							CastQ(minion)
						end
					end
				elseif not qFarmKey and EFarmKey then
					if SkillE.ready then
						if minion.health <= (eMinionDmg) then
							CastE(minion)
						end
					end
				end
			elseif (GetDistanceSqr(minion) > SkillQ.range*SkillQ.range) then
				if qFarmKey then
					if minion.health <= qMinionDmg and (GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range) then
						CastQ(minion)
					end
				end
				if eFarmKey then
					if minion.health <= eMinionDmg and (GetDistanceSqr(minion) <= SkillE.range*SkillE.range) then
						CastE(minion)
					end
				end
			end
		end
		if GetDistanceSqr(minion) <= myHero.range*myHero.range then
				if aaFarmKey then
					if myHero.canAttack then
						if minion.health <= (aaMinionDmg) then
							myHero:Attack(minion)
						end
					end
				end
			end
		break
	end
end
-- / Farm Function / --

-- / Clear Function / --
function MixedClear()
	if RyzeMenu.clear.JungleFarm then
		local JungleMob = GetJungleMob()
		if JungleMob ~= nil then
			if RyzeMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(JungleMob) <= SkillQ.range*SkillQ.range then
				CastQ(JungleMob)
			end
			if RyzeMenu.clear.clearE and SkillE.ready and GetDistanceSqr(JungleMob) <= SkillE.range*SkillE.range then
				CastE(JungleMob)
			end
			if RyzeMenu.clear.clearW and SkillW.ready and GetDistanceSqr(JungleMob) <= SkillW.range*SkillW.range then
				CastW(JungleMob)
			end
		end
	end
	if RyzeMenu.clear.ClearLane then
		for _, minion in pairs(enemyMinions.objects) do
			if  ValidTarget(minion) and minion ~= nil then
				if RyzeMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range then
					CastQ(minion)
				end
				if RyzeMenu.clear.clearE and SkillE.ready and GetDistanceSqr(minion) <= SkillE.range*SkillE.range then
					CastE(minion)
				end
				if RyzeMenu.clear.clearW and SkillW.ready and GetDistanceSqr(minion) <= SkillW.range*SkillW.range then 
					CastW(minion)
				end
			end
		end
	end
end
-- / Clear Function / --

-- / Casting Q Function / --
function CastQ(enemy)
	if not SkillQ.ready or (GetDistanceSqr(enemy) > SkillQ.range*SkillQ.range) then
		return false
	end
	if ValidTarget(enemy) and enemy ~= nil then 
		if VIP_USER then
			Packet("S_CAST", {spellId = _Q, targetNetworkId = enemy.networkID}):send()
			return true
		else
			CastSpell(_Q, enemy)
			return true
		end
	end
	return false
end
-- / Casting Q Function / --

-- / Casting E Function / --
function CastE(enemy)
	if not SkillE.ready or (GetDistanceSqr(enemy) > SkillE.range*SkillE.range) then
		return false
	end
	if ValidTarget(enemy) and enemy ~= nil then 
		if VIP_USER then
			Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
			return true
		else
			CastSpell(_E, enemy)
			return true
		end
	end
	return false
end
-- / Casting E Function / --

-- / Casting W Function / --
function CastW(enemy)
	if not SkillW.ready or (GetDistanceSqr(enemy) > SkillW.range*SkillW.range) then
		return false
	end
	if ValidTarget(enemy) and enemy ~= nil then 
		if VIP_USER then
			Packet("S_CAST", {spellId = _W, targetNetworkId = enemy.networkID}):send()
			return true
		else
			CastSpell(_W, enemy)
			return true
		end
	end
	return false
end
-- / Casting W Function / --

-- / Casting R Function / --
function CastR()
	if (SkillQ.ready or SkillW.ready or SkillE.ready) or not SkillR.ready then
		return false
	end
	if CountEnemyHeroInRange(SkillW.range) >= 1 then
		CastSpell(_R)
	end
end
-- / Casting R Function / --

-- / Use Items Function / --
function UseItems(enemy)
	if not enemy then
		enemy = Target
	end
	if ValidTarget(enemy) and enemy ~= nil then
		if dfgReady and GetDistanceSqr(enemy) <= 600*600 then
			CastSpell(dfgSlot, enemy)
		end
		if bftReady and GetDistanceSqr(enemy) <= 600*600 then
			CastSpell(bftSlot, enemy)
		end
		if hxgReady and GetDistanceSqr(enemy) <= 600*600 then
			CastSpell(hxgSlot, enemy)
		end
		if bwcReady and GetDistanceSqr(enemy) <= 450*450 then
			CastSpell(bwcSlot, enemy)
		end
		if brkReady and GetDistanceSqr(enemy) <= 450*450 then
			CastSpell(brkSlot, enemy)
		end
	end
end
-- / Use Items Function / --

-- / Use Consumables / --
function UseConsumables()
	--- Check if Zhonya/Wooglets Needed --
	if RyzeMenu.misc.ZWItems and isLow('Zhonya') and Target and (znaReady or wgtReady) then
		CastSpell((wgtSlot or znaSlot))
	end
	--- Check if Zhonya/Wooglets Needed --
	--- Check if Potions Needed --
	if RyzeMenu.misc.aHP and isLow('Health') and not (UsingHPot or UsingFlask) and (Items.HealthPot.ready or Items.FlaskPot.ready) then
		CastSpell((hpSlot or fskSlot))
	end
	if RyzeMenu.misc.aMP and isLow('Mana') and not (UsingMPot or UsingFlask) and (Items.ManaPot.ready or Items.FlaskPot.ready) then
		CastSpell((mpSlot or fskSlot))
	end
	--- Check if Potions Needed --
end	
-- / Use Consumables / --

-- / Auto Ignite Function / --
function AutoIgnite(enemy)
	if enemy.health <= iDmg and GetDistanceSqr(enemy) <= 600*600 then
		if iReady then 
			CastSpell(ignite, enemy)
		end
	end
end
-- / Auto Ignite Function / --

-- / Damage Calculation Function / --
function DamageCalculation()
	for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) and enemy ~= nil then
			dfgDmg, hxgDmg, bwcDmg, iDmg, bftDmg, liandrysDmg = 0, 0, 0, 0, 0, 0
			qDmg = ((SkillQ.ready and getDmg("Q",enemy,myHero)) or 0)
			wDmg = ((SkillW.ready and getDmg("W",enemy,myHero)) or 0)
			eDmg = ((SkillE.ready and getDmg("E",enemy,myHero)) or 0)
			dfgDmg = ((dfgReady and getDmg("DFG", enemy, myHero)) or 0)
			hxgDmg = ((hxgReady and getDmg("HXG", enemy, myHero)) or 0)
			bwcDmg = ((bwcReady and getDmg("BWC", enemy, myHero)) or 0)
			bftdmg = ((bftReady and getDmg("BLACKFIRE", enemy, myHero)) or 0)
			liandrysDmg = ((liandrysReady and getDmg("LIANDRYS", enemy, myHero)) or 0)
			iDmg = ((ignite and getDmg("IGNITE", enemy, myHero)) or 0)
			onspellDmg = liandrysDmg + bftDmg
			itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
			if enemy.health > (qDmg + eDmg + wDmg + itemsDmg) and itemsDmg ~= 0 then
				KillText[i] = 1
			elseif enemy.health <= qDmg then
				if SkillQ.ready then
					KillText[i] = 2
				else
					KillText[i] = 10
				end
			elseif enemy.health <= wDmg then
				if SkillW.ready then
					KillText[i] = 3
				else
					KillText[i] = 10
				end
			elseif enemy.health <= eDmg then
				if SkillE.ready then
					KillText[i] = 4
				else
					KillText[i] = 10
				end
			elseif enemy.health <= (qDmg + wDmg) then
				if SkillQ.ready and SkillW.ready then
					KillText[i] = 5
				else
					KillText[i] = 10
				end
			elseif enemy.health <= (qDmg + eDmg) then
				if SkillQ.ready and SkillE.ready then
					KillText[i] = 6
				else
					KillText[i] = 10
				end
			elseif enemy.health <= (wDmg + eDmg) then
				if SkillW.ready and SkillE.ready then
					KillText[i] = 7
				else
					KillText[i] = 10
				end
			elseif enemy.health <= (qDmg + wDmg + eDmg) then
				if SkillQ.ready and SkillW.ready and SkillE.ready then
					KillText[i] = 8
				else
					KillText[i] = 10
				end
			elseif enemy.health <= (qDmg + wDmg + eDmg + itemsDmg) then
				if SkillQ.ready and SkillW.ready and SkillE.ready then
					KillText[i] = 9
				else
					KillText[i] = 10
				end
			end
		end
	end
end
-- / Damage Calculation Function / --

-- / KillSteal Function / --
function KillSteal()
	for _, enemy in pairs(enemyHeroes) do
		if enemy ~= nil and ValidTarget(enemy) then
			local distance = GetDistanceSqr(enemy)
			local health = enemy.health
			if health <= qDmg and SkillQ.ready and (distance <= SkillQ.range*SkillQ.range) then
				CastQ(enemy)
			elseif health <= wDmg and SkillW.ready and (distance <= SkillW.range*SkillW.range) then
				CastW(enemy)
			elseif health <= eDmg and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
				CastE(enemy)
			elseif health <= (qDmg + wDmg) and SkillQ.ready and SkillW.ready and (distance <= SkillQ.range*SkillQ.range) then
				CastQ(enemy)
			elseif health <= (qDmg + eDmg) and SkillQ.ready and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
				CastE(enemy)
			elseif health <= (wDmg + eDmg) and SkillW.ready and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
				CastE(enemy)
			elseif health <= (qDmg + wDmg + eDmg) and SkillQ.ready and SkillW.ready and SkillE.ready and (distance <= SkillE.range*SkillE.range) then
				CastE(enemy)
			elseif RyzeMenu.killsteal.itemsKS then
				if health <= (qDmg + wDmg + eDmg + itemsDmg) and health >= (qDmg + wDmg + eDmg) then
					if SkillQ.ready and SkillW.ready and SkillE.ready then
						UseItems(enemy)
					end
				end
			end
		end
	end
end
-- / KillSteal Function / --

-- / Misc Functions / --
--- Get Mouse Pos Function ---
function getMousePos(range)
	local temprange = range or SkillWard.range
	local MyPos = Vector(myHero.x, myHero.y, myHero.z)
	local MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)
	return MyPos - (MyPos - MousePos):normalized() * SkillWard.range
end
--- Get Mouse Pos Function ---
--- Checking if Hero in Danger ---
function isInDanger(hero)
	nEnemiesClose, nEnemiesFar = 0, 0
	hpPercent = hero.health / hero.maxHealth
	for _, enemy in pairs(enemyHeroes) do
		if not enemy.dead and hero:GetDistance(enemy) <= 200 then
			nEnemiesClose = nEnemiesClose + 1
			if hpPercent < 0.5 and hpPercent < enemy.health / enemy.maxHealth then
				return true
			end
		elseif not enemy.dead and hero:GetDistance(enemy) <= 1000 then
			nEnemiesFar = nEnemiesFar + 1
		end
	end
	if nEnemiesClose > 1 then return
		true
	end
	if nEnemiesClose == 1 and nEnemiesFar > 1 then
		return true
	end
	return false
end
--- Checking if Hero in Danger ---
--- Get Jungle Mob Function ---
function GetJungleMob()
	for _, Mob in pairs(JungleFocusMobs) do
		if ValidTarget(Mob, SkillQ.range) then
			return Mob
		end
	end
	for _, Mob in pairs(JungleMobs) do
		if ValidTarget(Mob, SkillQ.range) then
			return Mob
		end
	end
end
--- Get Jungle Mob Function ---
--- Arrange Priorities 5v5 ---
function ArrangePriorities()
	for i, enemy in pairs(enemyHeroes) do
		SetPriority(priorityTable.AD_Carry, enemy, 1)
		SetPriority(priorityTable.AP, enemy, 2)
		SetPriority(priorityTable.Support, enemy, 3)
		SetPriority(priorityTable.Bruiser, enemy, 4)
		SetPriority(priorityTable.Tank, enemy, 5)
	end
end
--- Arrange Priorities 5v5 ---
--- Arrange Priorities 3v3 ---
function ArrangeTTPriorities()
	for i, enemy in pairs(enemyHeroes) do
		SetPriority(priorityTable.AD_Carry, enemy, 1)
		SetPriority(priorityTable.AP, enemy, 1)
		SetPriority(priorityTable.Support, enemy, 2)
		SetPriority(priorityTable.Bruiser, enemy, 2)
		SetPriority(priorityTable.Tank, enemy, 3)
	end
end
--- Arrange Priorities 3v3 ---
--- Set Priorities ---
function SetPriority(table, hero, priority)
	for i = 1, #table do
		if hero.charName:find(table[i]) ~= nil then
			TS_SetHeroPriority(priority, hero.charName)
		end
	end
end
--- Set Priorities ---
-- / Misc Functions / --

-- / On Create Obj Function / --
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("Global_Item_HealthPotion.troy") then
			if GetDistanceSqr(obj, myHero) <= 70*70 then
				UsingHPot = true
			end
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			if GetDistanceSqr(obj, myHero) <= 70*70 then
				UsingMPot = true
			end
		end
		if FocusJungleNames[obj.name] then
			JungleFocusMobs[#JungleFocusMobs+1] = obj
		elseif JungleMobNames[obj.name] then
			JungleMobs[#JungleMobs+1] = obj
		end
	end
end
-- / On Create Obj Function / --

-- / On Delete Obj Function / --
function OnDeleteObj(obj)
	if obj ~= nil then
		if obj.name:find("TeleportHome.troy") then
			Recall = false
		end
		if obj.name:find("Global_Item_HealthPotion.troy") then
			UsingHPot = false
		end
		if obj.name:find("Global_Item_ManaPotion.troy") then
			UsingMPot = false
		end
		for i, Mob in pairs(JungleMobs) do
			if obj.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in pairs(JungleFocusMobs) do
			if obj.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
end
-- / On Delete Obj Function / --

-- / On Draw Function / --
function OnDraw()
	if not TManager.onDraw:isReady() and RyzeMenu.misc.uTM then
		return
	end
	if not myHero.dead then
		if not RyzeMenu.drawing.disableAll then
			if SkillQ.ready and RyzeMenu.drawing.drawQ then 
				DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, SkillQ.color)
			end
			if SkillW.ready and RyzeMenu.drawing.drawW then
				DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, SkillW.color)
			end
			if SkillE.ready and RyzeMenu.drawing.drawE then
				DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, SkillE.color)
			end
		end
	end
	if RyzeMenu.drawing.drawText then
		for i = 1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and enemy ~= nil then
				local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
				local PosX = barPos.x - 35
				local PosY = barPos.y - 10
				if KillText[i] ~= 10 then
					DrawText(TextList[KillText[i]], 16, PosX, PosY, colorText)
				else
					DrawText(TextList[KillText[i]] .. string.format("%4.1f", ((enemy.health - (qDmg + wDmg + eDmg + itemsDmg)))) .. "s = Kill", 16, PosX, PosY, colorText)
				end
			end
		end
	end
	if Target then
		if RyzeMenu.drawing.drawTargetText then
			DrawText("Targeting: " .. Target.charName, 12, 100, 100, colorText)
		end
	end
end
-- / On Draw Function / --

-- / FPS Manager Functions / --
class 'TickManager'
function TickManager:__init(ticksPerSecond)
	self.TPS = ticksPerSecond
	self.lastClock = 0
	self.currentClock = 0
end
function TickManager:__type()
	return "TickManager"
end
function TickManager:setTPS(ticksPerSecond)
	self.TPS = ticksPerSecond
end
function TickManager:getTPS(ticksPerSecond)
	return self.TPS
end
function TickManager:isReady()
	self.currentClock = os.clock()
	if self.currentClock < self.lastClock + (1 / self.TPS) then
		return false
	end
	self.lastClock = self.currentClock
	return true
end
-- / FPS Manager Functions / --

-- / Lag Free Circles Functions / --
if VIP_USER then
	function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
		radius = radius or 300
		quality = math.max(8, round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
		quality = 2 * math.pi / quality
		radius = radius * .92
		local points = {}
		for theta = 0, 2 * math.pi + quality, quality do
			local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
			points[#points + 1] = D3DXVECTOR2(c.x, c.y)
		end
		DrawLines2(points, width or 1, color or 4294967295)
	end
	function round(num) 
		if num >= 0 then
			return math.floor(num+.5)
		else
			return math.ceil(num-.5)
		end
	end
	function DrawCircle2(x, y, z, radius, color)
		local vPos1 = Vector(x, y, z)
		local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
		local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
		local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
			DrawCircleNextLvl(x, y, z, radius, 1, color, RyzeMenu.drawing.lfc.CL) 
		end
	end
end
-- / Lag Free Circles Functions / --

-- / Checks Function / --
function Checks()
	if not TManager.onTick:isReady() and RyzeMenu.misc.uTM then
		return
	end
	if VIP_USER then
		if not RyzeMenu.drawing.lfc.LagFree then 
			_G.DrawCircle = _G.oldDrawCircle 
		else
			_G.DrawCircle = DrawCircle2
		end
	end
	TargetSelector.range = TargetSelectorRange()
	tsTarget = GetTarget()
	if tsTarget and tsTarget.type == myHero.type then
		Target = tsTarget
	else
		Target = nil
	end
	kSOW:ForceTarget(Target)
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	rstSlot, ssSlot, swSlot, vwSlot =			GetInventorySlotItem(2045),
												GetInventorySlotItem(2049),
												GetInventorySlotItem(2044),
												GetInventorySlotItem(2043)
	dfgSlot, hxgSlot, bwcSlot, brkSlot =		GetInventorySlotItem(3128),
												GetInventorySlotItem(3146),
												GetInventorySlotItem(3144),
												GetInventorySlotItem(3153)
	hpSlot, fskSlot =							GetInventorySlotItem(2003),
												GetInventorySlotItem(2041)
	znaSlot, wgtSlot, bftSlot, liandrysSlot =	GetInventorySlotItem(3157),
												GetInventorySlotItem(3090),
												GetInventorySlotItem(3188),
												GetInventorySlotItem(3151)
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)
	iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	dfgReady		= (dfgSlot		~= nil and myHero:CanUseSpell(dfgSlot)		== READY)
	hxgReady		= (hxgSlot		~= nil and myHero:CanUseSpell(hxgSlot)		== READY)
	bwcReady		= (bwcSlot		~= nil and myHero:CanUseSpell(bwcSlot)		== READY)
	brkReady		= (brkSlot		~= nil and myHero:CanUseSpell(brkSlot)		== READY)
	znaReady		= (znaSlot		~= nil and myHero:CanUseSpell(znaSlot)		== READY)
	wgtReady		= (wgtSlot		~= nil and myHero:CanUseSpell(wgtSlot)		== READY)
	bftReady		= (bftSlot		~= nil and myHero:CanUseSpell(bftSlot)		== READY)
	lyandrisReady	= (liandrysSlot ~= nil and myHero:CanUseSpell(liandrysSlot) == READY)
	Items.HealthPot.ready = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) 		== READY)
	Items.ManaPot.ready = (mpSlot ~= nil and myHero:CanUseSpell(mpSlot) 		== READY)
	Items.FlaskPot.ready = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) 		== READY)
	enemyMinions:update()
	allyMinions:update()
end
-- / Checks Function / --

-- / isLow Function / --
function isLow(Name)
	if Name == 'Zhonya' or Name == 'Wooglets' then
		if (myHero.health * (1/myHero.maxHealth)) <= (RyzeMenu.misc.ZWHealth * 0.01) then
			return true
		else
			return false
		end
	end
	if Name == 'Health' then
		if (myHero.health * (1/myHero.maxHealth)) <= (RyzeMenu.misc.HPHealth * 0.01) then
			return true
		else
			return false
		end
	end
	if Name == 'Mana' then
		if (myHero.mana * (1/myHero.maxMana)) <= (RyzeMenu.misc.MPMana * 0.01) then
			return true
		else
			return false
		end
	end
end
-- / isLow Function / --

-- / moveToCursor Function / --
function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		if not VIP_USER then
			myHero:MoveTo(moveToPos.x, moveToPos.z)
		else
			Packet('S_MOVE', {x = moveToPos.x, y = moveToPos.z}):send()
		end
	end		
end
-- / moveToCursor Function / --

-- / TargetSelectorRange Function / --
function TargetSelectorRange()
	return (SkillQ.ready and SkillE.ready) and SkillQ.range or (SkillQ.ready and not SkillE.ready) and SkillQ.range or (not SkillQ.ready and SkillE.ready) and SkillE.range or SkillW.range
end
-- / TargetSelectorRange Function / --

-- / GetTarget Function / --
function GetTarget()
	TargetSelector:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then
		return _G.MMA_Target
	end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
		return _G.AutoCarry.Attack_Crosshair.target
	end
    return TargetSelector.target
end
-- / GetTarget Function / --