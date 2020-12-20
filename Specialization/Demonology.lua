local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local Warlock = addonTable.Warlock;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local GetTime = GetTime;
local GetTotemInfo = GetTotemInfo;
local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local DE = {
	InnerDemons          = 267216,
	Demonbolt            = 264178,
	SummonDemonicTyrant  = 265187,
	SummonVilefiend      = 264119,
	CallDreadstalkers    = 104316,
	Doom                 = 603,
	DemonicStrength      = 267171,
	BilescourgeBombers   = 267211,
	Implosion            = 196277,
	SacrificedSouls      = 267214,
	HandOfGuldan         = 105174,
	NetherPortal         = 267217,
	DemonicCore          = 267102,
	DemonicCoreAura      = 264173,
	GrimoireFelguard     = 111898,
	PowerSiphon          = 264130,
	SoulStrike           = 264057,
	ShadowBolt           = 686,
	ImpendingCatastrophe = 321792,
	ScouringTithe        = 312321,
	SoulRot              = 325640,
	DecimatingBolt       = 325289,
	DemonicConsumption   = 267215,
	DemonicPower         = 265273,
	TrollRacial			 = 26297,
	Felstorm 			 = 89751
};

local TotemIcons = {
	[1616211] = 'Vilefiend',
	[136216]  = 'Felguard',
	[1378282] = 'Dreadstalker'
};

setmetatable(DE, Warlock.spellMeta);
local tyrantReady = false;
local tyrantTimeLimit = 0;
local forceTyrant = false;

function Warlock:Demonology()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = MaxDps:SmartAoe();
	local spellHistory = fd.spellHistory;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local wildImps = GetSpellCount(DE.Implosion); --Warlock:ImpsCount();

	local covenantId = fd.covenant.covenantId;
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local tyrantUp = buff[DE.DemonicPower].up;
	local petAura = MaxDps:IntUnitAura('pet', DE.Felstorm, nil, timeShift);
	local canDS = not petAura.up;

	if currentSpell == DE.CallDreadstalkers then
		soulShards = soulShards - 2;
	elseif currentSpell == DE.HandOfGuldan then
		soulShards = soulShards - 3;
	elseif currentSpell == DE.SummonVilefiend then
		soulShards = soulShards - 1;
	elseif currentSpell == DE.NetherPortal then
		soulShards = soulShards - 1;
	elseif currentSpell == DE.ShadowBolt then
		soulShards = soulShards + 1;
	elseif currentSpell == DE.Demonbolt then
		soulShards = soulShards + 2;
	elseif currentSpell == DE.SummonDemonicTyrant then
		soulShards = 5;
	end

	if soulShards < 0 then
		soulShards = 0;
	end

	if soulShards > 5 then
		soulShard = 5;
	end

	fd.wildImps = wildImps;
	fd.soulShards = soulShards;
	fd.targets = targets;
	fd.canDS = canDS;

--end setup

--main rotation

--is tyrant ready within 4 seconds?
if cooldown[DE.SummonDemonicTyrant].remains < 4 and timeToDie > 25
then
	return Warlock:DemonologyTyrantPrep();
end

--no
	--power siphon
	if talents[DE.PowerSiphon] and
		cooldown[DE.PowerSiphon].ready and 
		soulShards < 4 and
		wildImps > 1 and
		not tyrantUp
	then
		return DE.PowerSiphon;
	end

	--vilefiend
	if talents[DE.SummonVilefiend] and
		cooldown[DE.SummonVilefiend].ready and
		soulShards > 0 and
		currentSpell ~= DE.SummonVilefiend and (
			cooldown[DE.SummonDemonicTyrant].remains > 40 or 
			timeToDie < cooldown[DE.SummonDemonicTyrant].remains + 25
			)
	then
		return DE.SummonVilefiend;
	end

	--grimoire
	if talents[DE.GrimoireFelguard] and
		cooldown[DE.GrimoireFelguard].ready and 
		soulShards > 0 and (
			cooldown[DE.SummonDemonicTyrant].remains > 40 or 
			timeToDie < cooldown[DE.SummonDemonicTyrant].remains + 25
			)
	then
		return DE.GrimoireFelguard;
	end

	--dreadstalker
	if cooldown[DE.CallDreadstalkers].ready and
		soulShards > 1
	then
		return DE.CallDreadstalkers;
	end

	--demonic strength
	if talents[DE.DemonicStrength] and
		cooldown[DE.DemonicStrength].ready and 
		canDS
	then
		return DE.DemonicStrength;
	end

	--bilescourge bombers
	if talents[DE.BilescourgeBombers] and
		cooldown[DE.BilescourgeBombers].ready
	then
		return DE.BilescourgeBombers;
	end

	--guldan at 3 shards
	if soulShards > 2 and 
		currentSpell ~= DE.HandOfGuldan 
	then
		return DE.HandOfGuldan;
	end
		
	--decimating bolt if demonic core
	if buff[DE.DemonicCoreAura].up and
		cooldown[DE.DecimatingBolt].ready and
		currentSpell ~= DE.DecimatingBolt
	then
		return DE.DecimatingBolt;
	end

	--demonbolt if demonic core & <4 shards
	if buff[DE.DemonicCoreAura].up and
		soulShards < 4
	then
		return DE.Demonbolt;
	end

	--soulstrike
	if talents[DE.SoulStrike] and
		cooldown[DE.SoulStrike].ready 
	then
		return DE.SoulStrike;
	end

	--decimating bolt
	if cooldown[DE.DecimatingBolt].ready and
		currentSpell ~= DE.DecimatingBolt
	then
		return DE.DecimatingBolt;
	end

	--implosion if targets >1 & not guldan cast last & imps>3
	if targets > 1 and
		currentSpell ~= DE.HandOfGuldan and
		wildImps > 3
	then
		return DE.Implosion;
	end

	--shadowbolt
	return DE.ShadowBolt
