local version = "0.1"

-- / Hero Name Check / --
if myHero.charName ~= "Gangplank" then return end
-- / Hero Name Check / --

-- / Auto-Update Function / --
local Autoplank_Autoupdate = true
local UPDATE_SCRIPT_NAME = "Autoplank - Q = Money"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/UglyOldGuy/BoL/master/Autoplank.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
function AutoupdaterMsg(msg)
	print("<font color=\"#FF0000\">"..UPDATE_SCRIPT_NAME..":</font> <font color=\"#FFFFFF\">"..msg..".</font>")
end
if Autoplank_Autoupdate then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
-- / Auto-Update Function / --

-- / Loading Function / --
function OnLoad()
	Variables()
	AutoplankMenu()
end
-- / Loading Function / --

-- / Tick Function / --
function OnTick()
	Checks()
	DamageCalculation()
	UseConsumables()
	if Target then
		if AutoplankMenu.harass.Qharass and not SkillR.castingUlt then
			CastQ(Target)
		end
		if AutoplankMenu.killsteal.Ignite then
			AutoIgnite(Target)
		end
	end
	if AutoplankMenu.combo.autoE then
		for _, enemy in pairs(enemyHeroes) do
			if ValidTarget(enemy) and enemy ~= nil and GetDistanceSqr(enemy) > SkillR.range*SkillR.range and GetDistanceSqr(enemy) <= SkillE.range*SkillE.range and SkillR.castingUlt then
				CastE(enemy)
			end
		end
	end
	-- Menu Variables --
	ComboKey =	AutoplankMenu.combo.comboKey
	FarmingKey = AutoplankMenu.farming.farmKey
	HarassKey =	AutoplankMenu.harass.harassKey
	ClearKey =	AutoplankMenu.clear.clearKey
	-- Menu Variables --
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
	if AutoplankMenu.killsteal.smartKS then
		KillSteal()
	end
	if AutoplankMenu.misc.AutoLevelSkills == 1 then
		if myHero.level == 6 or myHero.level == 11 or myHero.level == 16 then
			LevelSpell(_R)
		end
	else
		autoLevelSetSequence(levelSequence[AutoplankMenu.misc.AutoLevelSkills-1])
	end
	if AutoplankMenu.misc.jumpAllies then
		DangerCheck()
	end
end
-- / Tick Function / --

