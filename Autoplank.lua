local version = "0.1"

-- / Hero Name Check / --
if myHero.charName ~= "Gangplank" then return end
-- / Hero Name Check / --

--[[-- / Auto-Update Function / --
local Autoplank_Autoupdate = false
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
-- / Auto-Update Function / --]]--

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
	SkillQ =	{range = 625, name = "Parrrley",	ready = false,	color = ARGB(255,178, 0 , 0 )	}
	SkillW =	{range = 0, name = "Remove Scurvy",	ready = false,	color = ARGB(255, 32,178,170)	}
	SkillE =	{range = 600, name = "Raise Morale",	ready = false,	color = ARGB(255,128, 0 ,128)	}
	SkillR =	{range = 10000, name = "Cannon Barrage",	ready = false,	castingUlt = false,	}
	--- Skills Vars ---
	--- Items Vars ---
	Items = {
		HealthPot	= {ready = false},
		ManaPot	= {ready = false},
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
	AutoplankMenu = scriptConfig("Gangplank - The Money-Farmer", "Autoplank")
		---> Combo Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Combo Settings]", "combo")
			AutoplankMenu.combo:addParam("comboKey", "Full Combo Key (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
			AutoplankMenu.combo:addParam("comboItems", "Use Items with Burst", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.combo:addParam("comboOrbwalk", "Orbwalk in Combo", SCRIPT_PARAM_ONOFF, false)
		AutoplankMenu.combo:permaShow("comboKey")
		---< Combo Menu
		---> Harass Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Harass Settings]", "harass")
			AutoplankMenu.harass:addParam("harassKey", "Harass Hotkey (T)", SCRIPT_PARAM_ONKEYDOWN, false, 84)
			AutoplankMenu.harass:addParam("harassOrbwalk", "Orbwalk in Harass", SCRIPT_PARAM_ONOFF, false)
		AutoplankMenu.harass:permaShow("harassKey")
		---< Harass Menu
		---> Farming Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Farming Settings]", "farming")
			AutoplankMenu.farming:addParam("farmKey", "Farming ON/Off (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
			AutoplankMenu.farming:addParam("qFarm", "Farm with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, false)
		AutoplankMenu.farming:permaShow("farmKey")
		---< Farming Menu
		---> Clear Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Clear Settings]", "clear")
			AutoplankMenu.clear:addParam("clearKey", "Jungle/Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
			AutoplankMenu.clear:addParam("JungleFarm", "Use Skills to Farm Jungle", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.clear:addParam("ClearLane", "Use Skills to Clear Lane", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.clear:addParam("clearQ", "Clear with "..SkillQ.name.." (Q)", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.clear:addParam("clearOrbM", "OrbWalk Minions", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.clear:addParam("clearOrbJ", "OrbWalk Jungle", SCRIPT_PARAM_ONOFF, false)
		---< Clear Menu
		---> KillSteal Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - KillSteal Settings]", "killsteal")
			AutoplankMenu.killsteal:addParam("smartKS", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.killsteal:addParam("ultKS", "Use "..SkillR.name.." (R) to KS", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.killsteal:addParam("itemsKS", "Use Items to KS", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.killsteal:addParam("Ignite", "Auto Ignite", SCRIPT_PARAM_ONOFF, false)
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
			AutoplankMenu.drawing:addParam("drawText", "Draw Enemy Text", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.drawing:addParam("drawTargetText", "Draw Who I'm Targetting", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.drawing:addParam("drawQ", "Parrrley (Q) Range", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.drawing:addParam("drawE", "Raise Morale (E) Range", SCRIPT_PARAM_ONOFF, false)
		---< Drawing Menu
		---> Misc Menu
		AutoplankMenu:addSubMenu("["..myHero.charName.." - Misc Settings]", "misc")
			AutoplankMenu.misc:addParam("AutoW", "Auto W", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.misc:addParam("EHealth", "Min Health % for W", SCRIPT_PARAM_SLICE, 15, 0, 100, -1)
			AutoplankMenu.misc:addParam("aHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.misc:addParam("HPHealth", "Min % for Health Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			AutoplankMenu.misc:addParam("aMP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.misc:addParam("MPMana", "Min % for Mana Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
			AutoplankMenu.misc:addParam("uTM", "Use Tick Manager/FPS Improver",SCRIPT_PARAM_ONOFF, false)
			AutoplankMenu.misc:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_LIST, 1, { "No", "Prioritise Q", "Prioritise W" })
		AutoplankMenu.misc:permaShow("AutoW")
		---< Misc Menu
		---> Target Selector
		TargetSelector = TargetSelector(TARGET_LESS_CAST, SkillQ.range, DAMAGE_PHYSICAL, true)
		TargetSelector.name = "Gangplank"
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
			CastR(Target)
			CastSpell(_E)
			CastQ(Target)
		else
			if AutoplankMenu.combo.comboOrbwalk then
				moveToCursor()
			end
		end
	end
end
-- / Full Combo Function / --

-- / Harass Combo Function / --
function HarassCombo()
	if ValidTarget(Target) and Target ~= nil then
		if AutoplankMenu.harass.harassOrbwalk then
			OrbWalking(Target)
		end
		CastQ(Target)
	else
		if AutoplankMenu.harass.harassOrbwalk then
			moveToCursor()
		end
	end
end
-- / Harass Combo Function / --

-- / Farm Function / --
function Farm()
	for _, minion in pairs(enemyMinions.objects) do
		local qMinionDmg = getDmg("Q", minion, myHero)
		local adMinionDmg = getDmg("AD", minion, myHero)
		local qFarmKey = AutoplankMenu.farming.qFarm
		if ValidTarget(minion) and minion ~= nil then
			if GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range then
				if qFarmKey then
					if SkillQ.ready then
						if minion.health <= (qMinionDmg + adMinionDmg) then
							CastQ(minion)
						end
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
	--- Jungle Clear ---
	if AutoplankMenu.clear.JungleFarm then
		local JungleMob = GetJungleMob()
		if JungleMob ~= nil then
			if AutoplankMenu.clear.clearOrbJ then
				OrbWalking(JungleMob)
			end
			if AutoplankMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(JungleMob) <= SkillQ.range*SkillQ.range then
				CastQ(JungleMob)
			end
		else
			if AutoplankMenu.clear.clearOrbJ then
				moveToCursor()
			end
		end
	end
	--- Jungle Clear ---
	--- Lane Clear ---
	if AutoplankMenu.clear.ClearLane then
		for _, minion in pairs(enemyMinions.objects) do
			if ValidTarget(minion) and minion ~= nil then
				if AutoplankMenu.clear.clearOrbM then
					OrbWalking(minion)
				end
				if AutoplankMenu.clear.clearQ and SkillQ.ready and GetDistanceSqr(minion) <= SkillQ.range*SkillQ.range then
					CastQ(minion)
				end
			else
				if AutoplankMenu.clear.clearOrbM then
					moveToCursor()
				end
			end
		end
	end
	--- Lane Clear ---
end
-- / Clear Function / --

-- / Casting Q Function / --
function CastQ(enemy)
	--- Dynamic Q Cast ---
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

-- / Casting R Function / --
function CastR()
	if CountEnemyHeroInRange(SkillR.range) >= 1 then
		if ValidTarget(enemy) and enemy ~= nil then
			if VIP_USER then
				Packet("S_CAST", {spellId = _R, targetNetworkId = enemy.networkID}):send()
				return true
			else
				CastSpell(_R, enemy)
			return true
			end
		end
	end
end
-- / Casting R Function / --

-- / Use Items Function / --
function UseItems(enemy)
	if not enemy then
		enemy = Target
	end
	if ValidTarget(enemy) and enemy ~= nil then
		if hydReady and GetDistanceSqr(enemy) <= 400*400 then
			CastSpell(hydSlot, enemy)
		end
		if bwcReady and GetDistanceSqr(enemy) <= 500*500 then
			CastSpell(bwcSlot, enemy)
		end
		if brkReady and GetDistanceSqr(enemy) <= 450*450 then
			CastSpell(brkSlot, enemy)
		end
	end
end
-- / Use Items Function / --

-- / Use Consumables Function / --
function UseConsumables()
	if AutoplankMenu.misc.aHP and isLow('Health') and not (UsingHPot or UsingFlask) and (Items.HealthPot.ready or Items.FlaskPot.ready) then
		CastSpell((hpSlot or fskSlot))
	end
	if AutoplankMenu.misc.AutoW and isLow('Health')  and SkillW.ready then
		CastSpell(_W)
	end
	if AutoplankMenu.misc.aMP and isLow('Mana') and not (UsingMPot or UsingFlask) and Items.HealthPot.ready then
		CastSpell(mpSlot)
	end
end	
-- / Use Consumables Function / --

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
			hydDmg, bwcDmg = 0, 0
			local qEnemyDmg = getDmg("Q", enemy, myHero)
			local adEnemyDmg = getDmg("AD", enemy, myHero)
			qDmg = ((SkillQ.ready and (qEnemyDmg + adEnemyDmg)) or 0)
			rDmg = getDmg("R",enemy,myHero)
			hydDmg = ((hydReady and getDmg("HYDRA", enemy, myHero)) or 0)
			bwcDmg = ((bwcReady and getDmg("BWC", enemy, myHero)) or 0)
			iDmg = ((ignite and getDmg("IGNITE", enemy, myHero)) or 0)
			itemsDmg = hydDmg + bwcDmg + iDmg
			if enemy.health <= qDmg then
				if SkillQ.ready then
					KillText[i] = 1
				else
					KillText[i] = 11
				end
			elseif enemy.health <= rDmg then
				if SkillR.ready then
					KillText[i] = 2
				else
					KillText[i] = 11
				end
			elseif enemy.health <= (qDmg + rDmg) and SkillQ.ready and SkillR.ready then
				if SkillQ.ready and SkillR.ready then
					KillText[i] = 3
				else
					KillText[i] = 11
				end
			elseif enemy.health <= (qDmg + rDmg + itemsDmg) and SkillQ.ready and SkillR.ready then
				if SkillQ.ready and SkillR.ready then
					KillText[i] = 4
				else
					KillText[i] = 11
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
			elseif AutoplankMenu.killsteal.ultKS then
				if health <= (qDmg + rDmg) and SkillQ.ready and SkillR.ready and (distance <= SkillQ.range*SkillQ.range) then
					CastQ(enemy)
					CastR(enemy)
				end
				if health <= rDmg and distance <= (SkillR.range*SkillR.range) then
					CastR(enemy)
				end
			elseif AutoplankMenu.killsteal.itemsKS then
				if health <= (qDmg + rDmg + itemsDmg) and SkillQ.ready and SkillR.ready then
					UseItems(enemy)
				end
			end
		end
	end
end
-- / KillSteal Function / --

-- / Misc Functions / --
	--- Danger Check ---
	function DangerCheck()
		if isInDanger(myHero) then
			CastSpell(_W)
			CastSpell(_E)
		end
	end
	--- Danger Check ---
	--- Get Mouse Pos Function by Klokje ---
	function getMousePos(range)
		local temprange = range or SkillWard.range
		local MyPos = Vector(myHero.x, myHero.y, myHero.z)
		local MousePos = Vector(mousePos.x, mousePos.y, mousePos.z)
		return MyPos - (MyPos - MousePos):normalized() * SkillWard.range
	end
	--- Get Mouse Pos Function by Klokje ---
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
		if nEnemiesClose > 1 then
			return true
		end
		if nEnemiesClose == 1 and nEnemiesFar > 1 then
			return true
		end
		return false
	end
	--- Checking if Hero in Danger ---
	--- Get Jungle Mob Function by Apple ---
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
	--- Get Jungle Mob Function by Apple ---
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
		if obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then
			Wards[#Wards+1] = obj
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
		for i, ward in pairs(Wards) do
			if not ward.valid or (obj.name == ward.name and obj.x == ward.x and obj.z == ward.z) then
				table.remove(Wards, i)
			end
		end
	end
end
-- / On Delete Obj Function / --

-- / On Draw Function / --
function OnDraw()
	if not TManager.onDraw:isReady() and AutoplankMenu.misc.uTM then
		return
	end
	if not myHero.dead then
		if not AutoplankMenu.drawing.disableAll then
			if SkillQ.ready and AutoplankMenu.drawing.drawQ then
				DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, SkillQ.color)
			end
			if SkillE.ready and AutoplankMenu.drawing.drawE then
				DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, SkillE.color)
			end
		end
	end
	if AutoplankMenu.drawing.drawText then
		for i = 1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and enemy ~= nil then
				local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z)) --(Credit to Zikkah)
				local PosX = barPos.x - 35
				local PosY = barPos.y - 10
				if KillText[i] ~= 10 then
					DrawText(TextList[KillText[i]], 16, PosX, PosY, colorText)
				else
					DrawText(TextList[KillText[i]] .. string.format("%4.1f", ((enemy.health - (qDmg + pDmg + wDmg + eDmg + itemsDmg)) * (1/rDmg)) * 2.5) .. "s = Kill", 16, PosX, PosY, colorText)
				end
			end
		end
	end
	if Target then
		if AutoplankMenu.drawing.drawTargetText then
			DrawText("Targeting: " .. Target.charName, 12, 100, 100, colorText)
		end
	end
end
-- / On Draw Function / --

-- / OrbWalking Functions / --
	--- Orbwalking Target ---
	function OrbWalking(Target)
		if TimeToAttack() and GetDistanceSqr(Target) <= (myHero.range + GetDistance(myHero.minBBox))*(myHero.range + GetDistance(myHero.minBBox)) then
			myHero:Attack(Target)
		elseif heroCanMove() then
			moveToCursor()
		end
	end
	--- Orbwalking Target ---
	--- Check When Its Time To Attack ---
	function TimeToAttack()
		return (GetTickCount() + GetLatency() * .5 > lastAttack + lastAttackCD)
	end
	--- Check When Its Time To Attack ---
	--- Prevent AA Canceling ---
	function heroCanMove()
		return (GetTickCount() + GetLatency() * .5 > lastAttack + lastWindUpTime + 20)
	end
	--- Prevent AA Canceling ---
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
	--- Move to Mouse ---
	--- On Process Spell ---
	function OnProcessSpell(object,spell)
		if not TManager.onSpell:isReady() and AutoplankMenu.misc.uTM then
			return
		end
		if object == myHero then
			if spell.name:lower():find("attack") then
				lastAttack = GetTickCount() - GetLatency()*0.5
				lastWindUpTime = spell.windUpTime*1000
				lastAttackCD = spell.animationTime*1000
			end
		end
	end
	--- On Process Spell ---
-- / OrbWalking Functions / --

/ FPS Manager Functions / --
class 'TickManager'
	--- TM Init Function ---
	function TickManager:__init(ticksPerSecond)
		self.TPS = ticksPerSecond
		self.lastClock = 0
		self.currentClock = 0
	end
	--- TM Init Function ---
	--- TM Type Function ---
	function TickManager:__type()
		return "TickManager"
	end
	--- TM Init Function ---
	--- Set TPS Function ---
	function TickManager:setTPS(ticksPerSecond)
		self.TPS = ticksPerSecond
	end
	--- Set TPS Function ---
	--- Get TPS Function ---
	function TickManager:getTPS(ticksPerSecond)
		return self.TPS
	end
	--- Get TPS Function ---
	--- TM Ready Function ---
	function TickManager:isReady()
		self.currentClock = os.clock()
		if self.currentClock < self.lastClock + (1 / self.TPS) then
			return false
		end
		self.lastClock = self.currentClock
		return true
	end
	--- TM Ready Function ---
-- / FPS Manager Functions / --

-- / Lag Free Circles Functions / --
if VIP_USER then
	--- Draw Circle Next Level Function ---
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
	--- Draw Cicle Next Level Function ---
	--- Round Function ---
	function round(num)
		if num >= 0 then
			return math.floor(num+.5)
		else
			return math.ceil(num-.5)
		end
	end
	--- Round Function ---
	--- Draw Cicle 2 Function ---
	function DrawCircle2(x, y, z, radius, color)
		local vPos1 = Vector(x, y, z)
		local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
		local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
		local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
			DrawCircleNextLvl(x, y, z, radius, 1, color, AutoplankMenu.drawing.lfc.CL)
		end
	end
	--- Draw Cicle 2 Function ---
end
-- / Lag Free Circles Functions /

-- / Checks Function / --
function Checks()
	--- Tick Manager Check ---
	if not TManager.onTick:isReady() and AutoplankMenu.misc.uTM then
		return
	end
	--- Tick Manager Check ---
	if VIP_USER then
		if not AutoplankMenu.drawing.lfc.LagFree then
			_G.DrawCircle = _G.oldDrawCircle
		else
			_G.DrawCircle = DrawCircle2
		end
	end
	--- Updates & Checks if Target is Valid ---
	tsTarget = GetTarget()
	if tsTarget and tsTarget.type == "obj_AI_Hero" then
		Target = tsTarget
	else
		Target = nil
	end
	--- Updates & Checks if Target is Valid ---
	--- Checks and finds Ignite ---
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	--- Checks and finds Ignite ---
	--- Slots for Items ---
	hpSlot, mpSlot, fskSlot =	GetInventorySlotItem(2003), GetInventorySlotItem(2004), GetInventorySlotItem(2041)
	hydSlot =	GetInventorySlotItem(3074)
	bwcSlot, brkSlot =	GetInventorySlotItem(3144), GetInventorySlotItem(3153)
	--- Slots for Items ---
	--- Checks if Spells are Ready ---
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)
	iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	--- Checks if Spells are Ready ---
	--- Checks if Active Items are Ready ---
	hydReady	= (hydSlot ~= nil and myHero:CanUseSpell(hydSlot) == READY)
	bwcReady	= (bwcSlot ~= nil and myHero:CanUseSpell(bwcSlot) == READY)
	brkReady	= (brkSlot ~= nil and myHero:CanUseSpell(brkSlot) == READY)
	--- Checks if Items are Ready ---
	--- Checks if Health Pots / Mana Pots are Ready ---
	Items.HealthPot.ready = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
	Items.FlaskPot.ready = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
	Items.ManaPot.ready = (mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
	--- Checks if Health Pots / Mana Pots are Ready ---
	--- Updates Minions ---
	enemyMinions:update()
	allyMinions:update()
	--- Updates Minions ---
end
-- / Checks Function / --

-- / isLow Function / --
function isLow(Name)
	if Name == 'Health' then
		if (myHero.health * (1/myHero.maxHealth)) <= (AutoplankMenu.misc.HPHealth * 0.01) then
			return true
		else
			return false
		end
	end
	if Name == 'Mana' then
		if (myHero.mana * (1/myHero.maxMana)) <= (AutoplankMenu.misc.MPMana * 0.01) then
			return true
		else
			return false
		end
	end
end
-- / isLow Function / --

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