end

--yes
function Warlock:DemonologyTyrantPrep()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local soulShards = fd.soulShards;
	local debuff = fd.debuff;
	local canDS = fd.canDS;
	local pets = Warlock:Pets();
	local vilefiendRemains = pets.Vilefiend;
	local felguardRemains = pets.Felguard;
	local dreadstalkerRemains = pets.Dreadstalker;
	local wildImps = GetSpellCount(DE.Implosion); --Warlock:ImpsCount();

	--evaluate readiness for tyrant
	if wildImps > 3 and
		(not cooldown[DE.SummonVilefiend].ready or not talents[DE.SummonVilefiend]) and
		not cooldown[DE.GrimoireFelguard].ready and
		not cooldown[DE.CallDreadstalkers].ready
	then
		tyrantReady = true;
	end

	--demonic strength with >3 imps & ds & vf & gr
	if talents[DE.DemonicStrength] and 
		cooldown[DE.DemonicStrength].ready and 
		canDS and 
		tyrantReady 
	then
		return DE.DemonicStrength;
	end

	--summon tyrant with >3 imps & ds & vf & gr
	if cooldown[DE.SummonDemonicTyrant].ready and 
		tyrantReady and
		currentSpell ~= DE.SummonDemonicTyrant 
	then
		tyrantReady = false;
		return DE.SummonDemonicTyrant;
	end

	--grimoire with dreadstalker
	if cooldown[DE.GrimoireFelguard].ready and 
		dreadstalkerRemains > 5 and
		soulShards > 0
	then 
		return DE.GrimoireFelguard;
	end

	--vilefiend with dreadstalker
	if talents[DE.SummonVilefiend] and
		cooldown[DE.SummonVilefiend].ready and
		dreadstalkerRemains > 5 and
		soulShards > 0 and
		currentSpell ~= DE.SummonVilefiend
	then
		return DE.SummonVilefiend;
	end

	--dreadstalker if at 5 shards
	if cooldown[DE.CallDreadstalkers].ready and 
		soulShards > 1 and 
		currentSpell ~= DE.CallDreadstalkers
	then
		return DE.CallDreadstalkers;
	end

	--guldan at 5 shards or 3 if not 1st cast
	if (soulShards > 4 and currentSpell ~= DE.HandOfGuldan) or
		(soulShards > 2 and wildImps and currentSpell ~= DE.HandOfGuldan)
	then
		return DE.HandOfGuldan;
	end

	--demonbolt if core & <4 shards
	if buff[DE.DemonicCoreAura].up and
		soulShards < 4 
	then
		return DE.Demonbolt;
	end

	--soulstrike
	if talents[DE.SoulStrike] and
		cooldown[DE.SoulStrike].ready
	then
		return DE.SoulStrike;
	end

	--ShadowBolt
	return DE.ShadowBolt;
end

function Warlock:Pets()
	local pets = {
		Vilefiend = 0,
		Felguard = 0,
		Dreadstalker = 0
	};

	for index = 1, MAX_TOTEMS do
		local hasTotem, totemName, startTime, duration, icon = GetTotemInfo(index);
		if hasTotem then
			local totemUnifiedName = TotemIcons[icon];
			if totemUnifiedName then
				local remains = startTime + duration - GetTime();
				pets[totemUnifiedName] = remains;
			end
		end
	end

	return pets;
end