-- / Variables Function / --
function Variables()
	--- Skills Vars --
	SkillQ =	{range = 625, name = "Parrrley",	ready = false,	delay = 400,	timeToHit = 0,	color = ARGB(255,178, 0 , 0 )	}
	SkillW =	{range = 0, name = "Remove Scurvy",	ready = false,	color = ARGB(255, 32,178,170)	}
	SkillE =	{range = 600, name = "Raise Morale",	ready = false,	color = ARGB(255,128, 0 ,128)	}
	SkillR =	{range = math.huge, name = "Cannon Barrage",	ready = false,	castingUlt = false,	}
	--- Skills Vars ---
	--- Items Vars ---
	Items = {
		HealthPot	= {ready = false},
		FlaskPot	= {ready = false},
		TrinketWard	= {ready = false},
		RubySightStone	= {ready = false},
		SightStone	= {ready = false},
		SightWard	= {ready = false},
		VisionWard	= {ready = false}
	}
	--- Items Vars ---
	--- Orbwalking Vars ---
	lastAnimation = "Run"
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0
	--- Orbwalking Vars ---
	--- TickManager Vars ---
	TManager = {
		onTick	= TickManager(20),
		onDraw	= TickManager(80),
		onSpell	= TickManager(15)
	}
	--- TickManager Vars ---
	if VIP_USER then
		--- LFC Vars ---
		_G.oldDrawCircle = rawget(_G, 'DrawCircle')
		_G.DrawCircle = DrawCircle2
		--- LFC Vars ---
	end
	--- Drawing Vars ---
	TextList = {"Harass him", "Q = Kill", "R = Kill", "Q+R = Kill!", "Q+R+Itm = Kill", "Need CDs"}
	KillText = {}
	colorText = ARGB(255,255,204,0)
	wardColor = {
		available	= ARGB(255,255,255,255),
		searching	= ARGB(255,250,123, 20),
		unavailable	= ARGB(255,255, 0 , 0 )
	}
	--- Drawing Vars ---
	--- Misc Vars ---
	levelSequence = {
		{ 1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3 }, -- Prioritise W
		{ 1,3,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 } -- Prioritise E
	}
	UsingHPot = false
	gameState = GetGame()
	if gameState.map.shortName == "twistedTreeline" then
		TTMAP = true
	else
		TTMAP = false
	end
	--- Misc Vars ---
	--- Tables ---
	Wards = {}
	allyHeroes = GetAllyHeroes()
	enemyHeroes = GetEnemyHeroes()
	enemyMinions = minionManager(MINION_ENEMY, SkillQ.range, player, MINION_SORT_HEALTH_ASC)
	allyMinions = minionManager(MINION_ALLY, SkillQ.range, player, MINION_SORT_HEALTH_ASC)
	JungleMobs = {}
	JungleFocusMobs = {}
	priorityTable = {
		AP = {
			"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus", "Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna", "Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra"
		},
		Support = {
			"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean"
		},
		Tank = {
			"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Nautilus", "Shen", "Singed", "Skarner", "Volibear", "Warwick", "Yorick", "Zac"
		},
		AD_Carry = {
			"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "KogMaw", "Lucian", "MasterYi", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir", "Talon","Tryndamere", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Yasuo","Zed"
		},
		Bruiser = {
			"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy", "Renekton", "Rengar", "Riven", "Rumble", "Shyvana", "Trundle", "Udyr", "Vi", "MonkeyKing", "XinZhao"
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
				JunglefocusMobs[#JungleFocusMobs+1] = object
			elseif JungleMobNames[object.name] then
				JungleMobs[#JungleMobs+1] = object
			end
		end
	end
--- Tables ---
end
-- / Variables Function / --

-- / Menu Function / --
function AutoplankMenu()
	--- Main Menu ---
	AutoplankMenu = scriptConfig("Katarina - The Sinister Blade", "Katarina")
		---> Combo Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
			AutoplankMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
			AutoplankMenu.combo:addParam("stopUlt", "Stop "..SkillR.name.." (R) If Target Can Die", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.combo:addParam("autoE", "Auto E if not in "..SkillR.name.." (R) Range while Ult", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.combo:addParam("detonateQ", "Try to Proc "..SkillQ.name.." (Q) Mark", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.combo:addParam("comboOrbwalk", "Orbwalk in Combo", SCRIPT_PARAM_ONOFF, true)
		AutoplankMenu.combo:permaShow("comboKey")
		---< Combo Menu
		---> Harass Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
			AutoplankMenu.harass:addParam("harassKey", "Harass Hotkey (T)", SCRIPT_PARAM_ONKEYDOWN, false, 84)
			AutoplankMenu.harass:addParam("hMode", "Harass Mode", SCRIPT_PARAM_LIST, 1, { "Q+E+W", "Q+W" })
			AutoplankMenu.harass:addParam("detonateQ", "Proc Q Mark", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.harass:addParam("wharass", "Always "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.harass:addParam("harassOrbwalk", "Orbwalk in Harass", SCRIPT_PARAM_ONOFF, true)
		AutoplankMenu.harass:permaShow("harassKey")
		---< Harass Menu
		---> Farming Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
			AutoplankMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, true, 90)
			AutoplankMenu.farming:addParam("qFarm", "Farm with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.farming:addParam("wFarm", "Farm with "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.farming:addParam("eFarm", "Farm with "..SkillE.name.." (E)", SCRIPT_PARAM_ONOFF, false)
		AutoplankMenu.farming:permaShow("farmKey")
		---< Farming Menu
		---> Clear Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "clear")
			AutoplankMenu.clear:addParam("clearKey", "Jungle/Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
			AutoplankMenu.clear:addParam("JungleFarm", "Use Skills to Farm Jungle", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("ClearLane", "Use Skills to Clear Lane", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("clearQ", "Clear with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("clearW", "Clear with "..SkillW.name.." (W)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("clearE", "Clear with "..SkillE.name.." (E)", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("clearOrbM", "OrbWalk Minions", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.clear:addParam("clearOrbJ", "OrbWalk Jungle", SCRIPT_PARAM_ONOFF, true)
		---< Clear Menu
		---> KillSteal Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "killsteal")
			AutoplankMenu.killsteal:addParam("smartKS", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.killsteal:addParam("ultKS", "Use "..SkillR.name.." (R) to KS", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.killsteal:addParam("itemsKS", "Use Items to KS", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.killsteal:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
		AutoplankMenu.killsteal:permaShow("smartKS")
		---< KillSteal Menu
		---> Drawing Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Drawing Settings]", "drawing")
		if VIP_USER then
			AutoplankMenu.drawing:addSubMenu("["..myHero.charName.." - LFC Settings]", "lfc")
				AutoplankMenu.drawing.lfc:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
				AutoplankMenu.drawing.lfc:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 300, 75, 2000, 0)
				AutoplankMenu.drawing.lfc:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
		end
			AutoplankMenu.drawing:addParam("disableAll", "Disable All Ranges Drawing", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.drawing:addParam("drawText", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.drawing:addParam("drawTargetText", "Draw Who I'm Targetting", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.drawing:addParam("drawQ", "Draw Bouncing Blades (Q) Range", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.drawing:addParam("drawW", "Draw Sinister Steel (W) Range", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.drawing:addParam("drawE", "Draw Shunpo (E) Range", SCRIPT_PARAM_ONOFF, false)
		---< Drawing Menu
		---> Misc Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
			AutoplankMenu.misc:addParam("wardJumpKey", "Ward Jump Hotkey (G)", SCRIPT_PARAM_ONKEYDOWN, false, 71)
			AutoplankMenu.misc:addParam("jumpAllies", "Jump To Allies if In Danger", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.misc:addParam("ZWItems", "Auto Zhonyas/Wooglets", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.misc:addParam("ZWHealth", "Min Health % for Zhonyas/Wooglets", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
			AutoplankMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
			AutoplankMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			AutoplankMenu.misc:addParam("uTM", "Use Tick Manager/FPS Improver",SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.misc:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_LIST, 1, { "No", "Prioritise Q", "Prioritise W" })
		AutoplankMenu.misc:permaShow("wardJumpKey")
		---< Misc Menu
		---> Target Selector
		TargetSelector = TargetSelector(TARGET_LESS_CAST, SkillE.range, DAMAGE_MAGIC, true)
		TargetSelector.name = "Katarina"
		AutoplankMenu:addTS(TargetSelector)
		---< Target Selector
		---> Arrange Priorities
		if heroManager.iCount < 10 then -- borrowed from Sidas Auto Carry, modified to 3v3
			PrintChat(" >> Too few champions to arrange priority")
		elseif heroManager.iCount == 6 and TTMAP then
			ArrangeTTPriorities()
		else
			ArrangePriorities()
		end
		---< Arrange Priorities
	-- Main Menu ---
end
-- / Menu Function / --

-- / Full Combo Function / --
function FullCombo()
	if not SkillR.castingUlt then
		if ValidTarget(Target) and Target ~= nil then
			if AutoplankMenu.combo.comboOrbwalk then
				OrbWalking(Target)
			end
			if AutoplankMenu.combo.comboItems then
				UseItems(Target)
			end
			CastQ(Target)
			if AutoplankMenu.combo.detonateQ and GetTickCount() >= SkillQ.timeToHit then
				if not SkillQ.ready then
					CastE(Target)
				end
				if not SkillE.ready then
					CastW(Target)
				end
			elseif not AutoplankMenu.combo.detonateQ then
				CastE(Target)
				CastW(Target)
			end
			CastR()
		else
			if AutoplankMenu.combo.comboOrbwalk then
				moveToCursor()
			end
		end
	end
end
-- / Full Combo Function / --