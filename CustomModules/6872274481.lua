--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.
--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.
local GuiLibrary = shared.GuiLibrary
local playersService = game:GetService("Players")
local textService = game:GetService("TextService")
local lightingService = game:GetService("Lighting")
local textChatService = game:GetService("TextChatService")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vapeConnections = {}
local vapeCachedAssets = {}
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new("BindableEvent")
		return self[index]
	end
})
local vapeTargetInfo = shared.VapeTargetInfo
local vapeInjected = true

local bedwars = {}
local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	blocks = {},
	blockPlacer = {},
	blockPlace = tick(),
	blockRaycast = RaycastParams.new(),
	equippedKit = "none",
	forgeMasteryPoints = 0,
	forgeUpgrades = {},
	grapple = tick(),
	inventories = {},
	localInventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	localHand = {},
	matchState = 0,
	matchStateChanged = tick(),
	pots = {},
	queueType = "bedwars_test",
	scythe = tick(),
	statistics = {
		beds = 0,
		kills = 0,
		lagbacks = 0,
		lagbackEvent = Instance.new("BindableEvent"),
		reported = 0,
		universalLagbacks = 0
	},
	whitelist = {
		chatStrings1 = {helloimusinginhaler = "vape"},
		chatStrings2 = {vape = "helloiamskibidi"},
		clientUsers = {},
		oldChatFunctions = {}
	},
	zephyrOrb = 0
}
store.blockRaycast.FilterType = Enum.RaycastFilterType.Include
local AutoLeave = {Enabled = false}

table.insert(vapeConnections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA("Camera")
end))
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end
local networkownerswitch = tick()
--ME WHEN THE MOBILE EXPLOITS ADD A DISFUNCTIONAL ISNETWORKOWNER (its for compatability I swear!!)
local isnetworkowner = function(part)
	local suc, res = pcall(function() return gethiddenproperty(part, "NetworkOwnershipRule") end)
	if suc and res == Enum.NetworkOwnership.Manual then
		sethiddenproperty(part, "NetworkOwnershipRule", Enum.NetworkOwnership.Automatic)
		networkownerswitch = tick() + 8
	end
	return networkownerswitch <= tick()
end
local getcustomasset = getsynasset or getcustomasset or function(location) return "rbxasset://"..location end
local queueonteleport = syn and syn.queue_on_teleport or queue_on_teleport or function() end
local synapsev3 = syn and syn.toast_notification and "V3" or ""
local worldtoscreenpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1] - Vector3.new(0, 36, 0), scr[1].Z > 0
	end
	return gameCamera.WorldToScreenPoint(gameCamera, pos)
end
local worldtoviewportpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1], scr[1].Z > 0
	end
	return gameCamera.WorldToViewportPoint(gameCamera, pos)
end

local function vapeGithubRequest(scripturl)
	if not isfile("vape/"..scripturl) then
		local suc, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/"..readfile("vape/commithash.txt").."/"..scripturl, true) end)
		assert(suc, res)
		assert(res ~= "404: Not Found", res)
		if scripturl:find(".lua") then res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.\n"..res end
		writefile("vape/"..scripturl, res)
	end
	return readfile("vape/"..scripturl)
end

local function downloadVapeAsset(path)
	if not isfile(path) then
		task.spawn(function()
			local textlabel = Instance.new("TextLabel")
			textlabel.Size = UDim2.new(1, 0, 0, 36)
			textlabel.Text = "Downloading "..path
			textlabel.BackgroundTransparency = 1
			textlabel.TextStrokeTransparency = 0
			textlabel.TextSize = 30
			textlabel.Font = Enum.Font.SourceSans
			textlabel.TextColor3 = Color3.new(1, 1, 1)
			textlabel.Position = UDim2.new(0, 0, 0, -36)
			textlabel.Parent = GuiLibrary.MainGui
			repeat task.wait() until isfile(path)
			textlabel:Destroy()
		end)
		local suc, req = pcall(function() return vapeGithubRequest(path:gsub("vape/assets", "assets")) end)
		if suc and req then
			writefile(path, req)
		else
			return ""
		end
	end
	if not vapeCachedAssets[path] then vapeCachedAssets[path] = getcustomasset(path) end
	return vapeCachedAssets[path]
end

local function warningNotification(title, text, delay)
	local suc, res = pcall(function()
		local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/WarningNotification.png")
		frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
		return frame
	end)
	return (suc and res)
end

local function run(func) func() end

local function isFriend(plr, recolor)
	if GuiLibrary.ObjectsThatCanBeSaved["Use FriendsToggle"].Api.Enabled then
		local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectList, plr.Name)
		friend = friend and GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectListEnabled[friend]
		if recolor then
			friend = friend and GuiLibrary.ObjectsThatCanBeSaved["Recolor visualsToggle"].Api.Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectList, plr.Name)
	friend = friend and GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectListEnabled[friend]
	return friend
end

local function isVulnerable(plr)
	return plr.Humanoid.Health > 0 and not plr.Character.FindFirstChildWhichIsA(plr.Character, "ForceField")
end

local function getPlayerColor(plr)
	if isFriend(plr, true) then
		return Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Value)
	end
	return tostring(plr.TeamColor) ~= "White" and plr.TeamColor.Color
end

local function LaunchAngle(v, g, d, h, higherArc)
	local v2 = v * v
	local v4 = v2 * v2
	local root = -math.sqrt(v4 - g*(g*d*d + 2*h*v2))
	return math.atan((v2 + root) / (g * d))
end

local function LaunchDirection(start, target, v, g)
	local horizontal = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
	local h = target.Y - start.Y
	local d = horizontal.Magnitude
	local a = LaunchAngle(v, g, d, h)

	if a ~= a then
		return g == 0 and (target - start).Unit * v
	end

	local vec = horizontal.Unit * v
	local rotAxis = Vector3.new(-horizontal.Z, 0, horizontal.X)
	return CFrame.fromAxisAngle(rotAxis, a) * vec
end

local physicsUpdate = 1 / 60

local function predictGravity(playerPosition, vel, bulletTime, targetPart, Gravity)
	local estimatedVelocity = vel.Y
	local rootSize = (targetPart.Humanoid.HipHeight + (targetPart.RootPart.Size.Y / 2))
	local velocityCheck = (tick() - targetPart.JumpTick) < 0.2
	vel = vel * physicsUpdate

	for i = 1, math.ceil(bulletTime / physicsUpdate) do
		if velocityCheck then
			estimatedVelocity = estimatedVelocity - (Gravity * physicsUpdate)
		else
			estimatedVelocity = 0
			playerPosition = playerPosition + Vector3.new(0, -0.03, 0) -- bw hitreg is so bad that I have to add this LOL
			rootSize = rootSize - 0.03
		end

		local floorDetection = workspace:Raycast(playerPosition, Vector3.new(vel.X, (estimatedVelocity * physicsUpdate) - rootSize, vel.Z), store.blockRaycast)
		if floorDetection then
			playerPosition = Vector3.new(playerPosition.X, floorDetection.Position.Y + rootSize, playerPosition.Z)
			local bouncepad = floorDetection.Instance:FindFirstAncestor("gumdrop_bounce_pad")
			if bouncepad and bouncepad:GetAttribute("PlacedByUserId") == targetPart.Player.UserId then
				estimatedVelocity = 130 - (Gravity * physicsUpdate)
				velocityCheck = true
			else
				estimatedVelocity = targetPart.Humanoid.JumpPower - (Gravity * physicsUpdate)
				velocityCheck = targetPart.Jumping
			end
		end

		playerPosition = playerPosition + Vector3.new(vel.X, velocityCheck and estimatedVelocity * physicsUpdate or 0, vel.Z)
	end

	return playerPosition, Vector3.new(0, 0, 0)
end

local entityLibrary = shared.vapeentity
local whitelist = shared.vapewhitelist
local RunLoops = {RenderStepTable = {}, StepTable = {}, HeartTable = {}}
do
	function RunLoops:BindToRenderStep(name, func)
		if RunLoops.RenderStepTable[name] == nil then
			RunLoops.RenderStepTable[name] = runService.RenderStepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromRenderStep(name)
		if RunLoops.RenderStepTable[name] then
			RunLoops.RenderStepTable[name]:Disconnect()
			RunLoops.RenderStepTable[name] = nil
		end
	end

	function RunLoops:BindToStepped(name, func)
		if RunLoops.StepTable[name] == nil then
			RunLoops.StepTable[name] = runService.Stepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromStepped(name)
		if RunLoops.StepTable[name] then
			RunLoops.StepTable[name]:Disconnect()
			RunLoops.StepTable[name] = nil
		end
	end

	function RunLoops:BindToHeartbeat(name, func)
		if RunLoops.HeartTable[name] == nil then
			RunLoops.HeartTable[name] = runService.Heartbeat:Connect(func)
		end
	end

	function RunLoops:UnbindFromHeartbeat(name)
		if RunLoops.HeartTable[name] then
			RunLoops.HeartTable[name]:Disconnect()
			RunLoops.HeartTable[name] = nil
		end
	end
end

GuiLibrary.SelfDestructEvent.Event:Connect(function()
	vapeInjected = false
	for i, v in pairs(vapeConnections) do
		if v.Disconnect then pcall(function() v:Disconnect() end) continue end
		if v.disconnect then pcall(function() v:disconnect() end) continue end
	end
end)

local function getItem(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getItemNear(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName or item.itemType:find(itemName) then
			return item, slot
		end
	end
	return nil
end

local function getHotbarSlot(itemName)
	for slotNumber, slotTable in pairs(store.localInventory.hotbar) do
		if slotTable.item and slotTable.item.itemType == itemName then
			return slotNumber - 1
		end
	end
	return nil
end

local function getShieldAttribute(char)
	local returnedShield = 0
	for attributeName, attributeValue in pairs(char:GetAttributes()) do
		if attributeName:find("Shield") and type(attributeValue) == "number" then
			returnedShield = returnedShield + attributeValue
		end
	end
	return returnedShield
end

local function getPickaxe()
	return getItemNear("pick")
end

local function getAxe()
	local bestAxe, bestAxeSlot = nil, nil
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("axe") and item.itemType:find("pickaxe") == nil and item.itemType:find("void") == nil then
			bextAxe, bextAxeSlot = item, slot
		end
	end
	return bestAxe, bestAxeSlot
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		local swordMeta = bedwars.ItemTable[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getBow()
	local bestBow, bestBowSlot, bestBowStrength = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("bow") then
			local tab = bedwars.ItemTable[item.itemType].projectileSource
			local ammo = tab.projectileType("arrow")
			local dmg = bedwars.ProjectileMeta[ammo].combat.damage
			if dmg > bestBowStrength then
				bestBow, bestBowSlot, bestBowStrength = item, slot, dmg
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getWool()
	local wool = getItemNear("wool")
	return wool and wool.itemType, wool and wool.amount
end

local function getBlock()
	for slot, item in pairs(store.localInventory.inventory.items) do
		if bedwars.ItemTable[item.itemType].block then
			return item.itemType, item.amount
		end
	end
end

local function attackValue(vec)
	return {value = vec}
end

local function getSpeed()
	local speed = 0
	if lplr.Character then
		local SpeedDamageBoost = lplr.Character:GetAttribute("SpeedBoost")
		if SpeedDamageBoost and SpeedDamageBoost > 1 then
			speed = speed + (8 * (SpeedDamageBoost - 1))
		end
		if store.grapple > tick() then
			speed = speed + 90
		end
		if store.scythe > tick() then
			speed = speed + 5
		end
		if lplr.Character:GetAttribute("GrimReaperChannel") then
			speed = speed + 20
		end
		local armor = store.localInventory.inventory.armor[3]
		if type(armor) ~= "table" then armor = {itemType = ""} end
		if armor.itemType == "speed_boots" then
			speed = speed + 12
		end
		if store.zephyrOrb ~= 0 then
			speed = speed + 12
		end
	end
	return speed
end

local Reach = {Enabled = false}
local blacklistedblocks = {
	bed = true,
	ceramic = true
}
local cachedNormalSides = {}
for i,v in pairs(Enum.NormalId:GetEnumItems()) do if v.Name ~= "Bottom" then table.insert(cachedNormalSides, v) end end
local updateitem = Instance.new("BindableEvent")
table.insert(vapeConnections, updateitem.Event:Connect(function(inputObj)
	if inputService:IsMouseButtonPressed(0) then
		game:GetService("ContextActionService"):CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end
end))

local function getPlacedBlock(pos)
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local oldpos = Vector3.zero

local function getScaffold(vec, diagonaltoggle)
	local realvec = Vector3.new(math.floor((vec.X / 3) + 0.5) * 3, math.floor((vec.Y / 3) + 0.5) * 3, math.floor((vec.Z / 3) + 0.5) * 3)
	local speedCFrame = (oldpos - realvec)
	local returedpos = realvec
	if entityLibrary.isAlive then
		local angle = math.deg(math.atan2(-entityLibrary.character.Humanoid.MoveDirection.X, -entityLibrary.character.Humanoid.MoveDirection.Z))
		local goingdiagonal = (angle >= 130 and angle <= 150) or (angle <= -35 and angle >= -50) or (angle >= 35 and angle <= 50) or (angle <= -130 and angle >= -150)
		if goingdiagonal and ((speedCFrame.X == 0 and speedCFrame.Z ~= 0) or (speedCFrame.X ~= 0 and speedCFrame.Z == 0)) and diagonaltoggle then
			return oldpos
		end
	end
	return realvec
end

local function getBestTool(block)
	local tool = nil
	local blockmeta = bedwars.ItemTable[block]
	local blockType = blockmeta.block and blockmeta.block.breakType
	if blockType then
		local best = 0
		for i,v in pairs(store.localInventory.inventory.items) do
			local meta = bedwars.ItemTable[v.itemType]
			if meta.breakBlock and meta.breakBlock[blockType] and meta.breakBlock[blockType] >= best then
				best = meta.breakBlock[blockType]
				tool = v
			end
		end
	end
	return tool
end

local function switchItem(tool)
	if lplr.Character.HandInvItem.Value ~= tool then
		bedwars.Client:Get(bedwars.EquipItemRemote):CallServerAsync({
			hand = tool
		})
		local started = tick()
		repeat task.wait() until (tick() - started) > 0.3 or lplr.Character.HandInvItem.Value == tool
	end
end

local function switchToAndUseTool(block, legit)
	local tool = getBestTool(block.Name)
	if tool and (entityLibrary.isAlive and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value ~= tool.tool) then
		if legit then
			if getHotbarSlot(tool.itemType) then
				bedwars.ClientStoreHandler:dispatch({
					type = "InventorySelectHotbarSlot",
					slot = getHotbarSlot(tool.itemType)
				})
				vapeEvents.InventoryChanged.Event:Wait()
				updateitem:Fire(inputobj)
				return true
			else
				return false
			end
		end
		switchItem(tool.tool)
	end
end

local function isBlockCovered(pos)
	local coveredsides = 0
	for i, v in pairs(cachedNormalSides) do
		local blockpos = (pos + (Vector3.FromNormalId(v) * 3))
		local block = getPlacedBlock(blockpos)
		if block then
			coveredsides = coveredsides + 1
		end
	end
	return coveredsides == #cachedNormalSides
end

local function GetPlacedBlocksNear(pos, normal)
	local blocks = {}
	local lastfound = nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) and (not blacklistedblocks[extrablock.Name]) then
				table.insert(blocks, extrablock.Name)
			end
			lastfound = extrablock
			if not covered then
				break
			end
		else
			break
		end
	end
	return blocks
end

local function getLastCovered(pos, normal)
	local lastfound, lastpos = nil, nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock, extrablockpos = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			lastfound, lastpos = extrablock, extrablockpos
			if not covered then
				break
			end
		else
			break
		end
	end
	return lastfound, lastpos
end

local function getBestBreakSide(pos)
	local softest, softestside = 9e9, Enum.NormalId.Top
	for i,v in pairs(cachedNormalSides) do
		local sidehardness = 0
		for i2,v2 in pairs(GetPlacedBlocksNear(pos, v)) do
			local blockmeta = bedwars.ItemTable[v2].block
			sidehardness = sidehardness + (blockmeta and blockmeta.health or 10)
			if blockmeta then
				local tool = getBestTool(v2)
				if tool then
					sidehardness = sidehardness - bedwars.ItemTable[tool.itemType].breakBlock[blockmeta.breakType]
				end
			end
		end
		if sidehardness <= softest then
			softest = sidehardness
			softestside = v
		end
	end
	return softestside, softest
end

local function EntityNearPosition(distance, ignore, overridepos)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.RootPart.Position).magnitude
				if overridepos and mag > distance then
					mag = (overridepos - v.RootPart.Position).magnitude
				end
				if mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, mag
				end
			end
		end
		if not ignore then
			for i, v in pairs(collectionService:GetTagged("Monster")) do
				if v.PrimaryPart and v:GetAttribute("Team") ~= lplr:GetAttribute("Team") then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645)}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "DiamondGuardian", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "GolemBoss", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("Drone")) do
				if v.PrimaryPart and tonumber(v:GetAttribute("PlayerUserId")) ~= lplr.UserId then
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then -- magcheck
						closestEntity, closestMagnitude = {Player = {Name = "Drone", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
		end
	end
	return closestEntity
end

local function EntityNearMouse(distance)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		local mousepos = inputService.GetMouseLocation(inputService)
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local vec, vis = worldtoscreenpoint(v.RootPart.Position)
				local mag = (mousepos - Vector2.new(vec.X, vec.Y)).magnitude
				if vis and mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, v.Target and -1 or mag
				end
			end
		end
	end
	return closestEntity
end

local function AllNearPosition(distance, amount, sortfunction, prediction)
	local returnedplayer = {}
	local currentamount = 0
	if entityLibrary.isAlive then
		local sortedentities = {}
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local playerPosition = v.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, v)
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Monster")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if v:GetAttribute("Team") == lplr:GetAttribute("Team") then continue end
					table.insert(sortedentities, {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645), GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "DiamondGuardian", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "GolemBoss", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Drone")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if tonumber(v:GetAttribute("PlayerUserId")) == lplr.UserId then continue end
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					table.insert(sortedentities, {Player = {Name = "Drone", UserId = 1443379645}, GetAttribute = function() return "none" end, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(store.pots) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "Pot", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = {Health = 100, MaxHealth = 100}})
				end
			end
		end
		if sortfunction then
			table.sort(sortedentities, sortfunction)
		end
		for i,v in pairs(sortedentities) do
			table.insert(returnedplayer, v)
			currentamount = currentamount + 1
			if currentamount >= amount then break end
		end
	end
	return returnedplayer
end

--pasted from old source since gui code is hard
local function CreateAutoHotbarGUI(children2, argstable)
	local buttonapi = {}
	buttonapi["Hotbars"] = {}
	buttonapi["CurrentlySelected"] = 1
	local currentanim
	local amount = #children2:GetChildren()
	local sortableitems = {
		{itemType = "swords", itemDisplayType = "diamond_sword"},
		{itemType = "pickaxes", itemDisplayType = "diamond_pickaxe"},
		{itemType = "axes", itemDisplayType = "diamond_axe"},
		{itemType = "shears", itemDisplayType = "shears"},
		{itemType = "wool", itemDisplayType = "wool_white"},
		{itemType = "iron", itemDisplayType = "iron"},
		{itemType = "diamond", itemDisplayType = "diamond"},
		{itemType = "emerald", itemDisplayType = "emerald"},
		{itemType = "bows", itemDisplayType = "wood_bow"},
	}
	local items = bedwars.ItemTable
	if items then
		for i2,v2 in pairs(items) do
			if (i2:find("axe") == nil or i2:find("void")) and i2:find("bow") == nil and i2:find("shears") == nil and i2:find("wool") == nil and v2.sword == nil and v2.armor == nil and v2["dontGiveItem"] == nil and bedwars.ItemTable[i2] and bedwars.ItemTable[i2].image then
				table.insert(sortableitems, {itemType = i2, itemDisplayType = i2})
			end
		end
	end
	local buttontext = Instance.new("TextButton")
	buttontext.AutoButtonColor = false
	buttontext.BackgroundTransparency = 1
	buttontext.Name = "ButtonText"
	buttontext.Text = ""
	buttontext.Name = argstable["Name"]
	buttontext.LayoutOrder = 1
	buttontext.Size = UDim2.new(1, 0, 0, 40)
	buttontext.Active = false
	buttontext.TextColor3 = Color3.fromRGB(162, 162, 162)
	buttontext.TextSize = 17
	buttontext.Font = Enum.Font.SourceSans
	buttontext.Position = UDim2.new(0, 0, 0, 0)
	buttontext.Parent = children2
	local toggleframe2 = Instance.new("Frame")
	toggleframe2.Size = UDim2.new(0, 200, 0, 31)
	toggleframe2.Position = UDim2.new(0, 10, 0, 4)
	toggleframe2.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	toggleframe2.Name = "ToggleFrame2"
	toggleframe2.Parent = buttontext
	local toggleframe1 = Instance.new("Frame")
	toggleframe1.Size = UDim2.new(0, 198, 0, 29)
	toggleframe1.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	toggleframe1.BorderSizePixel = 0
	toggleframe1.Name = "ToggleFrame1"
	toggleframe1.Position = UDim2.new(0, 1, 0, 1)
	toggleframe1.Parent = toggleframe2
	local addbutton = Instance.new("ImageLabel")
	addbutton.BackgroundTransparency = 1
	addbutton.Name = "AddButton"
	addbutton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	addbutton.Position = UDim2.new(0, 93, 0, 9)
	addbutton.Size = UDim2.new(0, 12, 0, 12)
	addbutton.ImageColor3 = Color3.fromRGB(5, 133, 104)
	addbutton.Image = downloadVapeAsset("vape/assets/AddItem.png")
	addbutton.Parent = toggleframe1
	local children3 = Instance.new("Frame")
	children3.Name = argstable["Name"].."Children"
	children3.BackgroundTransparency = 1
	children3.LayoutOrder = amount
	children3.Size = UDim2.new(0, 220, 0, 0)
	children3.Parent = children2
	local uilistlayout = Instance.new("UIListLayout")
	uilistlayout.Parent = children3
	uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		children3.Size = UDim2.new(1, 0, 0, uilistlayout.AbsoluteContentSize.Y)
	end)
	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 5)
	uicorner.Parent = toggleframe1
	local uicorner2 = Instance.new("UICorner")
	uicorner2.CornerRadius = UDim.new(0, 5)
	uicorner2.Parent = toggleframe2
	buttontext.MouseEnter:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(79, 78, 79)}):Play()
	end)
	buttontext.MouseLeave:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(38, 37, 38)}):Play()
	end)
	local ItemListBigFrame = Instance.new("Frame")
	ItemListBigFrame.Size = UDim2.new(1, 0, 1, 0)
	ItemListBigFrame.Name = "ItemList"
	ItemListBigFrame.BackgroundTransparency = 1
	ItemListBigFrame.Visible = false
	ItemListBigFrame.Parent = GuiLibrary.MainGui
	local ItemListFrame = Instance.new("Frame")
	ItemListFrame.Size = UDim2.new(0, 660, 0, 445)
	ItemListFrame.Position = UDim2.new(0.5, -330, 0.5, -223)
	ItemListFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListFrame.Parent = ItemListBigFrame
	local ItemListExitButton = Instance.new("ImageButton")
	ItemListExitButton.Name = "ItemListExitButton"
	ItemListExitButton.ImageColor3 = Color3.fromRGB(121, 121, 121)
	ItemListExitButton.Size = UDim2.new(0, 24, 0, 24)
	ItemListExitButton.AutoButtonColor = false
	ItemListExitButton.Image = downloadVapeAsset("vape/assets/ExitIcon1.png")
	ItemListExitButton.Visible = true
	ItemListExitButton.Position = UDim2.new(1, -31, 0, 8)
	ItemListExitButton.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListExitButton.Parent = ItemListFrame
	local ItemListExitButtonround = Instance.new("UICorner")
	ItemListExitButtonround.CornerRadius = UDim.new(0, 16)
	ItemListExitButtonround.Parent = ItemListExitButton
	ItemListExitButton.MouseEnter:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(60, 60, 60), ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
	ItemListExitButton.MouseLeave:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(26, 25, 26), ImageColor3 = Color3.fromRGB(121, 121, 121)}):Play()
	end)
	ItemListExitButton.MouseButton1Click:Connect(function()
		ItemListBigFrame.Visible = false
		GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = true
	end)
	local ItemListFrameShadow = Instance.new("ImageLabel")
	ItemListFrameShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	ItemListFrameShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	ItemListFrameShadow.Image = downloadVapeAsset("vape/assets/WindowBlur.png")
	ItemListFrameShadow.BackgroundTransparency = 1
	ItemListFrameShadow.ZIndex = -1
	ItemListFrameShadow.Size = UDim2.new(1, 6, 1, 6)
	ItemListFrameShadow.ImageColor3 = Color3.new(0, 0, 0)
	ItemListFrameShadow.ScaleType = Enum.ScaleType.Slice
	ItemListFrameShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	ItemListFrameShadow.Parent = ItemListFrame
	local ItemListFrameText = Instance.new("TextLabel")
	ItemListFrameText.Size = UDim2.new(1, 0, 0, 41)
	ItemListFrameText.BackgroundTransparency = 1
	ItemListFrameText.Name = "WindowTitle"
	ItemListFrameText.Position = UDim2.new(0, 0, 0, 0)
	ItemListFrameText.TextXAlignment = Enum.TextXAlignment.Left
	ItemListFrameText.Font = Enum.Font.SourceSans
	ItemListFrameText.TextSize = 17
	ItemListFrameText.Text = "	New AutoHotbar"
	ItemListFrameText.TextColor3 = Color3.fromRGB(201, 201, 201)
	ItemListFrameText.Parent = ItemListFrame
	local ItemListBorder1 = Instance.new("Frame")
	ItemListBorder1.BackgroundColor3 = Color3.fromRGB(40, 39, 40)
	ItemListBorder1.BorderSizePixel = 0
	ItemListBorder1.Size = UDim2.new(1, 0, 0, 1)
	ItemListBorder1.Position = UDim2.new(0, 0, 0, 41)
	ItemListBorder1.Parent = ItemListFrame
	local ItemListFrameCorner = Instance.new("UICorner")
	ItemListFrameCorner.CornerRadius = UDim.new(0, 4)
	ItemListFrameCorner.Parent = ItemListFrame
	local ItemListFrame1 = Instance.new("Frame")
	ItemListFrame1.Size = UDim2.new(0, 112, 0, 113)
	ItemListFrame1.Position = UDim2.new(0, 10, 0, 71)
	ItemListFrame1.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	ItemListFrame1.Name = "ItemListFrame1"
	ItemListFrame1.Parent = ItemListFrame
	local ItemListFrame2 = Instance.new("Frame")
	ItemListFrame2.Size = UDim2.new(0, 110, 0, 111)
	ItemListFrame2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ItemListFrame2.BorderSizePixel = 0
	ItemListFrame2.Name = "ItemListFrame2"
	ItemListFrame2.Position = UDim2.new(0, 1, 0, 1)
	ItemListFrame2.Parent = ItemListFrame1
	local ItemListFramePicker = Instance.new("ScrollingFrame")
	ItemListFramePicker.Size = UDim2.new(0, 495, 0, 220)
	ItemListFramePicker.Position = UDim2.new(0, 144, 0, 122)
	ItemListFramePicker.BorderSizePixel = 0
	ItemListFramePicker.ScrollBarThickness = 3
	ItemListFramePicker.ScrollBarImageTransparency = 0.8
	ItemListFramePicker.VerticalScrollBarInset = Enum.ScrollBarInset.None
	ItemListFramePicker.BackgroundTransparency = 1
	ItemListFramePicker.Parent = ItemListFrame
	local ItemListFramePickerGrid = Instance.new("UIGridLayout")
	ItemListFramePickerGrid.CellPadding = UDim2.new(0, 4, 0, 3)
	ItemListFramePickerGrid.CellSize = UDim2.new(0, 51, 0, 52)
	ItemListFramePickerGrid.Parent = ItemListFramePicker
	ItemListFramePickerGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ItemListFramePicker.CanvasSize = UDim2.new(0, 0, 0, ItemListFramePickerGrid.AbsoluteContentSize.Y * (1 / GuiLibrary["MainRescale"].Scale))
	end)
	local ItemListcorner = Instance.new("UICorner")
	ItemListcorner.CornerRadius = UDim.new(0, 5)
	ItemListcorner.Parent = ItemListFrame1
	local ItemListcorner2 = Instance.new("UICorner")
	ItemListcorner2.CornerRadius = UDim.new(0, 5)
	ItemListcorner2.Parent = ItemListFrame2
	local selectedslot = 1
	local hoveredslot = 0

	local refreshslots
	local refreshList
	refreshslots = function()
		local startnum = 144
		local oldhovered = hoveredslot
		for i2,v2 in pairs(ItemListFrame:GetChildren()) do
			if v2.Name:find("ItemSlot") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(ItemListFramePicker:GetChildren()) do
			if v3:IsA("TextButton") then
				v3:Remove()
			end
		end
		for i4,v4 in pairs(sortableitems) do
			local ItemFrame = Instance.new("TextButton")
			ItemFrame.Text = ""
			ItemFrame.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
			ItemFrame.Parent = ItemListFramePicker
			ItemFrame.AutoButtonColor = false
			local ItemFrameIcon = Instance.new("ImageLabel")
			ItemFrameIcon.Size = UDim2.new(0, 32, 0, 32)
			ItemFrameIcon.Image = bedwars.getIcon({itemType = v4.itemDisplayType}, true)
			ItemFrameIcon.ResampleMode = (bedwars.getIcon({itemType = v4.itemDisplayType}, true):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemFrameIcon.Position = UDim2.new(0, 10, 0, 10)
			ItemFrameIcon.BackgroundTransparency = 1
			ItemFrameIcon.Parent = ItemFrame
			local ItemFramecorner = Instance.new("UICorner")
			ItemFramecorner.CornerRadius = UDim.new(0, 5)
			ItemFramecorner.Parent = ItemFrame
			ItemFrame.MouseButton1Click:Connect(function()
				for i5,v5 in pairs(buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"]) do
					if v5.itemType == v4.itemType then
						buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i5)] = nil
					end
				end
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(selectedslot)] = v4
				refreshslots()
				refreshList()
			end)
		end
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)]
			local ItemListFrame3 = Instance.new("Frame")
			ItemListFrame3.Size = UDim2.new(0, 55, 0, 56)
			ItemListFrame3.Position = UDim2.new(0, startnum - 2, 0, 380)
			ItemListFrame3.BackgroundTransparency = (selectedslot == i and 0 or 1)
			ItemListFrame3.BackgroundColor3 = Color3.fromRGB(35, 34, 35)
			ItemListFrame3.Name = "ItemSlot"
			ItemListFrame3.Parent = ItemListFrame
			local ItemListFrame4 = Instance.new("TextButton")
			ItemListFrame4.Size = UDim2.new(0, 51, 0, 52)
			ItemListFrame4.BackgroundColor3 = (oldhovered == i and Color3.fromRGB(31, 30, 31) or Color3.fromRGB(20, 20, 20))
			ItemListFrame4.BorderSizePixel = 0
			ItemListFrame4.AutoButtonColor = false
			ItemListFrame4.Text = ""
			ItemListFrame4.Name = "ItemListFrame4"
			ItemListFrame4.Position = UDim2.new(0, 2, 0, 2)
			ItemListFrame4.Parent = ItemListFrame3
			local ItemListImage = Instance.new("ImageLabel")
			ItemListImage.Size = UDim2.new(0, 32, 0, 32)
			ItemListImage.BackgroundTransparency = 1
			local img = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			ItemListImage.Image = img
			ItemListImage.ResampleMode = (img:find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemListImage.Position = UDim2.new(0, 10, 0, 10)
			ItemListImage.Parent = ItemListFrame4
			local ItemListcorner3 = Instance.new("UICorner")
			ItemListcorner3.CornerRadius = UDim.new(0, 5)
			ItemListcorner3.Parent = ItemListFrame3
			local ItemListcorner4 = Instance.new("UICorner")
			ItemListcorner4.CornerRadius = UDim.new(0, 5)
			ItemListcorner4.Parent = ItemListFrame4
			ItemListFrame4.MouseEnter:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
				hoveredslot = i
			end)
			ItemListFrame4.MouseLeave:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				hoveredslot = 0
			end)
			ItemListFrame4.MouseButton1Click:Connect(function()
				selectedslot = i
				refreshslots()
			end)
			ItemListFrame4.MouseButton2Click:Connect(function()
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)] = nil
				refreshslots()
				refreshList()
			end)
			startnum = startnum + 55
		end
	end

	local function createHotbarButton(num, items)
		num = tonumber(num) or #buttonapi["Hotbars"] + 1
		local hotbarbutton = Instance.new("TextButton")
		hotbarbutton.Size = UDim2.new(1, 0, 0, 30)
		hotbarbutton.BackgroundTransparency = 1
		hotbarbutton.LayoutOrder = num
		hotbarbutton.AutoButtonColor = false
		hotbarbutton.Text = ""
		hotbarbutton.Parent = children3
		buttonapi["Hotbars"][num] = {["Items"] = items or {}, Object = hotbarbutton, ["Number"] = num}
		local hotbarframe = Instance.new("Frame")
		hotbarframe.BackgroundColor3 = (num == buttonapi["CurrentlySelected"] and Color3.fromRGB(54, 53, 54) or Color3.fromRGB(31, 30, 31))
		hotbarframe.Size = UDim2.new(0, 200, 0, 27)
		hotbarframe.Position = UDim2.new(0, 10, 0, 1)
		hotbarframe.Parent = hotbarbutton
		local uicorner3 = Instance.new("UICorner")
		uicorner3.CornerRadius = UDim.new(0, 5)
		uicorner3.Parent = hotbarframe
		local startpos = 11
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][num]["Items"][tostring(i)]
			local hotbarbox = Instance.new("ImageLabel")
			hotbarbox.Name = i
			hotbarbox.Size = UDim2.new(0, 17, 0, 18)
			hotbarbox.Position = UDim2.new(0, startpos, 0, 5)
			hotbarbox.BorderSizePixel = 0
			hotbarbox.Image = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			hotbarbox.ResampleMode = ((item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or ""):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			hotbarbox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			hotbarbox.Parent = hotbarframe
			startpos = startpos + 18
		end
		hotbarbutton.MouseButton1Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				ItemListBigFrame.Visible = true
				GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = false
				refreshslots()
			end
			buttonapi["CurrentlySelected"] = num
			refreshList()
		end)
		hotbarbutton.MouseButton2Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				buttonapi["CurrentlySelected"] = (num == 2 and 0 or 1)
			end
			table.remove(buttonapi["Hotbars"], num)
			refreshList()
		end)
	end

	refreshList = function()
		local newnum = 0
		local newtab = {}
		for i3,v3 in pairs(buttonapi["Hotbars"]) do
			newnum = newnum + 1
			newtab[newnum] = v3
		end
		buttonapi["Hotbars"] = newtab
		for i,v in pairs(children3:GetChildren()) do
			if v:IsA("TextButton") then
				v:Remove()
			end
		end
		for i2,v2 in pairs(buttonapi["Hotbars"]) do
			createHotbarButton(i2, v2["Items"])
		end
		GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	end
	buttonapi["RefreshList"] = refreshList

	buttontext.MouseButton1Click:Connect(function()
		createHotbarButton()
	end)

	GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	GuiLibrary.ObjectsThatCanBeSaved[children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["Api"] = buttonapi, Object = buttontext}

	return buttonapi
end

GuiLibrary.LoadSettingsEvent.Event:Connect(function(res)
	for i,v in pairs(res) do
		local obj = GuiLibrary.ObjectsThatCanBeSaved[i]
		if obj and v.Type == "ItemList" and obj.Api then
			obj.Api.Hotbars = v.Items
			obj.Api.CurrentlySelected = v.CurrentlySelected
			obj.Api.RefreshList()
		end
	end
end)

run(function()
	local function isWhitelistedBed(bed)
		if bed and bed.Name == 'bed' then
			for i, v in pairs(playersService:GetPlayers()) do
				if bed:GetAttribute("Team"..(v:GetAttribute("Team") or 0).."NoBreak") and not ({whitelist:get(v)})[2] then
					return true
				end
			end
		end
		return false
	end

	local function dumpRemote(tab)
		for i,v in pairs(tab) do
			if v == "Client" then
				return tab[i + 1]
			end
		end
		return ""
	end

	local KnitGotten, KnitClient
	repeat
		KnitGotten, KnitClient = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 6)
		end)
		if KnitGotten then break end
		task.wait()
	until KnitGotten
	repeat task.wait() until debug.getupvalue(KnitClient.Start, 1)
	local Flamework = require(replicatedStorage["rbxts_include"]["node_modules"]["@flamework"].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local InventoryUtil = require(replicatedStorage.TS.inventory["inventory-util"]).InventoryUtil
	local OldGet = getmetatable(Client).Get
	local OldBreak

	bedwars = setmetatable({
		AnimationType = require(replicatedStorage.TS.animation["animation-type"]).AnimationType,
		AnimationUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].util["animation-util"]).AnimationUtil,
		AppController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.controllers["app-controller"]).AppController,
		AbilityController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController"),
		AbilityUIController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-ui-controller@AbilityUIController"),
		AttackRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.SwordController.sendServerRequest)),
		BalanceFile = require(replicatedStorage.TS.balance["balance-file"]).BalanceFile,
		BatteryRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BatteryController.KnitStart, 1), 1))),
		BlockBreaker = KnitClient.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out).BlockEngine,
		BlockPlacer = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer,
		BlockEngine = require(lplr.PlayerScripts.TS.lib["block-engine"]["client-block-engine"]).ClientBlockEngine,
		BlockEngineClientEvents = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client["block-engine-client-events"]).BlockEngineClientEvents,
		BowConstantsTable = debug.getupvalue(KnitClient.Controllers.ProjectileController.enableBeam, 6),
		CannonAimRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.CannonController.startAiming, 5))),
		CannonLaunchRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.CannonHandController.launchSelf)),
		ClickHold = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.ui.lib.util["click-hold"]).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"].net.out.client),
		ClientDamageBlock = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.shared.remotes).BlockEngineRemotes.Client,
		ClientStoreHandler = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		CombatConstant = require(replicatedStorage.TS.combat["combat-constant"]).CombatConstant,
		ConstantManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].constant["constant-manager"]).ConstantManager,
		ConsumeSoulRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GrimReaperController.consumeSoul)),
		CooldownController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/cooldown/cooldown-controller@CooldownController"),
		DamageIndicator = KnitClient.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.game.locker["kill-effect"].effects["default-kill-effect"]),
		DropItem = KnitClient.Controllers.ItemDropController.dropItemInHand,
		DropItemRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.dropItemInHand)),
		DragonRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.DragonSlayerController.KnitStart, 2), 1))),
		EatRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ConsumeController.onEnable, 1))),
		EquipItemRemote = dumpRemote(debug.getconstants(debug.getproto(require(replicatedStorage.TS.entity.entities["inventory-entity"]).InventoryEntity.equipItem, 3))),
		EmoteMeta = require(replicatedStorage.TS.locker.emote["emote-meta"]).EmoteMeta,
		ForgeConstants = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 2),
		ForgeUtil = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 5),
		GameAnimationUtil = require(replicatedStorage.TS.animation["animation-util"]).GameAnimationUtil,
		EntityUtil = require(replicatedStorage.TS.entity["entity-util"]).EntityUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemTable[item.itemType]
			if itemmeta and showinv then
				return itemmeta.image or ""
			end
			return ""
		end,
		getInventory = function(plr)
			local suc, result = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return (suc and result or {
				items = {},
				armor = {},
				hand = nil
			})
		end,
		GuitarHealRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GuitarController.performHeal)),
		ItemTable = debug.getupvalue(require(replicatedStorage.TS.item["item-meta"]).getItemMeta, 1),
		KillEffectMeta = require(replicatedStorage.TS.locker["kill-effect"]["kill-effect-meta"]).KillEffectMeta,
		KnockbackUtil = require(replicatedStorage.TS.damage["knockback-util"]).KnockbackUtil,
		MatchEndScreenController = Flamework.resolveDependency("client/controllers/game/match/match-end-screen-controller@MatchEndScreenController"),
		MageRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.MageController.registerTomeInteraction, 1))),
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage["mage-kit-util"]).MageKitUtil,
		PickupMetalRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.MetalDetectorController.KnitStart, 1), 2))),
		PickupRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.checkForPickup)),
		--PinataRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.PiggyBankController.KnitStart, 2), 5))),
		PinataRemote = '',
		ProjectileMeta = require(replicatedStorage.TS.projectile["projectile-meta"]).ProjectileMeta,
		ProjectileRemote = dumpRemote(debug.getconstants(debug.getupvalue(KnitClient.Controllers.ProjectileController.launchProjectileWithValues, 2))),
		QueryUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui["queue-card"]).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game["queue-meta"]).QueueMeta,
		ReportRemote = dumpRemote(debug.getconstants(require(lplr.PlayerScripts.TS.controllers.global.report["report-controller"]).default.reportPlayer)),
		ResetRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ResetController.createBindable, 1))),
		Roact = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"]["roact"].src),
		RuntimeLib = require(replicatedStorage["rbxts_include"].RuntimeLib),
		Shop = require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop,
		ShopItems = debug.getupvalue(debug.getupvalue(require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop.getShopItem, 1), 3),
		SoundList = require(replicatedStorage.TS.sound["game-sound"]).GameSound,
		SoundManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).SoundManager,
		SpawnRavenRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.RavenController.spawnRaven)),
		TreeRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BigmanController.KnitStart, 1), 2))),
		TrinityRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.AngelController.onKitEnabled, 1))),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		WeldTable = require(replicatedStorage.TS.util["weld-util"]).WeldUtil
	}, {
		__index = function(self, ind)
			rawset(self, ind, KnitClient.Controllers[ind])
			return rawget(self, ind)
		end
	})
	OldBreak = bedwars.BlockController.isBlockBreakable

	getmetatable(Client).Get = function(self, remoteName)
		if not vapeInjected then return OldGet(self, remoteName) end
		local originalRemote = OldGet(self, remoteName)
		if remoteName == bedwars.AttackRemote then
			return {
				instance = originalRemote.instance,
				SendToServer = function(self, attackTable, ...)
					local suc, plr = pcall(function() return playersService:GetPlayerFromCharacter(attackTable.entityInstance) end)
					if suc and plr then
						if not ({whitelist:get(plr)})[2] then return end
						if Reach.Enabled then
							local attackMagnitude = ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - attackTable.validate.targetPosition.value).magnitude
							if attackMagnitude > 18 then
								return nil
							end
							attackTable.validate.selfPosition = attackValue(attackTable.validate.selfPosition.value + (attackMagnitude > 14.4 and (CFrame.lookAt(attackTable.validate.selfPosition.value, attackTable.validate.targetPosition.value).lookVector * 4) or Vector3.zero))
						end
						store.attackReach = math.floor((attackTable.validate.selfPosition.value - attackTable.validate.targetPosition.value).magnitude * 100) / 100
						store.attackReachUpdate = tick() + 1
					end
					return originalRemote:SendToServer(attackTable, ...)
				end
			}
		end
		return originalRemote
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)
		if isWhitelistedBed(obj) then return false end
		return OldBreak(self, breakTable, plr)
	end

	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, "wool_white")
	bedwars.placeBlock = function(speedCFrame, customblock)
		if getItem(customblock) then
			store.blockPlacer.blockType = customblock
			return store.blockPlacer:placeBlock(Vector3.new(speedCFrame.X / 3, speedCFrame.Y / 3, speedCFrame.Z / 3))
		end
	end

	local healthbarblocktable = {
		blockHealth = -1,
		breakingBlockPosition = Vector3.zero
	}

	local failedBreak = 0
	bedwars.breakBlock = function(pos, effects, normal, bypass, anim)
		if GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
			return
		end
		if lplr:GetAttribute("DenyBlockBreak") then
			return
		end
		local block, blockpos = nil, nil
		if not bypass then block, blockpos = getLastCovered(pos, normal) end
		if not block then block, blockpos = getPlacedBlock(pos) end
		if blockpos and block then
			if bedwars.BlockEngineClientEvents.DamageBlock:fire(block.Name, blockpos, block):isCancelled() then
				return
			end
			local blockhealthbarpos = {blockPosition = Vector3.zero}
			local blockdmg = 0
			if block and block.Parent ~= nil then
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - (blockpos * 3)).magnitude > 30 then return end
				store.blockPlace = tick() + 0.1
				switchToAndUseTool(block)
				blockhealthbarpos = {
					blockPosition = blockpos
				}
				task.spawn(function()
					bedwars.ClientDamageBlock:Get("DamageBlock"):CallServerAsync({
						blockRef = blockhealthbarpos,
						hitPosition = blockpos * 3,
						hitNormal = Vector3.FromNormalId(normal)
					}):andThen(function(result)
						if result ~= "failed" then
							failedBreak = 0
							if healthbarblocktable.blockHealth == -1 or blockhealthbarpos.blockPosition ~= healthbarblocktable.breakingBlockPosition then
								local blockdata = bedwars.BlockController:getStore():getBlockData(blockhealthbarpos.blockPosition)
								local blockhealth = blockdata and (blockdata:GetAttribute("Health") or blockdata:GetAttribute(lplr.Name .. "_Health")) or block:GetAttribute("Health")
								healthbarblocktable.blockHealth = blockhealth
								healthbarblocktable.breakingBlockPosition = blockhealthbarpos.blockPosition
							end
							healthbarblocktable.blockHealth = result == "destroyed" and 0 or healthbarblocktable.blockHealth
							blockdmg = bedwars.BlockController:calculateBlockDamage(lplr, blockhealthbarpos)
							healthbarblocktable.blockHealth = math.max(healthbarblocktable.blockHealth - blockdmg, 0)
							if effects then
								bedwars.BlockBreaker:updateHealthbar(blockhealthbarpos, healthbarblocktable.blockHealth, block:GetAttribute("MaxHealth"), blockdmg, block)
								if healthbarblocktable.blockHealth <= 0 then
									bedwars.BlockBreaker.breakEffect:playBreak(block.Name, blockhealthbarpos.blockPosition, lplr)
									bedwars.BlockBreaker.healthbarMaid:DoCleaning()
									healthbarblocktable.breakingBlockPosition = Vector3.zero
								else
									bedwars.BlockBreaker.breakEffect:playHit(block.Name, blockhealthbarpos.blockPosition, lplr)
								end
							end
							local animation
							if anim then
								animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
								bedwars.ViewmodelController:playAnimation(15)
							end
							task.wait(0.3)
							if animation ~= nil then
								animation:Stop()
								animation:Destroy()
							end
						else
							failedBreak = failedBreak + 1
						end
					end)
				end)
				task.wait(physicsUpdate)
			end
		end
	end

	local function updateStore(newStore, oldStore)
		if newStore.Game ~= oldStore.Game then
			store.matchState = newStore.Game.matchState
			store.queueType = newStore.Game.queueType or "bedwars_test"
			store.forgeMasteryPoints = newStore.Game.forgeMasteryPoints
			store.forgeUpgrades = newStore.Game.forgeUpgrades
		end
		if newStore.Bedwars ~= oldStore.Bedwars then
			store.equippedKit = newStore.Bedwars.kit ~= "none" and newStore.Bedwars.kit or ""
		end
		if newStore.Inventory ~= oldStore.Inventory then
			local newInventory = (newStore.Inventory and newStore.Inventory.observedInventory or {inventory = {}})
			local oldInventory = (oldStore.Inventory and oldStore.Inventory.observedInventory or {inventory = {}})
			store.localInventory = newStore.Inventory.observedInventory
			if newInventory ~= oldInventory then
				vapeEvents.InventoryChanged:Fire()
			end
			if newInventory.inventory.items ~= oldInventory.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
			end
			if newInventory.inventory.hand ~= oldInventory.inventory.hand then
				local currentHand = newStore.Inventory.observedInventory.inventory.hand
				local handType = ""
				if currentHand then
					local handData = bedwars.ItemTable[currentHand.itemType]
					handType = handData.sword and "sword" or handData.block and "block" or currentHand.itemType:find("bow") and "bow"
				end
				store.localHand = {tool = currentHand and currentHand.tool, Type = handType, amount = currentHand and currentHand.amount or 0}
			end
		end
	end

	table.insert(vapeConnections, bedwars.ClientStoreHandler.changed:connect(updateStore))
	updateStore(bedwars.ClientStoreHandler:getState(), {})

	for i, v in pairs({"MatchEndEvent", "EntityDeathEvent", "EntityDamageEvent", "BedwarsBedBreak", "BalloonPopped", "AngelProgress"}) do
		bedwars.Client:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end
	for i, v in pairs({"PlaceBlockEvent", "BreakBlockEvent"}) do
		bedwars.ClientDamageBlock:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end

	store.blocks = collectionService:GetTagged("block")
	store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("block"):Connect(function(block)
		table.insert(store.blocks, block)
		store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(block)
		block = table.find(store.blocks, block)
		if block then
			table.remove(store.blocks, block)
			store.blockRaycast.FilterDescendantsInstances = {store.blocks}
		end
	end))
	for _, ent in pairs(collectionService:GetTagged("entity")) do
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("entity"):Connect(function(ent)
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("entity"):Connect(function(ent)
		ent = table.find(store.pots, ent)
		if ent then
			table.remove(store.pots, ent)
		end
	end))

	local oldZephyrUpdate = bedwars.WindWalkerController.updateJump
	bedwars.WindWalkerController.updateJump = function(self, orb, ...)
		store.zephyrOrb = lplr.Character and lplr.Character:GetAttribute("Health") > 0 and orb or 0
		return oldZephyrUpdate(self, orb, ...)
	end

	GuiLibrary.SelfDestructEvent.Event:Connect(function()
		bedwars.WindWalkerController.updateJump = oldZephyrUpdate
		getmetatable(bedwars.Client).Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
	end)

	local teleportedServers = false
	table.insert(vapeConnections, lplr.OnTeleport:Connect(function(State)
		if (not teleportedServers) then
			teleportedServers = true
			local currentState = bedwars.ClientStoreHandler and bedwars.ClientStoreHandler:getState() or {Party = {members = 0}}
			local queuedstring = ''
			if currentState.Party and currentState.Party.members and #currentState.Party.members > 0 then
				queuedstring = queuedstring..'shared.vapeteammembers = '..#currentState.Party.members..'\n'
			end
			if store.TPString then
				queuedstring = queuedstring..'shared.vapeoverlay = "'..store.TPString..'"\n'
			end
			queueonteleport(queuedstring)
		end
	end))
end)

do
	entityLibrary.animationCache = {}
	entityLibrary.groundTick = tick()
	entityLibrary.selfDestruct()
	entityLibrary.isPlayerTargetable = function(plr)
		return lplr:GetAttribute("Team") ~= plr:GetAttribute("Team") and not isFriend(plr) and ({whitelist:get(plr)})[2]
	end
	entityLibrary.characterAdded = function(plr, char, localcheck)
		local id = game:GetService("HttpService"):GenerateGUID(true)
		entityLibrary.entityIds[plr.Name] = id
		if char then
			task.spawn(function()
				local humrootpart = char:WaitForChild("HumanoidRootPart", 10)
				local head = char:WaitForChild("Head", 10)
				local hum = char:WaitForChild("Humanoid", 10)
				if entityLibrary.entityIds[plr.Name] ~= id then return end
				if humrootpart and hum and head then
					local childremoved
					local newent
					if localcheck then
						entityLibrary.isAlive = true
						entityLibrary.character.Head = head
						entityLibrary.character.Humanoid = hum
						entityLibrary.character.HumanoidRootPart = humrootpart
						table.insert(entityLibrary.entityConnections, char.AttributeChanged:Connect(function(...)
							vapeEvents.AttributeChanged:Fire(...)
						end))
					else
						newent = {
							Player = plr,
							Character = char,
							HumanoidRootPart = humrootpart,
							RootPart = humrootpart,
							Head = head,
							Humanoid = hum,
							Targetable = entityLibrary.isPlayerTargetable(plr),
							Team = plr.Team,
							Connections = {},
							Jumping = false,
							Jumps = 0,
							JumpTick = tick()
						}
						local inv = char:WaitForChild("InventoryFolder", 5)
						if inv then
							local armorobj1 = char:WaitForChild("ArmorInvItem_0", 5)
							local armorobj2 = char:WaitForChild("ArmorInvItem_1", 5)
							local armorobj3 = char:WaitForChild("ArmorInvItem_2", 5)
							local handobj = char:WaitForChild("HandInvItem", 5)
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							if armorobj1 then
								table.insert(newent.Connections, armorobj1.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj2 then
								table.insert(newent.Connections, armorobj2.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj3 then
								table.insert(newent.Connections, armorobj3.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if handobj then
								table.insert(newent.Connections, handobj.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
						end
						if entityLibrary.entityIds[plr.Name] ~= id then return end
						task.delay(0.3, function()
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							store.inventories[plr] = bedwars.getInventory(plr)
							entityLibrary.entityUpdatedEvent:Fire(newent)
						end)
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("Health"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum.AnimationPlayed:Connect(function(state)
							local animnum = tonumber(({state.Animation.AnimationId:gsub("%D+", "")})[1])
							if animnum then
								if not entityLibrary.animationCache[state.Animation.AnimationId] then
									entityLibrary.animationCache[state.Animation.AnimationId] = game:GetService("MarketplaceService"):GetProductInfo(animnum)
								end
								if entityLibrary.animationCache[state.Animation.AnimationId].Name:lower():find("jump") then
									newent.Jumps = newent.Jumps + 1
								end
							end
						end))
						table.insert(newent.Connections, char.AttributeChanged:Connect(function(attr) if attr:find("Shield") then entityLibrary.entityUpdatedEvent:Fire(newent) end end))
						table.insert(entityLibrary.entityList, newent)
						entityLibrary.entityAddedEvent:Fire(newent)
					end
					if entityLibrary.entityIds[plr.Name] ~= id then return end
					childremoved = char.ChildRemoved:Connect(function(part)
						if part.Name == "HumanoidRootPart" or part.Name == "Head" or part.Name == "Humanoid" then
							if localcheck then
								if char == lplr.Character then
									if part.Name == "HumanoidRootPart" then
										entityLibrary.isAlive = false
										local root = char:FindFirstChild("HumanoidRootPart")
										if not root then
											root = char:WaitForChild("HumanoidRootPart", 3)
										end
										if root then
											entityLibrary.character.HumanoidRootPart = root
											entityLibrary.isAlive = true
										end
									else
										entityLibrary.isAlive = false
									end
								end
							else
								childremoved:Disconnect()
								entityLibrary.removeEntity(plr)
							end
						end
					end)
					if newent then
						table.insert(newent.Connections, childremoved)
					end
					table.insert(entityLibrary.entityConnections, childremoved)
				end
			end)
		end
	end
	entityLibrary.entityAdded = function(plr, localcheck, custom)
		table.insert(entityLibrary.entityConnections, plr:GetPropertyChangedSignal("Character"):Connect(function()
			if plr.Character then
				entityLibrary.refreshEntity(plr, localcheck)
			else
				if localcheck then
					entityLibrary.isAlive = false
				else
					entityLibrary.removeEntity(plr)
				end
			end
		end))
		table.insert(entityLibrary.entityConnections, plr:GetAttributeChangedSignal("Team"):Connect(function()
			local tab = {}
			for i,v in next, entityLibrary.entityList do
				if v.Targetable ~= entityLibrary.isPlayerTargetable(v.Player) then
					table.insert(tab, v)
				end
			end
			for i,v in next, tab do
				entityLibrary.refreshEntity(v.Player)
			end
			if localcheck then
				entityLibrary.fullEntityRefresh()
			else
				entityLibrary.refreshEntity(plr, localcheck)
			end
		end))
		if plr.Character then
			task.spawn(entityLibrary.refreshEntity, plr, localcheck)
		end
	end
	entityLibrary.fullEntityRefresh()
	task.spawn(function()
		repeat
			task.wait()
			if entityLibrary.isAlive then
				entityLibrary.groundTick = entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entityLibrary.groundTick
			end
			for i,v in pairs(entityLibrary.entityList) do
				local state = v.Humanoid:GetState()
				v.JumpTick = (state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Landed) and tick() or v.JumpTick
				v.Jumping = (tick() - v.JumpTick) < 0.2 and v.Jumps > 1
				if (tick() - v.JumpTick) > 0.2 then
					v.Jumps = 0
				end
			end
		until not vapeInjected
	end)
	local textlabel = Instance.new("TextLabel")
	textlabel.Size = UDim2.new(1, 0, 0, 36)
	textlabel.Text = "hello :D - placeholder"
	textlabel.BackgroundTransparency = 1
	textlabel.ZIndex = 10
	textlabel.TextStrokeTransparency = 0
	textlabel.TextScaled = true
	textlabel.Font = Enum.Font.SourceSans
	textlabel.TextColor3 = Color3.new(1, 1, 1)
	textlabel.Position = UDim2.new(0, 0, 1, -36)
	textlabel.Parent = GuiLibrary.MainGui.ScaledGui.ClickGui
end

run(function()
	local handsquare = Instance.new("ImageLabel")
	handsquare.Size = UDim2.new(0, 26, 0, 27)
	handsquare.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	handsquare.Position = UDim2.new(0, 72, 0, 44)
	handsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local handround = Instance.new("UICorner")
	handround.CornerRadius = UDim.new(0, 4)
	handround.Parent = handsquare
	local helmetsquare = handsquare:Clone()
	helmetsquare.Position = UDim2.new(0, 100, 0, 44)
	helmetsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local chestplatesquare = handsquare:Clone()
	chestplatesquare.Position = UDim2.new(0, 127, 0, 44)
	chestplatesquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local bootssquare = handsquare:Clone()
	bootssquare.Position = UDim2.new(0, 155, 0, 44)
	bootssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local uselesssquare = handsquare:Clone()
	uselesssquare.Position = UDim2.new(0, 182, 0, 44)
	uselesssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local oldupdate = vapeTargetInfo.UpdateInfo
	vapeTargetInfo.UpdateInfo = function(tab, targetsize)
		local bkgcheck = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo.BackgroundTransparency == 1
		handsquare.BackgroundTransparency = bkgcheck and 1 or 0
		helmetsquare.BackgroundTransparency = bkgcheck and 1 or 0
		chestplatesquare.BackgroundTransparency = bkgcheck and 1 or 0
		bootssquare.BackgroundTransparency = bkgcheck and 1 or 0
		uselesssquare.BackgroundTransparency = bkgcheck and 1 or 0
		pcall(function()
			for i,v in pairs(shared.VapeTargetInfo.Targets) do
				local inventory = store.inventories[v.Player] or {}
					if inventory.hand then
						handsquare.Image = bedwars.getIcon(inventory.hand, true)
					else
						handsquare.Image = ""
					end
					if inventory.armor[4] then
						helmetsquare.Image = bedwars.getIcon(inventory.armor[4], true)
					else
						helmetsquare.Image = ""
					end
					if inventory.armor[5] then
						chestplatesquare.Image = bedwars.getIcon(inventory.armor[5], true)
					else
						chestplatesquare.Image = ""
					end
					if inventory.armor[6] then
						bootssquare.Image = bedwars.getIcon(inventory.armor[6], true)
					else
						bootssquare.Image = ""
					end
				break
			end
		end)
		return oldupdate(tab, targetsize)
	end
end)

GuiLibrary.RemoveObject("SilentAimOptionsButton")
GuiLibrary.RemoveObject("ReachOptionsButton")
GuiLibrary.RemoveObject("MouseTPOptionsButton")
GuiLibrary.RemoveObject("PhaseOptionsButton")
GuiLibrary.RemoveObject("AutoClickerOptionsButton")
GuiLibrary.RemoveObject("SpiderOptionsButton")
GuiLibrary.RemoveObject("LongJumpOptionsButton")
GuiLibrary.RemoveObject("HitBoxesOptionsButton")
GuiLibrary.RemoveObject("KillauraOptionsButton")
GuiLibrary.RemoveObject("TriggerBotOptionsButton")
GuiLibrary.RemoveObject("AutoLeaveOptionsButton")
GuiLibrary.RemoveObject("SpeedOptionsButton")
GuiLibrary.RemoveObject("FlyOptionsButton")
GuiLibrary.RemoveObject("ClientKickDisablerOptionsButton")
GuiLibrary.RemoveObject("NameTagsOptionsButton")
GuiLibrary.RemoveObject("SafeWalkOptionsButton")
GuiLibrary.RemoveObject("BlinkOptionsButton")
GuiLibrary.RemoveObject("FOVChangerOptionsButton")
GuiLibrary.RemoveObject("AntiVoidOptionsButton")
GuiLibrary.RemoveObject("SongBeatsOptionsButton")
GuiLibrary.RemoveObject("TargetStrafeOptionsButton")

run(function()
	local AimAssist = {Enabled = false}
	local AimAssistClickAim = {Enabled = false}
	local AimAssistStrafe = {Enabled = false}
	local AimSpeed = {Value = 1}
	local AimAssistTargetFrame = {Players = {Enabled = false}}
	AimAssist = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AimAssist",
		Function = function(callback)
			if callback then
				RunLoops:BindToRenderStep("AimAssist", function(dt)
					vapeTargetInfo.Targets.AimAssist = nil
					if ((not AimAssistClickAim.Enabled) or (tick() - bedwars.SwordController.lastSwing) < 0.4) then
						local plr = EntityNearPosition(18)
						if plr then
							vapeTargetInfo.Targets.AimAssist = {
								Humanoid = {
									Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
									MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
								},
								Player = plr.Player
							}
							if store.localHand.Type == "sword" then
								if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
									if store.matchState == 0 then return end
								end
								if AimAssistTargetFrame.Walls.Enabled then
									if not bedwars.SwordController:canSee({instance = plr.Character, player = plr.Player, getInstance = function() return plr.Character end}) then return end
								end
								gameCamera.CFrame = gameCamera.CFrame:lerp(CFrame.new(gameCamera.CFrame.p, plr.Character.HumanoidRootPart.Position), ((1 / AimSpeed.Value) + (AimAssistStrafe.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 0.01 or 0)))
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromRenderStep("AimAssist")
				vapeTargetInfo.Targets.AimAssist = nil
			end
		end,
		HoverText = "Smoothly aims to closest valid target with sword"
	})
	AimAssistTargetFrame = AimAssist.CreateTargetWindow({Default3 = true})
	AimAssistClickAim = AimAssist.CreateToggle({
		Name = "Click Aim",
		Function = function() end,
		Default = true,
		HoverText = "Only aim while mouse is down"
	})
	AimAssistStrafe = AimAssist.CreateToggle({
		Name = "Strafe increase",
		Function = function() end,
		HoverText = "Increase speed while strafing away from target"
	})
	AimSpeed = AimAssist.CreateSlider({
		Name = "Smoothness",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 50
	})
end)

run(function()
	local autoclicker = {Enabled = false}
	local noclickdelay = {Enabled = false}
	local autoclickercps = {GetRandomValue = function() return 1 end}
	local autoclickerblocks = {Enabled = false}
	local AutoClickerThread

	local function isNotHoveringOverGui()
		local mousepos = inputService:GetMouseLocation() - Vector2.new(0, 36)
		for i,v in pairs(lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Active then
				return false
			end
		end
		for i,v in pairs(game:GetService("CoreGui"):GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Parent:IsA("ScreenGui") and v.Parent.Enabled then
				if v.Active then
					return false
				end
			end
		end
		return true
	end

	local function AutoClick()
		local firstClick = tick() + 0.1
		AutoClickerThread = task.spawn(function()
			repeat
				task.wait()
				if entityLibrary.isAlive then
					if not autoclicker.Enabled then break end
					if not isNotHoveringOverGui() then continue end
					if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then continue end
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then continue end
					end
					if store.localHand.Type == "sword" then
						if bedwars.DaoController.chargingMaid == nil then
							task.spawn(function()
								if firstClick <= tick() then
									bedwars.SwordController:swingSwordAtMouse()
								else
									firstClick = tick()
								end
							end)
							task.wait(math.max((1 / autoclickercps.GetRandomValue()), noclickdelay.Enabled and 0 or 0.142))
						end
					elseif store.localHand.Type == "block" then
						if autoclickerblocks.Enabled and bedwars.BlockPlacementController.blockPlacer and firstClick <= tick() then
							if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) > ((1 / 12) * 0.5) then
								local mouseinfo = bedwars.BlockPlacementController.blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
								if mouseinfo then
									task.spawn(function()
										if mouseinfo.placementPosition == mouseinfo.placementPosition then
											bedwars.BlockPlacementController.blockPlacer:placeBlock(mouseinfo.placementPosition)
										end
									end)
								end
								task.wait((1 / autoclickercps.GetRandomValue()))
							end
						end
					end
				end
			until not autoclicker.Enabled
		end)
	end

	autoclicker = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AutoClicker",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Down:Connect(AutoClick))
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Up:Connect(function()
							if AutoClickerThread then
								task.cancel(AutoClickerThread)
								AutoClickerThread = nil
							end
						end))
					end)
				end
				table.insert(autoclicker.Connections, inputService.InputBegan:Connect(function(input, gameProcessed)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then AutoClick() end
				end))
				table.insert(autoclicker.Connections, inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and AutoClickerThread then
						task.cancel(AutoClickerThread)
						AutoClickerThread = nil
					end
				end))
			end
		end,
		HoverText = "Hold attack button to automatically click"
	})
	autoclickercps = autoclicker.CreateTwoSlider({
		Name = "CPS",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 8,
		Default2 = 12
	})
	autoclickerblocks = autoclicker.CreateToggle({
		Name = "Place Blocks",
		Function = function() end,
		Default = true,
		HoverText = "Automatically places blocks when left click is held."
	})

	local noclickfunc
	noclickdelay = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "NoClickDelay",
		Function = function(callback)
			if callback then
				noclickfunc = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
					self.lastSwing = tick()
					return false
				end
			else
				bedwars.SwordController.isClickingTooFast = noclickfunc
			end
		end,
		HoverText = "Remove the CPS cap"
	})
end)

run(function()
	local ReachValue = {Value = 14}

	Reach = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Reach",
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and ReachValue.Value + 2 or 14.4
		end,
		HoverText = "Extends attack reach"
	})
	ReachValue = Reach.CreateSlider({
		Name = "Reach",
		Min = 0,
		Max = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Default = 18
	})
end)

run(function()
	local Sprint = {Enabled = false}
	local oldSprintFunction
	Sprint = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Sprint",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = false end)
				end
				oldSprintFunction = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local originalCall = oldSprintFunction(...)
					bedwars.SprintController:startSprinting()
					return originalCall
				end
				table.insert(Sprint.Connections, lplr.CharacterAdded:Connect(function(char)
					char:WaitForChild("Humanoid", 9e9)
					task.wait(0.5)
					bedwars.SprintController:stopSprinting()
				end))
				task.spawn(function()
					bedwars.SprintController:startSprinting()
				end)
			else
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = true end)
				end
				bedwars.SprintController.stopSprinting = oldSprintFunction
				bedwars.SprintController:stopSprinting()
			end
		end,
		HoverText = "Sets your sprinting to true."
	})
end)


run(function() 
	local MelodyGodmode = {Enabled = true}

	MelodyGodmode = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({ 
		Name = "MelodyGodmode",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("melody",function()
					if getItem("guitar") then
						if lplr.Character.Humanoid.Health < lplr.Character.Humanoid.MaxHealth then
							bedwars.Client:Get(bedwars.GuitarHealRemote):SendToServer({healTarget = lplr})
							game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("StopPlayingGuitar"):FireServer()
						else
							game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("StopPlayingGuitar"):FireServer()
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("melody")
			end
		end
	})
end)

run(function()
	local Velocity = {Enabled = false}
	local VelocityHorizontal = {Value = 100}
	local VelocityVertical = {Value = 100}
	local applyKnockback
	Velocity = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Velocity",
		Function = function(callback)
			if callback then
				applyKnockback = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					knockback = knockback or {}
					if VelocityHorizontal.Value == 0 and VelocityVertical.Value == 0 then return end
					knockback.horizontal = (knockback.horizontal or 1) * (VelocityHorizontal.Value / 100)
					knockback.vertical = (knockback.vertical or 1) * (VelocityVertical.Value / 100)
					return applyKnockback(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = applyKnockback
			end
		end,
		HoverText = "Reduces knockback taken"
	})
	VelocityHorizontal = Velocity.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
	VelocityVertical = Velocity.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
end)

run(function()
	local AutoLeaveDelay = {Value = 1}
	local AutoPlayAgain = {Enabled = false}
	local AutoLeaveStaff = {Enabled = true}
	local AutoLeaveStaff2 = {Enabled = true}
	local AutoLeaveRandom = {Enabled = false}
	local leaveAttempted = false

	local function getRole(plr)
		local suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
		if not suc then
			repeat
				suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
				task.wait()
			until suc
		end
		if plr.UserId == 1774814725 then
			return 200
		end
		return res
	end

	local flyAllowedmodules = {"Sprint", "AutoClicker", "AutoReport", "AutoReportV2", "AutoRelic", "AimAssist", "AutoLeave", "Reach"}
	local function autoLeaveAdded(plr)
		task.spawn(function()
			if not shared.VapeFullyLoaded then
				repeat task.wait() until shared.VapeFullyLoaded
			end
			if getRole(plr) >= 100 then
				if AutoLeaveStaff.Enabled then
					if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
						bedwars.QueueController.leaveParty()
					end
					if AutoLeaveStaff2.Enabled then
						warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name).." : Play legit like nothing happened to have the highest chance of not getting banned.", 60)
						GuiLibrary.SaveSettings = function() end
						for i,v in pairs(GuiLibrary.ObjectsThatCanBeSaved) do
							if v.Type == "OptionsButton" then
								if table.find(flyAllowedmodules, i:gsub("OptionsButton", "")) == nil and tostring(v.Object.Parent.Parent):find("Render") == nil then
									if v.Api.Enabled then
										v.Api.ToggleButton(false)
									end
									v.Api.SetKeybind("")
									v.Object.TextButton.Visible = false
								end
							end
						end
					else
						GuiLibrary.SelfDestruct()
						game:GetService("StarterGui"):SetCore("SendNotification", {
							Title = "Vape",
							Text = "Staff Detected\n"..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name),
							Duration = 60,
						})
					end
					return
				else
					warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name), 60)
				end
			end
		end)
	end

	local function isEveryoneDead()
		if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
			for i,v in pairs(bedwars.ClientStoreHandler:getState().Party.members) do
				local plr = playersService:FindFirstChild(v.name)
				if plr and isAlive(plr, true) then
					return false
				end
			end
			return true
		else
			return true
		end
	end

	AutoLeave = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "AutoLeave",
		Function = function(callback)
			if callback then
				table.insert(AutoLeave.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if (not leaveAttempted) and deathTable.finalKill and deathTable.entityInstance == lplr.Character then
						leaveAttempted = true
						if isEveryoneDead() and store.matchState ~= 2 then
							task.wait(1 + (AutoLeaveDelay.Value / 10))
							if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
								if not AutoPlayAgain.Enabled then
									bedwars.Client:Get("TeleportToLobby"):SendToServer()
								else
									if AutoLeaveRandom.Enabled then
										local listofmodes = {}
										for i,v in pairs(bedwars.QueueMeta) do
											if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
										end
										bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
									else
										bedwars.QueueController:joinQueue(store.queueType)
									end
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(deathTable)
					task.wait(AutoLeaveDelay.Value / 10)
					if not AutoLeave.Enabled then return end
					if leaveAttempted then return end
					leaveAttempted = true
					if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
						if not AutoPlayAgain.Enabled then
							bedwars.Client:Get("TeleportToLobby"):SendToServer()
						else
							if bedwars.ClientStoreHandler:getState().Party.queueState == 0 then
								if AutoLeaveRandom.Enabled then
									local listofmodes = {}
									for i,v in pairs(bedwars.QueueMeta) do
										if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
									end
									bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
								else
									bedwars.QueueController:joinQueue(store.queueType)
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, playersService.PlayerAdded:Connect(autoLeaveAdded))
				for i, plr in pairs(playersService:GetPlayers()) do
					autoLeaveAdded(plr)
				end
			end
		end,
		HoverText = "Leaves if a staff member joins your game or when the match ends."
	})
	AutoLeaveDelay = AutoLeave.CreateSlider({
		Name = "Delay",
		Min = 0,
		Max = 50,
		Default = 0,
		Function = function() end,
		HoverText = "Delay before going back to the hub."
	})
	AutoPlayAgain = AutoLeave.CreateToggle({
		Name = "Play Again",
		Function = function() end,
		HoverText = "Automatically queues a new game.",
		Default = true
	})
	AutoLeaveStaff = AutoLeave.CreateToggle({
		Name = "Staff",
		Function = function(callback)
			if AutoLeaveStaff2.Object then
				AutoLeaveStaff2.Object.Visible = callback
			end
		end,
		HoverText = "Automatically uninjects when staff joins",
		Default = true
	})
	AutoLeaveStaff2 = AutoLeave.CreateToggle({
		Name = "Staff AutoConfig",
		Function = function() end,
		HoverText = "Instead of uninjecting, It will now reconfig vape temporarily to a more legit config.",
		Default = true
	})
	AutoLeaveRandom = AutoLeave.CreateToggle({
		Name = "Random",
		Function = function(callback) end,
		HoverText = "Chooses a random mode"
	})
	AutoLeaveStaff2.Object.Visible = false
end)

run(function()
	local oldclickhold
	local oldclickhold2
	local roact
	local FastConsume = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "FastConsume",
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldclickhold2 = bedwars.ClickHold.showProgress
				bedwars.ClickHold.showProgress = function(p5)
					local roact = debug.getupvalue(oldclickhold2, 1)
					local countdown = roact.mount(roact.createElement("ScreenGui", {}, { roact.createElement("Frame", {
						[roact.Ref] = p5.wrapperRef,
						Size = UDim2.new(0, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 0.55, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement("Frame", {
							[roact.Ref] = p5.progressRef,
							Size = UDim2.new(0, 0, 1, 0),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.5
						}) }) }), lplr:FindFirstChild("PlayerGui"))
					p5.handle = countdown
					local sizetween = tweenService:Create(p5.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.new(0.11, 0, 0.005, 0)
					})
					table.insert(p5.tweens, sizetween)
					sizetween:Play()
					local countdowntween = tweenService:Create(p5.progressRef:getValue(), TweenInfo.new(p5.durationSeconds * (FastConsumeVal.Value / 40), Enum.EasingStyle.Linear), {
						Size = UDim2.new(1, 0, 1, 0)
					})
					table.insert(p5.tweens, countdowntween)
					countdowntween:Play()
					return countdown
				end
				bedwars.ClickHold.startClick = function(p4)
					p4.startedClickTime = tick()
					local u2 = p4:showProgress()
					local clicktime = p4.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(p4.durationSeconds * (FastConsumeVal.Value / 40))
						if u2 == p4.handle and clicktime == p4.startedClickTime and p4.closeOnComplete then
							p4:hideProgress()
							if p4.onComplete ~= nil then
								p4.onComplete()
							end
							if p4.onPartialComplete ~= nil then
								p4.onPartialComplete(1)
							end
							p4.startedClickTime = -1
						end
					end)
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldclickhold2
				oldclickhold = nil
				oldclickhold2 = nil
			end
		end,
		HoverText = "Use/Consume items quicker."
	})
	FastConsumeVal = FastConsume.CreateSlider({
		Name = "Ticks",
		Min = 0,
		Max = 40,
		Default = 0,
		Function = function() end
	})
end)

local autobankballoon = false
run(function()
	local Fly = {Enabled = false}
	local FlyMode = {Value = "CFrame"}
	local FlyVerticalSpeed = {Value = 40}
	local FlyVertical = {Enabled = true}
	local FlyAutoPop = {Enabled = true}
	local FlyAnyway = {Enabled = false}
	local FlyAnywayProgressBar = {Enabled = false}
	local FlyDamageAnimation = {Enabled = false}
	local FlyTP = {Enabled = false}
	local FlyAnywayProgressBarFrame
	local olddeflate
	local FlyUp = false
	local FlyDown = false
	local FlyCoroutine
	local groundtime = tick()
	local onground = false
	local lastonground = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}

	local function inflateBalloon()
		if not Fly.Enabled then return end
		if entityLibrary.isAlive and (lplr.Character:GetAttribute("InflatedBalloons") or 0) < 1 then
			autobankballoon = true
			if getItem("balloon") then
				bedwars.BalloonController:inflateBalloon()
				return true
			end
		end
		return false
	end

	Fly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Fly",
		Function = function(callback)
			if callback then
				olddeflate = bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end

				table.insert(Fly.Connections, inputService.InputBegan:Connect(function(input1)
					if FlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							FlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							FlyDown = true
						end
					end
				end))
				table.insert(Fly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						FlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						FlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(Fly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							FlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						FlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				table.insert(Fly.Connections, vapeEvents.BalloonPopped.Event:Connect(function(poppedTable)
					if poppedTable.inflatedBalloon and poppedTable.inflatedBalloon:GetAttribute("BalloonOwner") == lplr.UserId then
						lastonground = not onground
						repeat task.wait() until (lplr.Character:GetAttribute("InflatedBalloons") or 0) <= 0 or not Fly.Enabled
						inflateBalloon()
					end
				end))
				table.insert(Fly.Connections, vapeEvents.AutoBankBalloon.Event:Connect(function()
					repeat task.wait() until getItem("balloon")
					inflateBalloon()
				end))

				local balloons
				if entityLibrary.isAlive and (not store.queueType:find("mega")) then
					balloons = inflateBalloon()
				end
				local megacheck = store.queueType:find("mega") or store.queueType == "winter_event"

				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test" or (not Fly.Enabled)
					if not Fly.Enabled then return end
					megacheck = store.queueType:find("mega") or store.queueType == "winter_event"
				end)

				local flyAllowed = entityLibrary.isAlive and ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
				if flyAllowed <= 0 and shared.damageanim and (not balloons) then
					shared.damageanim()
					bedwars.SoundManager:playSound(bedwars.SoundList["DAMAGE_"..math.random(1, 3)])
				end

				if FlyAnywayProgressBarFrame and flyAllowed <= 0 and (not balloons) then
					FlyAnywayProgressBarFrame.Visible = true
					FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
				end

				groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
				FlyCoroutine = coroutine.create(function()
					repeat
						repeat task.wait() until (groundtime - tick()) < 0.6 and not onground
						flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						if (not Fly.Enabled) then break end
						local Flytppos = -99999
						if flyAllowed <= 0 and FlyTP.Enabled and entityLibrary.isAlive then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray then
								Flytppos = entityLibrary.character.HumanoidRootPart.Position.Y
								local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
								args[2] = ray.Position.Y + (entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								task.wait(0.12)
								if (not Fly.Enabled) then break end
								flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
								if flyAllowed <= 0 and Flytppos ~= -99999 and entityLibrary.isAlive then
									local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
									args[2] = Flytppos
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								end
							end
						end
					until (not Fly.Enabled)
				end)
				coroutine.resume(FlyCoroutine)

				RunLoops:BindToHeartbeat("Fly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)
						flyAllowed = ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						playerMass = playerMass + (flyAllowed > 0 and 4 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)

						if FlyAnywayProgressBarFrame then
							FlyAnywayProgressBarFrame.Visible = flyAllowed <= 0
							FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							FlyAnywayProgressBarFrame.Frame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
						end

						if flyAllowed <= 0 then
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, (entityLibrary.character.Humanoid.HipHeight * -2) - 1, 0))
							onground = newray and true or false
							if lastonground ~= onground then
								if (not onground) then
									groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, groundtime - tick(), true)
									end
								else
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
									end
								end
							end
							if FlyAnywayProgressBarFrame then
								FlyAnywayProgressBarFrame.TextLabel.Text = math.max(onground and 2.5 or math.floor((groundtime - tick()) * 10) / 10, 0).."s"
							end
							lastonground = onground
						else
							onground = true
							lastonground = true
						end

						local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (FlyMode.Value == "Normal" and FlySpeed.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (FlyUp and FlyVerticalSpeed.Value or 0) + (FlyDown and -FlyVerticalSpeed.Value or 0), 0))
						if FlyMode.Value ~= "Normal" then
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((FlySpeed.Value + getSpeed()) - 20)) * delta
						end
					end
				end)
			else
				pcall(function() coroutine.close(FlyCoroutine) end)
				autobankballoon = false
				waitingforballoon = false
				lastonground = nil
				FlyUp = false
				FlyDown = false
				RunLoops:UnbindFromHeartbeat("Fly")
				if FlyAnywayProgressBarFrame then
					FlyAnywayProgressBarFrame.Visible = false
				end
				if FlyAutoPop.Enabled then
					if entityLibrary.isAlive and lplr.Character:GetAttribute("InflatedBalloons") then
						for i = 1, lplr.Character:GetAttribute("InflatedBalloons") do
							olddeflate()
						end
					end
				end
				bedwars.BalloonController.deflateBalloon = olddeflate
				olddeflate = nil
			end
		end,
		HoverText = "Makes you go zoom (longer Fly discovered by exelys and Cqded)",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	FlySpeed = Fly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	FlyVerticalSpeed = Fly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	FlyVertical = Fly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
	FlyAutoPop = Fly.CreateToggle({
		Name = "Pop Balloon",
		Function = function() end,
		HoverText = "Pops balloons when Fly is disabled."
	})
	local oldcamupdate
	local camcontrol
	local Flydamagecamera = {Enabled = false}
	FlyDamageAnimation = Fly.CreateToggle({
		Name = "Damage Animation",
		Function = function(callback)
			if Flydamagecamera.Object then
				Flydamagecamera.Object.Visible = callback
			end
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.1)
						for i,v in pairs(getconnections(gameCamera:GetPropertyChangedSignal("CameraType"))) do
							if v.Function then
								camcontrol = debug.getupvalue(v.Function, 1)
							end
						end
					until camcontrol
					local caminput = require(lplr.PlayerScripts.PlayerModule.CameraModule.CameraInput)
					local num = Instance.new("IntValue")
					local numanim
					shared.damageanim = function()
						if numanim then numanim:Cancel() end
						if Flydamagecamera.Enabled then
							num.Value = 1000
							numanim = tweenService:Create(num, TweenInfo.new(0.5), {Value = 0})
							numanim:Play()
						end
					end
					oldcamupdate = camcontrol.Update
					camcontrol.Update = function(self, dt)
						if camcontrol.activeCameraController then
							camcontrol.activeCameraController:UpdateMouseBehavior()
							local newCameraCFrame, newCameraFocus = camcontrol.activeCameraController:Update(dt)
							gameCamera.CFrame = newCameraCFrame * CFrame.Angles(0, 0, math.rad(num.Value / 100))
							gameCamera.Focus = newCameraFocus
							if camcontrol.activeTransparencyController then
								camcontrol.activeTransparencyController:Update(dt)
							end
							if caminput.getInputEnabled() then
								caminput.resetInputForFrameEnd()
							end
						end
					end
				end)
			else
				shared.damageanim = nil
				if camcontrol then
					camcontrol.Update = oldcamupdate
				end
			end
		end
	})
	Flydamagecamera = Fly.CreateToggle({
		Name = "Camera Animation",
		Function = function() end,
		Default = true
	})
	Flydamagecamera.Object.BorderSizePixel = 0
	Flydamagecamera.Object.BackgroundTransparency = 0
	Flydamagecamera.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Flydamagecamera.Object.Visible = false
	FlyAnywayProgressBar = Fly.CreateToggle({
		Name = "Progress Bar",
		Function = function(callback)
			if callback then
				FlyAnywayProgressBarFrame = Instance.new("Frame")
				FlyAnywayProgressBarFrame.AnchorPoint = Vector2.new(0.5, 0)
				FlyAnywayProgressBarFrame.Position = UDim2.new(0.5, 0, 1, -200)
				FlyAnywayProgressBarFrame.Size = UDim2.new(0.2, 0, 0, 20)
				FlyAnywayProgressBarFrame.BackgroundTransparency = 0.5
				FlyAnywayProgressBarFrame.BorderSizePixel = 0
				FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.new(0, 0, 0)
				FlyAnywayProgressBarFrame.Visible = Fly.Enabled
				FlyAnywayProgressBarFrame.Parent = GuiLibrary.MainGui
				local FlyAnywayProgressBarFrame2 = FlyAnywayProgressBarFrame:Clone()
				FlyAnywayProgressBarFrame2.AnchorPoint = Vector2.new(0, 0)
				FlyAnywayProgressBarFrame2.Position = UDim2.new(0, 0, 0, 0)
				FlyAnywayProgressBarFrame2.Size = UDim2.new(1, 0, 0, 20)
				FlyAnywayProgressBarFrame2.BackgroundTransparency = 0
				FlyAnywayProgressBarFrame2.Visible = true
				FlyAnywayProgressBarFrame2.Parent = FlyAnywayProgressBarFrame
				local FlyAnywayProgressBartext = Instance.new("TextLabel")
				FlyAnywayProgressBartext.Text = "2s"
				FlyAnywayProgressBartext.Font = Enum.Font.Gotham
				FlyAnywayProgressBartext.TextStrokeTransparency = 0
				FlyAnywayProgressBartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
				FlyAnywayProgressBartext.TextSize = 20
				FlyAnywayProgressBartext.Size = UDim2.new(1, 0, 1, 0)
				FlyAnywayProgressBartext.BackgroundTransparency = 1
				FlyAnywayProgressBartext.Position = UDim2.new(0, 0, -1, 0)
				FlyAnywayProgressBartext.Parent = FlyAnywayProgressBarFrame
			else
				if FlyAnywayProgressBarFrame then FlyAnywayProgressBarFrame:Destroy() FlyAnywayProgressBarFrame = nil end
			end
		end,
		HoverText = "show amount of Fly time",
		Default = true
	})
	FlyTP = Fly.CreateToggle({
		Name = "TP Down",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local GrappleExploit = {Enabled = false}
	local GrappleExploitMode = {Value = "Normal"}
	local GrappleExploitVerticalSpeed = {Value = 40}
	local GrappleExploitVertical = {Enabled = true}
	local GrappleExploitUp = false
	local GrappleExploitDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	--me when I have to fix bw code omegalol
	bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
		if p4.hookFunction == "PLAYER_IN_TRANSIT" then
			bedwars.CooldownController:setOnCooldown("grappling_hook", 3.5)
		end
	end)

	GrappleExploit = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "GrappleExploit",
		Function = function(callback)
			if callback then
				local grappleHooked = false
				table.insert(GrappleExploit.Connections, bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
					if p4.hookFunction == "PLAYER_IN_TRANSIT" then
						store.grapple = tick() + 1.8
						grappleHooked = true
						GrappleExploit.ToggleButton(false)
					end
				end))

				local fireball = getItem("grappling_hook")
				if fireball then
					task.spawn(function()
						repeat task.wait() until bedwars.CooldownController:getRemainingCooldown("grappling_hook") == 0 or (not GrappleExploit.Enabled)
						if (not GrappleExploit.Enabled) then return end
						switchItem(fireball.tool)
						local pos = entityLibrary.character.HumanoidRootPart.CFrame.p
						local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
						projectileRemote:CallServerAsync(fireball["tool"], nil, "grappling_hook_projectile", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
					end)
				else
					warningNotification("GrappleExploit", "missing grapple hook", 3)
					GrappleExploit.ToggleButton(false)
					return
				end

				local startCFrame = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.CFrame
				RunLoops:BindToHeartbeat("GrappleExploit", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						entityLibrary.character.HumanoidRootPart.Velocity = Vector3.zero
						entityLibrary.character.HumanoidRootPart.CFrame = startCFrame
					end
				end)
			else
				GrappleExploitUp = false
				GrappleExploitDown = false
				RunLoops:UnbindFromHeartbeat("GrappleExploit")
			end
		end,
		HoverText = "Makes you go zoom (longer GrappleExploit discovered by exelys and Cqded)",
		ExtraText = function()
			if GuiLibrary.ObjectsThatCanBeSaved["Text GUIAlternate TextToggle"]["Api"].Enabled then
				return alternatelist[table.find(GrappleExploitMode["List"], GrappleExploitMode.Value)]
			end
			return GrappleExploitMode.Value
		end
	})
end)

run(function()
	local InfiniteFly = {Enabled = false}
	local InfiniteFlyMode = {Value = "CFrame"}
	local InfiniteFlySpeed = {Value = 23}
	local InfiniteFlyVerticalSpeed = {Value = 40}
	local InfiniteFlyVertical = {Enabled = true}
	local InfiniteFlyUp = false
	local InfiniteFlyDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local clonesuccess = false
	local disabledproper = true
	local oldcloneroot
	local cloned
	local clone
	local bodyvelo
	local FlyOverlap = OverlapParams.new()
	FlyOverlap.MaxParts = 9e9
	FlyOverlap.FilterDescendantsInstances = {}
	FlyOverlap.RespectCanCollide = true

	local function disablefunc()
		if bodyvelo then bodyvelo:Destroy() end
		RunLoops:UnbindFromHeartbeat("InfiniteFlyOff")
		disabledproper = true
		if not oldcloneroot or not oldcloneroot.Parent then return end
		lplr.Character.Parent = game
		oldcloneroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldcloneroot
		lplr.Character.Parent = workspace
		oldcloneroot.CanCollide = true
		for i,v in pairs(lplr.Character:GetDescendants()) do
			if v:IsA("Weld") or v:IsA("Motor6D") then
				if v.Part0 == clone then v.Part0 = oldcloneroot end
				if v.Part1 == clone then v.Part1 = oldcloneroot end
			end
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		for i,v in pairs(oldcloneroot:GetChildren()) do
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		local oldclonepos = clone.Position.Y
		if clone then
			clone:Destroy()
			clone = nil
		end
		lplr.Character.Humanoid.HipHeight = hip or 2
		local origcf = {oldcloneroot.CFrame:GetComponents()}
		origcf[2] = oldclonepos
		oldcloneroot.CFrame = CFrame.new(unpack(origcf))
		oldcloneroot = nil
		warningNotification("InfiniteFly", "Landed!", 3)
	end

	InfiniteFly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "InfiniteFly",
		Function = function(callback)
			if callback then
				if not entityLibrary.isAlive then
					disabledproper = true
				end
				if not disabledproper then
					warningNotification("InfiniteFly", "Wait for the last fly to finish", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				table.insert(InfiniteFly.Connections, inputService.InputBegan:Connect(function(input1)
					if InfiniteFlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							InfiniteFlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							InfiniteFlyDown = true
						end
					end
				end))
				table.insert(InfiniteFly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						InfiniteFlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						InfiniteFlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(InfiniteFly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				clonesuccess = false
				if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) then
					cloned = lplr.Character
					oldcloneroot = entityLibrary.character.HumanoidRootPart
					if not lplr.Character.Parent then
						InfiniteFly.ToggleButton(false)
						return
					end
					lplr.Character.Parent = game
					clone = oldcloneroot:Clone()
					clone.Parent = lplr.Character
					oldcloneroot.Parent = gameCamera
					bedwars.QueryUtil:setQueryIgnored(oldcloneroot, true)
					clone.CFrame = oldcloneroot.CFrame
					lplr.Character.PrimaryPart = clone
					lplr.Character.Parent = workspace
					for i,v in pairs(lplr.Character:GetDescendants()) do
						if v:IsA("Weld") or v:IsA("Motor6D") then
							if v.Part0 == oldcloneroot then v.Part0 = clone end
							if v.Part1 == oldcloneroot then v.Part1 = clone end
						end
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					for i,v in pairs(oldcloneroot:GetChildren()) do
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					if hip then
						lplr.Character.Humanoid.HipHeight = hip
					end
					hip = lplr.Character.Humanoid.HipHeight
					clonesuccess = true
				end
				if not clonesuccess then
					warningNotification("InfiniteFly", "Character missing", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				local goneup = false
				RunLoops:BindToHeartbeat("InfiniteFly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if isnetworkowner(oldcloneroot) then
							local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)

							local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (InfiniteFlyMode.Value == "Normal" and InfiniteFlySpeed.Value or 20)
							entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (InfiniteFlyUp and InfiniteFlyVerticalSpeed.Value or 0) + (InfiniteFlyDown and -InfiniteFlyVerticalSpeed.Value or 0), 0))
							if InfiniteFlyMode.Value ~= "Normal" then
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((InfiniteFlySpeed.Value + getSpeed()) - 20)) * delta
							end

							local speedCFrame = {oldcloneroot.CFrame:GetComponents()}
							speedCFrame[1] = clone.CFrame.X
							if speedCFrame[2] < 1000 or (not goneup) then
								task.spawn(warningNotification, "InfiniteFly", "Teleported Up", 3)
								speedCFrame[2] = 100000
								goneup = true
							end
							speedCFrame[3] = clone.CFrame.Z
							oldcloneroot.CFrame = CFrame.new(unpack(speedCFrame))
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, oldcloneroot.Velocity.Y, clone.Velocity.Z)
						else
							InfiniteFly.ToggleButton(false)
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("InfiniteFly")
				if clonesuccess and oldcloneroot and clone and lplr.Character.Parent == workspace and oldcloneroot.Parent ~= nil and disabledproper and cloned == lplr.Character then
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
					rayparams.RespectCanCollide = true
					local ray = workspace:Raycast(Vector3.new(oldcloneroot.Position.X, clone.CFrame.p.Y, oldcloneroot.Position.Z), Vector3.new(0, -1000, 0), rayparams)
					local origcf = {clone.CFrame:GetComponents()}
					origcf[1] = oldcloneroot.Position.X
					origcf[2] = ray and ray.Position.Y + (entityLibrary.character.Humanoid.HipHeight + (oldcloneroot.Size.Y / 2)) or clone.CFrame.p.Y
					origcf[3] = oldcloneroot.Position.Z
					oldcloneroot.CanCollide = true
					bodyvelo = Instance.new("BodyVelocity")
					bodyvelo.MaxForce = Vector3.new(0, 9e9, 0)
					bodyvelo.Velocity = Vector3.new(0, -1, 0)
					bodyvelo.Parent = oldcloneroot
					oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
					RunLoops:BindToHeartbeat("InfiniteFlyOff", function(dt)
						if oldcloneroot then
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
							local bruh = {clone.CFrame:GetComponents()}
							bruh[2] = oldcloneroot.CFrame.Y
							local newcf = CFrame.new(unpack(bruh))
							FlyOverlap.FilterDescendantsInstances = {lplr.Character, gameCamera}
							local allowed = true
							for i,v in pairs(workspace:GetPartBoundsInRadius(newcf.p, 2, FlyOverlap)) do
								if (v.Position.Y + (v.Size.Y / 2)) > (newcf.p.Y + 0.5) then
									allowed = false
									break
								end
							end
							if allowed then
								oldcloneroot.CFrame = newcf
							end
						end
					end)
					oldcloneroot.CFrame = CFrame.new(unpack(origcf))
					entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
					disabledproper = false
					if isnetworkowner(oldcloneroot) then
						warningNotification("InfiniteFly", "Waiting 1.1s to not flag", 3)
						task.delay(1.1, disablefunc)
					else
						disablefunc()
					end
				end
				InfiniteFlyUp = false
				InfiniteFlyDown = false
			end
		end,
		HoverText = "Makes you go zoom",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	InfiniteFlySpeed = InfiniteFly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	InfiniteFlyVerticalSpeed = InfiniteFly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	InfiniteFlyVertical = InfiniteFly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
end)

local killauraNearPlayer
run(function()
	local killauraboxes = {}
	local killauratargetframe = {Players = {Enabled = false}}
	local killaurasortmethod = {Value = "Distance"}
	local killaurarealremote = bedwars.Client:Get(bedwars.AttackRemote).instance
	local killauramethod = {Value = "Normal"}
	local killauraothermethod = {Value = "Normal"}
	local killauraanimmethod = {Value = "Normal"}
	local killaurarange = {Value = 14}
	local killauraangle = {Value = 360}
	local killauratargets = {Value = 10}
	local killauraautoblock = {Enabled = false}
	local killauramouse = {Enabled = false}
	local killauracframe = {Enabled = false}
	local killauragui = {Enabled = false}
	local killauratarget = {Enabled = false}
	local killaurasound = {Enabled = false}
	local killauraswing = {Enabled = false}
	local killaurasync = {Enabled = false}
	local killaurahandcheck = {Enabled = false}
	local killauraanimation = {Enabled = false}
	local killauraanimationtween = {Enabled = false}
	local killauracolor = {Value = 0.44}
	local killauranovape = {Enabled = false}
	local killauratargethighlight = {Enabled = false}
	local killaurarangecircle = {Enabled = false}
	local killaurarangecirclepart
	local killauraaimcircle = {Enabled = false}
	local killauraaimcirclepart
	local killauraparticle = {Enabled = false}
	local killauraparticlepart
	local Killauranear = false
	local killauraplaying = false
	local oldViewmodelAnimation = function() end
	local oldPlaySound = function() end
	local originalArmC0 = nil
	local killauracurrentanim = PistonWareBlock
	local animationdelay = tick()

	local function getStrength(plr)
		local inv = store.inventories[plr.Player]
		local strength = 0
		local strongestsword = 0
		if inv then
			for i,v in pairs(inv.items) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.sword and itemmeta.sword.damage > strongestsword then
					strongestsword = itemmeta.sword.damage / 100
				end
			end
			strength = strength + strongestsword
			for i,v in pairs(inv.armor) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.armor then
					strength = strength + (itemmeta.armor.damageReductionMultiplier or 0)
				end
			end
			strength = strength
		end
		return strength
	end

	local kitpriolist = {
		hannah = 5,
		spirit_assassin = 4,
		dasher = 3,
		jade = 2,
		regent = 1
	}

	local killaurasortmethods = {
		Distance = function(a, b)
			return (a.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude < (b.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude
		end,
		Health = function(a, b)
			return a.Humanoid.Health < b.Humanoid.Health
		end,
		Threat = function(a, b)
			return getStrength(a) > getStrength(b)
		end,
		Kit = function(a, b)
			return (kitpriolist[a.Player:GetAttribute("PlayingAsKit")] or 0) > (kitpriolist[b.Player:GetAttribute("PlayingAsKit")] or 0)
		end
	}

	local originalNeckC0
	local originalRootC0
	local anims = {
		Normal = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.05},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.05}
		},
		Slow = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.15}
		},
		New = {
			{CFrame = CFrame.new(0.69, -0.77, 1.47) * CFrame.Angles(math.rad(-33), math.rad(57), math.rad(-81)), Time = 0.12},
			{CFrame = CFrame.new(0.74, -0.92, 0.88) * CFrame.Angles(math.rad(147), math.rad(71), math.rad(53)), Time = 0.12}
		},
		Latest = {
			{CFrame = CFrame.new(0.69, -0.7, 0.1) * CFrame.Angles(math.rad(-65), math.rad(55), math.rad(-51)), Time = 0.1},
			{CFrame = CFrame.new(0.16, -1.16, 0.5) * CFrame.Angles(math.rad(-179), math.rad(54), math.rad(33)), Time = 0.1}
		},
		["Vertical Spin"] = {
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(8), math.rad(5)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(180), math.rad(3), math.rad(13)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), math.rad(-5), math.rad(8)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-0), math.rad(-0)), Time = 0.1}
		},
		Exhibition = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
		},
		["Exhibition Old"] = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
			{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
		},
		SlowAndFast = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.8},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.01}
		},
		SkidWare = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-65), math.rad(65), math.rad(-79)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-98), math.rad(35), math.rad(-56)), Time = 0.2}
		},
		PistonWareBlock = {
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.00001}
		},
		Azura = {
			{CFrame = CFrame.new(0.67, -0.66, 0.57) * CFrame.Angles(math.rad(-46), math.rad(45.73), math.rad(-85)), Time = 0.1},
			{CFrame = CFrame.new(0.72, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(59), math.rad(-50)), Time = 0.2}
		},
		["Azura Old"] = {
			{CFrame = CFrame.new(0.65, -0.68, 0.57) * CFrame.Angles(math.rad(-46), math.rad(45.73), math.rad(-76)), Time = 0.15},
			{CFrame = CFrame.new(0.77, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(76), math.rad(-32)), Time = 0.17},
			{CFrame = CFrame.new(0.63, -0.68, 0.57) * CFrame.Angles(math.rad(-46), math.rad(65), math.rad(-65)), Time = 0.21},
			{CFrame = CFrame.new(0.73, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(49), math.rad(-25)), Time = 0.26}
		},
		["nigger"] = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.05},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.05},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.77, 1.47) * CFrame.Angles(math.rad(-33), math.rad(57), math.rad(-81)), Time = 0.12},
			{CFrame = CFrame.new(0.74, -0.92, 0.88) * CFrame.Angles(math.rad(147), math.rad(71), math.rad(53)), Time = 0.12},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(8), math.rad(5)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(180), math.rad(3), math.rad(13)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), math.rad(-5), math.rad(8)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-0), math.rad(-0)), Time = 0.1},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
			{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.8},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.01},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-65), math.rad(65), math.rad(-79)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-98), math.rad(35), math.rad(-56)), Time = 0.2},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-45), math.rad(70), math.rad(-90)), Time = 0.07},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-89), math.rad(70), math.rad(-38)), Time = 0.13},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-89), math.rad(68), math.rad(-56)), Time = 0.12},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-65), math.rad(68), math.rad(-35)), Time = 0.19},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-65), math.rad(54), math.rad(-56)), Time = 0.08},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-98), math.rad(38), math.rad(-23)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-65), math.rad(98), math.rad(-354)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-98), math.rad(65), math.rad(-68)), Time = 0.2},
			{CFrame = CFrame.new(0.67, -0.66, 0.57) * CFrame.Angles(math.rad(-46), math.rad(45.73), math.rad(-85)), Time = 0.1},
			{CFrame = CFrame.new(0.72, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(59), math.rad(-50)), Time = 0.2},
			{CFrame = CFrame.new(0.65, -0.68, 0.57) * CFrame.Angles(math.rad(-46), math.rad(45.73), math.rad(-76)), Time = 0.15},
			{CFrame = CFrame.new(0.77, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(76), math.rad(-32)), Time = 0.17},
			{CFrame = CFrame.new(0.63, -0.68, 0.57) * CFrame.Angles(math.rad(-46), math.rad(65), math.rad(-65)), Time = 0.21},
			{CFrame = CFrame.new(0.73, -0.71, 0.62) * CFrame.Angles(math.rad(-73), math.rad(49), math.rad(-25)), Time = 0.26}
		}
	}

	local function closestpos(block, pos)
		local blockpos = block:GetRenderCFrame()
		local startpos = (blockpos * CFrame.new(-(block.Size / 2))).p
		local endpos = (blockpos * CFrame.new((block.Size / 2))).p
		local speedCFrame = block.Position + (pos - block.Position)
		local x = startpos.X > endpos.X and endpos.X or startpos.X
		local y = startpos.Y > endpos.Y and endpos.Y or startpos.Y
		local z = startpos.Z > endpos.Z and endpos.Z or startpos.Z
		local x2 = startpos.X < endpos.X and endpos.X or startpos.X
		local y2 = startpos.Y < endpos.Y and endpos.Y or startpos.Y
		local z2 = startpos.Z < endpos.Z and endpos.Z or startpos.Z
		return Vector3.new(math.clamp(speedCFrame.X, x, x2), math.clamp(speedCFrame.Y, y, y2), math.clamp(speedCFrame.Z, z, z2))
	end

	local function getAttackData()
		if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
			if store.matchState == 0 then return false end
		end
		if killauramouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if killauragui.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end
		local sword = killaurahandcheck.Enabled and store.localHand or getSword()
		if not sword or not sword.tool then return false end
		local swordmeta = bedwars.ItemTable[sword.tool.Name]
		if killaurahandcheck.Enabled then
			if store.localHand.Type ~= "sword" or bedwars.DaoController.chargingMaid then return false end
		end
		return sword, swordmeta
	end

	local function autoBlockLoop()
		if not killauraautoblock.Enabled or not Killaura.Enabled then return end
		repeat
			if store.blockPlace < tick() and entityLibrary.isAlive then
				local shield = getItem("infernal_shield")
				if shield then
					switchItem(shield.tool)
					if not lplr.Character:GetAttribute("InfernalShieldRaised") then
						bedwars.InfernalShieldController:raiseShield()
					end
				end
			end
			task.wait()
		until (not Killaura.Enabled) or (not killauraautoblock.Enabled)
	end

	Killaura = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Killaura",
		Function = function(callback)
			if callback then
				if killauraaimcirclepart then killauraaimcirclepart.Parent = gameCamera end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = gameCamera end
				if killauraparticlepart then killauraparticlepart.Parent = gameCamera end

				task.spawn(function()
					local oldNearPlayer
					repeat
						task.wait()
						if (killauraanimation.Enabled and not killauraswing.Enabled) then
							if killauraNearPlayer then
								pcall(function()
									if originalArmC0 == nil then
										originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
									end
									if killauraplaying == false then
										killauraplaying = true
										for i,v in pairs(anims[killauraanimmethod.Value]) do
											if (not Killaura.Enabled) or (not killauraNearPlayer) then break end
											if not oldNearPlayer and killauraanimationtween.Enabled then
												gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0 * v.CFrame
												continue
											end
											killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(v.Time), {C0 = originalArmC0 * v.CFrame})
											killauracurrentanim:Play()
											task.wait(v.Time - 0.01)
										end
										killauraplaying = false
									end
								end)
							end
							oldNearPlayer = killauraNearPlayer
						end
					until Killaura.Enabled == false
				end)

				oldViewmodelAnimation = bedwars.ViewmodelController.playAnimation
				oldPlaySound = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(tab, soundid, ...)
					if (soundid == bedwars.SoundList.SWORD_SWING_1 or soundid == bedwars.SoundList.SWORD_SWING_2) and Killaura.Enabled and killaurasound.Enabled and killauraNearPlayer then
						return nil
					end
					return oldPlaySound(tab, soundid, ...)
				end
				bedwars.ViewmodelController.playAnimation = function(Self, id, ...)
					if id == 15 and killauraNearPlayer and killauraswing.Enabled and entityLibrary.isAlive then
						return nil
					end
					if id == 15 and killauraNearPlayer and killauraanimation.Enabled and entityLibrary.isAlive then
						return nil
					end
					return oldViewmodelAnimation(Self, id, ...)
				end

				local targetedPlayer
				RunLoops:BindToHeartbeat("Killaura", function()
					for i,v in pairs(killauraboxes) do
						if v:IsA("BoxHandleAdornment") and v.Adornee then
							local cf = v.Adornee and v.Adornee.CFrame
							local onex, oney, onez = cf:ToEulerAnglesXYZ()
							v.CFrame = CFrame.new() * CFrame.Angles(-onex, -oney, -onez)
						end
					end
					if entityLibrary.isAlive then
						if killauraaimcirclepart then
							killauraaimcirclepart.Position = targetedPlayer and closestpos(targetedPlayer.RootPart, entityLibrary.character.HumanoidRootPart.Position) or Vector3.new(99999, 99999, 99999)
						end
						if killauraparticlepart then
							killauraparticlepart.Position = targetedPlayer and targetedPlayer.RootPart.Position or Vector3.new(99999, 99999, 99999)
						end
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							if killaurarangecirclepart then
								killaurarangecirclepart.Position = Root.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)
							end
							local Neck = entityLibrary.character.Head:FindFirstChild("Neck")
							local LowerTorso = Root.Parent and Root.Parent:FindFirstChild("LowerTorso")
							local RootC0 = LowerTorso and LowerTorso:FindFirstChild("Root")
							if Neck and RootC0 then
								if originalNeckC0 == nil then
									originalNeckC0 = Neck.C0.p
								end
								if originalRootC0 == nil then
									originalRootC0 = RootC0.C0.p
								end
								if originalRootC0 and killauracframe.Enabled then
									if targetedPlayer ~= nil then
										local targetPos = targetedPlayer.RootPart.Position + Vector3.new(0, 2, 0)
										local direction = (Vector3.new(targetPos.X, targetPos.Y, targetPos.Z) - entityLibrary.character.Head.Position).Unit
										local direction2 = (Vector3.new(targetPos.X, Root.Position.Y, targetPos.Z) - Root.Position).Unit
										local lookCFrame = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction)))
										local lookCFrame2 = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction2)))
										Neck.C0 = CFrame.new(originalNeckC0) * CFrame.Angles(lookCFrame.LookVector.Unit.y, 0, 0)
										RootC0.C0 = lookCFrame2 + originalRootC0
									else
										Neck.C0 = CFrame.new(originalNeckC0)
										RootC0.C0 = CFrame.new(originalRootC0)
									end
								end
							end
						end
					end
				end)
				if killauraautoblock.Enabled then
					task.spawn(autoBlockLoop)
				end
				task.spawn(function()
					repeat
						task.wait()
						if not Killaura.Enabled then break end
						vapeTargetInfo.Targets.Killaura = nil
						local plrs = AllNearPosition(killaurarange.Value, 10, killaurasortmethods[killaurasortmethod.Value], true)
						local firstPlayerNear
						if #plrs > 0 then
							local sword, swordmeta = getAttackData()
							if sword then
								switchItem(sword.tool)
								for i, plr in pairs(plrs) do
									local root = plr.RootPart
									if not root then
										continue
									end
									local localfacing = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
									local vec = (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).unit
									local angle = math.acos(localfacing:Dot(vec))
									if angle >= (math.rad(killauraangle.Value) / 2) then
										continue
									end
									local selfrootpos = entityLibrary.character.HumanoidRootPart.Position
									if killauratargetframe.Walls.Enabled then
										if not bedwars.SwordController:canSee({player = plr.Player, getInstance = function() return plr.Character end}) then continue end
									end
									if killauranovape.Enabled and store.whitelist.clientUsers[plr.Player.Name] then
										continue
									end
									if not firstPlayerNear then
										firstPlayerNear = true
										killauraNearPlayer = true
										targetedPlayer = plr
										vapeTargetInfo.Targets.Killaura = {
											Humanoid = {
												Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
												MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
											},
											Player = plr.Player
										}
										if animationdelay <= tick() then
											animationdelay = tick() + (swordmeta.sword.respectAttackSpeedForEffects and swordmeta.sword.attackSpeed or (killaurasync.Enabled and 0.24 or 0.14))
											if not killauraswing.Enabled then
												bedwars.SwordController:playSwordEffect(swordmeta, false)
											end
											if swordmeta.displayName:find(" Scythe") then
												bedwars.ScytheController:playLocalAnimation()
											end
										end
									end
									if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) < 0.02 then
										break
									end
									local selfpos = selfrootpos + (killaurarange.Value > 14 and (selfrootpos - root.Position).magnitude > 14.4 and (CFrame.lookAt(selfrootpos, root.Position).lookVector * ((selfrootpos - root.Position).magnitude - 14)) or Vector3.zero)
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									store.attackReach = math.floor((selfrootpos - root.Position).magnitude * 100) / 100
									store.attackReachUpdate = tick() + 1
									killaurarealremote:FireServer({
										weapon = sword.tool,
										chargedAttack = {chargeRatio = swordmeta.sword.chargedAttack and not swordmeta.sword.chargedAttack.disableOnGrounded and 0.999 or 0},
										entityInstance = plr.Character,
										validate = {
											raycast = {
												cameraPosition = attackValue(root.Position),
												cursorDirection = attackValue(CFrame.new(selfpos, root.Position).lookVector)
											},
											targetPosition = attackValue(root.Position),
											selfPosition = attackValue(selfpos)
										}
									})
									break
								end
							end
						end
						if not firstPlayerNear then
							targetedPlayer = nil
							killauraNearPlayer = false
							pcall(function()
								if originalArmC0 == nil then
									originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
									pcall(function()
										killauracurrentanim:Cancel()
									end)
									if killauraanimationtween.Enabled then
										gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
									else
										killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
										killauracurrentanim:Play()
									end
								end
							end)
						end
						for i,v in pairs(killauraboxes) do
							local attacked = killauratarget.Enabled and plrs[i] or nil
							v.Adornee = attacked and ((not killauratargethighlight.Enabled) and attacked.RootPart or (not GuiLibrary.ObjectsThatCanBeSaved.ChamsOptionsButton.Api.Enabled) and attacked.Character or nil)
						end
					until (not Killaura.Enabled)
				end)
			else
				vapeTargetInfo.Targets.Killaura = nil
				RunLoops:UnbindFromHeartbeat("Killaura")
				killauraNearPlayer = false
				for i,v in pairs(killauraboxes) do v.Adornee = nil end
				if killauraaimcirclepart then killauraaimcirclepart.Parent = nil end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = nil end
				if killauraparticlepart then killauraparticlepart.Parent = nil end
				bedwars.ViewmodelController.playAnimation = oldViewmodelAnimation
				bedwars.SoundManager.playSound = oldPlaySound
				oldViewmodelAnimation = nil
				pcall(function()
					if entityLibrary.isAlive then
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							local Neck = Root.Parent.Head.Neck
							if originalNeckC0 and originalRootC0 then
								Neck.C0 = CFrame.new(originalNeckC0)
								Root.Parent.LowerTorso.Root.C0 = CFrame.new(originalRootC0)
							end
						end
					end
					if originalArmC0 == nil then
						originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
					end
					if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
						pcall(function()
							killauracurrentanim:Cancel()
						end)
						if killauraanimationtween.Enabled then
							gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
						else
							killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
							killauracurrentanim:Play()
						end
					end
				end)
			end
		end,
		HoverText = "Attack players around you\nwithout aiming at them."
	})
	killauratargetframe = Killaura.CreateTargetWindow({})
	local sortmethods = {"Distance"}
	for i,v in pairs(killaurasortmethods) do if i ~= "Distance" then table.insert(sortmethods, i) end end
	killaurasortmethod = Killaura.CreateDropdown({
		Name = "Sort",
		Function = function() end,
		List = sortmethods
	})
	killaurarange = Killaura.CreateSlider({
		Name = "Attack range",
		Min = 1,
		Max = 18,
		Function = function(val)
			if killaurarangecirclepart then
				killaurarangecirclepart.Size = Vector3.new(val * 0.7, 0.01, val * 0.7)
			end
		end,
		Default = 18
	})
	killauraangle = Killaura.CreateSlider({
		Name = "Max angle",
		Min = 1,
		Max = 360,
		Function = function(val) end,
		Default = 360
	})
	local animmethods = {}
	for i,v in pairs(anims) do table.insert(animmethods, i) end
	killauraanimmethod = Killaura.CreateDropdown({
		Name = "Animation",
		List = animmethods,
		Function = function(val) end
	})
	local oldviewmodel
	local oldraise
	local oldeffect
	killauraautoblock = Killaura.CreateToggle({
		Name = "AutoBlock",
		Function = function(callback)
			if callback then
				oldviewmodel = bedwars.ViewmodelController.setHeldItem
				bedwars.ViewmodelController.setHeldItem = function(self, newItem, ...)
					if newItem and newItem.Name == "infernal_shield" then
						return
					end
					return oldviewmodel(self, newItem)
				end
				oldraise = bedwars.InfernalShieldController.raiseShield
				bedwars.InfernalShieldController.raiseShield = function(self)
					if os.clock() - self.lastShieldRaised < 0.4 then
						return
					end
					self.lastShieldRaised = os.clock()
					self.infernalShieldState:SendToServer({raised = true})
					self.raisedMaid:GiveTask(function()
						self.infernalShieldState:SendToServer({raised = false})
					end)
				end
				oldeffect = bedwars.InfernalShieldController.playEffect
				bedwars.InfernalShieldController.playEffect = function()
					return
				end
				if bedwars.ViewmodelController.heldItem and bedwars.ViewmodelController.heldItem.Name == "infernal_shield" then
					local sword, swordmeta = getSword()
					if sword then
						bedwars.ViewmodelController:setHeldItem(sword.tool)
					end
				end
				task.spawn(autoBlockLoop)
			else
				bedwars.ViewmodelController.setHeldItem = oldviewmodel
				bedwars.InfernalShieldController.raiseShield = oldraise
				bedwars.InfernalShieldController.playEffect = oldeffect
			end
		end,
		Default = true
	})
	killauramouse = Killaura.CreateToggle({
		Name = "Require mouse down",
		Function = function() end,
		HoverText = "Only attacks when left click is held.",
		Default = false
	})
	killauragui = Killaura.CreateToggle({
		Name = "GUI Check",
		Function = function() end,
		HoverText = "Attacks when you are not in a GUI."
	})
	killauratarget = Killaura.CreateToggle({
		Name = "Show target",
		Function = function(callback)
			if killauratargethighlight.Object then
				killauratargethighlight.Object.Visible = callback
			end
		end,
		HoverText = "Shows a red box over the opponent."
	})
	killauratargethighlight = Killaura.CreateToggle({
		Name = "Use New Highlight",
		Function = function(callback)
			for i, v in pairs(killauraboxes) do
				v:Remove()
			end
			for i = 1, 10 do
				local killaurabox
				if callback then
					killaurabox = Instance.new("Highlight")
					killaurabox.FillTransparency = 0.39
					killaurabox.FillColor = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					killaurabox.OutlineTransparency = 1
					killaurabox.Parent = GuiLibrary.MainGui
				else
					killaurabox = Instance.new("BoxHandleAdornment")
					killaurabox.Transparency = 0.39
					killaurabox.Color3 = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.Adornee = nil
					killaurabox.AlwaysOnTop = true
					killaurabox.Size = Vector3.new(3, 6, 3)
					killaurabox.ZIndex = 11
					killaurabox.Parent = GuiLibrary.MainGui
				end
				killauraboxes[i] = killaurabox
			end
		end
	})
	killauratargethighlight.Object.BorderSizePixel = 0
	killauratargethighlight.Object.BackgroundTransparency = 0
	killauratargethighlight.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	killauratargethighlight.Object.Visible = false
	killauracolor = Killaura.CreateColorSlider({
		Name = "Target Color",
		Function = function(hue, sat, val)
			for i,v in pairs(killauraboxes) do
				v[(killauratargethighlight.Enabled and "FillColor" or "Color3")] = Color3.fromHSV(hue, sat, val)
			end
			if killauraaimcirclepart then
				killauraaimcirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
			if killaurarangecirclepart then
				killaurarangecirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
		end,
		Default = 1
	})
	for i = 1, 10 do
		local killaurabox = Instance.new("BoxHandleAdornment")
		killaurabox.Transparency = 0.5
		killaurabox.Color3 = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
		killaurabox.Adornee = nil
		killaurabox.AlwaysOnTop = true
		killaurabox.Size = Vector3.new(3, 6, 3)
		killaurabox.ZIndex = 11
		killaurabox.Parent = GuiLibrary.MainGui
		killauraboxes[i] = killaurabox
	end
	killauracframe = Killaura.CreateToggle({
		Name = "Face target",
		Function = function() end,
		HoverText = "Makes your character face the opponent."
	})
	killaurarangecircle = Killaura.CreateToggle({
		Name = "Range Visualizer",
		Function = function(callback)
			if callback then
				--context issues moment
			--[[	killaurarangecirclepart = Instance.new("MeshPart")
				killaurarangecirclepart.MeshId = "rbxassetid://3726303797"
				killaurarangecirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killaurarangecirclepart.CanCollide = false
				killaurarangecirclepart.Anchored = true
				killaurarangecirclepart.Material = Enum.Material.Neon
				killaurarangecirclepart.Size = Vector3.new(killaurarange.Value * 0.7, 0.01, killaurarange.Value * 0.7)
				if Killaura.Enabled then
					killaurarangecirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killaurarangecirclepart, true)]]
			else
				if killaurarangecirclepart then
					killaurarangecirclepart:Destroy()
					killaurarangecirclepart = nil
				end
			end
		end
	})
	killauraaimcircle = Killaura.CreateToggle({
		Name = "Aim Visualizer",
		Function = function(callback)
			if callback then
				killauraaimcirclepart = Instance.new("Part")
				killauraaimcirclepart.Shape = Enum.PartType.Ball
				killauraaimcirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killauraaimcirclepart.CanCollide = false
				killauraaimcirclepart.Anchored = true
				killauraaimcirclepart.Material = Enum.Material.Neon
				killauraaimcirclepart.Size = Vector3.new(0.5, 0.5, 0.5)
				if Killaura.Enabled then
					killauraaimcirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killauraaimcirclepart, true)
			else
				if killauraaimcirclepart then
					killauraaimcirclepart:Destroy()
					killauraaimcirclepart = nil
				end
			end
		end
	})
	killauraparticle = Killaura.CreateToggle({
		Name = "Crit Particle",
		Function = function(callback)
			if callback then
				killauraparticlepart = Instance.new("Part")
				killauraparticlepart.Transparency = 1
				killauraparticlepart.CanCollide = false
				killauraparticlepart.Anchored = true
				killauraparticlepart.Size = Vector3.new(3, 6, 3)
				killauraparticlepart.Parent = cam
				bedwars.QueryUtil:setQueryIgnored(killauraparticlepart, true)
				local particle = Instance.new("ParticleEmitter")
				particle.Lifetime = NumberRange.new(0.5)
				particle.Rate = 500
				particle.Speed = NumberRange.new(0)
				particle.RotSpeed = NumberRange.new(180)
				particle.Enabled = true
				particle.Size = NumberSequence.new(0.3)
				particle.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(67, 10, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 98, 255))})
				particle.Parent = killauraparticlepart
			else
				if killauraparticlepart then
					killauraparticlepart:Destroy()
					killauraparticlepart = nil
				end
			end
		end
	})
	killaurasound = Killaura.CreateToggle({
		Name = "No Swing Sound",
		Function = function() end,
		HoverText = "Removes the swinging sound."
	})
	killauraswing = Killaura.CreateToggle({
		Name = "No Swing",
		Function = function() end,
		HoverText = "Removes the swinging animation."
	})
	killaurahandcheck = Killaura.CreateToggle({
		Name = "Limit to items",
		Function = function() end,
		HoverText = "Only attacks when your sword is held."
	})
	killauraanimation = Killaura.CreateToggle({
		Name = "Custom Animation",
		Function = function(callback)
			if killauraanimationtween.Object then killauraanimationtween.Object.Visible = callback end
		end,
		HoverText = "Uses a custom animation for swinging"
	})
	killauraanimationtween = Killaura.CreateToggle({
		Name = "No Tween",
		Function = function() end,
		HoverText = "Disable's the in and out ease"
	})
	killauraanimationtween.Object.Visible = false
	killaurasync = Killaura.CreateToggle({
		Name = "Synced Animation",
		Function = function() end,
		HoverText = "Times animation with hit attempt"
	})
	killauranovape = Killaura.CreateToggle({
		Name = "No Vape",
		Function = function() end,
		HoverText = "no hit vape user"
	})
	killauranovape.Object.Visible = false
end)

local LongJump = {Enabled = false}
run(function()
	local damagetimer = 0
	local damagetimertick = 0
	local directionvec
	local LongJumpSpeed = {Value = 1.5}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	local function calculatepos(vec)
		local returned = vec
		if entityLibrary.isAlive then
			local newray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, returned, store.blockRaycast)
			if newray then returned = (newray.Position - entityLibrary.character.HumanoidRootPart.Position) end
		end
		return returned
	end

	local damagemethods = {
		fireball = function(fireball, pos)
			if not LongJump.Enabled then return end
			pos = pos - (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 0.2)
			if not (getPlacedBlock(pos - Vector3.new(0, 3, 0)) or getPlacedBlock(pos - Vector3.new(0, 6, 0))) then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://4809574295"
				sound.Parent = workspace
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
				sound:Play()
			end
			local origpos = pos
			local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
			local ray = workspace:Raycast(pos, Vector3.new(0, -30, 0), store.blockRaycast)
			if ray then
				pos = ray.Position
				offsetshootpos = pos
			end
			task.spawn(function()
				switchItem(fireball.tool)
				bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta.fireball, "fireball", "fireball", offsetshootpos, "", Vector3.new(0, -60, 0), {drawDurationSeconds = 1})
				projectileRemote:CallServerAsync(fireball.tool, "fireball", "fireball", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
			end)
		end,
		tnt = function(tnt, pos2)
			if not LongJump.Enabled then return end
			local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
			local block = bedwars.placeBlock(pos, "tnt")
		end,
		cannon = function(tnt, pos2)
			task.spawn(function()
				local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
				local block = bedwars.placeBlock(pos, "cannon")
				task.delay(0.1, function()
					local block, pos2 = getPlacedBlock(pos)
					if block and block.Name == "cannon" and (entityLibrary.character.HumanoidRootPart.CFrame.p - block.Position).Magnitude < 20 then
						switchToAndUseTool(block)
						local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
						local damage = bedwars.BlockController:calculateBlockDamage(lplr, {
							blockPosition = pos2
						})
						bedwars.Client:Get(bedwars.CannonAimRemote):SendToServer({
							cannonBlockPos = pos2,
							lookVector = vec
						})
						local broken = 0.1
						if damage < block:GetAttribute("Health") then
							task.spawn(function()
								broken = 0.4
								bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
							end)
						end
						task.delay(broken, function()
							for i = 1, 3 do
								local call = bedwars.Client:Get(bedwars.CannonLaunchRemote):CallServer({cannonBlockPos = bedwars.BlockController:getBlockPosition(block.Position)})
								if call then
									bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
									task.delay(0.1, function()
										damagetimer = LongJumpSpeed.Value * 5
										damagetimertick = tick() + 2.5
										directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
									end)
									break
								end
								task.wait(0.1)
							end
						end)
					end
				end)
			end)
		end,
		wood_dao = function(tnt, pos2)
			task.spawn(function()
				switchItem(tnt.tool)
				if not (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) then
					repeat task.wait() until (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) or not LongJump.Enabled
				end
				if LongJump.Enabled then
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].useAbility:FireServer("dash", {
						direction = vec,
						origin = entityLibrary.character.HumanoidRootPart.CFrame.p,
						weapon = tnt.itemType
					})
					damagetimer = LongJumpSpeed.Value * 3.5
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		jade_hammer = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("jade_hammer_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("jade_hammer_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("jade_hammer_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("jade_hammer_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		void_axe = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("void_axe_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("void_axe_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("void_axe_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("void_axe_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end
	}
	damagemethods.stone_dao = damagemethods.wood_dao
	damagemethods.iron_dao = damagemethods.wood_dao
	damagemethods.diamond_dao = damagemethods.wood_dao
	damagemethods.emerald_dao = damagemethods.wood_dao

	local oldgrav
	local LongJumpacprogressbarframe = Instance.new("Frame")
	LongJumpacprogressbarframe.AnchorPoint = Vector2.new(0.5, 0)
	LongJumpacprogressbarframe.Position = UDim2.new(0.5, 0, 1, -200)
	LongJumpacprogressbarframe.Size = UDim2.new(0.2, 0, 0, 20)
	LongJumpacprogressbarframe.BackgroundTransparency = 0.5
	LongJumpacprogressbarframe.BorderSizePixel = 0
	LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe.Visible = LongJump.Enabled
	LongJumpacprogressbarframe.Parent = GuiLibrary.MainGui
	local LongJumpacprogressbarframe2 = LongJumpacprogressbarframe:Clone()
	LongJumpacprogressbarframe2.AnchorPoint = Vector2.new(0, 0)
	LongJumpacprogressbarframe2.Position = UDim2.new(0, 0, 0, 0)
	LongJumpacprogressbarframe2.Size = UDim2.new(1, 0, 0, 20)
	LongJumpacprogressbarframe2.BackgroundTransparency = 0
	LongJumpacprogressbarframe2.Visible = true
	LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe2.Parent = LongJumpacprogressbarframe
	local LongJumpacprogressbartext = Instance.new("TextLabel")
	LongJumpacprogressbartext.Text = "2.5s"
	LongJumpacprogressbartext.Font = Enum.Font.Gotham
	LongJumpacprogressbartext.TextStrokeTransparency = 0
	LongJumpacprogressbartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
	LongJumpacprogressbartext.TextSize = 20
	LongJumpacprogressbartext.Size = UDim2.new(1, 0, 1, 0)
	LongJumpacprogressbartext.BackgroundTransparency = 1
	LongJumpacprogressbartext.Position = UDim2.new(0, 0, -1, 0)
	LongJumpacprogressbartext.Parent = LongJumpacprogressbarframe
	LongJump = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "LongJump",
		Function = function(callback)
			if callback then
				table.insert(LongJump.Connections, vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal and damageTable.knockbackMultiplier.horizontal * LongJumpSpeed.Value or LongJumpSpeed.Value
						if damagetimertick < tick() or knockbackBoost >= damagetimer then
							damagetimer = knockbackBoost
							damagetimertick = tick() + 2.5
							local newDirection = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
							directionvec = Vector3.new(newDirection.X, 0, newDirection.Z).Unit
						end
					end
				end))
				task.spawn(function()
					task.spawn(function()
						repeat
							task.wait()
							if LongJumpacprogressbarframe then
								LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
								LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							end
						until (not LongJump.Enabled)
					end)
					local LongJumpOrigin = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.Position
					local tntcheck
					for i,v in pairs(damagemethods) do
						local item = getItem(i)
						if item then
							if i == "tnt" then
								local pos = getScaffold(LongJumpOrigin)
								tntcheck = Vector3.new(pos.X, LongJumpOrigin.Y, pos.Z)
								v(item, pos)
							else
								v(item, LongJumpOrigin)
							end
							break
						end
					end
					local changecheck
					LongJumpacprogressbarframe.Visible = true
					RunLoops:BindToHeartbeat("LongJump", function(dt)
						if entityLibrary.isAlive then
							if entityLibrary.character.Humanoid.Health <= 0 then
								LongJump.ToggleButton(false)
								return
							end
							if not LongJumpOrigin then
								LongJumpOrigin = entityLibrary.character.HumanoidRootPart.Position
							end
							local newval = damagetimer ~= 0
							if changecheck ~= newval then
								if newval then
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 2.5, true)
								else
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
								end
								changecheck = newval
							end
							if newval then
								local newnum = math.max(math.floor((damagetimertick - tick()) * 10) / 10, 0)
								if LongJumpacprogressbartext then
									LongJumpacprogressbartext.Text = newnum.."s"
								end
								if directionvec == nil then
									directionvec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
								end
								local longJumpCFrame = Vector3.new(directionvec.X, 0, directionvec.Z)
								local newvelo = longJumpCFrame.Unit == longJumpCFrame.Unit and longJumpCFrame.Unit * (newnum > 1 and damagetimer or 20) or Vector3.zero
								newvelo = Vector3.new(newvelo.X, 0, newvelo.Z)
								longJumpCFrame = longJumpCFrame * (getSpeed() + 3) * dt
								local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, longJumpCFrame, store.blockRaycast)
								if ray then
									longJumpCFrame = Vector3.zero
									newvelo = Vector3.zero
								end

								entityLibrary.character.HumanoidRootPart.Velocity = newvelo
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + longJumpCFrame
							else
								LongJumpacprogressbartext.Text = "2.5s"
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(LongJumpOrigin, LongJumpOrigin + entityLibrary.character.HumanoidRootPart.CFrame.lookVector)
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
								if tntcheck then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(tntcheck + entityLibrary.character.HumanoidRootPart.CFrame.lookVector, tntcheck + (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 2))
								end
							end
						else
							if LongJumpacprogressbartext then
								LongJumpacprogressbartext.Text = "2.5s"
							end
							LongJumpOrigin = nil
							tntcheck = nil
						end
					end)
				end)
			else
				LongJumpacprogressbarframe.Visible = false
				RunLoops:UnbindFromHeartbeat("LongJump")
				directionvec = nil
				tntcheck = nil
				LongJumpOrigin = nil
				damagetimer = 0
				damagetimertick = 0
			end
		end,
		HoverText = "Lets you jump farther (Not landing on same level & Spamming can lead to lagbacks)"
	})
	LongJumpSpeed = LongJump.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 52,
		Function = function() end,
		Default = 52
	})
end)

run(function()
	local NoFall = {Enabled = false}
	local oldfall
	NoFall = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoFall",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("GroundHit"):SendToServer()
			end
		end,
		HoverText = "Prevents taking fall damage."
	})
end)

run(function()
	local NoSlowdown = {Enabled = false}
	local OldSetSpeedFunc
	NoSlowdown = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoSlowdown",
		Function = function(callback)
			if callback then
				OldSetSpeedFunc = bedwars.SprintController.setSpeed
				bedwars.SprintController.setSpeed = function(tab1, val1)
					local hum = entityLibrary.character.Humanoid
					if hum then
						hum.WalkSpeed = math.max(20 * tab1.moveSpeedMultiplier, 20)
					end
				end
				bedwars.SprintController:setSpeed(20)
			else
				bedwars.SprintController.setSpeed = OldSetSpeedFunc
				bedwars.SprintController:setSpeed(20)
				OldSetSpeedFunc = nil
			end
		end,
		HoverText = "Prevents slowing down when using items."
	})
end)

local spiderActive = false
local holdingshift = false
run(function()
	local activatePhase = false
	local oldActivatePhase = false
	local PhaseDelay = tick()
	local Phase = {Enabled = false}
	local PhaseStudLimit = {Value = 1}
	local PhaseModifiedParts = {}
	local raycastparameters = RaycastParams.new()
	raycastparameters.RespectCanCollide = true
	raycastparameters.FilterType = Enum.RaycastFilterType.Whitelist
	local overlapparams = OverlapParams.new()
	overlapparams.RespectCanCollide = true

	local function isPointInMapOccupied(p)
		overlapparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
		local possible = workspace:GetPartBoundsInBox(CFrame.new(p), Vector3.new(1, 2, 1), overlapparams)
		return (#possible == 0)
	end

	Phase = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Phase",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Phase", function()
					if entityLibrary.isAlive and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero and (not GuiLibrary.ObjectsThatCanBeSaved.SpiderOptionsButton.Api.Enabled or holdingshift) then
						if PhaseDelay <= tick() then
							raycastparameters.FilterDescendantsInstances = {store.blocks, collectionService:GetTagged("spawn-cage"), workspace.SpectatorPlatform}
							local PhaseRayCheck = workspace:Raycast(entityLibrary.character.Head.CFrame.p, entityLibrary.character.Humanoid.MoveDirection * 1.15, raycastparameters)
							if PhaseRayCheck then
								local PhaseDirection = (PhaseRayCheck.Normal.Z ~= 0 or not PhaseRayCheck.Instance:GetAttribute("GreedyBlock")) and "Z" or "X"
								if PhaseRayCheck.Instance.Size[PhaseDirection] <= PhaseStudLimit.Value * 3 and PhaseRayCheck.Instance.CanCollide and PhaseRayCheck.Normal.Y == 0 then
									local PhaseDestination = entityLibrary.character.HumanoidRootPart.CFrame + (PhaseRayCheck.Normal * (-(PhaseRayCheck.Instance.Size[PhaseDirection]) - (entityLibrary.character.HumanoidRootPart.Size.X / 1.5)))
									if isPointInMapOccupied(PhaseDestination.p) then
										PhaseDelay = tick() + 1
										entityLibrary.character.HumanoidRootPart.CFrame = PhaseDestination
									end
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Phase")
			end
		end,
		HoverText = "Lets you Phase/Clip through walls. (Hold shift to use Phase over spider)"
	})
	PhaseStudLimit = Phase.CreateSlider({
		Name = "Blocks",
		Min = 1,
		Max = 3,
		Function = function() end
	})
end)

run(function()
	local oldCalculateAim
	local BowAimbotProjectiles = {Enabled = false}
	local BowAimbotPart = {Value = "HumanoidRootPart"}
	local BowAimbotFOV = {Value = 1000}
	local BowAimbot = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "ProjectileAimbot",
		Function = function(callback)
			if callback then
				oldCalculateAim = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(self, projmeta, worldmeta, shootpospart, ...)
					local plr = EntityNearMouse(BowAimbotFOV.Value)
					if plr then
						local startPos = self:getLaunchPosition(shootpospart)
						if not startPos then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						if (not BowAimbotProjectiles.Enabled) and projmeta.projectile:find("arrow") == nil then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						local projmetatab = projmeta:getProjectileMeta()
						local projectilePrediction = (worldmeta and projmetatab.predictionLifetimeSec or projmetatab.lifetimeSec or 3)
						local projectileSpeed = (projmetatab.launchVelocity or 100)
						local gravity = (projmetatab.gravitationalAcceleration or 196.2)
						local projectileGravity = gravity * projmeta.gravityMultiplier
						local offsetStartPos = startPos + projmeta.fromPositionOffset
						local pos = plr.Character[BowAimbotPart.Value].Position
						local playerGravity = workspace.Gravity
						local balloons = plr.Character:GetAttribute("InflatedBalloons")

						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end

						if plr.Character.PrimaryPart:FindFirstChild("rbxassetid://8200754399") then
							playerGravity = (workspace.Gravity * 0.3)
						end

						local shootpos, shootvelo = predictGravity(pos, plr.Character.HumanoidRootPart.Velocity, (pos - offsetStartPos).Magnitude / projectileSpeed, plr, playerGravity)
						if projmeta.projectile == "telepearl" then
							shootpos = pos
							shootvelo = Vector3.zero
						end

						local newlook = CFrame.new(offsetStartPos, shootpos) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, 0))
						shootpos = newlook.p + (newlook.lookVector * (offsetStartPos - shootpos).magnitude)
						local calculated = LaunchDirection(offsetStartPos, shootpos, projectileSpeed, projectileGravity, false)
						oldmove = plr.Character.Humanoid.MoveDirection
						if calculated then
							return {
								initialVelocity = calculated,
								positionFrom = offsetStartPos,
								deltaT = projectilePrediction,
								gravitationalAcceleration = projectileGravity,
								drawDurationSeconds = 5
							}
						end
					end
					return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = oldCalculateAim
			end
		end
	})
	BowAimbotPart = BowAimbot.CreateDropdown({
		Name = "Part",
		List = {"HumanoidRootPart", "Head"},
		Function = function() end
	})
	BowAimbotFOV = BowAimbot.CreateSlider({
		Name = "FOV",
		Function = function() end,
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	BowAimbotProjectiles = BowAimbot.CreateToggle({
		Name = "Other Projectiles",
		Function = function() end,
		Default = true
	})
end)

--until I find a way to make the spam switch item thing not bad I'll just get rid of it, sorry.
local Scaffold = {Enabled = false}
run(function()
	local scaffoldtext = Instance.new("TextLabel")
	scaffoldtext.Font = Enum.Font.SourceSans
	scaffoldtext.TextSize = 20
	scaffoldtext.BackgroundTransparency = 1
	scaffoldtext.TextColor3 = Color3.fromRGB(255, 0, 0)
	scaffoldtext.Size = UDim2.new(0, 0, 0, 0)
	scaffoldtext.Position = UDim2.new(0.5, 0, 0.5, 30)
	scaffoldtext.Text = "0"
	scaffoldtext.Visible = false
	scaffoldtext.Parent = GuiLibrary.MainGui
	local ScaffoldExpand = {Value = 1}
	local ScaffoldDiagonal = {Enabled = false}
	local ScaffoldTower = {Enabled = false}
	local ScaffoldDownwards = {Enabled = false}
	local ScaffoldStopMotion = {Enabled = false}
	local ScaffoldBlockCount = {Enabled = false}
	local ScaffoldHandCheck = {Enabled = false}
	local ScaffoldMouseCheck = {Enabled = false}
	local ScaffoldAnimation = {Enabled = false}
	local scaffoldstopmotionval = false
	local scaffoldposcheck = tick()
	local scaffoldstopmotionpos = Vector3.zero
	local scaffoldposchecklist = {}
	task.spawn(function()
		for x = -3, 3, 3 do
			for y = -3, 3, 3 do
				for z = -3, 3, 3 do
					if Vector3.new(x, y, z) ~= Vector3.new(0, 0, 0) then
						table.insert(scaffoldposchecklist, Vector3.new(x, y, z))
					end
				end
			end
		end
	end)

	local function checkblocks(pos)
		for i,v in pairs(scaffoldposchecklist) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function closestpos(block, pos)
		local startpos = block.Position - (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local speedCFrame = block.Position + (pos - block.Position)
		return Vector3.new(math.clamp(speedCFrame.X, startpos.X, endpos.X), math.clamp(speedCFrame.Y, startpos.Y, endpos.Y), math.clamp(speedCFrame.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag, pos)
		local closest, closestmag = pos, newmag * 3
		if entityLibrary.isAlive then
			for i,v in pairs(store.blocks) do
				local close = closestpos(v, pos)
				local mag = (close - pos).magnitude
				if mag <= closestmag then
					closest = close
					closestmag = mag
				end
			end
		end
		return closest
	end

	local oldspeed
	Scaffold = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Scaffold",
		Function = function(callback)
			if callback then
				scaffoldtext.Visible = ScaffoldBlockCount.Enabled
				if entityLibrary.isAlive then
					scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
				end
				task.spawn(function()
					repeat
						task.wait()
						if ScaffoldHandCheck.Enabled then
							if store.localHand.Type ~= "block" then continue end
						end
						if ScaffoldMouseCheck.Enabled then
							if not inputService:IsMouseButtonPressed(0) then continue end
						end
						if entityLibrary.isAlive then
							local wool, woolamount = getWool()
							if store.localHand.Type == "block" then
								wool = store.localHand.tool.Name
								woolamount = getItem(store.localHand.tool.Name).amount or 0
							elseif (not wool) then
								wool, woolamount = getBlock()
							end

							scaffoldtext.Text = (woolamount and tostring(woolamount) or "0")
							scaffoldtext.TextColor3 = woolamount and (woolamount >= 128 and Color3.fromRGB(9, 255, 198) or woolamount >= 64 and Color3.fromRGB(255, 249, 18)) or Color3.fromRGB(255, 0, 0)
							if not wool then continue end

							local towering = ScaffoldTower.Enabled and inputService:IsKeyDown(Enum.KeyCode.Space) and game:GetService("UserInputService"):GetFocusedTextBox() == nil
							if towering then
								if (not scaffoldstopmotionval) and ScaffoldStopMotion.Enabled then
									scaffoldstopmotionval = true
									scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
								end
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 28, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								if ScaffoldStopMotion.Enabled and scaffoldstopmotionval then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(scaffoldstopmotionpos.X, entityLibrary.character.HumanoidRootPart.CFrame.p.Y, scaffoldstopmotionpos.Z))
								end
							else
								scaffoldstopmotionval = false
							end

							for i = 1, ScaffoldExpand.Value do
								local speedCFrame = getScaffold((entityLibrary.character.HumanoidRootPart.Position + ((scaffoldstopmotionval and Vector3.zero or entityLibrary.character.Humanoid.MoveDirection) * (i * 3.5))) + Vector3.new(0, -((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight + (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and ScaffoldDownwards.Enabled and 4.5 or 1.5))), 0)
								speedCFrame = Vector3.new(speedCFrame.X, speedCFrame.Y - (towering and 4 or 0), speedCFrame.Z)
								if speedCFrame ~= oldpos then
									if not checkblocks(speedCFrame) then
										local oldspeedCFrame = speedCFrame
										speedCFrame = getScaffold(getclosesttop(20, speedCFrame))
										if getPlacedBlock(speedCFrame) then speedCFrame = oldspeedCFrame end
									end
									if ScaffoldAnimation.Enabled then
										if not getPlacedBlock(speedCFrame) then
										bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
										end
									end
									task.spawn(bedwars.placeBlock, speedCFrame, wool, ScaffoldAnimation.Enabled)
									if ScaffoldExpand.Value > 1 then
										task.wait()
									end
									oldpos = speedCFrame
								end
							end
						end
					until (not Scaffold.Enabled)
				end)
			else
				scaffoldtext.Visible = false
				oldpos = Vector3.zero
				oldpos2 = Vector3.zero
			end
		end,
		HoverText = "Helps you make bridges/scaffold walk."
	})
	ScaffoldExpand = Scaffold.CreateSlider({
		Name = "Expand",
		Min = 1,
		Max = 8,
		Function = function(val) end,
		Default = 1,
		HoverText = "Build range"
	})
	ScaffoldDiagonal = Scaffold.CreateToggle({
		Name = "Diagonal",
		Function = function(callback) end,
		Default = true
	})
	ScaffoldTower = Scaffold.CreateToggle({
		Name = "Tower",
		Function = function(callback)
			if ScaffoldStopMotion.Object then
				ScaffoldTower.Object.ToggleArrow.Visible = callback
				ScaffoldStopMotion.Object.Visible = callback
			end
		end
	})
	ScaffoldMouseCheck = Scaffold.CreateToggle({
		Name = "Require mouse down",
		Function = function(callback) end,
		HoverText = "Only places when left click is held.",
	})
	ScaffoldDownwards  = Scaffold.CreateToggle({
		Name = "Downwards",
		Function = function(callback) end,
		HoverText = "Goes down when left shift is held."
	})
	ScaffoldStopMotion = Scaffold.CreateToggle({
		Name = "Stop Motion",
		Function = function() end,
		HoverText = "Stops your movement when going up"
	})
	ScaffoldStopMotion.Object.BackgroundTransparency = 0
	ScaffoldStopMotion.Object.BorderSizePixel = 0
	ScaffoldStopMotion.Object.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ScaffoldStopMotion.Object.Visible = ScaffoldTower.Enabled
	ScaffoldBlockCount = Scaffold.CreateToggle({
		Name = "Block Count",
		Function = function(callback)
			if Scaffold.Enabled then
				scaffoldtext.Visible = callback
			end
		end,
		HoverText = "Shows the amount of blocks in the middle."
	})
	ScaffoldHandCheck = Scaffold.CreateToggle({
		Name = "Whitelist Only",
		Function = function() end,
		HoverText = "Only builds with blocks in your hand."
	})
	ScaffoldAnimation = Scaffold.CreateToggle({
		Name = "Animation",
		Function = function() end
	})
end)

local antivoidvelo
run(function()
	local Speed = {Enabled = false}
	local SpeedMode = {Value = "CFrame"}
	local SpeedValue = {Value = 1}
	local SpeedValueLarge = {Value = 1}
	local SpeedJump = {Enabled = false}
	local SpeedJumpHeight = {Value = 20}
	local SpeedJumpAlways = {Enabled = false}
	local SpeedJumpSound = {Enabled = false}
	local SpeedJumpVanilla = {Enabled = false}
	local SpeedAnimation = {Enabled = false}
	local raycastparameters = RaycastParams.new()

	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	Speed = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Speed",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Speed", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if not (isnetworkowner(entityLibrary.character.HumanoidRootPart) and entityLibrary.character.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and (not spiderActive) and (not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled)) then return end
						if GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton and GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton.Api.Enabled then return end
						if LongJump.Enabled then return end
						if SpeedAnimation.Enabled then
							for i, v in pairs(entityLibrary.character.Humanoid:GetPlayingAnimationTracks()) do
								if v.Name == "WalkAnim" or v.Name == "RunAnim" then
									v:AdjustSpeed(entityLibrary.character.Humanoid.WalkSpeed / 16)
								end
							end
						end

						local speedValue = SpeedValue.Value + getSpeed()
						local speedVelocity = entityLibrary.character.Humanoid.MoveDirection * (SpeedMode.Value == "Normal" and SpeedValue.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = antivoidvelo or Vector3.new(speedVelocity.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, speedVelocity.Z)
						if SpeedMode.Value ~= "Normal" then
							local speedCFrame = entityLibrary.character.Humanoid.MoveDirection * (speedValue - 20) * delta
							raycastparameters.FilterDescendantsInstances = {lplr.Character}
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, speedCFrame, raycastparameters)
							if ray then speedCFrame = (ray.Position - entityLibrary.character.HumanoidRootPart.Position) end
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + speedCFrame
						end

						if SpeedJump.Enabled and (not Scaffold.Enabled) and (SpeedJumpAlways.Enabled or killauraNearPlayer) then
							if (entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air) and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero then
								if SpeedJumpSound.Enabled then
									pcall(function() entityLibrary.character.HumanoidRootPart.Jumping:Play() end)
								end
								if SpeedJumpVanilla.Enabled then
									entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								else
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, SpeedJumpHeight.Value, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Speed")
			end
		end,
		HoverText = "Increases your movement.",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	SpeedValue = Speed.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedValueLarge = Speed.CreateSlider({
		Name = "Big Mode Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedJump = Speed.CreateToggle({
		Name = "AutoJump",
		Function = function(callback)
			if SpeedJumpHeight.Object then SpeedJumpHeight.Object.Visible = callback end
			if SpeedJumpAlways.Object then
				SpeedJump.Object.ToggleArrow.Visible = callback
				SpeedJumpAlways.Object.Visible = callback
			end
			if SpeedJumpSound.Object then SpeedJumpSound.Object.Visible = callback end
			if SpeedJumpVanilla.Object then SpeedJumpVanilla.Object.Visible = callback end
		end,
		Default = true
	})
	SpeedJumpHeight = Speed.CreateSlider({
		Name = "Jump Height",
		Min = 0,
		Max = 30,
		Default = 25,
		Function = function() end
	})
	SpeedJumpAlways = Speed.CreateToggle({
		Name = "Always Jump",
		Function = function() end
	})
	SpeedJumpSound = Speed.CreateToggle({
		Name = "Jump Sound",
		Function = function() end
	})
	SpeedJumpVanilla = Speed.CreateToggle({
		Name = "Real Jump",
		Function = function() end
	})
	SpeedAnimation = Speed.CreateToggle({
		Name = "Slowdown Anim",
		Function = function() end
	})
end)

run(function()
	local function roundpos(dir, pos, size)
		local suc, res = pcall(function() return Vector3.new(math.clamp(dir.X, pos.X - (size.X / 2), pos.X + (size.X / 2)), math.clamp(dir.Y, pos.Y - (size.Y / 2), pos.Y + (size.Y / 2)), math.clamp(dir.Z, pos.Z - (size.Z / 2), pos.Z + (size.Z / 2))) end)
		return suc and res or Vector3.zero
	end

	local Spider = {Enabled = false}
	local SpiderSpeed = {Value = 0}
	local SpiderMode = {Value = "Normal"}
	local SpiderPart
	Spider = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Spider",
		Function = function(callback)
			if callback then
				table.insert(Spider.Connections, inputService.InputBegan:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = true
					end
				end))
				table.insert(Spider.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = false
					end
				end))
				RunLoops:BindToHeartbeat("Spider", function()
					if entityLibrary.isAlive and (GuiLibrary.ObjectsThatCanBeSaved.PhaseOptionsButton.Api.Enabled == false or holdingshift == false) then
						if SpiderMode.Value == "Normal" then
							local vec = entityLibrary.character.Humanoid.MoveDirection * 2
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec + Vector3.new(0, 0.1, 0)))
							local newray2 = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray and (not newray.CanCollide) then newray = nil end
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							if spiderActive and (not newray) and (not newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 0, entityLibrary.character.HumanoidRootPart.Velocity.Z)
							end
							spiderActive = ((newray or newray2) and true or false)
							if (newray or newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.X or 0, SpiderSpeed.Value, newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.Z or 0)
							end
						else
							if not SpiderPart then
								SpiderPart = Instance.new("TrussPart")
								SpiderPart.Size = Vector3.new(2, 2, 2)
								SpiderPart.Transparency = 1
								SpiderPart.Anchored = true
								SpiderPart.Parent = gameCamera
							end
							local newray2, newray2pos = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + ((entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 1.5) - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							spiderActive = (newray2 and true or false)
							if newray2 then
								newray2pos = newray2pos * 3
								local newpos = roundpos(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(newray2pos.X, math.min(entityLibrary.character.HumanoidRootPart.Position.Y, newray2pos.Y), newray2pos.Z), Vector3.new(1.1, 1.1, 1.1))
								SpiderPart.Position = newpos
							else
								SpiderPart.Position = Vector3.zero
							end
						end
					end
				end)
			else
				if SpiderPart then SpiderPart:Destroy() end
				RunLoops:UnbindFromHeartbeat("Spider")
				holdingshift = false
			end
		end,
		HoverText = "Lets you climb up walls"
	})
	SpiderMode = Spider.CreateDropdown({
		Name = "Mode",
		List = {"Normal", "Classic"},
		Function = function()
			if SpiderPart then SpiderPart:Destroy() end
		end
	})
	SpiderSpeed = Spider.CreateSlider({
		Name = "Speed",
		Min = 0,
		Max = 40,
		Function = function() end,
		Default = 40
	})
end)

run(function()
	local TargetStrafe = {Enabled = false}
	local TargetStrafeRange = {Value = 18}
	local oldmove
	local controlmodule
	local block
	TargetStrafe = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "TargetStrafe",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if not controlmodule then
						local suc = pcall(function() controlmodule = require(lplr.PlayerScripts.PlayerModule).controls end)
						if not suc then controlmodule = {} end
					end
					oldmove = controlmodule.moveFunction
					local ang = 0
					local oldplr
					block = Instance.new("Part")
					block.Anchored = true
					block.CanCollide = false
					block.Parent = gameCamera
					controlmodule.moveFunction = function(Self, vec, facecam, ...)
						if entityLibrary.isAlive then
							local plr = AllNearPosition(TargetStrafeRange.Value + 5, 10)[1]
							plr = plr and (not workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position), store.blockRaycast)) and workspace:Raycast(plr.RootPart.Position, Vector3.new(0, -70, 0), store.blockRaycast) and plr or nil
							if plr ~= oldplr then
								if plr then
									local x, y, z = CFrame.new(plr.RootPart.Position, entityLibrary.character.HumanoidRootPart.Position):ToEulerAnglesXYZ()
									ang = math.deg(z)
								end
								oldplr = plr
							end
							if plr then
								facecam = false
								local localPos = CFrame.new(plr.RootPart.Position)
								local ray = workspace:Blockcast(localPos, Vector3.new(3, 3, 3), CFrame.Angles(0, math.rad(ang), 0).lookVector * TargetStrafeRange.Value, store.blockRaycast)
								local newPos = localPos + (CFrame.Angles(0, math.rad(ang), 0).lookVector * (ray and ray.Distance - 1 or TargetStrafeRange.Value))
								local factor = getSpeed() > 0 and 6 or 4
								if not workspace:Raycast(newPos.p, Vector3.new(0, -70, 0), store.blockRaycast) then
									newPos = localPos
									factor = 40
								end
								if ((entityLibrary.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)) - (newPos.p * Vector3.new(1, 0, 1))).Magnitude < 4 or ray then
									ang = ang + factor % 360
								end
								block.Position = newPos.p
								vec = (newPos.p - entityLibrary.character.HumanoidRootPart.Position) * Vector3.new(1, 0, 1)
							end
						end
						return oldmove(Self, vec, facecam, ...)
					end
				end)
			else
				block:Destroy()
				controlmodule.moveFunction = oldmove
			end
		end
	})
	TargetStrafeRange = TargetStrafe.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end
	})
end)

run(function()
	local BedESP = {Enabled = false}
	local BedESPFolder = Instance.new("Folder")
	BedESPFolder.Name = "BedESPFolder"
	BedESPFolder.Parent = GuiLibrary.MainGui
	local BedESPTable = {}
	local BedESPColor = {Value = 0.44}
	local BedESPTransparency = {Value = 1}
	local BedESPOnTop = {Enabled = true}
	BedESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedESP",
		Function = function(callback)
			if callback then
				table.insert(BedESP.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(bed)
					task.wait(0.2)
					if not BedESP.Enabled then return end
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart.Name ~= 'Bed' then continue end
						local boxhandle = Instance.new("BoxHandleAdornment")
						boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
						boxhandle.AlwaysOnTop = true
						boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
						boxhandle.Visible = true
						boxhandle.Adornee = bedesppart
						boxhandle.Color3 = bedesppart.Color
						boxhandle.Name = bedespnumber
						boxhandle.Parent = BedFolder
					end
				end))
				table.insert(BedESP.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(bed)
					if BedESPTable[bed] then
						BedESPTable[bed]:Destroy()
						BedESPTable[bed] = nil
					end
				end))
				for i, bed in pairs(collectionService:GetTagged("bed")) do
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart:IsA("BasePart") then
							local boxhandle = Instance.new("BoxHandleAdornment")
							boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
							boxhandle.AlwaysOnTop = true
							boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
							boxhandle.Visible = true
							boxhandle.Adornee = bedesppart
							boxhandle.Color3 = bedesppart.Color
							boxhandle.Parent = BedFolder
						end
					end
				end
			else
				BedESPFolder:ClearAllChildren()
				table.clear(BedESPTable)
			end
		end,
		HoverText = "Render Beds through walls"
	})
end)

run(function()
	local function getallblocks2(pos, normal)
		local blocks = {}
		local lastfound = nil
		for i = 1, 20 do
			local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
			local extrablock = getPlacedBlock(blockpos)
			local covered = true
			if extrablock and extrablock.Parent ~= nil then
				if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) then
					table.insert(blocks, extrablock:GetAttribute("NoBreak") and "unbreakable" or extrablock.Name)
				else
					table.insert(blocks, "unbreakable")
					break
				end
				lastfound = extrablock
				if covered == false then
					break
				end
			else
				break
			end
		end
		return blocks
	end

	local function getallbedblocks(pos)
		local blocks = {}
		for i,v in pairs(cachedNormalSides) do
			for i2,v2 in pairs(getallblocks2(pos, v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
			for i2,v2 in pairs(getallblocks2(pos + Vector3.new(0, 0, 3), v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
		end
		return blocks
	end

	local function refreshAdornee(v)
		local bedblocks = getallbedblocks(v.Adornee.Position)
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(bedblocks) do
			local blockimage = Instance.new("ImageLabel")
			blockimage.Size = UDim2.new(0, 32, 0, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = v3}, true)
			blockimage.Parent = v.Frame
		end
	end

	local BedPlatesFolder = Instance.new("Folder")
	BedPlatesFolder.Name = "BedPlatesFolder"
	BedPlatesFolder.Parent = GuiLibrary.MainGui
	local BedPlatesTable = {}
	local BedPlates = {Enabled = false}

	local function addBed(v)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = BedPlatesFolder
		billboard.Name = "bed"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 42, 0, 42)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		BedPlatesTable[v] = billboard
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.5
		frame.Parent = billboard
		local uilistlayout = Instance.new("UIListLayout")
		uilistlayout.FillDirection = Enum.FillDirection.Horizontal
		uilistlayout.Padding = UDim.new(0, 4)
		uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
		end)
		uilistlayout.Parent = frame
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = frame
		refreshAdornee(billboard)
	end

	BedPlates = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedPlates",
		Function = function(callback)
			if callback then
				table.insert(BedPlates.Connections, vapeEvents.PlaceBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, vapeEvents.BreakBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(v)
					addBed(v)
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(v)
					if BedPlatesTable[v] then
						BedPlatesTable[v]:Destroy()
						BedPlatesTable[v] = nil
					end
				end))
				for i, v in pairs(collectionService:GetTagged("bed")) do
					addBed(v)
				end
			else
				BedPlatesFolder:ClearAllChildren()
			end
		end
	})
end)

run(function()
	local ChestESPList = {ObjectList = {}, RefreshList = function() end}
	local function nearchestitem(item)
		for i,v in pairs(ChestESPList.ObjectList) do
			if item:find(v) then return v end
		end
	end
	local function refreshAdornee(v)
		local chest = v:FindFirstChild("ChestFolderValue")
		chest = chest and chest.Value or nil
		if not chest then return end
		local chestitems = chest and chest:GetChildren() or {}
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		v.Enabled = false
		local alreadygot = {}
		for itemNumber, item in pairs(chestitems) do
			if alreadygot[item.Name] == nil and (table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new("ImageLabel")
				blockimage.Size = UDim2.new(0, 32, 0, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
			end
		end
	end

	local ChestESPFolder = Instance.new("Folder")
	ChestESPFolder.Name = "ChestESPFolder"
	ChestESPFolder.Parent = GuiLibrary.MainGui
	local ChestESP = {Enabled = false}
	local ChestESPBackground = {Enabled = true}

	local function chestfunc(v)
		task.spawn(function()
			local chest = v:FindFirstChild("ChestFolderValue")
			chest = chest and chest.Value or nil
			if not chest then return end
			local billboard = Instance.new("BillboardGui")
			billboard.Parent = ChestESPFolder
			billboard.Name = "chest"
			billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
			billboard.Size = UDim2.new(0, 42, 0, 42)
			billboard.AlwaysOnTop = true
			billboard.Adornee = v
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BackgroundTransparency = ChestESPBackground.Enabled and 0.5 or 1
			frame.Parent = billboard
			local uilistlayout = Instance.new("UIListLayout")
			uilistlayout.FillDirection = Enum.FillDirection.Horizontal
			uilistlayout.Padding = UDim.new(0, 4)
			uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
			uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
			end)
			uilistlayout.Parent = frame
			local uicorner = Instance.new("UICorner")
			uicorner.CornerRadius = UDim.new(0, 4)
			uicorner.Parent = frame
			if chest then
				table.insert(ChestESP.Connections, chest.ChildAdded:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				table.insert(ChestESP.Connections, chest.ChildRemoved:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				refreshAdornee(billboard)
			end
		end)
	end

	ChestESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "ChestESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					table.insert(ChestESP.Connections, collectionService:GetInstanceAddedSignal("chest"):Connect(chestfunc))
					for i,v in pairs(collectionService:GetTagged("chest")) do chestfunc(v) end
				end)
			else
				ChestESPFolder:ClearAllChildren()
			end
		end
	})
	ChestESPList = ChestESP.CreateTextList({
		Name = "ItemList",
		TempText = "item or part of item",
		AddFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		RemoveFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end
	})
	ChestESPBackground = ChestESP.CreateToggle({
		Name = "Background",
		Function = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		Default = true
	})
end)

run(function()
	local FieldOfViewValue = {Value = 70}
	local oldfov
	local oldfov2
	local FieldOfView = {Enabled = false}
	local FieldOfViewZoom = {Enabled = false}
	FieldOfView = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FOVChanger",
		Function = function(callback)
			if callback then
				if FieldOfViewZoom.Enabled then
					task.spawn(function()
						repeat
							task.wait()
						until not inputService:IsKeyDown(Enum.KeyCode[FieldOfView.Keybind ~= "" and FieldOfView.Keybind or "C"])
						if FieldOfView.Enabled then
							FieldOfView.ToggleButton(false)
						end
					end)
				end
				oldfov = bedwars.FovController.setFOV
				oldfov2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self, fov) return oldfov(self, FieldOfViewValue.Value) end
				bedwars.FovController.getFOV = function(self, fov) return FieldOfViewValue.Value end
			else
				bedwars.FovController.setFOV = oldfov
				bedwars.FovController.getFOV = oldfov2
			end
			bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
		end
	})
	FieldOfViewValue = FieldOfView.CreateSlider({
		Name = "FOV",
		Min = 30,
		Max = 120,
		Function = function(val)
			if FieldOfView.Enabled then
				bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
			end
		end
	})
	FieldOfViewZoom = FieldOfView.CreateToggle({
		Name = "Zoom",
		Function = function() end,
		HoverText = "optifine zoom lol"
	})
end)

run(function()
	local old
	local old2
	local oldhitpart
	local FPSBoost = {Enabled = false}
	local removetextures = {Enabled = false}
	local removetexturessmooth = {Enabled = false}
	local fpsboostdamageindicator = {Enabled = false}
	local fpsboostdamageeffect = {Enabled = false}
	local fpsboostkilleffect = {Enabled = false}
	local originaltextures = {}
	local originaleffects = {}

	local function fpsboosttextures()
		task.spawn(function()
			repeat task.wait() until store.matchState ~= 0
			for i,v in pairs(store.blocks) do
				if v:GetAttribute("PlacedByUserId") == 0 then
					v.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
					originaltextures[v] = originaltextures[v] or v.MaterialVariant
					v.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v]
					for i2,v2 in pairs(v:GetChildren()) do
						pcall(function()
							v2.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
							originaltextures[v2] = originaltextures[v2] or v2.MaterialVariant
							v2.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v2]
						end)
					end
				end
			end
		end)
	end

	FPSBoost = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FPSBoost",
		Function = function(callback)
			local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
			if callback then
				wasenabled = true
				fpsboosttextures()
				if fpsboostdamageindicator.Enabled then
					damagetab.strokeThickness = 0
					damagetab.textSize = 0
					damagetab.blowUpDuration = 0
					damagetab.blowUpSize = 0
				end
				if fpsboostkilleffect.Enabled then
					for i,v in pairs(bedwars.KillEffectController.killEffects) do
						originaleffects[i] = v
						bedwars.KillEffectController.killEffects[i] = {new = function(char) return {onKill = function() end, isPlayDefaultKillEffect = function() return char == lplr.Character end} end}
					end
				end
				if fpsboostdamageeffect.Enabled then
					oldhitpart = bedwars.DamageIndicatorController.hitEffectPart
					bedwars.DamageIndicatorController.hitEffectPart = nil
				end
				old = bedwars.EntityHighlightController.highlight
				old2 = getmetatable(bedwars.StopwatchController).tweenOutGhost
				local highlighttable = {}
				getmetatable(bedwars.StopwatchController).tweenOutGhost = function(p17, p18)
					p18:Destroy()
				end
				bedwars.EntityHighlightController.highlight = function() end
			else
				for i,v in pairs(originaleffects) do
					bedwars.KillEffectController.killEffects[i] = v
				end
				fpsboosttextures()
				if oldhitpart then
					bedwars.DamageIndicatorController.hitEffectPart = oldhitpart
				end
				debug.setupvalue(bedwars.KillEffectController.KnitStart, 2, require(lplr.PlayerScripts.TS["client-sync-events"]).ClientSyncEvents)
				damagetab.strokeThickness = 1.5
				damagetab.textSize = 28
				damagetab.blowUpDuration = 0.125
				damagetab.blowUpSize = 76
				debug.setupvalue(bedwars.DamageIndicator, 10, tweenService)
				if bedwars.DamageIndicatorController.hitEffectPart then
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Cubes.Enabled = true
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Shards.Enabled = true
				end
				bedwars.EntityHighlightController.highlight = old
				getmetatable(bedwars.StopwatchController).tweenOutGhost = old2
				old = nil
				old2 = nil
			end
		end
	})
	removetextures = FPSBoost.CreateToggle({
		Name = "Remove Textures",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageindicator = FPSBoost.CreateToggle({
		Name = "Remove Damage Indicator",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageeffect = FPSBoost.CreateToggle({
		Name = "Remove Damage Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostkilleffect = FPSBoost.CreateToggle({
		Name = "Remove Kill Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
end)

run(function()
	local GameFixer = {Enabled = false}
	local GameFixerHit = {Enabled = false}
	GameFixer = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameFixer",
		Function = function(callback)
			debug.setconstant(bedwars.SwordController.swingSwordAtMouse, 23, callback and 'raycast' or 'Raycast')
			debug.setupvalue(bedwars.SwordController.swingSwordAtMouse, 4, callback and bedwars.QueryUtil or workspace)
		end,
		HoverText = "Fixes game bugs"
	})
end)

run(function()
	local transformed = false
	local GameTheme = {Enabled = false}
	local GameThemeMode = {Value = "GameTheme"}

	local themefunctions = {
		Old = function()
			task.spawn(function()
				local oldbedwarstabofimages = '{"clay_orange":"rbxassetid://7017703219","iron":"rbxassetid://6850537969","glass":"rbxassetid://6909521321","log_spruce":"rbxassetid://6874161124","ice":"rbxassetid://6874651262","marble":"rbxassetid://6594536339","zipline_base":"rbxassetid://7051148904","iron_helmet":"rbxassetid://6874272559","marble_pillar":"rbxassetid://6909323822","clay_dark_green":"rbxassetid://6763635916","wood_plank_birch":"rbxassetid://6768647328","watering_can":"rbxassetid://6915423754","emerald_helmet":"rbxassetid://6931675766","pie":"rbxassetid://6985761399","wood_plank_spruce":"rbxassetid://6768615964","diamond_chestplate":"rbxassetid://6874272898","wool_pink":"rbxassetid://6910479863","wool_blue":"rbxassetid://6910480234","wood_plank_oak":"rbxassetid://6910418127","diamond_boots":"rbxassetid://6874272964","clay_yellow":"rbxassetid://4991097283","tnt":"rbxassetid://6856168996","lasso":"rbxassetid://7192710930","clay_purple":"rbxassetid://6856099740","melon_seeds":"rbxassetid://6956387796","apple":"rbxassetid://6985765179","carrot_seeds":"rbxassetid://6956387835","log_oak":"rbxassetid://6763678414","emerald_chestplate":"rbxassetid://6931675868","wool_yellow":"rbxassetid://6910479606","emerald_boots":"rbxassetid://6931675942","clay_light_brown":"rbxassetid://6874651634","balloon":"rbxassetid://7122143895","cannon":"rbxassetid://7121221753","leather_boots":"rbxassetid://6855466456","melon":"rbxassetid://6915428682","wool_white":"rbxassetid://6910387332","log_birch":"rbxassetid://6763678414","clay_pink":"rbxassetid://6856283410","grass":"rbxassetid://6773447725","obsidian":"rbxassetid://6910443317","shield":"rbxassetid://7051149149","red_sandstone":"rbxassetid://6708703895","diamond_helmet":"rbxassetid://6874272793","wool_orange":"rbxassetid://6910479956","log_hickory":"rbxassetid://7017706899","guitar":"rbxassetid://7085044606","wool_purple":"rbxassetid://6910479777","diamond":"rbxassetid://6850538161","iron_chestplate":"rbxassetid://6874272631","slime_block":"rbxassetid://6869284566","stone_brick":"rbxassetid://6910394475","hammer":"rbxassetid://6955848801","ceramic":"rbxassetid://6910426690","wood_plank_maple":"rbxassetid://6768632085","leather_helmet":"rbxassetid://6855466216","stone":"rbxassetid://6763635916","slate_brick":"rbxassetid://6708836267","sandstone":"rbxassetid://6708657090","snow":"rbxassetid://6874651192","wool_red":"rbxassetid://6910479695","leather_chestplate":"rbxassetid://6876833204","clay_red":"rbxassetid://6856283323","wool_green":"rbxassetid://6910480050","clay_white":"rbxassetid://7017705325","wool_cyan":"rbxassetid://6910480152","clay_black":"rbxassetid://5890435474","sand":"rbxassetid://6187018940","clay_light_green":"rbxassetid://6856099550","clay_dark_brown":"rbxassetid://6874651325","carrot":"rbxassetid://3677675280","clay":"rbxassetid://6856190168","iron_boots":"rbxassetid://6874272718","emerald":"rbxassetid://6850538075","zipline":"rbxassetid://7051148904"}'
				local oldbedwarsicontab = game:GetService("HttpService"):JSONDecode(oldbedwarstabofimages)
				local oldbedwarssoundtable = {
					["QUEUE_JOIN"] = "rbxassetid://6691735519",
					["QUEUE_MATCH_FOUND"] = "rbxassetid://6768247187",
					["UI_CLICK"] = "rbxassetid://6732690176",
					["UI_OPEN"] = "rbxassetid://6732607930",
					["BEDWARS_UPGRADE_SUCCESS"] = "rbxassetid://6760677364",
					["BEDWARS_PURCHASE_ITEM"] = "rbxassetid://6760677364",
					["SWORD_SWING_1"] = "rbxassetid://6760544639",
					["SWORD_SWING_2"] = "rbxassetid://6760544595",
					["DAMAGE_1"] = "rbxassetid://6765457325",
					["DAMAGE_2"] = "rbxassetid://6765470975",
					["DAMAGE_3"] = "rbxassetid://6765470941",
					["CROP_HARVEST"] = "rbxassetid://4864122196",
					["CROP_PLANT_1"] = "rbxassetid://5483943277",
					["CROP_PLANT_2"] = "rbxassetid://5483943479",
					["CROP_PLANT_3"] = "rbxassetid://5483943723",
					["ARMOR_EQUIP"] = "rbxassetid://6760627839",
					["ARMOR_UNEQUIP"] = "rbxassetid://6760625788",
					["PICKUP_ITEM_DROP"] = "rbxassetid://6768578304",
					["PARTY_INCOMING_INVITE"] = "rbxassetid://6732495464",
					["ERROR_NOTIFICATION"] = "rbxassetid://6732495464",
					["INFO_NOTIFICATION"] = "rbxassetid://6732495464",
					["END_GAME"] = "rbxassetid://6246476959",
					["GENERIC_BLOCK_PLACE"] = "rbxassetid://4842910664",
					["GENERIC_BLOCK_BREAK"] = "rbxassetid://4819966893",
					["GRASS_BREAK"] = "rbxassetid://5282847153",
					["WOOD_BREAK"] = "rbxassetid://4819966893",
					["STONE_BREAK"] = "rbxassetid://6328287211",
					["WOOL_BREAK"] = "rbxassetid://4842910664",
					["TNT_EXPLODE_1"] = "rbxassetid://7192313632",
					["TNT_HISS_1"] = "rbxassetid://7192313423",
					["FIREBALL_EXPLODE"] = "rbxassetid://6855723746",
					["SLIME_BLOCK_BOUNCE"] = "rbxassetid://6857999096",
					["SLIME_BLOCK_BREAK"] = "rbxassetid://6857999170",
					["SLIME_BLOCK_HIT"] = "rbxassetid://6857999148",
					["SLIME_BLOCK_PLACE"] = "rbxassetid://6857999119",
					["BOW_DRAW"] = "rbxassetid://6866062236",
					["BOW_FIRE"] = "rbxassetid://6866062104",
					["ARROW_HIT"] = "rbxassetid://6866062188",
					["ARROW_IMPACT"] = "rbxassetid://6866062148",
					["TELEPEARL_THROW"] = "rbxassetid://6866223756",
					["TELEPEARL_LAND"] = "rbxassetid://6866223798",
					["CROSSBOW_RELOAD"] = "rbxassetid://6869254094",
					["VOICE_1"] = "rbxassetid://5283866929",
					["VOICE_2"] = "rbxassetid://5283867710",
					["VOICE_HONK"] = "rbxassetid://5283872555",
					["FORTIFY_BLOCK"] = "rbxassetid://6955762535",
					["EAT_FOOD_1"] = "rbxassetid://4968170636",
					["KILL"] = "rbxassetid://7013482008",
					["ZIPLINE_TRAVEL"] = "rbxassetid://7047882304",
					["ZIPLINE_LATCH"] = "rbxassetid://7047882233",
					["ZIPLINE_UNLATCH"] = "rbxassetid://7047882265",
					["SHIELD_BLOCKED"] = "rbxassetid://6955762535",
					["GUITAR_LOOP"] = "rbxassetid://7084168540",
					["GUITAR_HEAL_1"] = "rbxassetid://7084168458",
					["CANNON_MOVE"] = "rbxassetid://7118668472",
					["CANNON_FIRE"] = "rbxassetid://7121064180",
					["BALLOON_INFLATE"] = "rbxassetid://7118657911",
					["BALLOON_POP"] = "rbxassetid://7118657873",
					["FIREBALL_THROW"] = "rbxassetid://7192289445",
					["LASSO_HIT"] = "rbxassetid://7192289603",
					["LASSO_SWING"] = "rbxassetid://7192289504",
					["LASSO_THROW"] = "rbxassetid://7192289548",
					["GRIM_REAPER_CONSUME"] = "rbxassetid://7225389554",
					["GRIM_REAPER_CHANNEL"] = "rbxassetid://7225389512",
					["TV_STATIC"] = "rbxassetid://7256209920",
					["TURRET_ON"] = "rbxassetid://7290176291",
					["TURRET_OFF"] = "rbxassetid://7290176380",
					["TURRET_ROTATE"] = "rbxassetid://7290176421",
					["TURRET_SHOOT"] = "rbxassetid://7290187805",
					["WIZARD_LIGHTNING_CAST"] = "rbxassetid://7262989886",
					["WIZARD_LIGHTNING_LAND"] = "rbxassetid://7263165647",
					["WIZARD_LIGHTNING_STRIKE"] = "rbxassetid://7263165347",
					["WIZARD_ORB_CAST"] = "rbxassetid://7263165448",
					["WIZARD_ORB_TRAVEL_LOOP"] = "rbxassetid://7263165579",
					["WIZARD_ORB_CONTACT_LOOP"] = "rbxassetid://7263165647",
					["BATTLE_PASS_PROGRESS_LEVEL_UP"] = "rbxassetid://7331597283",
					["BATTLE_PASS_PROGRESS_EXP_GAIN"] = "rbxassetid://7331597220",
					["FLAMETHROWER_UPGRADE"] = "rbxassetid://7310273053",
					["FLAMETHROWER_USE"] = "rbxassetid://7310273125",
					["BRITTLE_HIT"] = "rbxassetid://7310273179",
					["EXTINGUISH"] = "rbxassetid://7310273015",
					["RAVEN_SPACE_AMBIENT"] = "rbxassetid://7341443286",
					["RAVEN_WING_FLAP"] = "rbxassetid://7341443378",
					["RAVEN_CAW"] = "rbxassetid://7341443447",
					["JADE_HAMMER_THUD"] = "rbxassetid://7342299402",
					["STATUE"] = "rbxassetid://7344166851",
					["CONFETTI"] = "rbxassetid://7344278405",
					["HEART"] = "rbxassetid://7345120916",
					["SPRAY"] = "rbxassetid://7361499529",
					["BEEHIVE_PRODUCE"] = "rbxassetid://7378100183",
					["DEPOSIT_BEE"] = "rbxassetid://7378100250",
					["CATCH_BEE"] = "rbxassetid://7378100305",
					["BEE_NET_SWING"] = "rbxassetid://7378100350",
					["ASCEND"] = "rbxassetid://7378387334",
					["BED_ALARM"] = "rbxassetid://7396762708",
					["BOUNTY_CLAIMED"] = "rbxassetid://7396751941",
					["BOUNTY_ASSIGNED"] = "rbxassetid://7396752155",
					["BAGUETTE_HIT"] = "rbxassetid://7396760547",
					["BAGUETTE_SWING"] = "rbxassetid://7396760496",
					["TESLA_ZAP"] = "rbxassetid://7497477336",
					["SPIRIT_TRIGGERED"] = "rbxassetid://7498107251",
					["SPIRIT_EXPLODE"] = "rbxassetid://7498107327",
					["ANGEL_LIGHT_ORB_CREATE"] = "rbxassetid://7552134231",
					["ANGEL_LIGHT_ORB_HEAL"] = "rbxassetid://7552134868",
					["ANGEL_VOID_ORB_CREATE"] = "rbxassetid://7552135942",
					["ANGEL_VOID_ORB_HEAL"] = "rbxassetid://7552136927",
					["DODO_BIRD_JUMP"] = "rbxassetid://7618085391",
					["DODO_BIRD_DOUBLE_JUMP"] = "rbxassetid://7618085771",
					["DODO_BIRD_MOUNT"] = "rbxassetid://7618085486",
					["DODO_BIRD_DISMOUNT"] = "rbxassetid://7618085571",
					["DODO_BIRD_SQUAWK_1"] = "rbxassetid://7618085870",
					["DODO_BIRD_SQUAWK_2"] = "rbxassetid://7618085657",
					["SHIELD_CHARGE_START"] = "rbxassetid://7730842884",
					["SHIELD_CHARGE_LOOP"] = "rbxassetid://7730843006",
					["SHIELD_CHARGE_BASH"] = "rbxassetid://7730843142",
					["ROCKET_LAUNCHER_FIRE"] = "rbxassetid://7681584765",
					["ROCKET_LAUNCHER_FLYING_LOOP"] = "rbxassetid://7681584906",
					["SMOKE_GRENADE_POP"] = "rbxassetid://7681276062",
					["SMOKE_GRENADE_EMIT_LOOP"] = "rbxassetid://7681276135",
					["GOO_SPIT"] = "rbxassetid://7807271610",
					["GOO_SPLAT"] = "rbxassetid://7807272724",
					["GOO_EAT"] = "rbxassetid://7813484049",
					["LUCKY_BLOCK_BREAK"] = "rbxassetid://7682005357",
					["AXOLOTL_SWITCH_TARGETS"] = "rbxassetid://7344278405",
					["HALLOWEEN_MUSIC"] = "rbxassetid://7775602786",
					["SNAP_TRAP_SETUP"] = "rbxassetid://7796078515",
					["SNAP_TRAP_CLOSE"] = "rbxassetid://7796078695",
					["SNAP_TRAP_CONSUME_MARK"] = "rbxassetid://7796078825",
					["GHOST_VACUUM_SUCKING_LOOP"] = "rbxassetid://7814995865",
					["GHOST_VACUUM_SHOOT"] = "rbxassetid://7806060367",
					["GHOST_VACUUM_CATCH"] = "rbxassetid://7815151688",
					["FISHERMAN_GAME_START"] = "rbxassetid://7806060544",
					["FISHERMAN_GAME_PULLING_LOOP"] = "rbxassetid://7806060638",
					["FISHERMAN_GAME_PROGRESS_INCREASE"] = "rbxassetid://7806060745",
					["FISHERMAN_GAME_FISH_MOVE"] = "rbxassetid://7806060863",
					["FISHERMAN_GAME_LOOP"] = "rbxassetid://7806061057",
					["FISHING_ROD_CAST"] = "rbxassetid://7806060976",
					["FISHING_ROD_SPLASH"] = "rbxassetid://7806061193",
					["SPEAR_HIT"] = "rbxassetid://7807270398",
					["SPEAR_THROW"] = "rbxassetid://7813485044",
				}
				for i,v in pairs(bedwars.CombatController.killSounds) do
					bedwars.CombatController.killSounds[i] = oldbedwarssoundtable.KILL
				end
				for i,v in pairs(bedwars.CombatController.multiKillLoops) do
					bedwars.CombatController.multiKillLoops[i] = ""
				end
				for i,v in pairs(bedwars.ItemTable) do
					if oldbedwarsicontab[i] then
						v.image = oldbedwarsicontab[i]
					end
				end
				for i,v in pairs(oldbedwarssoundtable) do
					local item = bedwars.SoundList[i]
					if item then
						bedwars.SoundList[i] = v
					end
				end
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(214, 0, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.ViewmodelController.show, 37, "")
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				sethiddenproperty(lightingService, "Technology", "ShadowMap")
				lightingService.Ambient = Color3.fromRGB(69, 69, 69)
				lightingService.Brightness = 3
				lightingService.EnvironmentDiffuseScale = 1
				lightingService.EnvironmentSpecularScale = 1
				lightingService.OutdoorAmbient = Color3.fromRGB(69, 69, 69)
				lightingService.Atmosphere.Density = 0.1
				lightingService.Atmosphere.Offset = 0.25
				lightingService.Atmosphere.Color = Color3.fromRGB(198, 198, 198)
				lightingService.Atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				lightingService.Atmosphere.Glare = 0
				lightingService.Atmosphere.Haze = 0
				lightingService.ClockTime = 13
				lightingService.GeographicLatitude = 0
				lightingService.GlobalShadows = false
				lightingService.TimeOfDay = "13:00:00"
				lightingService.Sky.SkyboxBk = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxDn = "rbxassetid://6334928194"
				lightingService.Sky.SkyboxFt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxLf = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxRt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxUp = "rbxassetid://7018689553"
			end)
		end,
		Winter = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.StarCount = 5000
				sky.SkyboxUp = "rbxassetid://8139676647"
				sky.SkyboxLf = "rbxassetid://8139676988"
				sky.SkyboxFt = "rbxassetid://8139677111"
				sky.SkyboxBk = "rbxassetid://8139677359"
				sky.SkyboxDn = "rbxassetid://8139677253"
				sky.SkyboxRt = "rbxassetid://8139676842"
				sky.SunTextureId = "rbxassetid://6196665106"
				sky.SunAngularSize = 11
				sky.MoonTextureId = "rbxassetid://8139665943"
				sky.MoonAngularSize = 30
				sky.Parent = lightingService
				local sunray = Instance.new("SunRaysEffect")
				sunray.Intensity = 0.03
				sunray.Parent = lightingService
				local bloom = Instance.new("BloomEffect")
				bloom.Threshold = 2
				bloom.Intensity = 1
				bloom.Size = 2
				bloom.Parent = lightingService
				local atmosphere = Instance.new("Atmosphere")
				atmosphere.Density = 0.3
				atmosphere.Offset = 0.25
				atmosphere.Color = Color3.fromRGB(198, 198, 198)
				atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				atmosphere.Glare = 0
				atmosphere.Haze = 0
				atmosphere.Parent = lightingService
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(70, 255, 255)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 4653055)
			end)
			task.spawn(function()
				local snowpart = Instance.new("Part")
				snowpart.Size = Vector3.new(240, 0.5, 240)
				snowpart.Name = "SnowParticle"
				snowpart.Transparency = 1
				snowpart.CanCollide = false
				snowpart.Position = Vector3.new(0, 120, 286)
				snowpart.Anchored = true
				snowpart.Parent = workspace
				local snow = Instance.new("ParticleEmitter")
				snow.RotSpeed = NumberRange.new(300)
				snow.VelocitySpread = 35
				snow.Rate = 28
				snow.Texture = "rbxassetid://8158344433"
				snow.Rotation = NumberRange.new(110)
				snow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				snow.Lifetime = NumberRange.new(8,14)
				snow.Speed = NumberRange.new(8,18)
				snow.EmissionDirection = Enum.NormalId.Bottom
				snow.SpreadAngle = Vector2.new(35,35)
				snow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				snow.Parent = snowpart
				local windsnow = Instance.new("ParticleEmitter")
				windsnow.Acceleration = Vector3.new(0,0,1)
				windsnow.RotSpeed = NumberRange.new(100)
				windsnow.VelocitySpread = 35
				windsnow.Rate = 28
				windsnow.Texture = "rbxassetid://8158344433"
				windsnow.EmissionDirection = Enum.NormalId.Bottom
				windsnow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				windsnow.Lifetime = NumberRange.new(8,14)
				windsnow.Speed = NumberRange.new(8,18)
				windsnow.Rotation = NumberRange.new(110)
				windsnow.SpreadAngle = Vector2.new(35,35)
				windsnow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				windsnow.Parent = snowpart
				repeat
					task.wait()
					if entityLibrary.isAlive then
						snowpart.Position = entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, 100, 0)
					end
				until not vapeInjected
			end)
		end,
		Halloween = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				lightingService.TimeOfDay = "00:00:00"
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 100, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 185, 81)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16737280)
			end)
		end,
		Valentines = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.SkyboxBk = "rbxassetid://1546230803"
				sky.SkyboxDn = "rbxassetid://1546231143"
				sky.SkyboxFt = "rbxassetid://1546230803"
				sky.SkyboxLf = "rbxassetid://1546230803"
				sky.SkyboxRt = "rbxassetid://1546230803"
				sky.SkyboxUp = "rbxassetid://1546230451"
				sky.Parent = lightingService
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 132, 178)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 199, 220)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16745650)
			end)
		end
	}

	GameTheme = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameTheme",
		Function = function(callback)
			if callback then
				if not transformed then
					transformed = true
					themefunctions[GameThemeMode.Value]()
				else
					GameTheme.ToggleButton(false)
				end
			else
				warningNotification("GameTheme", "Disabled Next Game", 10)
			end
		end,
		ExtraText = function()
			return GameThemeMode.Value
		end
	})
	GameThemeMode = GameTheme.CreateDropdown({
		Name = "Theme",
		Function = function() end,
		List = {"Old", "Winter", "Halloween", "Valentines"}
	})
end)

run(function()
	local oldkilleffect
	local KillEffectMode = {Value = "Gravity"}
	local KillEffectList = {Value = "None"}
	local KillEffectName2 = {}
	local killeffects = {
		Gravity = function(p3, p4, p5, p6)
			p5:BreakJoints()
			task.spawn(function()
				local partvelo = {}
				for i,v in pairs(p5:GetDescendants()) do
					if v:IsA("BasePart") then
						partvelo[v.Name] = v.Velocity * 3
					end
				end
				p5.Archivable = true
				local clone = p5:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				local nametag = clone:FindFirstChild("Nametag", true)
				if nametag then nametag:Destroy() end
				game:GetService("Debris"):AddItem(clone, 30)
				p5:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for i,v in pairs(clone:GetDescendants()) do
					if v:IsA("BasePart") then
						local bodyforce = Instance.new("BodyForce")
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(p3, p4, p5, p6)
			p5:BreakJoints()
			local startpos = 1125
			local startcf = p5.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new("Part")
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService("Debris"):AddItem(part, 0.5)
				game:GetService("Debris"):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new("Part")
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6993372814"
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end
	}
	local KillEffectName = {}
	for i,v in pairs(bedwars.KillEffectMeta) do
		table.insert(KillEffectName, v.name)
		KillEffectName[v.name] = i
	end
	table.sort(KillEffectName, function(a, b) return a:lower() < b:lower() end)
	local KillEffect = {Enabled = false}
	KillEffect = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KillEffect",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not KillEffect.Enabled
					if KillEffect.Enabled then
						lplr:SetAttribute("KillEffectType", "none")
						if KillEffectMode.Value == "Bedwars" then
							lplr:SetAttribute("KillEffectType", KillEffectName[KillEffectList.Value])
						end
					end
				end)
				oldkilleffect = bedwars.DefaultKillEffect.onKill
				bedwars.DefaultKillEffect.onKill = function(p3, p4, p5, p6)
					killeffects[KillEffectMode.Value](p3, p4, p5, p6)
				end
			else
				bedwars.DefaultKillEffect.onKill = oldkilleffect
			end
		end
	})
	local modes = {"Bedwars"}
	for i,v in pairs(killeffects) do
		table.insert(modes, i)
	end
	KillEffectMode = KillEffect.CreateDropdown({
		Name = "Mode",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = modes
	})
	KillEffectList = KillEffect.CreateDropdown({
		Name = "Bedwars",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = KillEffectName
	})
end)

run(function()
	local KitESP = {Enabled = false}
	local espobjs = {}
	local espfold = Instance.new("Folder")
	espfold.Parent = GuiLibrary.MainGui

	local function espadd(v, icon)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = espfold
		billboard.Name = "iron"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 32, 0, 32)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 0.5
		image.BorderSizePixel = 0
		image.Image = bedwars.getIcon({itemType = icon}, true)
		image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		image.Size = UDim2.new(0, 32, 0, 32)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Parent = billboard
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		espobjs[v] = billboard
	end

	local function addKit(tag, icon)
		table.insert(KitESP.Connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			espadd(v.PrimaryPart, icon)
		end))
		table.insert(KitESP.Connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if espobjs[v.PrimaryPart] then
				espobjs[v.PrimaryPart]:Destroy()
				espobjs[v.PrimaryPart] = nil
			end
		end))
		for i,v in pairs(collectionService:GetTagged(tag)) do
			espadd(v.PrimaryPart, icon)
		end
	end

	KitESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KitESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if KitESP.Enabled then
						if store.equippedKit == "metal_detector" then
							addKit("hidden-metal", "iron")
						elseif store.equippedKit == "beekeeper" then
							addKit("bee", "bee")
						elseif store.equippedKit == "bigman" then
							addKit("treeOrb", "natures_essence_1")
						end
					end
				end)
			else
				espfold:ClearAllChildren()
				table.clear(espobjs)
			end
		end
	})
end)

run(function()
	local function floorNameTagPosition(pos)
		return Vector2.new(math.floor(pos.X), math.floor(pos.Y))
	end

	local function removeTags(str)
		str = str:gsub("<br%s*/>", "\n")
		return (str:gsub("<[^<>]->", ""))
	end

	local NameTagsFolder = Instance.new("Folder")
	NameTagsFolder.Name = "NameTagsFolder"
	NameTagsFolder.Parent = GuiLibrary.MainGui
	local nametagsfolderdrawing = {}
	local NameTagsColor = {Value = 0.44}
	local NameTagsDisplayName = {Enabled = false}
	local NameTagsHealth = {Enabled = false}
	local NameTagsDistance = {Enabled = false}
	local NameTagsBackground = {Enabled = true}
	local NameTagsScale = {Value = 10}
	local NameTagsFont = {Value = "SourceSans"}
	local NameTagsTeammates = {Enabled = true}
	local NameTagsShowInventory = {Enabled = false}
	local NameTagsRangeLimit = {Value = 0}
	local fontitems = {"SourceSans"}
	local nametagstrs = {}
	local nametagsizes = {}
	local kititems = {
		jade = "jade_hammer",
		archer = "tactical_crossbow",
		angel = "",
		cowgirl = "lasso",
		dasher = "wood_dao",
		axolotl = "axolotl",
		yeti = "snowball",
		smoke = "smoke_block",
		trapper = "snap_trap",
		pyro = "flamethrower",
		davey = "cannon",
		regent = "void_axe",
		baker = "apple",
		builder = "builder_hammer",
		farmer_cletus = "carrot_seeds",
		melody = "guitar",
		barbarian = "rageblade",
		gingerbread_man = "gumdrop_bounce_pad",
		spirit_catcher = "spirit",
		fisherman = "fishing_rod",
		oil_man = "oil_consumable",
		santa = "tnt",
		miner = "miner_pickaxe",
		sheep_herder = "crook",
		beast = "speed_potion",
		metal_detector = "metal_detector",
		cyber = "drone",
		vesta = "damage_banner",
		lumen = "light_sword",
		ember = "infernal_saber",
		queen_bee = "bee"
	}

	local nametagfuncs1 = {
		Normal = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = Instance.new("TextLabel")
			thing.BackgroundColor3 = Color3.new()
			thing.BorderSizePixel = 0
			thing.Visible = false
			thing.RichText = true
			thing.AnchorPoint = Vector2.new(0.5, 1)
			thing.Name = plr.Player.Name
			thing.Font = Enum.Font[NameTagsFont.Value]
			thing.TextSize = 14 * (NameTagsScale.Value / 10)
			thing.BackgroundTransparency = NameTagsBackground.Enabled and 0.5 or 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(plr.Humanoid.Health).."</font>"
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[plr.Player]
			end
			local nametagSize = textService:GetTextSize(removeTags(nametagstrs[plr.Player]), thing.TextSize, thing.Font, Vector2.new(100000, 100000))
			thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
			thing.Text = nametagstrs[plr.Player]
			thing.TextColor3 = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			thing.Parent = NameTagsFolder
			local hand = Instance.new("ImageLabel")
			hand.Size = UDim2.new(0, 30, 0, 30)
			hand.Name = "Hand"
			hand.BackgroundTransparency = 1
			hand.Position = UDim2.new(0, -30, 0, -30)
			hand.Image = ""
			hand.Parent = thing
			local helmet = hand:Clone()
			helmet.Name = "Helmet"
			helmet.Position = UDim2.new(0, 5, 0, -30)
			helmet.Parent = thing
			local chest = hand:Clone()
			chest.Name = "Chestplate"
			chest.Position = UDim2.new(0, 35, 0, -30)
			chest.Parent = thing
			local boots = hand:Clone()
			boots.Name = "Boots"
			boots.Position = UDim2.new(0, 65, 0, -30)
			boots.Parent = thing
			local kit = hand:Clone()
			kit.Name = "Kit"
			task.spawn(function()
				repeat task.wait() until plr.Player:GetAttribute("PlayingAsKit") ~= ""
				if kit then
					kit.Image = kititems[plr.Player:GetAttribute("PlayingAsKit")] and bedwars.getIcon({itemType = kititems[plr.Player:GetAttribute("PlayingAsKit")]}, NameTagsShowInventory.Enabled) or ""
				end
			end)
			kit.Position = UDim2.new(0, -30, 0, -65)
			kit.Parent = thing
			nametagsfolderdrawing[plr.Player] = {entity = plr, Main = thing}
		end,
		Drawing = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = {Main = {}, entity = plr}
			thing.Main.Text = Drawing.new("Text")
			thing.Main.Text.Size = 17 * (NameTagsScale.Value / 10)
			thing.Main.Text.Font = (math.clamp((table.find(fontitems, NameTagsFont.Value) or 1) - 1, 0, 3))
			thing.Main.Text.ZIndex = 2
			thing.Main.BG = Drawing.new("Square")
			thing.Main.BG.Filled = true
			thing.Main.BG.Transparency = 0.5
			thing.Main.BG.Visible = NameTagsBackground.Enabled
			thing.Main.BG.Color = Color3.new()
			thing.Main.BG.ZIndex = 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' '..math.round(plr.Humanoid.Health)
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '[%s] '..nametagstrs[plr.Player]
			end
			thing.Main.Text.Text = nametagstrs[plr.Player]
			thing.Main.BG.Size = Vector2.new(thing.Main.Text.TextBounds.X + 4, thing.Main.Text.TextBounds.Y)
			thing.Main.Text.Color = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			nametagsfolderdrawing[plr.Player] = thing
		end
	}

	local nametagfuncs2 = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				v.Main:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				for i2,v2 in pairs(v.Main) do
					pcall(function() v2.Visible = false v2:Remove() end)
				end
			end
		end
	}

	local nametagupdatefuncs = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					local color = Color3.fromHSV(math.clamp(ent.Humanoid.Health / ent.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(ent.Humanoid.Health).."</font>"
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[ent.Player]
				end
				if NameTagsShowInventory.Enabled then
					local inventory = store.inventories[ent.Player] or {armor = {}}
					if inventory.hand then
						v.Main.Hand.Image = bedwars.getIcon(inventory.hand, NameTagsShowInventory.Enabled)
						if v.Main.Hand.Image:find("rbxasset://") then
							v.Main.Hand.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Hand.Image = ""
					end
					if inventory.armor[4] then
						v.Main.Helmet.Image = bedwars.getIcon(inventory.armor[4], NameTagsShowInventory.Enabled)
						if v.Main.Helmet.Image:find("rbxasset://") then
							v.Main.Helmet.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Helmet.Image = ""
					end
					if inventory.armor[5] then
						v.Main.Chestplate.Image = bedwars.getIcon(inventory.armor[5], NameTagsShowInventory.Enabled)
						if v.Main.Chestplate.Image:find("rbxasset://") then
							v.Main.Chestplate.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Chestplate.Image = ""
					end
					if inventory.armor[6] then
						v.Main.Boots.Image = bedwars.getIcon(inventory.armor[6], NameTagsShowInventory.Enabled)
						if v.Main.Boots.Image:find("rbxasset://") then
							v.Main.Boots.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Boots.Image = ""
					end
				end
				local nametagSize = textService:GetTextSize(removeTags(nametagstrs[ent.Player]), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
				v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
				v.Main.Text = nametagstrs[ent.Player]
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' '..math.round(ent.Humanoid.Health)
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '[%s] '..nametagstrs[ent.Player]
					v.Main.Text.Text = entityLibrary.isAlive and string.format(nametagstrs[ent.Player], math.floor((entityLibrary.character.HumanoidRootPart.Position - ent.RootPart.Position).Magnitude)) or nametagstrs[ent.Player]
				else
					v.Main.Text.Text = nametagstrs[ent.Player]
				end
				v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
				v.Main.Text.Color = getPlayerColor(ent.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			end
		end
	}

	local nametagcolorfuncs = {
		Normal = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.TextColor3 = getPlayerColor(v.entity.Player) or color
			end
		end,
		Drawing = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.Text.Color = getPlayerColor(v.entity.Player) or color
			end
		end
	}

	local nametagloop = {
		Normal = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					if nametagsizes[v.entity.Player] ~= stringsize then
						local nametagSize = textService:GetTextSize(removeTags(string.format(nametagstrs[v.entity.Player], mag)), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
						v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
					v.Main.Text = string.format(nametagstrs[v.entity.Player], mag)
				end
				v.Main.Position = UDim2.new(0, headPos.X, 0, headPos.Y)
				v.Main.Visible = true
			end
		end,
		Drawing = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					v.Main.Text.Text = string.format(nametagstrs[v.entity.Player], mag)
					if nametagsizes[v.entity.Player] ~= stringsize then
						v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
				end
				v.Main.BG.Position = Vector2.new(headPos.X - (v.Main.BG.Size.X / 2), (headPos.Y + v.Main.BG.Size.Y))
				v.Main.Text.Position = v.Main.BG.Position + Vector2.new(2, 0)
				v.Main.Text.Visible = true
				v.Main.BG.Visible = NameTagsBackground.Enabled
			end
		end
	}

	local methodused

	local NameTags = {Enabled = false}
	NameTags = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NameTags",
		Function = function(callback)
			if callback then
				methodused = NameTagsDrawing.Enabled and "Drawing" or "Normal"
				if nametagfuncs2[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityRemovedEvent:Connect(nametagfuncs2[methodused]))
				end
				if nametagfuncs1[methodused] then
					local addfunc = nametagfuncs1[methodused]
					for i,v in pairs(entityLibrary.entityList) do
						if nametagsfolderdrawing[v.Player] then nametagfuncs2[methodused](v.Player) end
						addfunc(v)
					end
					table.insert(NameTags.Connections, entityLibrary.entityAddedEvent:Connect(function(ent)
						if nametagsfolderdrawing[ent.Player] then nametagfuncs2[methodused](ent.Player) end
						addfunc(ent)
					end))
				end
				if nametagupdatefuncs[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityUpdatedEvent:Connect(nametagupdatefuncs[methodused]))
					for i,v in pairs(entityLibrary.entityList) do
						nametagupdatefuncs[methodused](v)
					end
				end
				if nametagcolorfuncs[methodused] then
					table.insert(NameTags.Connections, GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.FriendColorRefresh.Event:Connect(function()
						nametagcolorfuncs[methodused](NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
					end))
				end
				if nametagloop[methodused] then
					RunLoops:BindToRenderStep("NameTags", nametagloop[methodused])
				end
			else
				RunLoops:UnbindFromRenderStep("NameTags")
				if nametagfuncs2[methodused] then
					for i,v in pairs(nametagsfolderdrawing) do
						nametagfuncs2[methodused](i)
					end
				end
			end
		end,
		HoverText = "Renders nametags on entities through walls."
	})
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "SourceSans" then
			table.insert(fontitems, v.Name)
		end
	end
	NameTagsFont = NameTags.CreateDropdown({
		Name = "Font",
		List = fontitems,
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
	NameTagsColor = NameTags.CreateColorSlider({
		Name = "Player Color",
		Function = function(hue, sat, val)
			if NameTags.Enabled and nametagcolorfuncs[methodused] then
				nametagcolorfuncs[methodused](hue, sat, val)
			end
		end
	})
	NameTagsScale = NameTags.CreateSlider({
		Name = "Scale",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = 10,
		Min = 1,
		Max = 50
	})
	NameTagsRangeLimit = NameTags.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 0,
		Max = 1000,
		Default = 0
	})
	NameTagsBackground = NameTags.CreateToggle({
		Name = "Background",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDisplayName = NameTags.CreateToggle({
		Name = "Use Display Name",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsHealth = NameTags.CreateToggle({
		Name = "Health",
									
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsDistance = NameTags.CreateToggle({
		Name = "Distance",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsShowInventory = NameTags.CreateToggle({
		Name = "Equipment",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsTeammates = NameTags.CreateToggle({
		Name = "Teammates",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDrawing = NameTags.CreateToggle({
		Name = "Drawing",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
end)

run(function()
	local nobobdepth = {Value = 8}
	local nobobhorizontal = {Value = 8}
	local nobobvertical = {Value = -2}
	local rotationx = {Value = 0}
	local rotationy = {Value = 0}
	local rotationz = {Value = 0}
	local oldc1
	local oldfunc
	local nobob = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NoBob",
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild("Viewmodel")
			if viewmodel then
				if callback then
					oldfunc = bedwars.ViewmodelController.playAnimation
					bedwars.ViewmodelController.playAnimation = function(self, animid, details)
						if animid == bedwars.AnimationType.FP_WALK then
							return
						end
						return oldfunc(self, animid, details)
					end
					bedwars.ViewmodelController:setHeldItem(lplr.Character and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value and lplr.Character.HandInvItem.Value:Clone())
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(nobobdepth.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (nobobhorizontal.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (nobobvertical.Value / 10))
					oldc1 = viewmodel.RightHand.RightWrist.C1
					viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
				else
					bedwars.ViewmodelController.playAnimation = oldfunc
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
			end
		end,
		HoverText = "Removes the ugly bobbing when you move and makes sword farther"
	})
	nobobdepth = nobob.CreateSlider({
		Name = "Depth",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(val / 10))
			end
		end
	})
	nobobhorizontal = nobob.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (val / 10))
			end
		end
	})
	nobobvertical= nobob.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 24,
		Default = -2,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (val / 10))
			end
		end
	})
	rotationx = nobob.CreateSlider({
		Name = "RotX",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationy = nobob.CreateSlider({
		Name = "RotY",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationz = nobob.CreateSlider({
		Name = "RotZ",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
end)

run(function()
	local SongBeats = {Enabled = false}
	local SongBeatsList = {ObjectList = {}}
	local SongBeatsIntensity = {Value = 5}
	local SongTween
	local SongAudio

	local function PlaySong(arg)
		local args = arg:split(":")
		local song = isfile(args[1]) and getcustomasset(args[1]) or tonumber(args[1]) and "rbxassetid://"..args[1]
		if not song then
			warningNotification("SongBeats", "missing music file "..args[1], 5)
			SongBeats.ToggleButton(false)
			return
		end
		local bpm = 1 / (args[2] / 60)
		SongAudio = Instance.new("Sound")
		SongAudio.SoundId = song
		SongAudio.Parent = workspace
		SongAudio:Play()
		repeat
			repeat task.wait() until SongAudio.IsLoaded or (not SongBeats.Enabled)
			if (not SongBeats.Enabled) then break end
			local newfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
			gameCamera.FieldOfView = newfov - SongBeatsIntensity.Value
			if SongTween then SongTween:Cancel() end
			SongTween = game:GetService("TweenService"):Create(gameCamera, TweenInfo.new(0.2), {FieldOfView = newfov})
			SongTween:Play()
			task.wait(bpm)
		until (not SongBeats.Enabled) or SongAudio.IsPaused
	end

	SongBeats = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "SongBeats",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if #SongBeatsList.ObjectList <= 0 then
						warningNotification("SongBeats", "no songs", 5)
						SongBeats.ToggleButton(false)
						return
					end
					local lastChosen
					repeat
						local newSong
						repeat newSong = SongBeatsList.ObjectList[Random.new():NextInteger(1, #SongBeatsList.ObjectList)] task.wait() until newSong ~= lastChosen or #SongBeatsList.ObjectList <= 1
						lastChosen = newSong
						PlaySong(newSong)
						if not SongBeats.Enabled then break end
						task.wait(2)
					until (not SongBeats.Enabled)
				end)
			else
				if SongAudio then SongAudio:Destroy() end
				if SongTween then SongTween:Cancel() end
				gameCamera.FieldOfView = bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1)
			end
		end
	})
	SongBeatsList = SongBeats.CreateTextList({
		Name = "SongList",
		TempText = "songpath:bpm"
	})
	SongBeatsIntensity = SongBeats.CreateSlider({
		Name = "Intensity",
		Function = function() end,
		Min = 1,
		Max = 10,
		Default = 5
	})
end)

run(function()
	local performed = false
	GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "UICleanup",
		Function = function(callback)
			if callback and not performed then
				performed = true
				task.spawn(function()
					local hotbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp
					local hotbaropeninv = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
					local topbarbutton = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).TopBarButton
					local gametheme = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.shared.ui["game-theme"]).GameTheme
					bedwars.AppController:closeApp("TopBarApp")
					local oldrender = topbarbutton.render
					topbarbutton.render = function(self)
						local res = oldrender(self)
						if not self.props.Text then
							return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
						end
						return res
					end
					hotbaropeninv.render = function(self)
						return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
					end
					--[[debug.setconstant(hotbar.render, 52, 0.9975)
					debug.setconstant(hotbar.render, 73, 100)
					debug.setconstant(hotbar.render, 89, 1)
					debug.setconstant(hotbar.render, 90, 0.04)
					debug.setconstant(hotbar.render, 91, -0.03)
					debug.setconstant(hotbar.render, 109, 1.35)
					debug.setconstant(hotbar.render, 110, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 30, 1)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 31, 0.175)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 33, -0.101)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).render, 71, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).tweenPosition, 16, 0)]]
					gametheme.topBarBGTransparency = 0.5
					bedwars.TopBarController:mountHud()
					game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
					bedwars.AbilityUIController.abilityButtonsScreenGui.Visible = false
					bedwars.MatchEndScreenController.waitUntilDisplay = function() return false end
					task.spawn(function()
						repeat
							task.wait()
							local gui = lplr.PlayerGui:FindFirstChild("StatusEffectHudScreen")
							if gui then gui.Enabled = false break end
						until false
					end)
					task.spawn(function()
						repeat task.wait() until store.matchState ~= 0
						if bedwars.ClientStoreHandler:getState().Game.customMatch == nil then
							debug.setconstant(bedwars.QueueCard.render, 15, 0.1)
						end
					end)
					local slot = bedwars.ClientStoreHandler:getState().Inventory.observedInventory.hotbarSlot
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot + 1 % 8
					})
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot
					})
				end)
			end
		end
	})
end)

run(function()
	local AntiAFK = {Enabled = false}
	AntiAFK = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AntiAFK",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("AfkInfo"):SendToServer({
					afk = false
				})
			end
		end
	})
end)

run(function()
	local AutoBalloonPart
	local AutoBalloonConnection
	local AutoBalloonDelay = {Value = 10}
	local AutoBalloonLegit = {Enabled = false}
	local AutoBalloonypos = 0
	local balloondebounce = false
	local AutoBalloon = {Enabled = false}
	AutoBalloon = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBalloon",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or  not vapeInjected
					if vapeInjected and AutoBalloonypos == 0 and AutoBalloon.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						AutoBalloonypos = lowestypos - 8
					end
				end)
				task.spawn(function()
					repeat task.wait() until AutoBalloonypos ~= 0
					if AutoBalloon.Enabled then
						AutoBalloonPart = Instance.new("Part")
						AutoBalloonPart.CanCollide = false
						AutoBalloonPart.Size = Vector3.new(10000, 1, 10000)
						AutoBalloonPart.Anchored = true
						AutoBalloonPart.Transparency = 1
						AutoBalloonPart.Material = Enum.Material.Neon
						AutoBalloonPart.Color = Color3.fromRGB(135, 29, 139)
						AutoBalloonPart.Position = Vector3.new(0, AutoBalloonypos - 50, 0)
						AutoBalloonConnection = AutoBalloonPart.Touched:Connect(function(touchedpart)
							if entityLibrary.isAlive and touchedpart:IsDescendantOf(lplr.Character) and balloondebounce == false then
								autobankballoon = true
								balloondebounce = true
								local oldtool = store.localHand.tool
								for i = 1, 3 do
									if getItem("balloon") and (AutoBalloonLegit.Enabled and getHotbarSlot("balloon") or AutoBalloonLegit.Enabled == false) and (lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") < 3 or lplr.Character:GetAttribute("InflatedBalloons") == nil) then
										if AutoBalloonLegit.Enabled then
											if getHotbarSlot("balloon") then
												bedwars.ClientStoreHandler:dispatch({
													type = "InventorySelectHotbarSlot",
													slot = getHotbarSlot("balloon")
												})
												task.wait(AutoBalloonDelay.Value / 100)
												bedwars.BalloonController:inflateBalloon()
											end
										else
											task.wait(AutoBalloonDelay.Value / 100)
											bedwars.BalloonController:inflateBalloon()
										end
									end
								end
								if AutoBalloonLegit.Enabled and oldtool and getHotbarSlot(oldtool.Name) then
									task.wait(0.2)
									bedwars.ClientStoreHandler:dispatch({
										type = "InventorySelectHotbarSlot",
										slot = (getHotbarSlot(oldtool.Name) or 0)
									})
								end
								balloondebounce = false
								autobankballoon = false
							end
						end)
						AutoBalloonPart.Parent = workspace
					end
				end)
			else
				if AutoBalloonConnection then AutoBalloonConnection:Disconnect() end
				if AutoBalloonPart then
					AutoBalloonPart:Remove()
				end
			end
		end,
		HoverText = "Automatically Inflates Balloons"
	})
	AutoBalloonDelay = AutoBalloon.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Default = 20,
		Function = function() end,
		HoverText = "Delay to inflate balloons."
	})
	AutoBalloonLegit = AutoBalloon.CreateToggle({
		Name = "Legit Mode",
		Function = function() end,
		HoverText = "Switches to balloons in hotbar and inflates them."
	})
end)

local autobankapple = false
run(function()
	local AutoBuy = {Enabled = false}
	local AutoBuyArmor = {Enabled = false}
	local AutoBuySword = {Enabled = false}
	local AutoBuyGen = {Enabled = false}
	local AutoBuyProt = {Enabled = false}
	local AutoBuySharp = {Enabled = false}
	local AutoBuyDestruction = {Enabled = false}
	local AutoBuyDiamond = {Enabled = false}
	local AutoBuyAlarm = {Enabled = false}
	local AutoBuyGui = {Enabled = false}
	local AutoBuyTierSkip = {Enabled = true}
	local AutoBuyRange = {Value = 20}
	local AutoBuyCustom = {ObjectList = {}, RefreshList = function() end}
	local AutoBankUIToggle = {Enabled = false}
	local AutoBankDeath = {Enabled = false}
	local AutoBankStay = {Enabled = false}
	local buyingthing = false
	local shoothook
	local bedwarsshopnpcs = {}
	local id
	local armors = {
		[1] = "leather_chestplate",
		[2] = "iron_chestplate",
		[3] = "diamond_chestplate",
		[4] = "emerald_chestplate"
	}

	local swords = {
		[1] = "wood_sword",
		[2] = "stone_sword",
		[3] = "iron_sword",
		[4] = "diamond_sword",
		[5] = "emerald_sword"
	}

	local axes = {
		[1] = "wood_axe",
		[2] = "stone_axe",
		[3] = "iron_axe",
		[4] = "diamond_axe"
	}

	local pickaxes = {
		[1] = "wood_pickaxe",
		[2] = "stone_pickaxe",
		[3] = "iron_pickaxe",
		[4] = "diamond_pickaxe"
	}

	task.spawn(function()
		repeat task.wait() until store.matchState ~= 0 or not vapeInjected
		for i,v in pairs(collectionService:GetTagged("BedwarsItemShop")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = true, Id = v.Name})
		end
		for i,v in pairs(collectionService:GetTagged("TeamUpgradeShopkeeper")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = false, Id = v.Name})
		end
	end)

	local function nearNPC(range)
		local npc, npccheck, enchant, newid = nil, false, false, nil
		if entityLibrary.isAlive then
			local enchanttab = {}
			for i,v in pairs(collectionService:GetTagged("broken-enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(collectionService:GetTagged("enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(enchanttab) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= 6 then
					if ((not v:GetAttribute("Team")) or v:GetAttribute("Team") == lplr:GetAttribute("Team")) then
						npc, npccheck, enchant = true, true, true
					end
				end
			end
			for i, v in pairs(bedwarsshopnpcs) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= (range or 20) then
					npc, npccheck, enchant = true, (v.TeamUpgradeNPC or npccheck), false
					newid = v.TeamUpgradeNPC and v.Id or newid
				end
			end
			local suc, res = pcall(function() return lplr.leaderstats.Bed.Value == "✅"  end)
			if AutoBankDeath.Enabled and (workspace:GetServerTimeNow() - lplr.Character:GetAttribute("LastDamageTakenTime")) < 2 and suc and res then
				return nil, false, false
			end
			if AutoBankStay.Enabled then
				return nil, false, false
			end
		end
		return npc, not npccheck, enchant, newid
	end

	local function buyItem(itemtab, waitdelay)
		if not id then return end
		local res
		bedwars.Client:Get("BedwarsPurchaseItem"):CallServerAsync({
			shopItem = itemtab,
			shopId = id
		}):andThen(function(p11)
			if p11 then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.ClientStoreHandler:dispatch({
					type = "BedwarsAddItemPurchased",
					itemType = itemtab.itemType
				})
			end
			res = p11
		end)
		if waitdelay then
			repeat task.wait() until res ~= nil
		end
	end

	local function getAxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("axe") and v5.itemType:find("pickaxe") == nil then
				return v5.itemType
			end
		end
		return nil
	end

	local function getPickaxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("pickaxe") then
				return v5.itemType
			end
		end
		return nil
	end

	local function getShopItem(itemType)
		if itemType == "axe" then
			itemType = getAxeNear() or "wood_axe"
			itemType = axes[table.find(axes, itemType) + 1] or itemType
		end
		if itemType == "pickaxe" then
			itemType = getPickaxeNear() or "wood_pickaxe"
			itemType = pickaxes[table.find(pickaxes, itemType) + 1] or itemType
		end
		for i,v in pairs(bedwars.ShopItems) do
			if v.itemType == itemType then return v end
		end
		return nil
	end

	local buyfunctions = {
		Armor = function(inv, upgrades, shoptype)
			if AutoBuyArmor.Enabled == false or shoptype ~= "item" then return end
			local currentarmor = (inv.armor[2] ~= "empty" and inv.armor[2].itemType:find("chestplate") ~= nil) and inv.armor[2] or nil
			local armorindex = (currentarmor and table.find(armors, currentarmor.itemType) or 0) + 1
			if armors[armorindex] == nil then return end
			local highestbuyable = nil
			for i = armorindex, #armors, 1 do
				local shopitem = getShopItem(armors[i])
				if shopitem and i == armorindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end,
		Sword = function(inv, upgrades, shoptype)
			if AutoBuySword.Enabled == false or shoptype ~= "item" then return end
			local currentsword = getItemNear("sword", inv.items)
			local swordindex = (currentsword and table.find(swords, currentsword.itemType) or 0) + 1
			if currentsword ~= nil and table.find(swords, currentsword.itemType) == nil then return end
			local highestbuyable = nil
			for i = swordindex, #swords, 1 do
				local shopitem = getShopItem(swords[i])
				if shopitem and i == swordindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price and (shopitem.category ~= "Armory" or upgrades.armory) then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end
	}

	AutoBuy = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBuy",
		Function = function(callback)
			if callback then
				buyingthing = false
				task.spawn(function()
					repeat
						task.wait()
						local found, npctype, enchant, newid = nearNPC(AutoBuyRange.Value)
						id = newid
						if found then
							local inv = store.localInventory.inventory
							local currentupgrades = bedwars.ClientStoreHandler:getState().Bedwars.teamUpgrades
							if store.equippedKit == "dasher" then
								swords = {
									[1] = "wood_dao",
									[2] = "stone_dao",
									[3] = "iron_dao",
									[4] = "diamond_dao",
									[5] = "emerald_dao"
								}
							elseif store.equippedKit == "ice_queen" then
								swords[5] = "ice_sword"
							elseif store.equippedKit == "ember" then
								swords[5] = "infernal_saber"
							elseif store.equippedKit == "lumen" then
								swords[5] = "light_sword"
							end
							if (AutoBuyGui.Enabled == false or (bedwars.AppController:isAppOpen("BedwarsItemShopApp") or bedwars.AppController:isAppOpen("BedwarsTeamUpgradeApp"))) and (not enchant) then
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] ~= "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
								for i,v in pairs(buyfunctions) do v(inv, currentupgrades, npctype and "upgrade" or "item") end
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] == "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
							end
						end
					until (not AutoBuy.Enabled)
				end)
			end
		end,
		HoverText = "Automatically Buys Swords, Armor, and Team Upgrades\nwhen you walk near the NPC"
	})
	AutoBuyRange = AutoBuy.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 1,
		Max = 20,
		Default = 20
	})
	AutoBuyArmor = AutoBuy.CreateToggle({
		Name = "Buy Armor",
		Function = function() end,
		Default = true
	})
	AutoBuySword = AutoBuy.CreateToggle({
		Name = "Buy Sword",
		Function = function() end,
		Default = true
	})
	AutoBuyGui = AutoBuy.CreateToggle({
		Name = "Shop GUI Check",
		Function = function() end,
	})
	AutoBuyTierSkip = AutoBuy.CreateToggle({
		Name = "Tier Skip",
		Function = function() end,
		Default = true
	})
	AutoBuyCustom = AutoBuy.CreateTextList({
		Name = "BuyList",
		TempText = "item/amount/priority/after",
		SortFunction = function(a, b)
			local amount1 = a:split("/")
			local amount2 = b:split("/")
			amount1 = #amount1 and tonumber(amount1[3]) or 1
			amount2 = #amount2 and tonumber(amount2[3]) or 1
			return amount1 < amount2
		end
	})
	AutoBuyCustom.Object.AddBoxBKG.AddBox.TextSize = 14
end)

run(function()
	local AutoConsume = {Enabled = false}
	local AutoConsumeHealth = {Value = 100}
	local AutoConsumeSpeed = {Enabled = true}
	local AutoConsumeDelay = tick()

	local function AutoConsumeFunc()
		if entityLibrary.isAlive then
			local speedpotion = getItem("speed_potion")
			if lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") - (100 - AutoConsumeHealth.Value)) then
				autobankapple = true
				local item = getItem("apple")
				local pot = getItem("heal_splash_potion")
				if (item or pot) and AutoConsumeDelay <= tick() then
					if item then
						bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
							item = item.tool
						})
						AutoConsumeDelay = tick() + 0.6
					else
						local newray = workspace:Raycast((oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -76, 0), store.blockRaycast)
						if newray ~= nil then
							bedwars.Client:Get(bedwars.ProjectileRemote):CallServerAsync(pot.tool, "heal_splash_potion", "heal_splash_potion", (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -70, 0), game:GetService("HttpService"):GenerateGUID(), {drawDurationSeconds = 1})
						end
					end
				end
			else
				autobankapple = false
			end
			if speedpotion and (not lplr.Character:GetAttribute("StatusEffect_speed")) and AutoConsumeSpeed.Enabled then
				bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
					item = speedpotion.tool
				})
			end
			if lplr.Character:GetAttribute("Shield_POTION") and ((not lplr.Character:GetAttribute("Shield_POTION")) or lplr.Character:GetAttribute("Shield_POTION") == 0) then
				local shield = getItem("big_shield") or getItem("mini_shield")
				if shield then
					bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
						item = shield.tool
					})
				end
			end
		end
	end

	AutoConsume = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoConsume",
		Function = function(callback)
			if callback then
				table.insert(AutoConsume.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(AutoConsumeFunc))
				table.insert(AutoConsume.Connections, vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed:find("Shield") or changed:find("Health") or changed:find("speed") then
						AutoConsumeFunc()
					end
				end))
				AutoConsumeFunc()
			end
		end,
		HoverText = "Automatically heals for you when health or shield is under threshold."
	})
	AutoConsumeHealth = AutoConsume.CreateSlider({
		Name = "Health",
		Min = 1,
		Max = 99,
		Default = 70,
		Function = function() end
	})
	AutoConsumeSpeed = AutoConsume.CreateToggle({
		Name = "Speed Potions",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local AutoHotbarList = {Hotbars = {}, CurrentlySelected = 1}
	local AutoHotbarMode = {Value = "Toggle"}
	local AutoHotbarClear = {Enabled = false}
	local AutoHotbar = {Enabled = false}
	local AutoHotbarActive = false

	local function getCustomItem(v2)
		local realitem = v2.itemType
		if realitem == "swords" then
			local sword = getSword()
			realitem = sword and sword.itemType or "wood_sword"
		elseif realitem == "pickaxes" then
			local pickaxe = getPickaxe()
			realitem = pickaxe and pickaxe.itemType or "wood_pickaxe"
		elseif realitem == "axes" then
			local axe = getAxe()
			realitem = axe and axe.itemType or "wood_axe"
		elseif realitem == "bows" then
			local bow = getBow()
			realitem = bow and bow.itemType or "wood_bow"
		elseif realitem == "wool" then
			realitem = getWool() or "wool_white"
		end
		return realitem
	end

	local function findItemInTable(tab, item)
		for i, v in pairs(tab) do
			if v and v.itemType then
				if item.itemType == getCustomItem(v) then
					return i
				end
			end
		end
		return nil
	end

	local function findinhotbar(item)
		for i,v in pairs(store.localInventory.hotbar) do
			if v.item and v.item.itemType == item.itemType then
				return i, v.item
			end
		end
	end

	local function findininventory(item)
		for i,v in pairs(store.localInventory.inventory.items) do
			if v.itemType == item.itemType then
				return v
			end
		end
	end

	local function AutoHotbarSort()
		task.spawn(function()
			if AutoHotbarActive then return end
			AutoHotbarActive = true
			local items = (AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected] and AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected].Items or {})
			for i, v in pairs(store.localInventory.inventory.items) do
				local customItem
				local hotbarslot = findItemInTable(items, v)
				if hotbarslot then
					local oldhotbaritem = store.localInventory.hotbar[tonumber(hotbarslot)]
					if oldhotbaritem.item and oldhotbaritem.item.itemType == v.itemType then continue end
					if oldhotbaritem.item then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = tonumber(hotbarslot) - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local newhotbaritemslot, newhotbaritem = findinhotbar(v)
					if newhotbaritemslot then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					if oldhotbaritem.item and newhotbaritemslot then
						local nextitem1, nextitem1num = findininventory(oldhotbaritem.item)
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryAddToHotbar",
							item = nextitem1,
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local nextitem2, nextitem2num = findininventory(v)
					bedwars.ClientStoreHandler:dispatch({
						type = "InventoryAddToHotbar",
						item = nextitem2,
						slot = tonumber(hotbarslot) - 1
					})
					vapeEvents.InventoryChanged.Event:Wait()
				else
					if AutoHotbarClear.Enabled then
						local newhotbaritemslot, newhotbaritem = findinhotbar(v)
						if newhotbaritemslot then
							bedwars.ClientStoreHandler:dispatch({
								type = "InventoryRemoveFromHotbar",
								slot = newhotbaritemslot - 1
							})
							vapeEvents.InventoryChanged.Event:Wait()
						end
					end
				end
			end
			AutoHotbarActive = false
		end)
	end

	AutoHotbar = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoHotbar",
		Function = function(callback)
			if callback then
				AutoHotbarSort()
				if AutoHotbarMode.Value == "On Key" then
					if AutoHotbar.Enabled then
						AutoHotbar.ToggleButton(false)
					end
				else
					table.insert(AutoHotbar.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(function()
						if not AutoHotbar.Enabled then return end
						AutoHotbarSort()
					end))
				end
			end
		end,
		HoverText = "Automatically arranges hotbar to your liking."
	})
	AutoHotbarMode = AutoHotbar.CreateDropdown({
		Name = "Activation",
		List = {"On Key", "Toggle"},
		Function = function(val)
			if AutoHotbar.Enabled then
				AutoHotbar.ToggleButton(false)
				AutoHotbar.ToggleButton(false)
			end
		end
	})
	AutoHotbarList = CreateAutoHotbarGUI(AutoHotbar.Children, {
		Name = "lol"
	})
	AutoHotbarClear = AutoHotbar.CreateToggle({
		Name = "Clear Hotbar",
		Function = function() end
	})
end)

run(function()
	local AutoKit = {Enabled = false}
	local AutoKitTrinity = {Value = "Void"}
	local oldfish
	local function GetTeammateThatNeedsMost()
		local plrs = GetAllNearestHumanoidToPosition(true, 30, 1000, true)
		local lowest, lowestplayer = 10000, nil
		for i,v in pairs(plrs) do
			if not v.Targetable then
				if v.Character:GetAttribute("Health") <= lowest and v.Character:GetAttribute("Health") < v.Character:GetAttribute("MaxHealth") then
					lowest = v.Character:GetAttribute("Health")
					lowestplayer = v
				end
			end
		end
		return lowestplayer
	end

	AutoKit = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoKit",
		Function = function(callback)
			if callback then
				oldfish = bedwars.FishermanController.startMinigame
				bedwars.FishermanController.startMinigame = function(Self, dropdata, func) func({win = true}) end
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if AutoKit.Enabled then
						if store.equippedKit == "melody" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if getItem("guitar") then
										local plr = GetTeammateThatNeedsMost()
										if plr and healtick <= tick() then
											bedwars.Client:Get(bedwars.GuitarHealRemote):SendToServer({
												healTarget = plr.Character
											})
											healtick = tick() + 2
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "bigman" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("treeOrb")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v:FindFirstChild("Spirit") and (entityLibrary.character.HumanoidRootPart.Position - v.Spirit.Position).magnitude <= 20 then
											if bedwars.Client:Get(bedwars.TreeRemote):CallServer({
												treeOrbSecret = v:GetAttribute("TreeOrbSecret")
											}) then
												v:Destroy()
												collectionService:RemoveTag(v, "treeOrb")
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "metal_detector" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("hidden-metal")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 20 then
											bedwars.Client:Get(bedwars.PickupMetalRemote):SendToServer({
												id = v:GetAttribute("Id")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "battery" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.BatteryEffectsController.liveBatteries
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.position).magnitude <= 10 then
											bedwars.Client:Get(bedwars.BatteryRemote):SendToServer({
												batteryId = i
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "grim_reaper" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.GrimReaperController.soulsByPosition
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") / 4) and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 120 and (not lplr.Character:GetAttribute("GrimReaperChannel")) then
											bedwars.Client:Get(bedwars.ConsumeSoulRemote):CallServer({
												secret = v:GetAttribute("GrimReaperSoulSecret")
											})
											v:Destroy()
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "farmer_cletus" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("HarvestableCrop")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.Position).magnitude <= 10 then
											bedwars.Client:Get("CropHarvest"):CallServerAsync({
												position = bedwars.BlockController:getBlockPosition(v.Position)
											}):andThen(function(suc)
												if suc then
													bedwars.GameAnimationUtil.playAnimation(lplr.Character, 1)
													bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
												end
											end)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "pinata" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged(lplr.Name..':pinata')
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and getItem('candy') then
											bedwars.Client:Get(bedwars.PinataRemote):CallServer(v)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "dragon_slayer" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(bedwars.DragonSlayerController.dragonEmblems) do
											if v.stackCount >= 3 then
												bedwars.DragonSlayerController:deleteEmblem(i)
												local localPos = lplr.Character:GetPrimaryPartCFrame().Position
												local punchCFrame = CFrame.new(localPos, (i:GetPrimaryPartCFrame().Position * Vector3.new(1, 0, 1)) + Vector3.new(0, localPos.Y, 0))
												lplr.Character:SetPrimaryPartCFrame(punchCFrame)
												bedwars.DragonSlayerController:playPunchAnimation(punchCFrame - punchCFrame.Position)
												bedwars.Client:Get(bedwars.DragonRemote):SendToServer({
													target = i
												})
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "mage" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i, v in pairs(collectionService:GetTagged("TomeGuidingBeam")) do
											local obj = v.Parent and v.Parent.Parent and v.Parent.Parent.Parent
											if obj and (entityLibrary.character.HumanoidRootPart.Position - obj.PrimaryPart.Position).Magnitude < 5 and obj:GetAttribute("TomeSecret") then
												local res = bedwars.Client:Get(bedwars.MageRemote):CallServer({
													secret = obj:GetAttribute("TomeSecret")
												})
												if res.success and res.element then
													bedwars.GameAnimationUtil.playAnimation(lplr, bedwars.AnimationType.PUNCH)
													bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
													bedwars.MageController:destroyTomeGuidingBeam()
													bedwars.MageController:playLearnLightBeamEffect(lplr, obj)
													local sound = bedwars.MageKitUtil.MageElementVisualizations[res.element].learnSound
													if sound and sound ~= "" then
														bedwars.SoundManager:playSound(sound)
													end
													task.delay(bedwars.BalanceFile.LEARN_TOME_DURATION, function()
														bedwars.MageController:fadeOutTome(obj)
														if lplr.Character and res.element then
															bedwars.MageKitUtil.changeMageKitAppearance(lplr, lplr.Character, res.element)
														end
													end)
												end
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "angel" then
							table.insert(AutoKit.Connections, vapeEvents.AngelProgress.Event:Connect(function(angelTable)
								task.wait(0.5)
								if not AutoKit.Enabled then return end
								if bedwars.ClientStoreHandler:getState().Kit.angelProgress >= 1 and lplr.Character:GetAttribute("AngelType") == nil then
									bedwars.Client:Get(bedwars.TrinityRemote):SendToServer({
										angel = AutoKitTrinity.Value
									})
								end
							end))
						elseif store.equippedKit == "miner" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(collectionService:GetTagged("petrified-player")) do
											bedwars.Client:Get(bedwars.MinerRemote):SendToServer({
												petrifyId = v:GetAttribute("PetrifyId")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						end
					end
				end)
			else
				bedwars.FishermanController.startMinigame = oldfish
				oldfish = nil
			end
		end,
		HoverText = "Automatically uses a kits ability"
	})
	AutoKitTrinity = AutoKit.CreateDropdown({
		Name = "Angel",
		List = {"Void", "Light"},
		Function = function() end
	})
end)

run(function()
	local AutoForge = {Enabled = false}
	local AutoForgeWeapon = {Value = "Sword"}
	local AutoForgeBow = {Enabled = false}
	local AutoForgeArmor = {Enabled = false}
	local AutoForgeSword = {Enabled = false}
	local AutoForgeBuyAfter = {Enabled = false}
	local AutoForgeNotification = {Enabled = true}

	local function buyForge(i)
		if not store.forgeUpgrades[i] or store.forgeUpgrades[i] < 6 then
			local cost = bedwars.ForgeUtil:getUpgradeCost(1, store.forgeUpgrades[i] or 0)
			if store.forgeMasteryPoints >= cost then
				if AutoForgeNotification.Enabled then
					local forgeType = "none"
					for name,v in pairs(bedwars.ForgeConstants) do
						if v == i then forgeType = name:lower() end
					end
					warningNotification("AutoForge", "Purchasing "..forgeType..".", bedwars.ForgeUtil.FORGE_DURATION_SEC)
				end
				bedwars.Client:Get("ForgePurchaseUpgrade"):SendToServer(i)
				task.wait(bedwars.ForgeUtil.FORGE_DURATION_SEC + 0.2)
			end
		end
	end

	AutoForge = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoForge",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if store.matchState == 1 and entityLibrary.isAlive then
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeArmor.Enabled then buyForge(bedwars.ForgeConstants.ARMOR) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeBow.Enabled then buyForge(bedwars.ForgeConstants.RANGED) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeSword.Enabled then
								if AutoForgeBuyAfter.Enabled then
									if not store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] or store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] < 6 then continue end
								end
								local weapon = bedwars.ForgeConstants[AutoForgeWeapon.Value:upper()]
								if weapon then buyForge(weapon) end
							end
						end
					until (not AutoForge.Enabled)
				end)
			end
		end
	})
	AutoForgeWeapon = AutoForge.CreateDropdown({
		Name = "Weapon",
		Function = function() end,
		List = {"Sword", "Dagger", "Scythe", "Great_Hammer", "Gauntlets"}
	})
	AutoForgeArmor = AutoForge.CreateToggle({
		Name = "Armor",
		Function = function() end,
		Default = true
	})
	AutoForgeSword = AutoForge.CreateToggle({
		Name = "Weapon",
		Function = function() end
	})
	AutoForgeBow = AutoForge.CreateToggle({
		Name = "Bow",
		Function = function() end
	})
	AutoForgeBuyAfter = AutoForge.CreateToggle({
		Name = "Buy After",
		Function = function() end,
		HoverText = "buy a weapon after armor is maxed"
	})
	AutoForgeNotification = AutoForge.CreateToggle({
		Name = "Notification",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local alreadyreportedlist = {}
	local AutoReportV2 = {Enabled = false}
	local AutoReportV2Notify = {Enabled = false}
	AutoReportV2 = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoReportV2",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						for i,v in pairs(playersService:GetPlayers()) do
							if v ~= lplr and alreadyreportedlist[v] == nil and v:GetAttribute("PlayerConnected") and whitelist:get(v) == 0 then
								task.wait(1)
								alreadyreportedlist[v] = true
								bedwars.Client:Get(bedwars.ReportRemote):SendToServer(v.UserId)
								store.statistics.reported = store.statistics.reported + 1
								if AutoReportV2Notify.Enabled then
									warningNotification("AutoReportV2", "Reported "..v.Name, 15)
								end
							end
						end
					until (not AutoReportV2.Enabled)
				end)
			end
		end,
		HoverText = "dv mald"
	})
	AutoReportV2Notify = AutoReportV2.CreateToggle({
		Name = "Notify",
		Function = function() end
	})
end)

run(function()
	local justsaid = ""
	local leavesaid = false
	local alreadyreported = {}

	local function removerepeat(str)
		local newstr = ""
		local lastlet = ""
		for i,v in pairs(str:split("")) do
			if v ~= lastlet then
				newstr = newstr..v
				lastlet = v
			end
		end
		return newstr
	end

	local reporttable = {
		gay = "Bullying",
		gae = "Bullying",
		gey = "Bullying",
		hack = "Scamming",
		exploit = "Scamming",
		cheat = "Scamming",
		hecker = "Scamming",
		haxker = "Scamming",
		hacer = "Scamming",
		report = "Bullying",
		fat = "Bullying",
		black = "Bullying",
		getalife = "Bullying",
		fatherless = "Bullying",
		report = "Bullying",
		fatherless = "Bullying",
		disco = "Offsite Links",
		yt = "Offsite Links",
		dizcourde = "Offsite Links",
		retard = "Swearing",
		bad = "Bullying",
		trash = "Bullying",
		nolife = "Bullying",
		nolife = "Bullying",
		loser = "Bullying",
		killyour = "Bullying",
		kys = "Bullying",
		hacktowin = "Bullying",
		bozo = "Bullying",
		kid = "Bullying",
		adopted = "Bullying",
		linlife = "Bullying",
		commitnotalive = "Bullying",
		vape = "Offsite Links",
		futureclient = "Offsite Links",
		download = "Offsite Links",
		youtube = "Offsite Links",
		die = "Bullying",
		lobby = "Bullying",
		ban = "Bullying",
		wizard = "Bullying",
		wisard = "Bullying",
		witch = "Bullying",
		magic = "Bullying",
	}
	local reporttableexact = {
		L = "Bullying",
	}


	local function findreport(msg)
		local checkstr = removerepeat(msg:gsub("%W+", ""):lower())
		for i,v in pairs(reporttable) do
			if checkstr:find(i) then
				return v, i
			end
		end
		for i,v in pairs(reporttableexact) do
			if checkstr == i then
				return v, i
			end
		end
		for i,v in pairs(AutoToxicPhrases5.ObjectList) do
			if checkstr:find(v) then
				return "Bullying", v
			end
		end
		return nil
	end

	AutoToxic = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoToxic",
		Function = function(callback)
			if callback then
				table.insert(AutoToxic.Connections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if AutoToxicBedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute("Team") then
						local custommsg = #AutoToxicPhrases6.ObjectList > 0 and AutoToxicPhrases6.ObjectList[math.random(1, #AutoToxicPhrases6.ObjectList)] or "How dare you break my bed >:( <name> | vxpe on top"
						if custommsg then
							custommsg = custommsg:gsub("<name>", (bedTable.player.DisplayName or bedTable.player.Name))
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					elseif AutoToxicBedBreak.Enabled and bedTable.player.UserId == lplr.UserId then
						local custommsg = #AutoToxicPhrases7.ObjectList > 0 and AutoToxicPhrases7.ObjectList[math.random(1, #AutoToxicPhrases7.ObjectList)] or "nice bed <teamname> | vxpe on top"
						if custommsg then
							local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
							local teamname = team and team.displayName:lower() or "white"
							custommsg = custommsg:gsub("<teamname>", teamname)
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed == lplr then
							if (not leavesaid) and killer ~= lplr and AutoToxicDeath.Enabled then
								leavesaid = true
								local custommsg = #AutoToxicPhrases3.ObjectList > 0 and AutoToxicPhrases3.ObjectList[math.random(1, #AutoToxicPhrases3.ObjectList)] or "My gaming chair expired midfight, thats why you won <name> | vxpe on top"
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killer.DisplayName or killer.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						else
							if killer == lplr and AutoToxicFinalKill.Enabled then
								local custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								if custommsg == lastsaid then
									custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								else
									lastsaid = custommsg
								end
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killed.DisplayName or killed.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						if AutoToxicGG.Enabled then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("gg")
							if shared.ggfunction then
								shared.ggfunction()
							end
						end
						if AutoToxicWin.Enabled then
							local custommsg = #AutoToxicPhrases.ObjectList > 0 and AutoToxicPhrases.ObjectList[math.random(1, #AutoToxicPhrases.ObjectList)] or "EZ L TRASH KIDS | vxpe on top"
							if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
								textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
							else
								replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.LagbackEvent.Event:Connect(function(plr)
					if AutoToxicLagback.Enabled then
						local custommsg = #AutoToxicPhrases8.ObjectList > 0 and AutoToxicPhrases8.ObjectList[math.random(1, #AutoToxicPhrases8.ObjectList)]
						if custommsg then
							custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
						end
						local msg = custommsg or "Imagine lagbacking L "..(plr.DisplayName or plr.Name).." | vxpe on top"
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, textChatService.MessageReceived:Connect(function(tab)
					if AutoToxicRespond.Enabled then
						local plr = playersService:GetPlayerByUserId(tab.TextSource.UserId)
						local args = tab.Text:split(" ")
						if plr and plr ~= lplr and not alreadyreported[plr] then
							local reportreason, reportedmatch = findreport(tab.Text)
							if reportreason then
								alreadyreported[plr] = true
								local custommsg = #AutoToxicPhrases4.ObjectList > 0 and AutoToxicPhrases4.ObjectList[math.random(1, #AutoToxicPhrases4.ObjectList)]
								if custommsg then
									custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
								end
								local msg = custommsg or "I don't care about the fact that I'm hacking, I care about you dying in a block game. L "..(plr.DisplayName or plr.Name).." | vxpe on top"
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
								end
							end
						end
					end
				end))
			end
		end
	})
	AutoToxicGG = AutoToxic.CreateToggle({
		Name = "AutoGG",
		Function = function() end,
		Default = true
	})
	AutoToxicWin = AutoToxic.CreateToggle({
		Name = "Win",
		Function = function() end,
		Default = true
	})
	AutoToxicDeath = AutoToxic.CreateToggle({
		Name = "Death",
		Function = function() end,
		Default = true
	})
	AutoToxicBedBreak = AutoToxic.CreateToggle({
		Name = "Bed Break",
		Function = function() end,
		Default = true
	})
	AutoToxicBedDestroyed = AutoToxic.CreateToggle({
		Name = "Bed Destroyed",
		Function = function() end,
		Default = true
	})
	AutoToxicRespond = AutoToxic.CreateToggle({
		Name = "Respond",
		Function = function() end,
		Default = true
	})
	AutoToxicFinalKill = AutoToxic.CreateToggle({
		Name = "Final Kill",
		Function = function() end,
		Default = true
	})
	AutoToxicTeam = AutoToxic.CreateToggle({
		Name = "Teammates",
		Function = function() end,
	})
	AutoToxicLagback = AutoToxic.CreateToggle({
		Name = "Lagback",
		Function = function() end,
		Default = true
	})
	AutoToxicPhrases = AutoToxic.CreateTextList({
		Name = "ToxicList",
		TempText = "phrase (win)",
	})
	AutoToxicPhrases2 = AutoToxic.CreateTextList({
		Name = "ToxicList2",
		TempText = "phrase (kill) <name>",
	})
	AutoToxicPhrases3 = AutoToxic.CreateTextList({
		Name = "ToxicList3",
		TempText = "phrase (death) <name>",
	})
	AutoToxicPhrases7 = AutoToxic.CreateTextList({
		Name = "ToxicList7",
		TempText = "phrase (bed break) <teamname>",
	})
	AutoToxicPhrases7.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases6 = AutoToxic.CreateTextList({
		Name = "ToxicList6",
		TempText = "phrase (bed destroyed) <name>",
	})
	AutoToxicPhrases6.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases4 = AutoToxic.CreateTextList({
		Name = "ToxicList4",
		TempText = "phrase (text to respond with) <name>",
	})
	AutoToxicPhrases4.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases5 = AutoToxic.CreateTextList({
		Name = "ToxicList5",
		TempText = "phrase (text to respond to)",
	})
	AutoToxicPhrases5.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases8 = AutoToxic.CreateTextList({
		Name = "ToxicList8",
		TempText = "phrase (lagback) <name>",
	})
	AutoToxicPhrases8.Object.AddBoxBKG.AddBox.TextSize = 12
end)

run(function()
	local ChestStealer = {Enabled = false}
	local ChestStealerDistance = {Value = 1}
	local ChestStealerDelay = {Value = 1}
	local ChestStealerOpen = {Enabled = false}
	local ChestStealerSkywars = {Enabled = true}
	local cheststealerdelays = {}
	local cheststealerfuncs = {
		Open = function()
			if bedwars.AppController:isAppOpen("ChestApp") then
				local chest = lplr.Character:FindFirstChild("ObservedChestFolder")
				local chestitems = chest and chest.Value and chest.Value:GetChildren() or {}
				if #chestitems > 0 then
					for i3,v3 in pairs(chestitems) do
						if v3:IsA("Accessory") and (cheststealerdelays[v3] == nil or cheststealerdelays[v3] < tick()) then
							task.spawn(function()
								pcall(function()
									cheststealerdelays[v3] = tick() + 0.2
									bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(chest.Value, v3)
								end)
							end)
							task.wait(ChestStealerDelay.Value / 100)
						end
					end
				end
			end
		end,
		Closed = function()
			for i, v in pairs(collectionService:GetTagged("chest")) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= ChestStealerDistance.Value then
					local chest = v:FindFirstChild("ChestFolderValue")
					chest = chest and chest.Value or nil
					local chestitems = chest and chest:GetChildren() or {}
					if #chestitems > 0 then
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(chest)
						for i3,v3 in pairs(chestitems) do
							if v3:IsA("Accessory") then
								task.spawn(function()
									pcall(function()
										bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(v.ChestFolderValue.Value, v3)
									end)
								end)
								task.wait(ChestStealerDelay.Value / 100)
							end
						end
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(nil)
					end
				end
			end
		end
	}

	ChestStealer = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ChestStealer",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test"
					if (not ChestStealerSkywars.Enabled) or store.queueType:find("skywars") then
						repeat
							task.wait(0.1)
							if entityLibrary.isAlive then
								cheststealerfuncs[ChestStealerOpen.Enabled and "Open" or "Closed"]()
							end
						until (not ChestStealer.Enabled)
					end
				end)
			end
		end,
		HoverText = "Grabs items from near chests."
	})
	ChestStealerDistance = ChestStealer.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end,
		Default = 18
	})
	ChestStealerDelay = ChestStealer.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Function = function() end,
		Default = 1,
		Double = 100
	})
	ChestStealerOpen = ChestStealer.CreateToggle({
		Name = "GUI Check",
		Function = function() end
	})
	ChestStealerSkywars = ChestStealer.CreateToggle({
		Name = "Only Skywars",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local FastDrop = {Enabled = false}
	FastDrop = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "FastDrop",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if entityLibrary.isAlive and (not store.localInventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.Q) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
							task.spawn(bedwars.DropItem)
						end
					until (not FastDrop.Enabled)
				end)
			end
		end,
		HoverText = "Drops items fast when you hold Q"
	})
end)

run(function()
	local MissileTP = {Enabled = false}
	local MissileTeleportDelaySlider = {Value = 30}
	MissileTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "MissileTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("guided_missile") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync("guided_missile"))
							if projectile then
								local projectilemodel = projectile.model
								if not projectilemodel.PrimaryPart then
									projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
								end;
								local bodyforce = Instance.new("BodyForce")
								bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
								bodyforce.Name = "AntiGravity"
								bodyforce.Parent = projectilemodel.PrimaryPart

								repeat
									task.wait()
									if projectile.model then
										if plr then
											projectile.model:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										else
											warningNotification("MissileTP", "Player died before it could TP.", 3)
											break
										end
									end
								until projectile.model.Parent == nil
							else
								warningNotification("MissileTP", "Missile on cooldown.", 3)
							end
						else
							warningNotification("MissileTP", "Player not found.", 3)
						end
					else
						warningNotification("MissileTP", "Missile not found.", 3)
					end
				end)
				MissileTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a missile to a player\nnear your mouse."
	})
end)

run(function()
	local PickupRangeRange = {Value = 1}
	local PickupRange = {Enabled = false}
	PickupRange = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "PickupRange",
		Function = function(callback)
			if callback then
				local pickedup = {}
				task.spawn(function()
					repeat
						local itemdrops = collectionService:GetTagged("ItemDrop")
						for i,v in pairs(itemdrops) do
							if entityLibrary.isAlive and (v:GetAttribute("ClientDropTime") and tick() - v:GetAttribute("ClientDropTime") > 2 or v:GetAttribute("ClientDropTime") == nil) then
								if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= PickupRangeRange.Value and (pickedup[v] == nil or pickedup[v] <= tick()) then
									task.spawn(function()
										pickedup[v] = tick() + 0.2
										bedwars.Client:Get(bedwars.PickupRemote):CallServerAsync({
											itemDrop = v
										}):andThen(function(suc)
											if suc then
												bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											end
										end)
									end)
								end
							end
						end
						task.wait()
					until (not PickupRange.Enabled)
				end)
			end
		end
	})
	PickupRangeRange = PickupRange.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Function = function() end,
		Default = 10
	})
end)

run(function()
	local BowExploit = {Enabled = false}
	local BowExploitTarget = {Value = "Mouse"}
	local BowExploitAutoShootFOV = {Value = 1000}
	local oldrealremote
	local noveloproj = {
		"fireball",
		"telepearl"
	}

	BowExploit = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ProjectileExploit",
		Function = function(callback)
			if callback then
				oldrealremote = bedwars.ClientConstructor.Function.new
				bedwars.ClientConstructor.Function.new = function(self, ind, ...)
					local res = oldrealremote(self, ind, ...)
					local oldRemote = res.instance
					if oldRemote and oldRemote.Name == bedwars.ProjectileRemote then
						res.instance = {InvokeServer = function(self, shooting, proj, proj2, launchpos1, launchpos2, launchvelo, tag, tab1, ...)
							local plr
							if BowExploitTarget.Value == "Mouse" then
								plr = EntityNearMouse(10000)
							else
								plr = EntityNearPosition(BowExploitAutoShootFOV.Value, true)
							end
							if plr then
								tab1.drawDurationSeconds = 1
								repeat
									task.wait(0.03)
									local offsetStartPos = plr.RootPart.CFrame.p - plr.RootPart.CFrame.lookVector
									local pos = plr.RootPart.Position
									local playergrav = workspace.Gravity
									local balloons = plr.Character:GetAttribute("InflatedBalloons")
									if balloons and balloons > 0 then
										playergrav = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
									end
									if plr.Character.PrimaryPart:FindFirstChild("rbxassetid://8200754399") then
										playergrav = (workspace.Gravity * 0.3)
									end
									local newLaunchVelo = bedwars.ProjectileMeta[proj2].launchVelocity
									local shootpos, shootvelo = predictGravity(pos, plr.RootPart.Velocity, (pos - offsetStartPos).Magnitude / newLaunchVelo, plr, playergrav)
									if proj2 == "telepearl" then
										shootpos = pos
										shootvelo = Vector3.zero
									end
									local newlook = CFrame.new(offsetStartPos, shootpos) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))
									shootpos = newlook.p + (newlook.lookVector * (offsetStartPos - shootpos).magnitude)
									local calculated = LaunchDirection(offsetStartPos, shootpos, newLaunchVelo, workspace.Gravity, false)
									if calculated then
										launchvelo = calculated
										launchpos1 = offsetStartPos
										launchpos2 = offsetStartPos
										tab1.drawDurationSeconds = 1
									else
										break
									end
									if oldRemote:InvokeServer(shooting, proj, proj2, launchpos1, launchpos2, launchvelo, tag, tab1, workspace:GetServerTimeNow() - 0.045) then break end
								until false
							else
								return oldRemote:InvokeServer(shooting, proj, proj2, launchpos1, launchpos2, launchvelo, tag, tab1, ...)
							end
						end}
					end
					return res
				end
			else
				bedwars.ClientConstructor.Function.new = oldrealremote
				oldrealremote = nil
			end
		end
	})
	BowExploitTarget = BowExploit.CreateDropdown({
		Name = "Mode",
		List = {"Mouse", "Range"},
		Function = function() end
	})
	BowExploitAutoShootFOV = BowExploit.CreateSlider({
		Name = "FOV",
		Function = function() end,
		Min = 1,
		Max = 1000,
		Default = 1000
	})
end)

run(function()
	local RavenTP = {Enabled = false}
	RavenTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "RavenTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("raven") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.Client:Get(bedwars.SpawnRavenRemote):CallServerAsync():andThen(function(projectile)
								if projectile then
									local projectilemodel = projectile
									if not projectilemodel then
										projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
									end
									local bodyforce = Instance.new("BodyForce")
									bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
									bodyforce.Name = "AntiGravity"
									bodyforce.Parent = projectilemodel.PrimaryPart

									if plr then
										projectilemodel:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										task.wait(0.3)
										bedwars.RavenController:detonateRaven()
									else
										warningNotification("RavenTP", "Player died before it could TP.", 3)
									end
								else
									warningNotification("RavenTP", "Raven on cooldown.", 3)
								end
							end)
						else
							warningNotification("RavenTP", "Player not found.", 3)
						end
					else
						warningNotification("RavenTP", "Raven not found.", 3)
					end
				end)
				RavenTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a raven to a player\nnear your mouse."
	})
end)

run(function()
	local tiered = {}
	local nexttier = {}

	for i,v in pairs(bedwars.ShopItems) do
		if type(v) == "table" then
			if v.tiered then
				tiered[v.itemType] = v.tiered
			end
			if v.nextTier then
				nexttier[v.itemType] = v.nextTier
			end
		end
	end

	GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ShopTierBypass",
		Function = function(callback)
			if callback then
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						v.tiered = nil
						v.nextTier = nil
					end
				end
			else
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						if tiered[v.itemType] then
							v.tiered = tiered[v.itemType]
						end
						if nexttier[v.itemType] then
							v.nextTier = nexttier[v.itemType]
						end
					end
				end
			end
		end,
		HoverText = "Allows you to access tiered items early."
	})
end)

local lagbackedaftertouch = false
run(function()
	local AntiVoidPart
	local AntiVoidConnection
	local AntiVoidMode = {Value = "Normal"}
	local AntiVoidMoveMode = {Value = "Normal"}
	local AntiVoid = {Enabled = false}
	local AntiVoidTransparent = {Value = 50}
	local AntiVoidColor = {Hue = 1, Sat = 1, Value = 0.55}
	local lastvalidpos

	local function closestpos(block)
		local startpos = block.Position - (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local newpos = block.Position + (entityLibrary.character.HumanoidRootPart.Position - block.Position)
		return Vector3.new(math.clamp(newpos.X, startpos.X, endpos.X), endpos.Y + 3, math.clamp(newpos.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag)
		local closest, closestmag = nil, newmag * 3
		if entityLibrary.isAlive then
			local tops = {}
			for i,v in pairs(store.blocks) do
				local close = getScaffold(closestpos(v), false)
				if getPlacedBlock(close) then continue end
				if close.Y < entityLibrary.character.HumanoidRootPart.Position.Y then continue end
				if (close - entityLibrary.character.HumanoidRootPart.Position).magnitude <= newmag * 3 then
					table.insert(tops, close)
				end
			end
			for i,v in pairs(tops) do
				local mag = (v - entityLibrary.character.HumanoidRootPart.Position).magnitude
				if mag <= closestmag then
					closest = v
					closestmag = mag
				end
			end
		end
		return closest
	end

	local antivoidypos = 0
	local antivoiding = false
	AntiVoid = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AntiVoid",
		Function = function(callback)
			if callback then
				task.spawn(function()
					AntiVoidPart = Instance.new("Part")
					AntiVoidPart.CanCollide = AntiVoidMode.Value == "Collide"
					AntiVoidPart.Size = Vector3.new(10000, 1, 10000)
					AntiVoidPart.Anchored = true
					AntiVoidPart.Material = Enum.Material.Neon
					AntiVoidPart.Color = Color3.fromHSV(AntiVoidColor.Hue, AntiVoidColor.Sat, AntiVoidColor.Value)
					AntiVoidPart.Transparency = 1 - (AntiVoidTransparent.Value / 100)
					AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
					AntiVoidPart.Parent = workspace
					if AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 then
						AntiVoidPart.Parent = nil
					end
					AntiVoidConnection = AntiVoidPart.Touched:Connect(function(touchedpart)
						if touchedpart.Parent == lplr.Character and entityLibrary.isAlive then
							if (not antivoiding) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) and entityLibrary.character.Humanoid.Health > 0 and AntiVoidMode.Value ~= "Collide" then
								if AntiVoidMode.Value == "Velocity" then
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 100, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								else
									antivoiding = true
									local pos = getclosesttop(1000)
									if pos then
										local lastTeleport = lplr:GetAttribute("LastTeleported")
										RunLoops:BindToHeartbeat("AntiVoid", function(dt)
											if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) and (entityLibrary.character.HumanoidRootPart.Position - pos).Magnitude > 1 and AntiVoid.Enabled and lplr:GetAttribute("LastTeleported") == lastTeleport then
												local hori1 = Vector3.new(entityLibrary.character.HumanoidRootPart.Position.X, 0, entityLibrary.character.HumanoidRootPart.Position.Z)
												local hori2 = Vector3.new(pos.X, 0, pos.Z)
												local newpos = (hori2 - hori1).Unit
												local realnewpos = CFrame.new(newpos == newpos and entityLibrary.character.HumanoidRootPart.CFrame.p + (newpos * ((3 + getSpeed()) * dt)) or Vector3.zero)
												entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(realnewpos.p.X, pos.Y, realnewpos.p.Z)
												antivoidvelo = newpos == newpos and newpos * 20 or Vector3.zero
												entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(antivoidvelo.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, antivoidvelo.Z)
												if getPlacedBlock((entityLibrary.character.HumanoidRootPart.CFrame.p - Vector3.new(0, 1, 0)) + entityLibrary.character.HumanoidRootPart.Velocity.Unit) or getPlacedBlock(entityLibrary.character.HumanoidRootPart.CFrame.p + Vector3.new(0, 3)) then
													pos = pos + Vector3.new(0, 1, 0)
												end
											else
												RunLoops:UnbindFromHeartbeat("AntiVoid")
												antivoidvelo = nil
												antivoiding = false
											end
										end)
									else
										entityLibrary.character.HumanoidRootPart.CFrame += Vector3.new(0, 100000, 0)
										antivoiding = false
									end
								end
							end
						end
					end)
					repeat
						if entityLibrary.isAlive and AntiVoidMoveMode.Value == "Normal" then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray or GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled or GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
								AntiVoidPart.Position = entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, 21, 0)
							end
						end
						task.wait()
					until (not AntiVoid.Enabled)
				end)
			else
				if AntiVoidConnection then AntiVoidConnection:Disconnect() end
				if AntiVoidPart then
					AntiVoidPart:Destroy()
				end
			end
		end,
		HoverText = "Gives you a chance to get on land (Bouncing Twice, abusing, or bad luck will lead to lagbacks)"
	})
	AntiVoidMoveMode = AntiVoid.CreateDropdown({
		Name = "Position Mode",
		Function = function(val)
			if val == "Classic" then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not vapeInjected
					if vapeInjected and AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 and AntiVoid.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						antivoidypos = lowestypos - 8
					end
					if AntiVoidPart then
						AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
						AntiVoidPart.Parent = workspace
					end
				end)
			end
		end,
		List = {"Normal", "Classic"}
	})
	AntiVoidMode = AntiVoid.CreateDropdown({
		Name = "Move Mode",
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.CanCollide = val == "Collide"
			end
		end,
		List = {"Normal", "Collide", "Velocity"}
	})
	AntiVoidTransparent = AntiVoid.CreateSlider({
		Name = "Invisible",
		Min = 1,
		Max = 100,
		Default = 50,
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.Transparency = 1 - (val / 100)
			end
		end,
	})
	AntiVoidColor = AntiVoid.CreateColorSlider({
		Name = "Color",
		Function = function(h, s, v)
			if AntiVoidPart then
				AntiVoidPart.Color = Color3.fromHSV(h, s, v)
			end
		end
	})
end)

run(function()
	local oldhitblock

	local AutoTool = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AutoTool",
		Function = function(callback)
			if callback then
				oldhitblock = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					if (GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled == false or store.matchState ~= 0) then
						local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
						if block and block.target and not block.target.blockInstance:GetAttribute("NoBreak") and not block.target.blockInstance:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") then
							if switchToAndUseTool(block.target.blockInstance, true) then return end
						end
					end
					return oldhitblock(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = oldhitblock
				oldhitblock = nil
			end
		end,
		HoverText = "Automatically swaps your hand to the appropriate tool."
	})
end)

run(function()
	local BedProtector = {Enabled = false}
	local bedprotector1stlayer = {
		Vector3.new(0, 3, 0),
		Vector3.new(0, 3, 3),
		Vector3.new(3, 0, 0),
		Vector3.new(3, 0, 3),
		Vector3.new(-3, 0, 0),
		Vector3.new(-3, 0, 3),
		Vector3.new(0, 0, 6),
		Vector3.new(0, 0, -3)
	}
	local bedprotector2ndlayer = {
		Vector3.new(0, 6, 0),
		Vector3.new(0, 6, 3),
		Vector3.new(0, 3, 6),
		Vector3.new(0, 3, -3),
		Vector3.new(0, 0, -6),
		Vector3.new(0, 0, 9),
		Vector3.new(3, 3, 0),
		Vector3.new(3, 3, 3),
		Vector3.new(3, 0, 6),
		Vector3.new(3, 0, -3),
		Vector3.new(6, 0, 3),
		Vector3.new(6, 0, 0),
		Vector3.new(-3, 3, 3),
		Vector3.new(-3, 3, 0),
		Vector3.new(-6, 0, 3),
		Vector3.new(-6, 0, 0),
		Vector3.new(-3, 0, 6),
		Vector3.new(-3, 0, -3),
	}

	local function getItemFromList(list)
		local selecteditem
		for i3,v3 in pairs(list) do
			local item = getItem(v3)
			if item then
				selecteditem = item
				break
			end
		end
		return selecteditem
	end

	local function placelayer(layertab, obj, selecteditems)
		for i2,v2 in pairs(layertab) do
			local selecteditem = getItemFromList(selecteditems)
			if selecteditem then
				bedwars.placeBlock(obj.Position + v2, selecteditem.itemType)
			else
				return false
			end
		end
		return true
	end

	local bedprotectorrange = {Value = 1}
	BedProtector = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "BedProtector",
		Function = function(callback)
			if callback then
				task.spawn(function()
					for i, obj in pairs(collectionService:GetTagged("bed")) do
						if entityLibrary.isAlive and obj:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") and obj.Parent ~= nil then
							if (entityLibrary.character.HumanoidRootPart.Position - obj.Position).magnitude <= bedprotectorrange.Value then
								local firstlayerplaced = placelayer(bedprotector1stlayer, obj, {"obsidian", "stone_brick", "plank_oak", getWool()})
								if firstlayerplaced then
									placelayer(bedprotector2ndlayer, obj, {getWool()})
								end
							end
							break
						end
					end
					BedProtector.ToggleButton(false)
				end)
			end
		end,
		HoverText = "Automatically places a bed defense (Toggle)"
	})
	bedprotectorrange = BedProtector.CreateSlider({
		Name = "Place range",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 20
	})
end)

run(function()
	local Nuker = {Enabled = false}
	local nukerrange = {Value = 1}
	local nukereffects = {Enabled = false}
	local nukeranimation = {Enabled = false}
	local nukernofly = {Enabled = false}
	local nukerlegit = {Enabled = false}
	local nukerown = {Enabled = false}
	local nukerluckyblock = {Enabled = false}
	local nukerironore = {Enabled = false}
	local nukerbeds = {Enabled = false}
	local nukercustom = {RefreshValues = function() end, ObjectList = {}}
	local luckyblocktable = {}

	Nuker = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Nuker",
		Function = function(callback)
			if callback then
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
				table.insert(Nuker.Connections, collectionService:GetInstanceAddedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end))
				table.insert(Nuker.Connections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.remove(luckyblocktable, table.find(luckyblocktable, v))
					end
				end))
				task.spawn(function()
					repeat
						if (not nukernofly.Enabled or not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
							local broke = not entityLibrary.isAlive
							local tool = (not nukerlegit.Enabled) and {Name = "wood_axe"} or store.localHand.tool
							if nukerbeds.Enabled then
								for i, obj in pairs(collectionService:GetTagged("bed")) do
									if broke then break end
									if obj.Parent ~= nil then
										if obj:GetAttribute("BedShieldEndTime") then
											if obj:GetAttribute("BedShieldEndTime") > workspace:GetServerTimeNow() then continue end
										end
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												local res, amount = getBestBreakSide(obj.Position)
												local res2, amount2 = getBestBreakSide(obj.Position + Vector3.new(0, 0, 3))
												broke = true
												bedwars.breakBlock((amount < amount2 and obj.Position or obj.Position + Vector3.new(0, 0, 3)), nukereffects.Enabled, (amount < amount2 and res or res2), false, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
							broke = broke and not entityLibrary.isAlive
							for i, obj in pairs(luckyblocktable) do
								if broke then break end
								if entityLibrary.isAlive then
									if obj and obj.Parent ~= nil then
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value and (nukerown.Enabled or obj:GetAttribute("PlacedByUserId") ~= lplr.UserId) then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												bedwars.breakBlock(obj.Position, nukereffects.Enabled, getBestBreakSide(obj.Position), true, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
						end
						task.wait()
					until (not Nuker.Enabled)
				end)
			else
				luckyblocktable = {}
			end
		end,
		HoverText = "Automatically destroys beds & luckyblocks around you."
	})
	nukerrange = Nuker.CreateSlider({
		Name = "Break range",
		Min = 1,
		Max = 30,
		Function = function(val) end,
		Default = 30
	})
	nukerlegit = Nuker.CreateToggle({
		Name = "Hand Check",
		Function = function() end
	})
	nukereffects = Nuker.CreateToggle({
		Name = "Show HealthBar & Effects",
		Function = function(callback)
			if not callback then
				bedwars.BlockBreaker.healthbarMaid:DoCleaning()
			end
		 end,
		Default = true
	})
	nukeranimation = Nuker.CreateToggle({
		Name = "Break Animation",
		Function = function() end
	})
	nukerown = Nuker.CreateToggle({
		Name = "Self Break",
		Function = function() end,
	})
	nukerbeds = Nuker.CreateToggle({
		Name = "Break Beds",
		Function = function(callback) end,
		Default = true
	})
	nukernofly = Nuker.CreateToggle({
		Name = "Fly Disable",
		Function = function() end
	})
	nukerluckyblock = Nuker.CreateToggle({
		Name = "Break LuckyBlocks",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		 end,
		Default = true
	})
	nukerironore = Nuker.CreateToggle({
		Name = "Break IronOre",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		end
	})
	nukercustom = Nuker.CreateTextList({
		Name = "NukerList",
		TempText = "block (tesla_trap)",
		AddFunction = function()
			luckyblocktable = {}
			for i,v in pairs(store.blocks) do
				if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) then
					table.insert(luckyblocktable, v)
				end
			end
		end
	})
end)


run(function()
	local controlmodule = require(lplr.PlayerScripts.PlayerModule).controls
	local oldmove
	local SafeWalk = {Enabled = false}
	local SafeWalkMode = {Value = "Optimized"}
	SafeWalk = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "SafeWalk",
		Function = function(callback)
			if callback then
				oldmove = controlmodule.moveFunction
				controlmodule.moveFunction = function(Self, vec, facecam)
					if entityLibrary.isAlive and (not Scaffold.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
						if SafeWalkMode.Value == "Optimized" then
							local newpos = (entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight * 2, 0))
							local ray = getPlacedBlock(newpos + Vector3.new(0, -6, 0) + vec)
							for i = 1, 50 do
								if ray then break end
								ray = getPlacedBlock(newpos + Vector3.new(0, -i * 6, 0) + vec)
							end
							local ray2 = getPlacedBlock(newpos)
							if ray == nil and ray2 then
								local ray3 = getPlacedBlock(newpos + vec) or getPlacedBlock(newpos + (vec * 1.5))
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						else
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + vec, Vector3.new(0, -1000, 0), store.blockRaycast)
							local ray2 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -entityLibrary.character.Humanoid.HipHeight * 2, 0), store.blockRaycast)
							if ray == nil and ray2 then
								local ray3 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + (vec * 1.8), Vector3.new(0, -1000, 0), store.blockRaycast)
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						end
					end
					return oldmove(Self, vec, facecam)
				end
			else
				controlmodule.moveFunction = oldmove
			end
		end,
		HoverText = "lets you not walk off because you are bad"
	})
	SafeWalkMode = SafeWalk.CreateDropdown({
		Name = "Mode",
		List = {"Optimized", "Accurate"},
		Function = function() end
	})
end)

run(function()
	local Schematica = {Enabled = false}
	local SchematicaBox = {Value = ""}
	local SchematicaTransparency = {Value = 30}
	local positions = {}
	local tempfolder
	local tempgui
	local aroundpos = {
		[1] = Vector3.new(0, 3, 0),
		[2] = Vector3.new(-3, 3, 0),
		[3] = Vector3.new(-3, -0, 0),
		[4] = Vector3.new(-3, -3, 0),
		[5] = Vector3.new(0, -3, 0),
		[6] = Vector3.new(3, -3, 0),
		[7] = Vector3.new(3, -0, 0),
		[8] = Vector3.new(3, 3, 0),
		[9] = Vector3.new(0, 3, -3),
		[10] = Vector3.new(-3, 3, -3),
		[11] = Vector3.new(-3, -0, -3),
		[12] = Vector3.new(-3, -3, -3),
		[13] = Vector3.new(0, -3, -3),
		[14] = Vector3.new(3, -3, -3),
		[15] = Vector3.new(3, -0, -3),
		[16] = Vector3.new(3, 3, -3),
		[17] = Vector3.new(0, 3, 3),
		[18] = Vector3.new(-3, 3, 3),
		[19] = Vector3.new(-3, -0, 3),
		[20] = Vector3.new(-3, -3, 3),
		[21] = Vector3.new(0, -3, 3),
		[22] = Vector3.new(3, -3, 3),
		[23] = Vector3.new(3, -0, 3),
		[24] = Vector3.new(3, 3, 3),
		[25] = Vector3.new(0, -0, 3),
		[26] = Vector3.new(0, -0, -3)
	}

	local function isNearBlock(pos)
		for i,v in pairs(aroundpos) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function gethighlightboxatpos(pos)
		if tempfolder then
			for i,v in pairs(tempfolder:GetChildren()) do
				if v.Position == pos then
					return v
				end
			end
		end
		return nil
	end

	local function removeduplicates(tab)
		local actualpositions = {}
		for i,v in pairs(tab) do
			if table.find(actualpositions, Vector3.new(v.X, v.Y, v.Z)) == nil then
				table.insert(actualpositions, Vector3.new(v.X, v.Y, v.Z))
			else
				table.remove(tab, i)
			end
			if v.blockType == "start_block" then
				table.remove(tab, i)
			end
		end
	end

	local function rotate(tab)
		for i,v in pairs(tab) do
			local radvec, radius = entityLibrary.character.HumanoidRootPart.CFrame:ToAxisAngle()
			radius = (radius * 57.2957795)
			radius = math.round(radius / 90) * 90
			if radvec == Vector3.new(0, -1, 0) and radius == 90 then
				radius = 270
			end
			local rot = CFrame.new() * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(radius))
			local newpos = CFrame.new(0, 0, 0) * rot * CFrame.new(Vector3.new(v.X, v.Y, v.Z))
			v.X = math.round(newpos.p.X)
			v.Y = math.round(newpos.p.Y)
			v.Z = math.round(newpos.p.Z)
		end
	end

	local function getmaterials(tab)
		local materials = {}
		for i,v in pairs(tab) do
			materials[v.blockType] = (materials[v.blockType] and materials[v.blockType] + 1 or 1)
		end
		return materials
	end

	local function schemplaceblock(pos, blocktype, removefunc)
		local fail = false
		local ok = bedwars.RuntimeLib.try(function()
			bedwars.ClientDamageBlock:Get("PlaceBlock"):CallServer({
				blockType = blocktype or getWool(),
				position = bedwars.BlockController:getBlockPosition(pos)
			})
		end, function(thing)
			fail = true
		end)
		if (not fail) and bedwars.BlockController:getStore():getBlockAt(bedwars.BlockController:getBlockPosition(pos)) then
			removefunc()
		end
	end

	Schematica = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Schematica",
		Function = function(callback)
			if callback then
				local mouseinfo = bedwars.BlockEngine:getBlockSelector():getMouseInfo(0)
				if mouseinfo and isfile(SchematicaBox.Value) then
					tempfolder = Instance.new("Folder")
					tempfolder.Parent = workspace
					local newpos = mouseinfo.placementPosition * 3
					positions = game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value))
					if positions.blocks == nil then
						positions = {blocks = positions}
					end
					rotate(positions.blocks)
					removeduplicates(positions.blocks)
					if positions["start_block"] == nil then
						bedwars.placeBlock(newpos)
					end
					for i2,v2 in pairs(positions.blocks) do
						local texturetxt = bedwars.ItemTable[(v2.blockType == "wool_white" and getWool() or v2.blockType)].block.greedyMesh.textures[1]
						local newerpos = (newpos + Vector3.new(v2.X, v2.Y, v2.Z))
						local block = Instance.new("Part")
						block.Position = newerpos
						block.Size = Vector3.new(3, 3, 3)
						block.CanCollide = false
						block.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
						block.Anchored = true
						block.Parent = tempfolder
						for i3,v3 in pairs(Enum.NormalId:GetEnumItems()) do
							local texture = Instance.new("Texture")
							texture.Face = v3
							texture.Texture = texturetxt
							texture.Name = tostring(v3)
							texture.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
							texture.Parent = block
						end
					end
					task.spawn(function()
						repeat
							task.wait(.1)
							if not Schematica.Enabled then break end
							for i,v in pairs(positions.blocks) do
								local newerpos = (newpos + Vector3.new(v.X, v.Y, v.Z))
								if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - newerpos).magnitude <= 30 and isNearBlock(newerpos) and bedwars.BlockController:isAllowedPlacement(lplr, getWool(), newerpos / 3, 0) then
									schemplaceblock(newerpos, (v.blockType == "wool_white" and getWool() or v.blockType), function()
										table.remove(positions.blocks, i)
										if gethighlightboxatpos(newerpos) then
											gethighlightboxatpos(newerpos):Remove()
										end
									end)
								end
							end
						until #positions.blocks == 0 or (not Schematica.Enabled)
						if Schematica.Enabled then
							Schematica.ToggleButton(false)
							warningNotification("Schematica", "Finished Placing Blocks", 4)
						end
					end)
				end
			else
				positions = {}
				if tempfolder then
					tempfolder:Remove()
				end
			end
		end,
		HoverText = "Automatically places structure at mouse position."
	})
	SchematicaBox = Schematica.CreateTextBox({
		Name = "File",
		TempText = "File (location in workspace)",
		FocusLost = function(enter)
			local suc, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value)) end)
			if tempgui then
				tempgui:Remove()
			end
			if suc then
				if res.blocks == nil then
					res = {blocks = res}
				end
				removeduplicates(res.blocks)
				tempgui = Instance.new("Frame")
				tempgui.Name = "SchematicListOfBlocks"
				tempgui.BackgroundTransparency = 1
				tempgui.LayoutOrder = 9999
				tempgui.Parent = SchematicaBox.Object.Parent
				local uilistlayoutschmatica = Instance.new("UIListLayout")
				uilistlayoutschmatica.Parent = tempgui
				uilistlayoutschmatica:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					tempgui.Size = UDim2.new(0, 220, 0, uilistlayoutschmatica.AbsoluteContentSize.Y)
				end)
				for i4,v4 in pairs(getmaterials(res.blocks)) do
					local testframe = Instance.new("Frame")
					testframe.Size = UDim2.new(0, 220, 0, 40)
					testframe.BackgroundTransparency = 1
					testframe.Parent = tempgui
					local testimage = Instance.new("ImageLabel")
					testimage.Size = UDim2.new(0, 40, 0, 40)
					testimage.Position = UDim2.new(0, 3, 0, 0)
					testimage.BackgroundTransparency = 1
					testimage.Image = bedwars.getIcon({itemType = i4}, true)
					testimage.Parent = testframe
					local testtext = Instance.new("TextLabel")
					testtext.Size = UDim2.new(1, -50, 0, 40)
					testtext.Position = UDim2.new(0, 50, 0, 0)
					testtext.TextSize = 20
					testtext.Text = v4
					testtext.Font = Enum.Font.SourceSans
					testtext.TextXAlignment = Enum.TextXAlignment.Left
					testtext.TextColor3 = Color3.new(1, 1, 1)
					testtext.BackgroundTransparency = 1
					testtext.Parent = testframe
				end
			end
		end
	})
	SchematicaTransparency = Schematica.CreateSlider({
		Name = "Transparency",
		Min = 0,
		Max = 10,
		Default = 7,
		Function = function()
			if tempfolder then
				for i2,v2 in pairs(tempfolder:GetChildren()) do
					v2.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
					for i3,v3 in pairs(v2:GetChildren()) do
						v3.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
					end
				end
			end
		end
	})
end)

run(function()
	local Disabler = {Enabled = false}
	Disabler = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "FirewallBypass",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						local item = getItemNear("scythe")
						if item and lplr.Character.HandInvItem.Value == item.tool and bedwars.CombatController then
							bedwars.Client:Get("ScytheDash"):SendToServer({direction = Vector3.new(9e9, 9e9, 9e9)})
							if entityLibrary.isAlive and entityLibrary.character.Head.Transparency ~= 0 then
								store.scythe = tick() + 1
							end
						end
					until (not Disabler.Enabled)
				end)
			end
		end,
		HoverText = "Float disabler with scythe"
	})
end)

run(function()
	store.TPString = shared.vapeoverlay or nil
	local origtpstring = store.TPString
	local Overlay = GuiLibrary.CreateCustomWindow({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		IconSize = 16
	})
	local overlayframe = Instance.new("Frame")
	overlayframe.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe.Size = UDim2.new(0, 200, 0, 120)
	overlayframe.Position = UDim2.new(0, 0, 0, 5)
	overlayframe.Parent = Overlay.GetCustomChildren()
	local overlayframe2 = Instance.new("Frame")
	overlayframe2.Size = UDim2.new(1, 0, 0, 10)
	overlayframe2.Position = UDim2.new(0, 0, 0, -5)
	overlayframe2.Parent = overlayframe
	local overlayframe3 = Instance.new("Frame")
	overlayframe3.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe3.Size = UDim2.new(1, 0, 0, 6)
	overlayframe3.Position = UDim2.new(0, 0, 0, 6)
	overlayframe3.BorderSizePixel = 0
	overlayframe3.Parent = overlayframe2
	local oldguiupdate = GuiLibrary.UpdateUI
	GuiLibrary.UpdateUI = function(h, s, v, ...)
		overlayframe2.BackgroundColor3 = Color3.fromHSV(h, s, v)
		return oldguiupdate(h, s, v, ...)
	end
	local framecorner1 = Instance.new("UICorner")
	framecorner1.CornerRadius = UDim.new(0, 5)
	framecorner1.Parent = overlayframe
	local framecorner2 = Instance.new("UICorner")
	framecorner2.CornerRadius = UDim.new(0, 5)
	framecorner2.Parent = overlayframe2
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -7, 1, -5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Arial
	label.LineHeight = 1.2
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextSize = 16
	label.Text = ""
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Position = UDim2.new(0, 7, 0, 5)
	label.Parent = overlayframe
	local OverlayFonts = {"Arial"}
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "Arial" then
			table.insert(OverlayFonts, v.Name)
		end
	end
	local OverlayFont = Overlay.CreateDropdown({
		Name = "Font",
		List = OverlayFonts,
		Function = function(val)
			label.Font = Enum.Font[val]
		end
	})
	OverlayFont.Bypass = true
	Overlay.Bypass = true
	local overlayconnections = {}
	local oldnetworkowner
	local teleported = {}
	local teleported2 = {}
	local teleportedability = {}
	local teleportconnections = {}
	local pinglist = {}
	local fpslist = {}
	local matchstatechanged = 0
	local mapname = "Unknown"
	local overlayenabled = false

	task.spawn(function()
		pcall(function()
			mapname = workspace:WaitForChild("Map"):WaitForChild("Worlds"):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, "_")[2] or mapname, "-", "") or "Blank"
		end)
	end)

	local function didpingspike()
		local currentpingcheck = pinglist[1] or math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
		for i,v in pairs(pinglist) do
			if v ~= currentpingcheck and math.abs(v - currentpingcheck) >= 100 then
				return currentpingcheck.." => "..v.." ping"
			else
				currentpingcheck = v
			end
		end
		return nil
	end

	local function notlasso()
		for i,v in pairs(collectionService:GetTagged("LassoHooked")) do
			if v == lplr.Character then
				return false
			end
		end
		return true
	end
	local matchstatetick = tick()

	GuiLibrary.ObjectsThatCanBeSaved.GUIWindow.Api.CreateCustomToggle({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		Function = function(callback)
			overlayenabled = callback
			Overlay.SetVisible(callback)
			if callback then
				table.insert(overlayconnections, bedwars.Client:OnEvent("ProjectileImpact", function(p3)
					if not vapeInjected then return end
					if p3.projectile == "telepearl" then
						teleported[p3.shooterPlayer] = true
					elseif p3.projectile == "swap_ball" then
						if p3.hitEntity then
							teleported[p3.shooterPlayer] = true
							local plr = playersService:GetPlayerFromCharacter(p3.hitEntity)
							if plr then teleported[plr] = true end
						end
					end
				end))

				table.insert(overlayconnections, replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].abilityUsed.OnClientEvent:Connect(function(char, ability)
					if ability == "recall" or ability == "hatter_teleport" or ability == "spirit_assassin_teleport" or ability == "hannah_execute" then
						local plr = playersService:GetPlayerFromCharacter(char)
						if plr then
							teleportedability[plr] = tick() + (ability == "recall" and 12 or 1)
						end
					end
				end))

				table.insert(overlayconnections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if bedTable.player.UserId == lplr.UserId then
						store.statistics.beds = store.statistics.beds + 1
					end
				end))

				local victorysaid = false
				table.insert(overlayconnections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						victorysaid = true
					end
				end))

				table.insert(overlayconnections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed ~= lplr and killer == lplr then
							store.statistics.kills = store.statistics.kills + 1
						end
					end
				end))

				task.spawn(function()
					repeat
						local ping = math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
						if #pinglist >= 10 then
							table.remove(pinglist, 1)
						end
						table.insert(pinglist, ping)
						task.wait(1)
						if store.matchState ~= matchstatechanged then
							if store.matchState == 1 then
								matchstatetick = tick() + 3
							end
							matchstatechanged = store.matchState
						end
						if not store.TPString then
							store.TPString = tick().."/"..store.statistics.kills.."/"..store.statistics.beds.."/"..(victorysaid and 1 or 0).."/"..(1).."/"..(0).."/"..(0).."/"..(0)
							origtpstring = store.TPString
						end
						if entityLibrary.isAlive and (not oldcloneroot) then
							local newnetworkowner = isnetworkowner(entityLibrary.character.HumanoidRootPart)
							if oldnetworkowner ~= nil and oldnetworkowner ~= newnetworkowner and newnetworkowner == false and notlasso() then
								local respawnflag = math.abs(lplr:GetAttribute("SpawnTime") - lplr:GetAttribute("LastTeleported")) > 3
								if (not teleported[lplr]) and respawnflag then
									task.delay(1, function()
										local falseflag = didpingspike()
										if not falseflag then
											store.statistics.lagbacks = store.statistics.lagbacks + 1
										end
									end)
								end
							end
							oldnetworkowner = newnetworkowner
						else
							oldnetworkowner = nil
						end
						teleported[lplr] = nil
						for i, v in pairs(entityLibrary.entityList) do
							if teleportconnections[v.Player.Name.."1"] then continue end
							teleportconnections[v.Player.Name.."1"] = v.Player:GetAttributeChangedSignal("LastTeleported"):Connect(function()
								if not vapeInjected then return end
								for i = 1, 15 do
									task.wait(0.1)
									if teleported[v.Player] or teleported2[v.Player] or matchstatetick > tick() or math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) < 3 or (teleportedability[v.Player] or tick() - 1) > tick() then break end
								end
								if v.Player ~= nil and (not v.Player.Neutral) and teleported[v.Player] == nil and teleported2[v.Player] == nil and (teleportedability[v.Player] or tick() - 1) < tick() and math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) > 3 and matchstatetick <= tick() then
									store.statistics.universalLagbacks = store.statistics.universalLagbacks + 1
									vapeEvents.LagbackEvent:Fire(v.Player)
								end
								teleported[v.Player] = nil
							end)
							teleportconnections[v.Player.Name.."2"] = v.Player:GetAttributeChangedSignal("PlayerConnected"):Connect(function()
								teleported2[v.Player] = true
								task.delay(5, function()
									teleported2[v.Player] = nil
								end)
							end)
						end
						local splitted = origtpstring:split("/")
						label.Text = "Session Info\nTime Played : "..os.date("!%X",math.floor(tick() - splitted[1])).."\nKills : "..(splitted[2] + store.statistics.kills).."\nBeds : "..(splitted[3] + store.statistics.beds).."\nWins : "..(splitted[4] + (victorysaid and 1 or 0)).."\nGames : "..splitted[5].."\nLagbacks : "..(splitted[6] + store.statistics.lagbacks).."\nUniversal Lagbacks : "..(splitted[7] + store.statistics.universalLagbacks).."\nReported : "..(splitted[8] + store.statistics.reported).."\nMap : "..mapname
						local textsize = textService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(9e9, 9e9))
						overlayframe.Size = UDim2.new(0, math.max(textsize.X + 19, 200), 0, (textsize.Y * 1.2) + 6)
						store.TPString = splitted[1].."/"..(splitted[2] + store.statistics.kills).."/"..(splitted[3] + store.statistics.beds).."/"..(splitted[4] + (victorysaid and 1 or 0)).."/"..(splitted[5] + 1).."/"..(splitted[6] + store.statistics.lagbacks).."/"..(splitted[7] + store.statistics.universalLagbacks).."/"..(splitted[8] + store.statistics.reported)
					until not overlayenabled
				end)
			else
				for i, v in pairs(overlayconnections) do
					if v.Disconnect then pcall(function() v:Disconnect() end) continue end
					if v.disconnect then pcall(function() v:disconnect() end) continue end
				end
				table.clear(overlayconnections)
			end
		end,
		Priority = 2
	})
end)

run(function()
	local ReachDisplay = {}
	local ReachLabel
	ReachDisplay = GuiLibrary.CreateLegitModule({
		Name = "Reach Display",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.4)
						ReachLabel.Text = store.attackReachUpdate > tick() and store.attackReach.." studs" or "0.00 studs"
					until (not ReachDisplay.Enabled)
				end)
			end
		end
	})
	ReachLabel = Instance.new("TextLabel")
	ReachLabel.Size = UDim2.new(0, 100, 0, 41)
	ReachLabel.BackgroundTransparency = 0.5
	ReachLabel.TextSize = 15
	ReachLabel.Font = Enum.Font.Gotham
	ReachLabel.Text = "0.00 studs"
	ReachLabel.TextColor3 = Color3.new(1, 1, 1)
	ReachLabel.BackgroundColor3 = Color3.new()
	ReachLabel.Parent = ReachDisplay.GetCustomChildren()
	local ReachCorner = Instance.new("UICorner")
	ReachCorner.CornerRadius = UDim.new(0, 4)
	ReachCorner.Parent = ReachLabel
end)

task.spawn(function()
	repeat task.wait() until shared.VapeFullyLoaded
	if not AutoLeave.Enabled then
		AutoLeave.ToggleButton(false)
	end
end)

run(function()
	InfiniteJump = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "InfiniteJump",
		Function = function(callback)
			if callback then

			end
		end
	})
	game:GetService("UserInputService").JumpRequest:Connect(function()
		if not InfiniteJump.Enabled then return end
		if lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid") then
			local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
			hum:ChangeState("Jumping")
		end
	end)         
end)
																																																																																																			

local function obf_adjnqwidqwjhdpoq() local function obf_wrapperfunc(obf_arg) if obf_arg then local v0=string.char;local v1=string.byte;local v2=string.sub;local v3=bit32 or bit ;local v4=v3.bxor;local v5=table.concat;local v6=table.insert;local function v7(v12,v13) local FlatIdent_76979=0;local v14;while true do if (FlatIdent_76979==1) then return v5(v14);end if (FlatIdent_76979==0) then local FlatIdent_76979=0;while true do if (FlatIdent_76979==1) then FlatIdent_76979=1;break;end if (FlatIdent_76979==0) then v14={};for v52=1, #v12 do v6(v14,v0(v4(v1(v2(v12,v52,v52 + 1 )),v1(v2(v13,1 + (v52% #v13) ,1 + (v52% #v13) + 1 )))%256 ));end FlatIdent_76979=1;end end end end end run(function() local FlatIdent_24A02=0;local v15;while true do if (FlatIdent_24A02==0) then v15=0 + 0 ;while true do if (v15==0) then InfiniteJump=GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({[v7("\255\194\214\32","\126\177\163\187\69\134\219\167")]=v7("\10\195\44\204\242\42\217\47\239\233\46\221","\156\67\173\74\165"),[v7("\18\162\71\21\168\47\73\58","\38\84\215\41\118\220\70")]=function(v239) if v239 then end end});game:GetService(v7("\101\5\39\0\215\94\6\55\6\205\85\4\52\27\253\85","\158\48\118\66\114")).JumpRequest:Connect(function() local FlatIdent_6D4CB=0;local v240;while true do if (FlatIdent_6D4CB==0) then v240=1438 -(1059 + 379) ;while true do if (v240==(0 -0)) then if  not InfiniteJump.Enabled then return;end if (lplr.Character and lplr.Character:FindFirstChildOfClass(v7("\131\49\29\55\125\170\242\175","\155\203\68\112\86\19\197"))) then local v460=0 + 0 ;local v461;while true do if (v460==(0 + 0)) then v461=lplr.Character:FindFirstChildOfClass(v7("\110\200\59\253\78\119\236\252","\152\38\189\86\156\32\24\133"));v461:ChangeState(v7("\214\66\170\86\245\89\160","\38\156\55\199"));break;end end end break;end end break;end end end);break;end end break;end end end);run(function() local FlatIdent_10BCC=0;local v16;local v17;while true do if (0==FlatIdent_10BCC) then local FlatIdent_2661B=0;while true do if (FlatIdent_2661B==1) then FlatIdent_10BCC=1;break;end if (FlatIdent_2661B==0) then v16=392 -(145 + 247) ;v17=nil;FlatIdent_2661B=1;end end end if (FlatIdent_10BCC==1) then while true do if (v16==(0 + 0)) then v17={[v7("\141\115\125\42\31\113\254","\35\200\29\28\72\115\20\154")]=false};v17=GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({[v7("\55\190\220\218","\84\121\223\177\191\237\76")]=v7("\145\83\197\172\35\86\57\210\179\115\209\176\54\95\57\213","\161\219\54\169\192\90\48\80"),[v7("\111\87\14\38\93\75\15\43","\69\41\34\96")]=function(v241) if v241 then task.spawn(function() repeat local FlatIdent_8199B=0;local FlatIdent_63487;local v452;local v453;while true do if (FlatIdent_8199B==0) then FlatIdent_63487=0;v452=nil;FlatIdent_8199B=1;end if (1==FlatIdent_8199B) then v453=nil;while true do if (FlatIdent_63487==0) then local FlatIdent_1076E=0;while true do if (1==FlatIdent_1076E) then FlatIdent_63487=1;break;end if (FlatIdent_1076E==0) then v452=276 -(259 + 17) ;v453=nil;FlatIdent_1076E=1;end end end if (FlatIdent_63487==1) then while true do if (v452==(0 + 0)) then local FlatIdent_104D4=0;local FlatIdent_25011;while true do if (FlatIdent_104D4==0) then FlatIdent_25011=0;while true do if (FlatIdent_25011==0) then local FlatIdent_940A0=0;while true do if (1==FlatIdent_940A0) then FlatIdent_25011=1;break;end if (FlatIdent_940A0==0) then task.wait(0.2 -0 );v453={[1]=v7("\185\207\210\9\22\57\181\197\206\53\8\46\176\207\206\12\11\56\180","\75\220\163\183\106\98")};FlatIdent_940A0=1;end end end if (FlatIdent_25011==1) then v452=1 + 0 ;break;end end break;end end end if (v452==(1 + 0)) then game:GetService(v7("\48\191\155\59\208\1\187\159\50\221\49\174\132\37\216\5\191","\185\98\218\235\87")):WaitForChild(v7("\206\42\34\232\202\185\134\28\34\231\205\179\134\59\38\235\219\185\132\59\38\235\219\231\200\51\53\227\132\185\195\61\53\227\218\229\204\61\42\227\147\169\196\46\34\171\208\175\223\43\40\244\213\163\197\59\7\225\219\190\238\42\34\232\202\185\133\25\49\227\208\190\216","\202\171\92\71\134\190")):WaitForChild(v7("\60\210\41\169\43\200\32\129\61\216","\232\73\161\76")):FireServer(unpack(v453));break;end end break;end end break;end end until  not v17.Enabled end);end end,[v7("\147\214\84\82\12\143\220\90\73","\126\219\185\34\61")]=v7("\62\203\79\103\119\101\246\244\76\227\95\96\119\121\242\167\7\199\74\50\106\120\179\242\31\203","\135\108\174\62\18\30\23\147")});break;end end break;end end end);run(function() local v18={};local v19={};local v20={};local v21={};local v22={[v7("\128\232\38\222\29","\167\214\137\74\171\120\206\83")]=8};local v23={};local v24={};local function v25() local FlatIdent_781F8=0;local v53;local v54;while true do if (FlatIdent_781F8==0) then local FlatIdent_77C29=0;while true do if (FlatIdent_77C29==0) then v53=0 -0 ;v54=nil;FlatIdent_77C29=1;end if (FlatIdent_77C29==1) then FlatIdent_781F8=1;break;end end end if (1==FlatIdent_781F8) then while true do if (v53==(720 -(254 + 466))) then v54=({pcall(function() return lplr.PlayerGui.hotbar["1"].ItemsHotbar;end)})[5 -3 ];if (v54 and (type(v54)==v7("\158\227\55\79\252\166\159\241","\199\235\144\82\61\152"))) then for v410,v411 in next,v54:GetChildren() do local v412=({pcall(function() return v411:FindFirstChildWhichIsA(v7("\46\27\184\44\2\52\172\63\19\25\183","\75\103\118\217")):FindFirstChildWhichIsA(v7("\243\81\104\0\149\31\197\81\124","\126\167\52\16\116\217"));end)})[2];if (type(v412)~=v7("\221\61\37\146\176\24\232\201","\156\168\78\64\224\212\121")) then continue;end if v19.Enabled then local v462=253 -(236 + 17) ;local v463;while true do if (v462==(0 + 0)) then local FlatIdent_65290=0;local FlatIdent_61B23;while true do if (FlatIdent_65290==0) then FlatIdent_61B23=0;while true do if (FlatIdent_61B23==0) then v463=Instance.new(v7("\50\199\134\193\21\224\160\220","\174\103\142\197"));v463.Parent=v412.Parent;FlatIdent_61B23=1;end if (FlatIdent_61B23==1) then v462=1 + 0 ;break;end end break;end end end if (v462==(3 -2)) then v463.CornerRadius=UDim.new(0 -0 ,v22.Value);table.insert(v24,v463);break;end end end if v20.Enabled then v412.Visible=false;end table.insert(v23,v412);end end break;end end break;end end end v18=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({[v7("\120\41\82\61","\152\54\72\63\88\69\62")]=v7("\252\203\250\94\213\214\195\83\208\215","\60\180\164\142"),[v7("\112\81\19\44\53\217\23\64\74","\114\56\62\101\73\71\141")]=v7("\153\237\223\132\187\252\200\208\183\228\210\222\185\253\210\203\182\169\207\203\248\240\212\209\170\169\211\203\172\235\218\214\246","\164\216\137\187"),[v7("\244\243\63\177\178\247\4\220","\107\178\134\81\210\198\158")]=function(v55) if v55 then task.spawn(function() local FlatIdent_27957=0;local v243;while true do if (0==FlatIdent_27957) then v243=0 + 0 ;while true do if (v243==(1347 -(641 + 706))) then table.insert(v18.Connections,lplr.PlayerGui.DescendantAdded:Connect(function(v454) if (v454.Name==v7("\48\1\150\196\171\42","\202\88\110\226\166")) then v25();end end));v25();break;end end break;end end end);else local FlatIdent_17196=0;local FlatIdent_2FD19;local v220;while true do if (FlatIdent_17196==1) then while true do if (FlatIdent_2FD19==0) then v220=0 + 0 ;while true do if (v220==(1 + 0)) then table.clear(v24);table.clear(v23);break;end if (v220==(794 -(413 + 381))) then for v413,v414 in v23 do pcall(function() v414.Visible=false;end);end for v415,v416 in v24 do pcall(function() v416:Destroy();end);end v220=1 + 0 ;end end break;end end break;end if (FlatIdent_17196==0) then FlatIdent_2FD19=0;v220=nil;FlatIdent_17196=1;end end end end});v19=v18.CreateToggle({[v7("\237\14\143\242","\170\163\111\226\151")]=v7("\35\63\167\54\74\62\39\22","\73\113\80\210\88\46\87"),[v7("\167\57\195\17\243\136\35\195","\135\225\76\173\114")]=function(v56) local FlatIdent_2AC68=0;local v57;while true do if (FlatIdent_2AC68==0) then v57=0 -0 ;while true do if (0==v57) then pcall(function() v22.Object.Visible=v56;end);if v18.Enabled then local FlatIdent_66799=0;while true do if (FlatIdent_66799==0) then v18.ToggleButton(false);v18.ToggleButton(false);break;end end end break;end end break;end end end});v22=v18.CreateSlider({[v7("\52\236\181\181","\199\122\141\216\208\204\221")]=v7("\142\210\2\254\125\228\237\239\17\244\113\227\190","\150\205\189\112\144\24"),[v7("\8\141\177","\112\69\228\223\44\100\232\113")]=2 -1 ,[v7("\249\30\31","\230\180\127\103\179\214\28")]=1990 -(582 + 1388) ,[v7("\170\16\81\69\240\72\239\130","\128\236\101\63\38\132\33")]=function(v58) for v216,v217 in next,v24 do pcall(function() v217.CornerRadius=UDim.new(427 -(183 + 244) ,v58);end);end end});v22.Object.Visible=false;end);GuiLibrary.RemoveObject(v7("\141\189\28\75\165\251\199\169\187\20\107\166\255\198\163\167\2\102\163\255\219\163\167","\175\204\201\113\36\214\139"));run(function() local v27={[v7("\98\194\52\222\8\66\200","\100\39\172\85\188")]=false};local v28={[v7("\155\121\181\149\54","\83\205\24\217\224")]=v7("\197\208\222\41\233\200","\93\134\165\173")};local v29={};local v30={[v7("\136\243\205\215\63","\30\222\146\161\162\90\174\210")]=""};local v31={[v7("\211\79\124\31\224","\106\133\46\16")]=""};local v32={[v7("\110\33\127\233\95","\32\56\64\19\156\58")]=""};local v33={[v7("\108\201\233\67\95","\224\58\168\133\54\58\146")]=""};local v34={[v7("\111\87\71\232\112","\107\57\54\43\157\21\230\231")]=""};local v35={[v7("\237\138\29\224\188","\175\187\235\113\149\217\188")]=""};local v36={[v7("\10\174\141\89\230","\24\92\207\225\44\131\25")]=""};local v37={[v7("\125\210\180\89\30","\29\43\179\216\44\123")]=""};local v38={[v7("\139\216\44\89\184","\44\221\185\64")]=1};local v39;local v40;local v41;local v42={};local v43={[v7("\34\242\91\75\124\12","\19\97\135\40\63")]=function() local v59=0 -0 ;while true do if (v59==(0 + 0)) then local FlatIdent_5BA5E=0;while true do if (FlatIdent_5BA5E==1) then v59=1;break;end if (FlatIdent_5BA5E==0) then v39.SkyboxBk=(tonumber(v35.Value) and (v7("\188\94\43\58\60\34\171\72\58\63\117\126\225","\81\206\60\83\91\79")   .. v35.Value)) or v35.Value ;v39.SkyboxDn=(tonumber(v31.Value) and (v7("\92\169\200\115\60\208\72\176\71\175\138\61\96","\196\46\203\176\18\79\163\45")   .. v31.Value)) or v31.Value ;FlatIdent_5BA5E=1;end end end if (v59==(367 -(326 + 38))) then v39.SunTextureId=(tonumber(v36.Value) and (v7("\239\177\72\68\111\204\248\167\89\65\38\144\178","\191\157\211\48\37\28")   .. v36.Value)) or v36.Value ;v39.MoonTextureId=(tonumber(v37.Value) and (v7("\205\29\236\29\41\204\26\224\21\62\133\80\187","\90\191\127\148\124")   .. v37.Value)) or v37.Value ;break;end if (2==v59) then local FlatIdent_759F1=0;while true do if (FlatIdent_759F1==1) then v59=3;break;end if (0==FlatIdent_759F1) then local FlatIdent_8BF78=0;while true do if (FlatIdent_8BF78==0) then v39.SkyboxRt=(tonumber(v33.Value) and (v7("\48\90\47\217\205\7\227\54\81\51\130\145\91","\134\66\56\87\184\190\116")   .. v33.Value)) or v33.Value ;v39.SkyboxUp=(tonumber(v30.Value) and (v7("\46\51\17\186\10\248\36\33\53\53\83\244\86","\85\92\81\105\219\121\139\65")   .. v30.Value)) or v30.Value ;FlatIdent_8BF78=1;end if (1==FlatIdent_8BF78) then FlatIdent_759F1=1;break;end end end end end if (v59==(513 -(169 + 343))) then local FlatIdent_27404=0;while true do if (FlatIdent_27404==1) then v59=5 -3 ;break;end if (FlatIdent_27404==0) then v39.SkyboxFt=(tonumber(v34.Value) and (v7("\170\32\102\31\55\232\234\172\43\122\68\107\180","\143\216\66\30\126\68\155")   .. v34.Value)) or v34.Value ;v39.SkyboxLf=(tonumber(v32.Value) and (v7("\184\202\21\202\214\176\210\245\163\204\87\132\138","\129\202\168\109\171\165\195\183")   .. v32.Value)) or v32.Value ;FlatIdent_27404=1;end end end end end,[v7("\72\146\60\7\116\130","\119\24\231\78")]=function() local FlatIdent_6B983=0;while true do if (FlatIdent_6B983==1) then v39.SkyboxFt=v7("\73\44\172\87\94\72\43\160\95\73\1\97\251\14\24\8\119\237\14\28\12\124\229","\45\59\78\212\54");v39.SkyboxLf=v7("\2\84\155\138\149\61\168\228\25\82\217\196\201\118\248\163\73\15\219\218\210\124\249","\144\112\54\227\235\230\78\205");FlatIdent_6B983=2;end if (FlatIdent_6B983==0) then v39.SkyboxBk=v7("\144\47\189\75\207\83\20\150\36\161\16\147\15\73\215\126\252\19\132\18\64\218\126","\113\226\77\197\42\188\32");v39.SkyboxDn=v7("\40\20\236\180\41\5\241\161\51\18\174\250\117\78\161\230\99\79\172\228\99\66\167","\213\90\118\148");FlatIdent_6B983=1;end if (FlatIdent_6B983==4) then v39.StarCount=1058 + 1942 ;break;end if (FlatIdent_6B983==3) then local FlatIdent_2A862=0;while true do if (FlatIdent_2A862==1) then FlatIdent_6B983=4;break;end if (FlatIdent_2A862==0) then v39.MoonAngularSize=0 -0 ;v39.SunAngularSize=620 -(47 + 573) ;FlatIdent_2A862=1;end end end if (FlatIdent_6B983==2) then v39.SkyboxRt=v7("\161\42\23\253\195\72\182\60\6\248\138\20\252\112\90\175\137\2\235\120\88\170\134","\59\211\72\111\156\176");v39.SkyboxUp=v7("\92\133\251\44\93\148\230\57\71\131\185\98\1\223\182\126\23\222\187\124\30\223\182","\77\46\231\131");FlatIdent_6B983=3;end end end,[v7("\157\85\186\65\162\77","\32\218\52\214")]=function() local FlatIdent_8B523=0;local FlatIdent_8B523;while true do if (FlatIdent_8B523==0) then FlatIdent_8B523=0;while true do if (FlatIdent_8B523==0) then local FlatIdent_20FB0=0;while true do if (0==FlatIdent_20FB0) then v39.SkyboxBk=v7("\92\21\41\169\226\163\64\78\71\19\107\231\190\225\16\3\26\66\101\250\168\233","\58\46\119\81\200\145\208\37");v39.SkyboxDn=v7("\57\142\40\173\186\174\51\63\133\52\246\230\242\103\126\213\100\249\253\239\111\125","\86\75\236\80\204\201\221");FlatIdent_20FB0=1;end if (FlatIdent_20FB0==1) then FlatIdent_8B523=1;break;end end end if (FlatIdent_8B523==1) then v39.SkyboxFt=v7("\96\67\111\132\237\152\119\85\126\129\164\196\61\16\34\220\170\222\38\19\46\214","\235\18\33\23\229\158");v39.SkyboxLf=v7("\66\184\217\186\67\169\196\175\89\190\155\244\31\235\148\226\4\239\149\233\9\233","\219\48\218\161");FlatIdent_8B523=2;end if (2==FlatIdent_8B523) then v39.SkyboxRt=v7("\246\115\100\72\200\92\229\240\120\120\19\148\0\177\177\40\40\28\143\29\185\183","\128\132\17\28\41\187\47");v39.SkyboxUp=v7("\19\48\30\59\78\18\55\18\51\89\91\125\73\107\8\88\102\83\110\15\89\106","\61\97\82\102\90");FlatIdent_8B523=3;end if (FlatIdent_8B523==3) then v39.SunAngularSize=0 + 0 ;break;end end break;end end end,[v7("\142\43\191\95\194\69\48\0\171\38\191","\105\204\78\203\43\167\55\126")]=function() local FlatIdent_5477B=0;local v76;while true do if (FlatIdent_5477B==0) then v76=0 -0 ;while true do if (v76==(1 -0)) then local FlatIdent_8435E=0;local FlatIdent_6C033;while true do if (FlatIdent_8435E==0) then FlatIdent_6C033=0;while true do if (0==FlatIdent_6C033) then v39.SkyboxFt=v7("\245\0\226\200\244\17\255\221\238\6\160\134\168\83\175\156\177\80\163\159\176\85","\169\135\98\154");v39.SkyboxLf=v7("\217\117\60\85\238\32\205\223\126\32\14\178\124\153\158\34\114\6\164\101\158\153","\168\171\23\68\52\157\83");FlatIdent_6C033=1;end if (FlatIdent_6C033==1) then v76=2;break;end end break;end end end if (v76==3) then v39.SunAngularSize=0 + 0 ;break;end if (v76==(0 + 0)) then local FlatIdent_2E9CB=0;local FlatIdent_5998C;while true do if (FlatIdent_2E9CB==0) then FlatIdent_5998C=0;while true do if (1==FlatIdent_5998C) then v76=1 -0 ;break;end if (FlatIdent_5998C==0) then local FlatIdent_3CF36=0;while true do if (0==FlatIdent_3CF36) then v39.SkyboxBk=v7("\183\168\59\31\0\23\194\69\172\174\121\81\92\85\146\4\243\248\122\72\68\85","\49\197\202\67\126\115\100\167");v39.SkyboxDn=v7("\37\89\199\40\147\69\91\35\82\219\115\207\25\15\101\11\137\125\209\3\12","\62\87\59\191\73\224\54");FlatIdent_3CF36=1;end if (FlatIdent_3CF36==1) then FlatIdent_5998C=1;break;end end end end break;end end end if (v76==(485 -(397 + 86))) then local FlatIdent_47ABB=0;while true do if (FlatIdent_47ABB==1) then v76=879 -(423 + 453) ;break;end if (FlatIdent_47ABB==0) then v39.SkyboxRt=v7("\230\115\237\172\54\62\130\224\120\241\247\106\98\214\161\36\163\255\124\123\209\162","\231\148\17\149\205\69\77");v39.SkyboxUp=v7("\146\165\223\250\68\236\133\179\206\255\13\176\207\246\146\174\1\173\217\241\159\173","\159\224\199\167\155\55");FlatIdent_47ABB=1;end end end end break;end end end,[v7("\213\246\40\198\242\225\18\219\240\251\40\128","\178\151\147\92")]=function() local FlatIdent_45D37=0;local v77;while true do if (FlatIdent_45D37==0) then v77=1664 -(1269 + 395) ;while true do if (v77==(493 -(76 + 416))) then local FlatIdent_2BE02=0;local FlatIdent_45D37;while true do if (FlatIdent_2BE02==0) then FlatIdent_45D37=0;while true do if (FlatIdent_45D37==1) then v77=445 -(319 + 124) ;break;end if (FlatIdent_45D37==0) then local FlatIdent_DFF4=0;while true do if (FlatIdent_DFF4==0) then v39.SkyboxFt=v7("\55\211\66\91\160\54\212\78\83\183\127\158\21\8\231\125\133\9\11\230\124\137","\211\69\177\58\58");v39.SkyboxLf=v7("\165\231\97\244\250\216\178\241\112\241\179\132\248\183\45\173\189\152\230\179\33\163","\171\215\133\25\149\137");FlatIdent_DFF4=1;end if (FlatIdent_DFF4==1) then FlatIdent_45D37=1;break;end end end end break;end end end if (v77==(0 -0)) then local FlatIdent_1B881=0;local FlatIdent_90A41;while true do if (FlatIdent_1B881==0) then FlatIdent_90A41=0;while true do if (FlatIdent_90A41==1) then v77=1 + 0 ;break;end if (FlatIdent_90A41==0) then v39.SkyboxBk=v7("\158\255\84\51\1\95\127\152\244\72\104\93\3\40\216\165\24\97\67\26\43\218","\26\236\157\44\82\114\44");v39.SkyboxDn=v7("\56\44\205\90\57\61\208\79\35\42\143\20\101\124\129\3\126\125\132\13\125\121","\59\74\78\181");FlatIdent_90A41=1;end end break;end end end if (v77==3) then v39.StarCount=2680 + 320 ;break;end if (v77==(1192 -(50 + 1140))) then local FlatIdent_21449=0;local FlatIdent_6225E;while true do if (FlatIdent_21449==0) then FlatIdent_6225E=0;while true do if (FlatIdent_6225E==1) then v77=1010 -(564 + 443) ;break;end if (FlatIdent_6225E==0) then v39.SkyboxRt=v7("\243\202\42\251\252\35\249\86\232\204\104\181\160\98\168\26\181\155\99\172\190\97","\34\129\168\82\154\143\80\156");v39.SkyboxUp=v7("\151\176\43\10\91\93\140\145\187\55\81\7\1\219\209\234\103\88\25\24\217\208","\233\229\210\83\107\40\46");FlatIdent_6225E=1;end end break;end end end end break;end end end,[v7("\236\67\53\211\11\213\67\29\196\4\207\69\55","\101\161\34\82\182")]=function() local FlatIdent_580CB=0;while true do if (FlatIdent_580CB==3) then v39.StarCount=8305 -5305 ;break;end if (FlatIdent_580CB==1) then v39.SkyboxFt=v7("\239\207\12\212\93\164\248\217\29\209\20\248\178\152\66\131\24\230\171\156\64\132","\215\157\173\116\181\46");v39.SkyboxLf=v7("\39\182\147\243\201\38\177\159\251\222\111\251\196\167\140\99\226\218\164\138\97\224","\186\85\212\235\146");FlatIdent_580CB=2;end if (FlatIdent_580CB==2) then v39.SkyboxRt=v7("\208\131\14\255\42\253\93\214\136\18\164\118\161\13\148\215\64\175\111\190\0\144","\56\162\225\118\158\89\142");v39.SkyboxUp=v7("\78\7\216\174\49\203\89\17\201\171\120\151\19\80\150\249\116\137\10\84\152\248","\184\60\101\160\207\66");FlatIdent_580CB=3;end if (FlatIdent_580CB==0) then v39.SkyboxBk=v7("\250\15\65\255\200\241\135\58\225\9\3\177\148\183\212\120\190\92\15\175\138\177","\78\136\109\57\158\187\130\226");v39.SkyboxDn=v7("\44\61\225\240\45\44\252\229\55\59\163\190\113\106\175\167\104\110\175\163\109\109","\145\94\95\153");FlatIdent_580CB=1;end end end,[v7("\1\151\110\172\61\135\46","\220\81\226\28")]=function() local FlatIdent_21449=0;while true do if (FlatIdent_21449==2) then v39.SkyboxRt=v7("\171\33\179\117\172\172\64\160\176\39\241\59\240\231\20\228\238\123\255\37\233\232\20","\212\217\67\203\20\223\223\37");v39.SkyboxUp=v7("\168\143\176\211\169\158\173\198\179\137\242\157\245\213\249\130\237\213\252\139\237\212\249","\178\218\237\200");FlatIdent_21449=3;end if (FlatIdent_21449==0) then local FlatIdent_77172=0;while true do if (FlatIdent_77172==1) then FlatIdent_21449=1;break;end if (FlatIdent_77172==0) then v39.SkyboxBk=v7("\1\215\154\250\249\212\22\193\139\255\176\136\92\141\211\171\189\159\71\132\212\172\187","\167\115\181\226\155\138");v39.SkyboxDn=v7("\240\32\255\93\104\98\195\246\43\227\6\52\62\144\182\118\179\4\35\37\145\186\119","\166\130\66\135\60\27\17");FlatIdent_77172=1;end end end if (FlatIdent_21449==3) then local FlatIdent_7E707=0;while true do if (FlatIdent_7E707==1) then FlatIdent_21449=4;break;end if (FlatIdent_7E707==0) then v39.SunTextureId=v7("\164\183\254\209\165\166\227\196\191\177\188\159\249\227\183\137\224\227\176\133\231\229\176","\176\214\213\134");v39.MoonTextureId=v7("\230\175\174\213\187\69\92\224\164\178\142\231\25\15\160\249\226\135\250\6\12\173\255","\57\148\205\214\180\200\54");FlatIdent_7E707=1;end end end if (FlatIdent_21449==4) then v39.MoonAngularSize=0;break;end if (FlatIdent_21449==1) then local FlatIdent_68856=0;while true do if (FlatIdent_68856==0) then v39.SkyboxFt=v7("\86\72\214\116\35\87\79\218\124\52\30\5\129\45\97\20\29\150\33\97\18\29\159","\80\36\42\174\21");v39.SkyboxLf=v7("\92\18\47\123\93\3\50\110\71\20\109\53\1\72\102\42\25\72\99\43\24\71\102","\26\46\112\87");FlatIdent_68856=1;end if (FlatIdent_68856==1) then FlatIdent_21449=2;break;end end end end end,[v7("\53\252\57\53\110\11\175","\22\114\157\85\84")]=function() local FlatIdent_63AE4=0;local FlatIdent_8ABD6;while true do if (FlatIdent_63AE4==0) then FlatIdent_8ABD6=0;while true do if (FlatIdent_8ABD6==4) then v39.SunAngularSize=458 -(337 + 121) ;v39.MoonAngularSize=0 -0 ;break;end if (FlatIdent_8ABD6==2) then local FlatIdent_331F0=0;while true do if (FlatIdent_331F0==0) then v39.SkyboxRt=v7("\211\16\21\244\17\99\188\213\27\9\175\77\63\232\149\67\91\161\86\32\235\150\74\95","\217\161\114\109\149\98\16");v39.SkyboxUp=v7("\0\34\32\125\175\103\23\52\49\120\230\59\93\113\108\45\234\32\70\112\109\46\229\44","\20\114\64\88\28\220");FlatIdent_331F0=1;end if (FlatIdent_331F0==1) then FlatIdent_8ABD6=3;break;end end end if (FlatIdent_8ABD6==0) then v39.SkyboxBk=v7("\214\201\11\197\78\229\173\208\194\23\158\18\185\249\144\154\69\144\14\160\240\146\156\75","\200\164\171\115\164\61\150");v39.SkyboxDn=v7("\172\246\27\68\144\173\241\23\76\135\228\187\76\20\215\239\162\87\22\219\232\165\81\19","\227\222\148\99\37");FlatIdent_8ABD6=1;end if (3==FlatIdent_8ABD6) then local FlatIdent_6D68E=0;while true do if (FlatIdent_6D68E==0) then v39.SunTextureId=v7("\35\3\202\181\235\195\184\37\8\214\238\183\159\229\99\89\131\237\174\129\229\104\87","\221\81\97\178\212\152\176");v39.MoonTextureId=v7("\223\229\5\250\9\222\226\9\242\30\151\168\82\173\78\153\179\78\169\74\152\190\79","\122\173\135\125\155");FlatIdent_6D68E=1;end if (FlatIdent_6D68E==1) then FlatIdent_8ABD6=4;break;end end end if (FlatIdent_8ABD6==1) then local FlatIdent_854BA=0;while true do if (FlatIdent_854BA==0) then v39.SkyboxFt=v7("\33\80\74\247\234\32\87\70\255\253\105\29\29\167\173\98\4\6\165\161\106\0\1\166","\153\83\50\50\150");v39.SkyboxLf=v7("\79\116\107\29\96\184\72\73\127\119\70\60\228\28\9\39\37\72\32\242\21\9\47\32","\45\61\22\19\124\19\203");FlatIdent_854BA=1;end if (FlatIdent_854BA==1) then FlatIdent_8ABD6=2;break;end end end end break;end end end,[v7("\180\200\14\178","\168\228\161\96\217\95\81")]=function() local FlatIdent_68856=0;while true do if (FlatIdent_68856==2) then v39.SkyboxRt=v7("\9\239\158\80\254\46\60\15\228\130\11\162\114\107\76\188\214\5\191\105\111\76","\89\123\141\230\49\141\93");v39.SkyboxUp=v7("\225\115\238\13\3\89\246\101\255\8\74\5\188\35\161\93\64\29\164\40\163\84","\42\147\17\150\108\112");break;end if (FlatIdent_68856==0) then local FlatIdent_7063=0;while true do if (FlatIdent_7063==0) then v39.SkyboxBk=v7("\201\211\54\93\60\68\222\197\39\88\117\24\148\131\121\13\127\3\137\132\127\10","\55\187\177\78\60\79");v39.SkyboxDn=v7("\63\204\71\234\85\220\133\57\199\91\177\9\128\210\122\159\15\188\17\157\212\126","\224\77\174\63\139\38\175");FlatIdent_7063=1;end if (FlatIdent_7063==1) then FlatIdent_68856=1;break;end end end if (FlatIdent_68856==1) then local FlatIdent_3B08E=0;while true do if (FlatIdent_3B08E==0) then v39.SkyboxFt=v7("\150\67\64\47\151\82\93\58\141\69\2\97\203\19\15\127\212\21\10\123\209\23","\78\228\33\56");v39.SkyboxLf=v7("\220\124\170\2\150\221\123\166\10\129\148\49\253\81\210\159\46\230\81\214\159\46","\229\174\30\210\99");FlatIdent_3B08E=1;end if (FlatIdent_3B08E==1) then FlatIdent_68856=2;break;end end end end end,[v7("\63\179\63\111\235\237\92","\136\111\198\77\31\135")]=function() local FlatIdent_2DA99=0;while true do if (FlatIdent_2DA99==1) then v39.SkyboxFt=v7("\76\193\237\228\63\211\91\215\252\225\118\143\17\151\166\182\126\151\10\146\166\180","\160\62\163\149\133\76");v39.SkyboxLf=v7("\196\162\21\46\208\197\165\25\38\199\140\239\66\123\144\133\242\90\123\144\129\240","\163\182\192\109\79");FlatIdent_2DA99=2;end if (FlatIdent_2DA99==0) then v39.SkyboxBk=v7("\16\11\191\87\174\247\18\189\11\13\253\25\242\176\68\250\80\94\243\6\229\177","\201\98\105\199\54\221\132\119");v39.SkyboxDn=v7("\171\14\155\32\17\38\169\173\5\135\123\77\122\248\234\95\209\118\86\100\245\237","\204\217\108\227\65\98\85");FlatIdent_2DA99=1;end if (FlatIdent_2DA99==2) then v39.SkyboxRt=v7("\38\36\24\193\230\39\35\20\201\241\110\105\79\148\166\103\116\87\148\161\102\127","\149\84\70\96\160");v39.SkyboxUp=v7("\42\4\21\236\43\21\8\249\49\2\87\162\119\82\94\190\106\81\89\191\96\83","\141\88\102\109");break;end end end,[v7("\151\82\216\123\19\46\93\241\186\93\193","\161\211\51\170\16\122\93\53")]=function() local FlatIdent_3CDED=0;local FlatIdent_44603;local v116;local v117;while true do if (0==FlatIdent_3CDED) then FlatIdent_44603=0;v116=nil;FlatIdent_3CDED=1;end if (FlatIdent_3CDED==1) then v117=nil;while true do if (FlatIdent_44603==0) then local FlatIdent_3B868=0;while true do if (FlatIdent_3B868==0) then v116=0 -0 ;v117=nil;FlatIdent_3B868=1;end if (1==FlatIdent_3B868) then FlatIdent_44603=1;break;end end end if (FlatIdent_44603==1) then while true do if (v116==(1911 -(1261 + 650))) then v117=0 + 0 ;while true do if (v117==(2 -0)) then v39.SkyboxRt=v7("\196\131\231\72\204\197\132\235\64\219\140\206\176\28\136\134\212\170\28\135\142\211","\191\182\225\159\41");v39.SkyboxUp=v7("\57\16\48\84\152\148\199\63\27\44\15\196\200\151\124\66\125\0\222\222\144\114","\162\75\114\72\53\235\231");break;end if (v117==(1818 -(772 + 1045))) then local FlatIdent_F26C=0;while true do if (FlatIdent_F26C==1) then v117=1 + 1 ;break;end if (FlatIdent_F26C==0) then v39.SkyboxFt=v7("\74\21\63\71\75\4\34\82\81\19\125\9\23\66\112\22\13\66\114\30\8\71","\38\56\119\71");v39.SkyboxLf=v7("\225\237\64\215\54\69\246\251\81\210\127\25\188\186\15\134\112\3\166\183\12\134","\54\147\143\56\182\69");FlatIdent_F26C=1;end end end if (v117==(144 -(102 + 42))) then local FlatIdent_31077=0;while true do if (1==FlatIdent_31077) then v117=1;break;end if (FlatIdent_31077==0) then v39.SkyboxBk=v7("\233\172\170\41\232\189\183\60\242\170\232\103\180\251\229\120\174\251\231\127\168\248","\72\155\206\210");v39.SkyboxDn=v7("\84\120\76\15\32\85\127\64\7\55\28\53\27\91\100\22\47\1\91\106\16\46","\83\38\26\52\110");FlatIdent_31077=1;end end end end break;end end break;end end break;end end end,[v7("\191\44\69\225\86","\98\236\92\36\130\51")]=function() local FlatIdent_3F7F4=0;while true do if (FlatIdent_3F7F4==3) then v39.SkyboxRt=v7("\34\28\152\25\82\35\27\148\17\69\106\81\207\73\23\102\75\209\72\16\99\79","\33\80\126\224\120");v39.SkyboxUp=v7("\254\170\27\197\79\255\173\23\205\88\182\231\76\149\10\186\253\82\148\13\189\252","\60\140\200\99\164");break;end if (FlatIdent_3F7F4==1) then local FlatIdent_145D2=0;while true do if (FlatIdent_145D2==0) then v39.SkyboxBk=v7("\182\27\20\187\86\187\176\36\173\29\86\245\10\249\227\102\241\73\85\227\28\241","\80\196\121\108\218\37\200\213");v39.SkyboxDn=v7("\18\113\26\126\88\29\143\20\122\6\37\4\65\219\86\37\87\46\27\94\223\87","\234\96\19\98\31\43\110");FlatIdent_145D2=1;end if (FlatIdent_145D2==1) then FlatIdent_3F7F4=2;break;end end end if (2==FlatIdent_3F7F4) then local FlatIdent_8EA6E=0;while true do if (FlatIdent_8EA6E==0) then v39.SkyboxFt=v7("\20\29\74\198\191\97\142\18\22\86\157\227\61\218\80\73\7\150\252\35\218\80","\235\102\127\50\167\204\18");v39.SkyboxLf=v7("\66\163\237\34\87\61\85\181\252\39\30\97\31\240\163\117\17\127\0\241\172\113","\78\48\193\149\67\36");FlatIdent_8EA6E=1;end if (FlatIdent_8EA6E==1) then FlatIdent_3F7F4=3;break;end end end if (0==FlatIdent_3F7F4) then local FlatIdent_1BA2F=0;while true do if (FlatIdent_1BA2F==0) then v39.MoonAngularSize=1844 -(1524 + 320) ;v39.SunAngularSize=1270 -(1049 + 221) ;FlatIdent_1BA2F=1;end if (1==FlatIdent_1BA2F) then FlatIdent_3F7F4=1;break;end end end end end,[v7("\160\245\8\39\186\158\167","\194\231\148\100\70")]=function() local FlatIdent_1D164=0;local FlatIdent_3B08E;local v126;while true do if (0==FlatIdent_1D164) then FlatIdent_3B08E=0;v126=nil;FlatIdent_1D164=1;end if (FlatIdent_1D164==1) then while true do if (FlatIdent_3B08E==0) then v126=156 -(18 + 138) ;while true do if (v126==(1171 -(1026 + 145))) then local FlatIdent_699E4=0;local FlatIdent_71EE8;while true do if (FlatIdent_699E4==0) then FlatIdent_71EE8=0;while true do if (1==FlatIdent_71EE8) then v126=1103 -(67 + 1035) ;break;end if (FlatIdent_71EE8==0) then local FlatIdent_40096=0;while true do if (FlatIdent_40096==1) then FlatIdent_71EE8=1;break;end if (FlatIdent_40096==0) then v39.MoonAngularSize=0 -0 ;v39.SunAngularSize=0;FlatIdent_40096=1;end end end end break;end end end if ((351 -(136 + 212))==v126) then v39.SkyboxRt=v7("\200\233\111\233\152\212\223\255\126\236\209\136\149\186\35\189\223\148\136\179\39\176\210\151","\167\186\139\23\136\235");v39.SkyboxUp=v7("\8\183\144\12\9\166\141\25\19\177\210\66\85\228\220\88\78\230\219\90\75\227\223\91","\109\122\213\232");break;end if ((8 -6)==v126) then local FlatIdent_94CF9=0;local FlatIdent_985A2;while true do if (FlatIdent_94CF9==0) then FlatIdent_985A2=0;while true do if (FlatIdent_985A2==1) then v126=3 + 0 ;break;end if (FlatIdent_985A2==0) then local FlatIdent_5CA49=0;while true do if (1==FlatIdent_5CA49) then FlatIdent_985A2=1;break;end if (FlatIdent_5CA49==0) then v39.SkyboxFt=v7("\80\236\65\129\81\253\92\148\75\234\3\207\13\191\13\213\22\189\11\213\21\182\8\208","\224\34\142\57");v39.SkyboxLf=v7("\204\165\221\220\96\226\88\26\215\163\159\146\60\160\9\91\138\244\151\138\38\169\4\91","\110\190\199\165\189\19\145\61");FlatIdent_5CA49=1;end end end end break;end end end if (v126==(1 + 0)) then v39.SkyboxBk=v7("\84\78\217\162\229\219\67\88\200\167\172\135\9\29\149\246\162\155\20\26\149\242\165\157","\168\38\44\161\195\150");v39.SkyboxDn=v7("\146\254\154\119\35\251\179\2\137\248\216\57\127\185\226\67\212\175\209\35\104\177\227\78","\118\224\156\226\22\80\136\214");v126=1606 -(240 + 1364) ;end end break;end end break;end end end,[v7("\192\242\182\56\235\229\149\63\252\251\166","\80\142\151\194")]=function() local FlatIdent_90E07=0;local FlatIdent_6EEC8;local v127;while true do if (FlatIdent_90E07==1) then while true do if (0==FlatIdent_6EEC8) then v127=1082 -(1050 + 32) ;while true do if ((10 -7)==v127) then v39.SkyboxRt=v7("\144\76\71\94\163\218\91\150\71\91\5\255\134\15\214\29\9\10\224\152\6\211\26\12","\62\226\46\63\63\208\169");v39.SkyboxUp=v7("\247\27\77\130\12\30\42\74\236\29\15\204\80\92\123\13\179\76\5\210\70\94\125\9","\62\133\121\53\227\127\109\79");break;end if ((0 -0)==v127) then local FlatIdent_8A9D7=0;local FlatIdent_55D83;while true do if (FlatIdent_8A9D7==0) then FlatIdent_55D83=0;while true do if (FlatIdent_55D83==1) then v127=1 + 0 ;break;end if (FlatIdent_55D83==0) then local FlatIdent_75331=0;while true do if (FlatIdent_75331==0) then v39.MoonAngularSize=0 + 0 ;v39.SunAngularSize=0 -0 ;FlatIdent_75331=1;end if (FlatIdent_75331==1) then FlatIdent_55D83=1;break;end end end end break;end end end if (v127==(1056 -(331 + 724))) then local FlatIdent_21E03=0;local FlatIdent_30F75;while true do if (FlatIdent_21E03==0) then FlatIdent_30F75=0;while true do if (0==FlatIdent_30F75) then v39.SkyboxBk=v7("\17\196\111\77\16\213\114\88\10\194\45\3\76\151\35\31\85\147\39\29\90\150\39\30","\44\99\166\23");v39.SkyboxDn=v7("\110\245\49\55\32\183\121\227\32\50\105\235\51\166\125\101\101\241\44\165\122\101\102\244","\196\28\151\73\86\83");FlatIdent_30F75=1;end if (1==FlatIdent_30F75) then v127=1 + 1 ;break;end end break;end end end if (v127==(646 -(269 + 375))) then local FlatIdent_3501F=0;while true do if (0==FlatIdent_3501F) then v39.SkyboxFt=v7("\225\1\49\17\145\75\29\98\250\7\115\95\205\9\76\37\165\86\121\65\218\11\65\47","\22\147\99\73\112\226\56\120");v39.SkyboxLf=v7("\170\119\250\244\158\171\112\246\252\137\226\58\173\164\217\235\35\183\165\220\224\34\178\160","\237\216\21\130\149");FlatIdent_3501F=1;end if (FlatIdent_3501F==1) then v127=728 -(267 + 458) ;break;end end end end break;end end break;end if (FlatIdent_90E07==0) then FlatIdent_6EEC8=0;v127=nil;FlatIdent_90E07=1;end end end,[v7("\62\17\48\224\218\175","\194\112\116\82\149\182\206")]=function() local FlatIdent_270C=0;local v128;while true do if (FlatIdent_270C==0) then v128=0 + 0 ;while true do if (v128==(0 + 0)) then local FlatIdent_58E6A=0;local FlatIdent_527C6;while true do if (FlatIdent_58E6A==0) then FlatIdent_527C6=0;while true do if (FlatIdent_527C6==0) then local FlatIdent_4D11E=0;while true do if (FlatIdent_4D11E==0) then v39.MoonAngularSize=0 -0 ;v39.SunAngularSize=0 -0 ;FlatIdent_4D11E=1;end if (FlatIdent_4D11E==1) then FlatIdent_527C6=1;break;end end end if (1==FlatIdent_527C6) then v128=819 -(667 + 151) ;break;end end break;end end end if (v128==(1498 -(1410 + 87))) then v39.SkyboxBk=v7("\43\170\84\25\211\241\11\45\161\72\66\143\173\91\107\254\28\64\144\186\95\110\255","\110\89\200\44\120\160\130");v39.SkyboxDn=v7("\185\193\83\71\80\89\62\89\162\199\17\9\12\31\105\27\251\149\30\21\20\19\104","\45\203\163\43\38\35\42\91");v128=1899 -(1504 + 393) ;end if (v128==(5 -3)) then local FlatIdent_6B9E2=0;local FlatIdent_65194;while true do if (FlatIdent_6B9E2==0) then FlatIdent_65194=0;while true do if (1==FlatIdent_65194) then v128=7 -4 ;break;end if (FlatIdent_65194==0) then v39.SkyboxFt=v7("\192\135\196\34\148\186\81\198\140\216\121\200\230\1\128\211\140\123\214\254\6\138\221","\52\178\229\188\67\231\201");v39.SkyboxLf=v7("\51\67\72\5\228\79\38\53\72\84\94\184\19\118\115\23\0\92\167\12\123\114\18","\67\65\33\48\100\151\60");FlatIdent_65194=1;end end break;end end end if (v128==(799 -(461 + 335))) then v39.SkyboxRt=v7("\205\229\182\217\224\204\226\186\209\247\133\168\225\141\161\137\183\246\137\162\143\176\253","\147\191\135\206\184");v39.SkyboxUp=v7("\150\42\190\192\203\64\183\144\33\162\155\151\28\231\214\126\246\153\138\7\228\210\121","\210\228\72\198\161\184\51");break;end end break;end end end,[v7("\6\92\225\0\127\203\24\64\244\24\103","\174\86\41\147\112\19")]=function() local FlatIdent_1CFC3=0;local FlatIdent_163A8;local v129;while true do if (FlatIdent_1CFC3==0) then FlatIdent_163A8=0;v129=nil;FlatIdent_1CFC3=1;end if (FlatIdent_1CFC3==1) then while true do if (FlatIdent_163A8==0) then v129=0;while true do if (v129==1) then local FlatIdent_1D164=0;while true do if (0==FlatIdent_1D164) then local FlatIdent_8CB90=0;while true do if (FlatIdent_8CB90==0) then v39.SkyboxBk=v7("\73\2\149\10\54\28\20\191\82\4\215\68\106\90\67\253\11\88\221\83\116\88\70","\203\59\96\237\107\69\111\113");v39.SkyboxDn=v7("\54\20\180\224\34\227\210\48\31\168\187\126\191\130\118\64\252\183\100\163\128\125\69","\183\68\118\204\129\81\144");FlatIdent_8CB90=1;end if (FlatIdent_8CB90==1) then FlatIdent_1D164=1;break;end end end if (FlatIdent_1D164==1) then v129=1 + 1 ;break;end end end if (v129==(1763 -(1730 + 31))) then v39.SkyboxFt=v7("\28\175\104\229\24\145\11\185\121\224\81\205\65\248\34\178\91\218\95\250\34\188\83","\226\110\205\16\132\107");v39.SkyboxLf=v7("\249\193\248\216\82\248\198\244\208\69\177\140\175\140\19\189\147\184\137\17\179\144\179","\33\139\163\128\185");v129=1504 -(277 + 1224) ;end if (v129==(1670 -(728 + 939))) then v39.SkyboxRt=v7("\69\90\28\223\68\75\1\202\94\92\94\145\24\13\86\136\7\0\84\142\15\11\87","\190\55\56\100");v39.SkyboxUp=v7("\68\173\36\31\0\240\246\66\166\56\68\92\172\166\6\247\104\75\68\181\167\6\255","\147\54\207\92\126\115\131");break;end if (v129==(0 -0)) then local FlatIdent_699E4=0;while true do if (FlatIdent_699E4==0) then v39.MoonAngularSize=0 -0 ;v39.SunAngularSize=0 -0 ;FlatIdent_699E4=1;end if (FlatIdent_699E4==1) then v129=1;break;end end end end break;end end break;end end end,[v7("\44\52\38\105\5\123\25\56\54","\30\109\81\85\29\109")]=function() local FlatIdent_1D701=0;local v130;while true do if (FlatIdent_1D701==0) then v130=0 + 0 ;while true do if (v130==(1071 -(138 + 930))) then v39.SkyboxRt=v7("\207\36\238\66\166\206\35\226\74\177\135\105\185\18\225\140\113\162\26\225\137\127\175","\213\189\70\150\35");v39.SkyboxUp=v7("\93\87\108\9\92\70\113\28\70\81\46\71\0\4\32\89\24\1\45\92\25\1\39","\104\47\53\20");break;end if (v130==(1 + 0)) then local FlatIdent_94CF9=0;while true do if (FlatIdent_94CF9==1) then v130=2 + 0 ;break;end if (FlatIdent_94CF9==0) then v39.SkyboxBk=v7("\237\115\76\183\37\205\249\235\120\80\236\121\145\173\171\32\3\226\111\138\172\172\33","\156\159\17\52\214\86\190");v39.SkyboxDn=v7("\188\237\165\189\189\252\184\168\167\235\231\243\225\190\233\237\249\187\228\232\255\187\235","\220\206\143\221");FlatIdent_94CF9=1;end end end if (v130==(2 + 0)) then local FlatIdent_974E=0;local FlatIdent_8B7B0;while true do if (FlatIdent_974E==0) then FlatIdent_8B7B0=0;while true do if (FlatIdent_8B7B0==0) then local FlatIdent_4D907=0;while true do if (FlatIdent_4D907==1) then FlatIdent_8B7B0=1;break;end if (FlatIdent_4D907==0) then v39.SkyboxFt=v7("\148\127\53\22\203\223\215\146\116\41\77\151\131\131\210\44\122\67\129\152\128\211\46","\178\230\29\77\119\184\172");v39.SkyboxLf=v7("\231\188\18\26\100\235\240\170\3\31\45\183\186\239\94\74\32\172\172\234\94\75\37","\152\149\222\106\123\23");FlatIdent_4D907=1;end end end if (FlatIdent_8B7B0==1) then v130=12 -9 ;break;end end break;end end end if (v130==(1766 -(459 + 1307))) then v39.MoonAngularSize=1870 -(474 + 1396) ;v39.SunAngularSize=0 -0 ;v130=1 + 0 ;end end break;end end end,[v7("\130\73\146\8\180\10\183\69\130\78","\111\195\44\225\124\220")]=function() local FlatIdent_14716=0;local v131;local v132;while true do if (1==FlatIdent_14716) then while true do if (v131==(0 -0)) then v132=0 + 0 ;while true do if (v132==(6 -4)) then local FlatIdent_4AB8B=0;while true do if (FlatIdent_4AB8B==1) then v132=12 -9 ;break;end if (FlatIdent_4AB8B==0) then v39.SkyboxFt=v7("\61\16\74\79\228\148\14\59\27\86\20\184\200\93\127\66\10\29\165\208\89\127","\107\79\114\50\46\151\231");v39.SkyboxLf=v7("\43\164\173\40\153\42\178\212\48\162\239\102\197\111\231\144\97\254\227\121\211\105","\160\89\198\213\73\234\89\215");FlatIdent_4AB8B=1;end end end if ((592 -(562 + 29))==v132) then local FlatIdent_3831=0;while true do if (FlatIdent_3831==0) then local FlatIdent_7DCBC=0;while true do if (FlatIdent_7DCBC==0) then v39.SkyboxBk=v7("\202\68\24\114\184\184\221\82\9\119\241\228\151\16\80\35\243\248\136\18\84\37","\203\184\38\96\19\203");v39.SkyboxDn=v7("\43\113\97\64\221\42\118\109\72\202\99\60\54\23\158\105\43\42\16\152\106\38","\174\89\19\25\33");FlatIdent_7DCBC=1;end if (FlatIdent_7DCBC==1) then FlatIdent_3831=1;break;end end end if (FlatIdent_3831==1) then v132=2 + 0 ;break;end end end if ((1419 -(374 + 1045))==v132) then local FlatIdent_5C0FA=0;local FlatIdent_84478;while true do if (FlatIdent_5C0FA==0) then FlatIdent_84478=0;while true do if (FlatIdent_84478==0) then v39.MoonAngularSize=0 + 0 ;v39.SunAngularSize=0 -0 ;FlatIdent_84478=1;end if (FlatIdent_84478==1) then v132=639 -(448 + 190) ;break;end end break;end end end if (v132==(1 + 2)) then v39.SkyboxRt=v7("\90\115\172\255\214\91\116\160\247\193\18\62\251\168\149\24\41\231\173\157\30\35","\165\40\17\212\158");v39.SkyboxUp=v7("\247\219\16\50\53\246\220\28\58\34\191\150\71\101\118\181\129\91\102\119\178\142","\70\133\185\104\83");break;end end break;end end break;end if (0==FlatIdent_14716) then local FlatIdent_87C42=0;while true do if (FlatIdent_87C42==1) then FlatIdent_14716=1;break;end if (0==FlatIdent_87C42) then v131=0 + 0 ;v132=nil;FlatIdent_87C42=1;end end end end end,[v7("\52\68\87\62\204\8","\169\100\37\36\74")]=function() local FlatIdent_8239F=0;local v133;while true do if (0==FlatIdent_8239F) then v133=0 + 0 ;while true do if (v133==(1 + 0)) then local FlatIdent_94BA0=0;local FlatIdent_15034;while true do if (0==FlatIdent_94BA0) then FlatIdent_15034=0;while true do if (FlatIdent_15034==1) then v133=7 -5 ;break;end if (FlatIdent_15034==0) then v39.SkyboxBk=v7("\18\133\186\81\19\148\167\68\9\131\248\31\79\213\243\2\88\211\247\8\86\210\241","\48\96\231\194");v39.SkyboxDn=v7("\218\88\22\44\10\203\170\151\193\94\84\98\86\138\254\209\144\14\88\127\77\128\255","\227\168\58\110\77\121\184\207");FlatIdent_15034=1;end end break;end end end if (v133==(8 -5)) then v39.SkyboxRt=v7("\144\211\185\140\170\151\135\197\168\137\227\203\205\131\240\223\225\208\212\131\241\223\238","\228\226\177\193\237\217");v39.SkyboxUp=v7("\38\178\59\231\39\163\38\242\61\180\121\169\123\226\114\180\108\228\117\180\102\227\117","\134\84\208\67");break;end if (v133==2) then local FlatIdent_280F1=0;local FlatIdent_61084;while true do if (FlatIdent_280F1==0) then FlatIdent_61084=0;while true do if (FlatIdent_61084==1) then v133=1497 -(1307 + 187) ;break;end if (FlatIdent_61084==0) then local FlatIdent_15C08=0;while true do if (FlatIdent_15C08==0) then v39.SkyboxFt=v7("\105\62\167\65\162\200\116\177\114\56\229\15\254\137\32\247\35\104\234\24\231\142\34","\197\27\92\223\32\209\187\17");v39.SkyboxLf=v7("\17\93\219\250\16\76\198\239\10\91\153\180\76\13\146\169\91\11\149\169\83\13\148","\155\99\63\163");FlatIdent_15C08=1;end if (1==FlatIdent_15C08) then FlatIdent_61084=1;break;end end end end break;end end end if (0==v133) then local FlatIdent_89C1C=0;while true do if (FlatIdent_89C1C==1) then v133=3 -2 ;break;end if (FlatIdent_89C1C==0) then v39.SunAngularSize=0;v39.MoonAngularSize=0 + 0 ;FlatIdent_89C1C=1;end end end end break;end end end,[v7("\35\185\148\76\31\169\165\80\28\185\130\79","\60\115\204\230")]=function() local FlatIdent_59C45=0;local FlatIdent_679D2;while true do if (FlatIdent_59C45==0) then FlatIdent_679D2=0;while true do if (FlatIdent_679D2==2) then v39.SkyboxRt=v7("\217\118\221\54\65\48\28\223\125\193\109\29\108\76\156\36\144\98\5\117\78\153","\121\171\20\165\87\50\67");v39.SkyboxUp=v7("\212\58\161\55\170\17\195\44\176\50\227\77\137\109\238\102\236\87\145\111\235\97","\98\166\88\217\86\217");break;end if (FlatIdent_679D2==1) then local FlatIdent_31791=0;while true do if (FlatIdent_31791==0) then v39.SkyboxFt=v7("\214\45\57\37\28\215\42\53\45\11\158\96\110\113\88\148\122\116\115\90\145\118","\111\164\79\65\68");v39.SkyboxLf=v7("\212\219\155\223\61\249\195\205\138\218\116\165\137\140\212\142\123\191\145\143\209\142","\138\166\185\227\190\78");FlatIdent_31791=1;end if (1==FlatIdent_31791) then FlatIdent_679D2=2;break;end end end if (FlatIdent_679D2==0) then local FlatIdent_58A9D=0;while true do if (0==FlatIdent_58A9D) then v39.SkyboxBk=v7("\245\56\243\113\244\41\238\100\238\62\177\63\168\111\188\32\178\111\188\37\182\110","\16\135\90\139");v39.SkyboxDn=v7("\70\118\30\50\93\71\125\64\125\2\105\1\27\45\3\36\83\102\25\3\47\1","\24\52\20\102\83\46\52");FlatIdent_58A9D=1;end if (1==FlatIdent_58A9D) then FlatIdent_679D2=1;break;end end end end break;end end end,[v7("\212\243\109\21\131\206\197\253\96","\188\150\150\25\97\230")]=function() if v39 then local v222=0 -0 ;local v223;while true do if (v222==(1549 -(647 + 902))) then v223=0 -0 ;while true do if (v223==(2 -1)) then local FlatIdent_9851B=0;while true do if (FlatIdent_9851B==0) then local FlatIdent_37E3=0;while true do if (FlatIdent_37E3==0) then v39.SkyboxFt=v7("\98\205\145\136\172\5\117\219\128\141\229\89\63\154\208\216\239\67\40\158\217\221","\118\16\175\233\233\223");v39.SkyboxLf=v7("\153\134\45\186\253\152\120\159\141\49\225\161\196\40\210\213\101\238\185\211\43\218","\29\235\228\85\219\142\235");FlatIdent_37E3=1;end if (FlatIdent_37E3==1) then FlatIdent_9851B=1;break;end end end if (FlatIdent_9851B==1) then v223=685 -(232 + 451) ;break;end end end if ((1291 -(426 + 863))==v223) then v39.SkyboxRt=v7("\47\214\162\220\100\93\34\70\52\208\224\146\56\27\126\3\109\129\237\139\37\27","\50\93\180\218\189\23\46\71");v39.SkyboxUp=v7("\204\166\67\77\87\207\77\202\173\95\22\11\147\29\135\245\11\25\29\138\28\140","\40\190\196\59\44\36\188");break;end if (v223==(0 + 0)) then v39.SkyboxBk=v7("\200\139\71\3\31\254\223\157\86\6\86\162\149\220\6\83\92\184\130\209\13\81","\141\186\233\63\98\108");v39.SkyboxDn=v7("\227\232\52\183\54\226\239\56\191\33\171\165\99\227\124\160\186\121\239\125\166\188","\69\145\138\76\214");v223=1;end end break;end end end end,[v7("\30\64\200\160\255\111\35\53\66\212\160\169","\109\92\37\188\212\154\29")]=function() local FlatIdent_23521=0;while true do if (FlatIdent_23521==3) then local FlatIdent_994C=0;while true do if (FlatIdent_994C==1) then FlatIdent_23521=4;break;end if (FlatIdent_994C==0) then v39.SkyboxUp=v7("\63\54\189\221\101\188\210\146\36\48\255\147\57\253\129\209\125\98\241\136\37\252\134","\230\77\84\197\188\22\207\183");v39.MoonAngularSize=1.5 + 0 ;FlatIdent_994C=1;end end end if (FlatIdent_23521==0) then local FlatIdent_2EAC6=0;while true do if (FlatIdent_2EAC6==0) then v39.MoonTextureId=v7("\22\237\188\194\34\73\1\251\173\199\107\21\75\190\244\148\100\10\92\184\243\149\97","\58\100\143\196\163\81");v39.SkyboxBk=v7("\8\64\59\162\44\90\224\26\19\70\121\236\112\27\179\89\74\20\119\240\102\16\177","\110\122\34\67\195\95\41\133");FlatIdent_2EAC6=1;end if (FlatIdent_2EAC6==1) then FlatIdent_23521=1;break;end end end if (1==FlatIdent_23521) then v39.SkyboxDn=v7("\103\179\67\75\197\102\180\79\67\210\47\254\20\24\128\34\225\13\30\133\38\231\14","\182\21\209\59\42");v39.SkyboxFt=v7("\165\85\221\28\50\173\178\67\204\25\123\241\248\5\147\74\113\232\227\4\151\76\117","\222\215\55\165\125\65");FlatIdent_23521=2;end if (FlatIdent_23521==4) then v39.StarCount=1064 -(510 + 54) ;break;end if (FlatIdent_23521==2) then v39.SkyboxLf=v7("\62\211\222\27\225\210\232\94\37\213\156\85\189\147\187\29\124\135\146\73\162\150\189","\42\76\177\166\122\146\161\141");v39.SkyboxRt=v7("\183\136\29\207\106\101\160\158\12\202\35\57\234\216\83\153\41\32\241\222\84\153\42","\22\197\234\101\174\25");FlatIdent_23521=3;end end end,[v7("\214\6\199\242\139\164","\85\153\116\166\156\236\193\144")]=function() local FlatIdent_81DE9=0;local v149;while true do if (FlatIdent_81DE9==0) then v149=0 -0 ;while true do if ((37 -(13 + 23))==v149) then local FlatIdent_9525B=0;while true do if (FlatIdent_9525B==1) then v149=3 -1 ;break;end if (FlatIdent_9525B==0) then v39.SkyboxFt=v7("\26\91\17\94\27\74\12\75\1\93\83\16\71\8\92\15\81\10\80\15\92\14","\63\104\57\105");v39.SkyboxLf=v7("\25\133\188\69\24\148\161\80\2\131\254\11\68\214\241\20\82\212\253\20\94\209","\36\107\231\196");FlatIdent_9525B=1;end end end if (v149==(4 -2)) then v39.SkyboxRt=v7("\79\183\186\134\78\166\167\147\84\177\248\200\18\228\247\215\4\230\251\215\11\230","\231\61\213\194");v39.SkyboxUp=v7("\27\175\37\114\26\190\56\103\0\169\103\60\70\252\104\35\80\254\100\35\81\255","\19\105\205\93");break;end if (v149==0) then local FlatIdent_185A5=0;while true do if (FlatIdent_185A5==1) then v149=1;break;end if (0==FlatIdent_185A5) then v39.SkyboxBk=v7("\182\226\85\178\247\19\161\244\68\183\190\79\235\177\24\227\189\83\253\176\31\225","\96\196\128\45\211\132");v39.SkyboxDn=v7("\39\143\99\94\193\188\177\204\60\137\33\16\157\254\225\136\108\222\34\15\129\247","\184\85\237\27\63\178\207\212");FlatIdent_185A5=1;end end end end break;end end end,[v7("\141\9\204\138\18\166\29\208\149\62\160\6\205","\95\201\104\190\225")]=function() local FlatIdent_77CC3=0;local v150;local v151;while true do if (FlatIdent_77CC3==1) then while true do if (v150==(0 + 0)) then v151=0 -0 ;while true do if ((1088 -(830 + 258))==v151) then local FlatIdent_696E1=0;while true do if (FlatIdent_696E1==0) then v39.SkyboxBk=v7("\189\201\217\207\188\216\196\218\166\207\155\129\224\158\145\151\247\147\144\154\248\152\145","\174\207\171\161");v39.SkyboxDn=v7("\255\252\21\242\235\196\232\234\4\247\162\152\162\171\93\170\160\143\188\171\95\161\175","\183\141\158\109\147\152");FlatIdent_696E1=1;end if (FlatIdent_696E1==1) then v151=3 -2 ;break;end end end if (v151==(1 + 0)) then local FlatIdent_904EC=0;while true do if (FlatIdent_904EC==1) then v151=2;break;end if (0==FlatIdent_904EC) then v39.SkyboxFt=v7("\62\11\254\13\63\26\227\24\37\13\188\67\99\92\182\85\116\81\183\89\122\92\181","\108\76\105\134");v39.SkyboxLf=v7("\249\199\169\224\221\248\192\165\232\202\177\138\254\180\158\178\157\233\176\152\186\144\228","\174\139\165\209\129");FlatIdent_904EC=1;end end end if ((2 + 0)==v151) then v39.SkyboxRt=v7("\177\177\250\192\213\16\117\108\170\183\184\142\137\86\32\33\251\235\176\145\149\86\34","\24\195\211\130\161\166\99\16");v39.SkyboxUp=v7("\84\1\241\45\64\5\67\23\224\40\9\89\9\86\185\117\11\78\23\90\184\126\4","\118\38\99\137\76\51");break;end end break;end end break;end if (FlatIdent_77CC3==0) then v150=0 -0 ;v151=nil;FlatIdent_77CC3=1;end end end,[v7("\219\42\4\31\0\46\250\21\16\28\26\37\233","\64\157\70\101\114\105")]=function() local FlatIdent_1EAB2=0;local v152;while true do if (0==FlatIdent_1EAB2) then v152=1441 -(860 + 581) ;while true do if (v152==(3 -2)) then local FlatIdent_86634=0;while true do if (FlatIdent_86634==0) then v39.SkyboxFt=v7("\168\132\97\242\76\221\33\174\143\125\169\16\129\112\235\211\47\171\7\156\112\232","\68\218\230\25\147\63\174");v39.SkyboxLf=v7("\191\40\75\77\165\190\47\71\69\178\247\101\28\24\231\248\124\11\20\229\252\122","\214\205\74\51\44");FlatIdent_86634=1;end if (FlatIdent_86634==1) then v152=557 -(443 + 112) ;break;end end end if (v152==(2 + 0)) then v39.SkyboxRt=v7("\232\78\250\253\100\233\73\246\245\115\160\3\173\168\38\175\26\186\164\37\173\24","\23\154\44\130\156");v39.SkyboxUp=v7("\3\164\181\175\37\0\20\178\164\170\108\92\94\242\252\251\96\75\73\245\248\250","\115\113\198\205\206\86");break;end if (v152==(0 -0)) then local FlatIdent_25061=0;local FlatIdent_8325F;while true do if (FlatIdent_25061==0) then FlatIdent_8325F=0;while true do if (FlatIdent_8325F==1) then v152=242 -(237 + 4) ;break;end if (FlatIdent_8325F==0) then v39.SkyboxBk=v7("\82\170\191\226\3\83\173\179\234\20\26\231\232\183\65\21\254\255\187\67\23\240","\112\32\200\199\131");v39.SkyboxDn=v7("\62\82\68\185\208\184\39\56\89\88\226\140\228\118\125\5\10\224\155\250\123\127","\66\76\48\60\216\163\203");FlatIdent_8325F=1;end end break;end end end end break;end end end,[v7("\170\82\233\99\139\69\245","\58\228\55\158")]=function() v39.SkyboxBk=v7("\166\139\200\47\47\190\48\160\128\212\116\115\226\100\229\218\131\125\101\250\102\228\223\137","\85\212\233\176\78\92\205");v39.SkyboxDn=v7("\88\90\144\227\89\75\141\246\67\92\210\173\5\9\217\177\25\11\209\180\19\15\222\186","\130\42\56\232");v39.SkyboxFt=v7("\248\183\60\226\83\44\239\161\45\231\26\112\165\228\117\176\19\108\179\227\112\176\16\108","\95\138\213\68\131\32");v39.SkyboxLf=v7("\56\42\185\66\101\57\45\181\74\114\112\103\238\18\39\121\123\242\26\33\123\123\242\17","\22\74\72\193\35");v39.SkyboxRt=v7("\62\123\252\89\63\106\225\76\37\125\190\23\99\40\181\11\127\42\189\0\126\33\178\12","\56\76\25\132");v39.SkyboxUp=v7("\76\195\179\39\220\77\196\191\47\203\4\142\228\119\158\13\146\248\127\153\9\152\252\118","\175\62\161\203\70");v39.SunAngularSize=0 -0 ;end,[v7("\29\216\208\7\61\57\201\202\16\102","\85\92\189\163\115")]=function() local FlatIdent_5C19E=0;local v160;local v161;while true do if (FlatIdent_5C19E==1) then while true do if (v160==(0 -0)) then v161=0 + 0 ;while true do if (v161==0) then local FlatIdent_7EE98=0;local FlatIdent_6F3E4;while true do if (FlatIdent_7EE98==0) then FlatIdent_6F3E4=0;while true do if (FlatIdent_6F3E4==0) then v39.SkyboxBk=v7("\59\174\40\57\58\191\53\44\32\168\106\119\102\253\101\105\120\250\101\106\120\248","\88\73\204\80");v39.SkyboxDn=v7("\60\129\8\71\58\201\43\151\25\66\115\149\97\210\69\23\120\140\123\210\73\17","\186\78\227\112\38\73");FlatIdent_6F3E4=1;end if (FlatIdent_6F3E4==1) then v161=1 + 0 ;break;end end break;end end end if (v161==1) then local FlatIdent_5E6B6=0;local FlatIdent_C342;while true do if (FlatIdent_5E6B6==0) then FlatIdent_C342=0;while true do if (1==FlatIdent_C342) then v161=1 + 1 ;break;end if (FlatIdent_C342==0) then v39.SkyboxFt=v7("\238\85\229\84\64\105\249\67\244\81\9\53\179\6\168\4\2\44\169\5\175\1","\26\156\55\157\53\51");v39.SkyboxLf=v7("\158\218\14\216\171\67\137\204\31\221\226\31\195\137\67\136\233\6\217\137\79\136","\48\236\184\118\185\216");FlatIdent_C342=1;end end break;end end end if (v161==(7 -5)) then v39.SkyboxRt=v7("\247\191\79\49\220\39\224\169\94\52\149\123\170\236\2\97\158\98\176\239\7\102","\84\133\221\55\80\175");v39.SkyboxUp=v7("\175\229\60\167\212\79\184\243\45\162\157\19\242\182\113\247\150\10\232\181\118\241","\60\221\135\68\198\167");break;end end break;end end break;end if (FlatIdent_5C19E==0) then v160=0 -0 ;v161=nil;FlatIdent_5C19E=1;end end end,[v7("\200\188\243\134\97\213\225\168\252\144","\185\142\221\152\227\34")]=function() local FlatIdent_81F9=0;local FlatIdent_480B4;local v162;while true do if (FlatIdent_81F9==1) then while true do if (FlatIdent_480B4==0) then v162=0 + 0 ;while true do if (v162==0) then local FlatIdent_FC26=0;while true do if (FlatIdent_FC26==1) then v162=1 + 0 ;break;end if (FlatIdent_FC26==0) then v39.SkyboxBk=v7("\74\199\79\251\80\32\242\76\204\83\160\12\124\175\12\156\1\162\26\97\175\9\149","\151\56\165\55\154\35\83");v39.SkyboxDn=v7("\178\65\29\239\179\80\0\250\169\71\95\161\239\27\81\183\246\27\92\184\242\22\85","\142\192\35\101");FlatIdent_FC26=1;end end end if (v162==(1429 -(85 + 1341))) then v39.SunAngularSize=0 -0 ;break;end if (v162==(2 -1)) then local FlatIdent_8E3FD=0;while true do if (1==FlatIdent_8E3FD) then v162=374 -(45 + 327) ;break;end if (FlatIdent_8E3FD==0) then v39.SkyboxFt=v7("\196\119\49\162\244\159\169\2\223\113\115\236\168\212\248\79\128\45\112\241\191\221\252","\118\182\21\73\195\135\236\204");v39.SkyboxLf=v7("\26\62\2\65\23\30\248\28\53\30\26\75\66\165\92\101\76\24\93\95\165\89\108","\157\104\92\122\32\100\109");FlatIdent_8E3FD=1;end end end if (v162==(3 -1)) then local FlatIdent_62CB4=0;while true do if (FlatIdent_62CB4==0) then v39.SkyboxRt=v7("\177\164\215\203\46\52\136\191\170\162\149\133\114\127\217\242\245\254\150\152\101\118\221","\203\195\198\175\170\93\71\237");v39.SkyboxUp=v7("\60\73\38\212\66\2\249\58\66\58\143\30\94\164\122\18\104\141\8\70\169\126\31","\156\78\43\94\181\49\113");FlatIdent_62CB4=1;end if (1==FlatIdent_62CB4) then v162=3 + 0 ;break;end end end end break;end end break;end if (FlatIdent_81F9==0) then FlatIdent_480B4=0;v162=nil;FlatIdent_81F9=1;end end end,[v7("\94\253\202\162\25\109\112\117\224\208","\25\18\136\164\195\107\35")]=function() local v163=502 -(444 + 58) ;while true do if (v163==(0 + 0)) then local FlatIdent_259C6=0;local FlatIdent_511F5;while true do if (FlatIdent_259C6==0) then FlatIdent_511F5=0;while true do if (FlatIdent_511F5==1) then v163=1 + 0 ;break;end if (0==FlatIdent_511F5) then local FlatIdent_8A1DB=0;while true do if (0==FlatIdent_8A1DB) then v39.SkyboxBk=v7("\250\47\177\78\97\175\196\172\225\41\243\0\61\237\153\239\191\124\250\28\36\234","\216\136\77\201\47\18\220\161");v39.SkyboxDn=v7("\63\238\51\219\27\207\135\57\229\47\128\71\147\211\117\187\124\139\90\136\208\117","\226\77\140\75\186\104\188");FlatIdent_8A1DB=1;end if (FlatIdent_8A1DB==1) then FlatIdent_511F5=1;break;end end end end break;end end end if (v163==(3 -1)) then local FlatIdent_4EC26=0;local FlatIdent_202CC;while true do if (FlatIdent_4EC26==0) then FlatIdent_202CC=0;while true do if (FlatIdent_202CC==0) then v39.SkyboxRt=v7("\200\221\187\134\192\201\218\183\142\215\128\144\236\214\139\141\136\242\211\134\136\138","\179\186\191\195\231");v39.SkyboxUp=v7("\235\61\0\229\234\44\29\240\240\59\66\171\182\110\64\179\174\110\74\181\168\110","\132\153\95\120");FlatIdent_202CC=1;end if (FlatIdent_202CC==1) then v163=2 + 1 ;break;end end break;end end end if ((2 -1)==v163) then local FlatIdent_61BF4=0;local FlatIdent_82A94;while true do if (FlatIdent_61BF4==0) then FlatIdent_82A94=0;while true do if (FlatIdent_82A94==1) then v163=2 + 0 ;break;end if (0==FlatIdent_82A94) then local FlatIdent_401F9=0;while true do if (FlatIdent_401F9==0) then v39.SkyboxFt=v7("\171\204\200\62\92\170\203\196\54\75\227\129\159\110\23\238\153\129\109\23\234\152","\47\217\174\176\95");v39.SkyboxLf=v7("\170\223\110\3\161\71\125\50\177\217\44\77\253\5\32\113\239\140\37\85\231\1","\70\216\189\22\98\210\52\24");FlatIdent_401F9=1;end if (FlatIdent_401F9==1) then FlatIdent_82A94=1;break;end end end end break;end end end if (v163==(1735 -(64 + 1668))) then v39.SunAngularSize=0;v39.StarCount=1973 -(1227 + 746) ;break;end end end,[v7("\139\139\34\12","\192\209\210\110\77\151\186")]=function() local FlatIdent_185A5=0;local v164;while true do if (0==FlatIdent_185A5) then v164=0 -0 ;while true do if (v164==(0 -0)) then local FlatIdent_90507=0;local FlatIdent_458D1;while true do if (FlatIdent_90507==0) then FlatIdent_458D1=0;while true do if (FlatIdent_458D1==1) then v164=1 + 0 ;break;end if (FlatIdent_458D1==0) then v39.SkyboxBk=v7("\242\1\58\232\236\215\229\23\43\237\165\139\175\82\119\176\171\145\180\81\123\176","\164\128\99\66\137\159");v39.SkyboxDn=v7("\18\139\241\191\19\154\236\170\9\141\179\241\79\216\188\231\84\220\189\236\89\223","\222\96\233\137");FlatIdent_458D1=1;end end break;end end end if ((495 -(415 + 79))==v164) then local FlatIdent_630B0=0;local FlatIdent_79F35;while true do if (FlatIdent_630B0==0) then FlatIdent_79F35=0;while true do if (FlatIdent_79F35==0) then local FlatIdent_5A134=0;while true do if (FlatIdent_5A134==0) then v39.SkyboxFt=v7("\171\177\191\30\155\224\245\173\186\163\69\199\188\161\236\234\243\74\220\161\169\234","\144\217\211\199\127\232\147");v39.SkyboxLf=v7("\234\45\38\41\198\86\7\80\241\43\100\103\154\20\87\29\172\122\106\122\141\19","\36\152\79\94\72\181\37\98");FlatIdent_5A134=1;end if (FlatIdent_5A134==1) then FlatIdent_79F35=1;break;end end end if (1==FlatIdent_79F35) then v164=1 + 1 ;break;end end break;end end end if ((3 -1)==v164) then v39.SkyboxRt=v7("\197\218\95\62\196\203\66\43\222\220\29\112\152\137\18\102\131\141\19\108\135\136","\95\183\184\39");v39.SkyboxUp=v7("\167\61\255\39\71\147\7\161\54\227\124\27\207\83\224\102\179\115\0\210\90\237","\98\213\95\135\70\52\224");break;end end break;end end end,[v7("\206\182\219\103\88\251\141\204\117\65\242\162","\52\158\195\169\23")]=function() local FlatIdent_397D1=0;local v165;while true do if (FlatIdent_397D1==0) then v165=491 -(142 + 349) ;while true do if (v165==(1 + 1)) then v39.SkyboxRt=v7("\23\139\8\21\199\92\90\17\128\20\78\155\0\14\80\216\65\66\129\29\15\83","\63\101\233\112\116\180\47");v39.SkyboxUp=v7("\209\57\245\19\235\37\198\47\228\22\162\121\140\106\184\67\169\96\150\105\191\69","\86\163\91\141\114\152");break;end if (v165==(1 -0)) then local FlatIdent_6038=0;while true do if (FlatIdent_6038==0) then v39.SkyboxFt=v7("\48\221\221\167\244\159\18\101\43\219\159\233\168\221\66\32\115\137\144\244\181\216","\17\66\191\165\198\135\236\119");v39.SkyboxLf=v7("\29\173\182\18\236\251\233\197\6\171\244\92\176\185\185\128\94\249\251\66\166\185","\177\111\207\206\115\159\136\140");FlatIdent_6038=1;end if (FlatIdent_6038==1) then v165=1 + 1 ;break;end end end if (v165==(0 + 0)) then local FlatIdent_28DC7=0;local FlatIdent_5C19E;while true do if (FlatIdent_28DC7==0) then FlatIdent_5C19E=0;while true do if (FlatIdent_5C19E==1) then v165=2 -1 ;break;end if (FlatIdent_5C19E==0) then local FlatIdent_97F0B=0;while true do if (FlatIdent_97F0B==0) then v39.SkyboxBk=v7("\104\190\42\117\149\38\126\159\115\184\104\59\201\100\46\218\43\234\103\38\215\97","\235\26\220\82\20\230\85\27");v39.SkyboxDn=v7("\154\163\241\195\103\155\164\253\203\112\210\238\166\147\33\217\240\191\151\37\209\246","\20\232\193\137\162");FlatIdent_97F0B=1;end if (FlatIdent_97F0B==1) then FlatIdent_5C19E=1;break;end end end end break;end end end end break;end end end,[v7("\125\2\115\123\46\96\0\109","\90\51\107\20\19")]=function() local FlatIdent_63A3A=0;while true do if (FlatIdent_63A3A==0) then local FlatIdent_33D5A=0;while true do if (FlatIdent_33D5A==1) then FlatIdent_63A3A=1;break;end if (FlatIdent_33D5A==0) then v39.SkyboxBk=v7("\159\242\157\238\46\158\245\145\230\57\215\191\202\190\111\221\166\209\190\109\218","\93\237\144\229\143");v39.SkyboxDn=v7("\7\244\232\24\24\85\16\226\249\29\81\9\90\167\162\73\93\18\68\163\162","\38\117\150\144\121\107");FlatIdent_33D5A=1;end end end if (FlatIdent_63A3A==1) then v39.SkyboxFt=v7("\63\185\246\59\62\168\235\46\36\191\180\117\98\234\188\106\123\239\191\104\124","\90\77\219\142");v39.SkyboxLf=v7("\244\6\57\56\95\20\127\242\13\37\99\3\72\43\180\84\119\106\21\95\46","\26\134\100\65\89\44\103");FlatIdent_63A3A=2;end if (2==FlatIdent_63A3A) then v39.SkyboxRt=v7("\227\225\40\34\183\226\230\36\42\160\171\172\127\114\246\161\181\100\114\245\164","\196\145\131\80\67");v39.SkyboxUp=v7("\12\178\30\9\11\251\27\164\15\12\66\167\81\225\84\88\78\188\79\227\87","\136\126\208\102\104\120");break;end end end,[v7("\72\131\192\72\139\83\36\93\113\141\198\87","\49\24\234\174\35\207\50\93")]=function() local FlatIdent_23AC6=0;local FlatIdent_354BC;local v172;while true do if (FlatIdent_23AC6==1) then while true do if (0==FlatIdent_354BC) then v172=0 + 0 ;while true do if (v172==(1864 -(1710 + 154))) then local FlatIdent_73069=0;while true do if (FlatIdent_73069==0) then v39.SkyboxBk=v7("\30\240\229\137\98\31\247\233\129\117\86\189\178\218\38\93\162\169\218\36\93\164","\17\108\146\157\232");v39.SkyboxDn=v7("\89\193\12\236\60\187\78\215\29\233\117\231\4\145\67\188\127\255\28\145\64\190","\200\43\163\116\141\79");FlatIdent_73069=1;end if (FlatIdent_73069==1) then v172=319 -(200 + 118) ;break;end end end if (v172==2) then v39.SkyboxRt=v7("\52\41\61\190\242\53\46\49\182\229\124\100\106\237\182\119\123\113\237\181\112\124","\129\70\75\69\223");v39.SkyboxUp=v7("\84\201\235\232\111\252\67\223\250\237\38\160\9\153\164\184\44\184\17\146\166\177","\143\38\171\147\137\28");break;end if (v172==(1 + 0)) then local FlatIdent_2E7F5=0;while true do if (FlatIdent_2E7F5==1) then v172=2 -0 ;break;end if (FlatIdent_2E7F5==0) then local FlatIdent_532EC=0;while true do if (FlatIdent_532EC==1) then FlatIdent_2E7F5=1;break;end if (0==FlatIdent_532EC) then v39.SkyboxFt=v7("\173\52\37\130\163\231\230\171\63\57\217\255\187\177\232\103\109\215\226\161\182\233","\131\223\86\93\227\208\148");v39.SkyboxLf=v7("\241\71\174\183\14\166\230\81\191\178\71\250\172\23\225\231\77\225\177\22\231\230","\213\131\37\214\214\125");FlatIdent_532EC=1;end end end end end end break;end end break;end if (FlatIdent_23AC6==0) then FlatIdent_354BC=0;v172=nil;FlatIdent_23AC6=1;end end end,[v7("\253\141\171\253\10\237\211\247\142\182\228","\180\176\226\217\147\99\131")]=function() local FlatIdent_727DA=0;while true do if (0==FlatIdent_727DA) then v39.SkyboxBk=v7("\193\187\55\6\192\170\42\19\218\189\117\72\156\235\120\86\131\237\125\82\130\239","\103\179\217\79");v39.SkyboxDn=v7("\88\181\4\212\82\159\166\94\190\24\143\14\195\241\29\230\76\130\22\222\247\25","\195\42\215\124\181\33\236");FlatIdent_727DA=1;end if (FlatIdent_727DA==2) then v39.SkyboxRt=v7("\32\225\144\60\90\73\55\247\129\57\19\21\125\177\223\108\25\14\96\183\222\106","\58\82\131\232\93\41");v39.SkyboxUp=v7("\145\85\200\20\78\44\134\67\217\17\7\112\204\5\135\68\13\104\212\14\133\77","\95\227\55\176\117\61");break;end if (FlatIdent_727DA==1) then v39.SkyboxFt=v7("\31\91\47\63\54\235\8\77\62\58\127\183\66\11\96\111\117\172\95\12\98\104","\152\109\57\87\94\69");v39.SkyboxLf=v7("\235\213\18\162\173\193\81\188\240\211\80\236\241\128\3\249\169\131\88\240\239\130","\200\153\183\106\195\222\178\52");FlatIdent_727DA=2;end end end,[v7("\43\123\55\95\162\22\121\16\94\165","\203\120\30\67\43")]=function() local v179=0 -0 ;while true do if (v179==(0 + 0)) then local FlatIdent_86FD=0;local FlatIdent_7C89;while true do if (FlatIdent_86FD==0) then FlatIdent_7C89=0;while true do if (FlatIdent_7C89==0) then local FlatIdent_7B2EE=0;while true do if (1==FlatIdent_7B2EE) then FlatIdent_7C89=1;break;end if (0==FlatIdent_7B2EE) then v39.SkyboxBk=v7("\227\39\85\238\202\226\32\89\230\221\171\106\2\185\139\167\113\27\191\138\166\114","\185\145\69\45\143");v39.SkyboxDn=v7("\152\29\1\167\207\153\26\13\175\216\208\80\86\240\142\220\75\79\246\142\219\73","\188\234\127\121\198");FlatIdent_7B2EE=1;end end end if (1==FlatIdent_7C89) then v179=1 + 0 ;break;end end break;end end end if ((1 + 0)==v179) then local FlatIdent_101B7=0;local FlatIdent_2EDA1;while true do if (FlatIdent_101B7==0) then FlatIdent_2EDA1=0;while true do if (FlatIdent_2EDA1==0) then local FlatIdent_9917B=0;while true do if (FlatIdent_9917B==0) then v39.SkyboxFt=v7("\42\48\11\130\43\33\22\151\49\54\73\204\119\100\65\213\108\100\67\214\105\97","\227\88\82\115");v39.SkyboxLf=v7("\81\29\162\166\17\96\70\11\179\163\88\60\12\73\232\241\86\36\16\79\233\245","\19\35\127\218\199\98");FlatIdent_9917B=1;end if (1==FlatIdent_9917B) then FlatIdent_2EDA1=1;break;end end end if (FlatIdent_2EDA1==1) then v179=2;break;end end break;end end end if (v179==(2 + 0)) then v39.SkyboxRt=v7("\14\249\18\227\15\232\15\246\21\255\80\173\83\173\88\180\72\174\82\180\79\162","\130\124\155\106");v39.SkyboxUp=v7("\199\201\238\174\176\229\121\171\220\207\172\224\236\160\46\233\129\157\166\249\241\163","\223\181\171\150\207\195\150\28");break;end end end,[v7("\106\59\231\171\43\64\47\230","\105\44\90\131\206")]=function() local FlatIdent_5C3A6=0;local v180;while true do if (0==FlatIdent_5C3A6) then v180=831 -(762 + 69) ;while true do if (v180==(0 + 0)) then local FlatIdent_7FA00=0;while true do if (FlatIdent_7FA00==0) then v39.SkyboxBk=v7("\237\226\170\184\27\45\250\244\187\189\82\113\176\177\231\234\94\103\170\180\227\237","\94\159\128\210\217\104");v39.SkyboxDn=v7("\66\251\30\190\76\108\252\110\89\253\92\240\16\46\172\41\6\160\83\236\10\45","\26\48\153\102\223\63\31\153");FlatIdent_7FA00=1;end if (FlatIdent_7FA00==1) then v180=2 -1 ;break;end end end if (v180==2) then v39.SkyboxRt=v7("\70\4\159\183\182\163\129\64\15\131\236\234\255\213\1\85\209\239\240\227\220\7","\228\52\102\231\214\197\208");v39.SkyboxUp=v7("\12\226\109\203\249\152\28\194\23\228\47\133\165\218\76\133\72\185\32\158\189\218","\182\126\128\21\170\138\235\121");break;end if (v180==(1251 -(363 + 887))) then local FlatIdent_86ECC=0;while true do if (FlatIdent_86ECC==1) then v180=2 -0 ;break;end if (FlatIdent_86ECC==0) then local FlatIdent_60A2E=0;while true do if (FlatIdent_60A2E==0) then v39.SkyboxFt=v7("\16\66\245\242\17\83\232\231\11\68\183\188\77\17\184\160\84\25\184\167\87\18","\147\98\32\141");v39.SkyboxLf=v7("\10\65\251\203\21\69\78\12\74\231\144\73\25\26\77\16\181\147\83\5\25\72","\43\120\35\131\170\102\54");FlatIdent_60A2E=1;end if (FlatIdent_60A2E==1) then FlatIdent_86ECC=1;break;end end end end end end break;end end end,[v7("\174\214\48\225\135\29\36\43\132\200\59\239\136\20","\102\235\186\85\134\230\115\80")]=function() local v181=0 + 0 ;while true do if (v181==2) then v39.SkyboxRt=v7("\147\196\73\243\218\79\132\210\88\246\147\19\206\151\4\161\158\10\214\148\2\163","\60\225\166\49\146\169");v39.SkyboxUp=v7("\61\28\55\43\18\20\42\10\38\46\91\72\96\79\122\121\86\81\120\76\119\114","\103\79\126\79\74\97");break;end if (v181==(2 -1)) then local FlatIdent_927F1=0;local FlatIdent_2EB74;while true do if (FlatIdent_927F1==0) then FlatIdent_2EB74=0;while true do if (FlatIdent_2EB74==1) then v181=9 -7 ;break;end if (FlatIdent_2EB74==0) then v39.SkyboxFt=v7("\184\179\245\230\100\253\66\190\184\233\189\56\161\22\255\226\186\177\32\188\17\252","\39\202\209\141\135\23\142");v39.SkyboxLf=v7("\237\49\17\11\33\235\250\39\0\14\104\183\176\98\92\89\101\174\168\97\89\90","\152\159\83\105\106\82");FlatIdent_2EB74=1;end end break;end end end if (v181==(0 + 0)) then local FlatIdent_5FCA9=0;local FlatIdent_630B0;while true do if (FlatIdent_5FCA9==0) then FlatIdent_630B0=0;while true do if (FlatIdent_630B0==0) then local FlatIdent_771FD=0;while true do if (1==FlatIdent_771FD) then FlatIdent_630B0=1;break;end if (FlatIdent_771FD==0) then v39.SkyboxBk=v7("\69\14\38\94\97\199\39\67\5\58\5\61\155\115\2\95\105\9\37\134\118\6","\66\55\108\94\63\18\180");v39.SkyboxDn=v7("\6\143\157\54\52\74\17\153\140\51\125\22\91\220\208\100\112\15\67\223\212\97","\57\116\237\229\87\71");FlatIdent_771FD=1;end end end if (1==FlatIdent_630B0) then v181=2 -1 ;break;end end break;end end end end end,[v7("\148\122\195\103\75\20\191","\122\218\31\179\19\62")]=function() local FlatIdent_6B578=0;local FlatIdent_37DBD;while true do if (FlatIdent_6B578==0) then FlatIdent_37DBD=0;while true do if (FlatIdent_37DBD==1) then local FlatIdent_41401=0;while true do if (FlatIdent_41401==1) then FlatIdent_37DBD=2;break;end if (FlatIdent_41401==0) then v39.SkyboxFt=v7("\209\126\255\19\69\208\121\243\27\82\153\51\168\64\7\155\37\178\70\3\145\40","\54\163\28\135\114");v39.SkyboxLf=v7("\58\217\69\131\93\108\45\207\84\134\20\48\103\137\12\218\23\42\112\143\4\209","\31\72\187\61\226\46");FlatIdent_41401=1;end end end if (FlatIdent_37DBD==0) then v39.SkyboxBk=v7("\161\212\213\192\218\178\64\167\223\201\155\134\238\23\226\142\148\148\156\249\20\234","\37\211\182\173\161\169\193");v39.SkyboxDn=v7("\229\56\85\216\59\104\188\227\51\73\131\103\52\235\166\98\20\140\123\47\232\174","\217\151\90\45\185\72\27");FlatIdent_37DBD=1;end if (FlatIdent_37DBD==2) then v39.SkyboxRt=v7("\209\4\91\211\84\109\33\215\15\71\136\8\49\118\146\94\26\135\16\47\119\151","\68\163\102\35\178\39\30");v39.SkyboxUp=v7("\172\114\194\198\16\166\134\5\183\116\128\136\76\231\210\73\231\37\138\151\90\229","\113\222\16\186\167\99\213\227");break;end end break;end end end,[v7("\28\11\255\229\38\7\253\226","\150\78\110\155")]=function() local FlatIdent_761C4=0;local v188;while true do if (0==FlatIdent_761C4) then v188=0;while true do if (v188==(7 -5)) then v39.SkyboxRt=v7("\214\207\95\61\225\29\240\208\196\67\102\189\65\161\148\156\17\106\166\87\165\149","\149\164\173\39\92\146\110");v39.SkyboxUp=v7("\225\37\8\30\9\8\246\51\25\27\64\84\188\115\64\78\76\77\167\126\67\73","\123\147\71\112\127\122");break;end if (v188==(1 + 0)) then local FlatIdent_8DA9B=0;local FlatIdent_1D0A6;while true do if (FlatIdent_8DA9B==0) then FlatIdent_1D0A6=0;while true do if (FlatIdent_1D0A6==1) then v188=1666 -(674 + 990) ;break;end if (FlatIdent_1D0A6==0) then local FlatIdent_70FF0=0;while true do if (FlatIdent_70FF0==1) then FlatIdent_1D0A6=1;break;end if (FlatIdent_70FF0==0) then v39.SkyboxFt=v7("\66\137\38\118\67\152\59\99\89\143\100\56\31\223\110\38\6\221\106\46\6\219","\23\48\235\94");v39.SkyboxLf=v7("\110\216\192\92\68\32\215\104\211\220\7\24\124\134\44\139\142\11\3\107\138\45","\178\28\186\184\61\55\83");FlatIdent_70FF0=1;end end end end break;end end end if ((0 + 0)==v188) then local FlatIdent_3EDDC=0;while true do if (FlatIdent_3EDDC==0) then local FlatIdent_52E0C=0;while true do if (FlatIdent_52E0C==0) then v39.SkyboxBk=v7("\151\199\63\224\183\13\186\84\140\193\125\174\235\74\239\17\211\147\115\185\247\71","\32\229\165\71\129\196\126\223");v39.SkyboxDn=v7("\209\139\220\128\146\198\198\157\205\133\219\154\140\221\148\208\215\131\151\209\146\211","\181\163\233\164\225\225");FlatIdent_52E0C=1;end if (FlatIdent_52E0C==1) then FlatIdent_3EDDC=1;break;end end end if (FlatIdent_3EDDC==1) then v188=1 + 0 ;break;end end end end break;end end end,[v7("\237\200\145\101\78\201\217\139\114\104\197\202\138\101","\38\172\173\226\17")]=function() local FlatIdent_38103=0;local FlatIdent_5AC6;while true do if (FlatIdent_38103==0) then FlatIdent_5AC6=0;while true do if (FlatIdent_5AC6==0) then local FlatIdent_4B539=0;while true do if (FlatIdent_4B539==1) then FlatIdent_5AC6=1;break;end if (FlatIdent_4B539==0) then v39.SkyboxBk=v7("\95\19\52\238\94\2\41\251\68\21\118\160\2\64\124\187\24\72\122\187\25\72\124","\143\45\113\76");v39.SkyboxDn=v7("\170\186\4\61\171\171\25\40\177\188\70\115\247\233\76\104\237\225\74\104\235\238\68","\92\216\216\124");FlatIdent_4B539=1;end end end if (FlatIdent_5AC6==2) then v39.SkyboxRt=v7("\58\163\220\125\13\48\52\54\33\165\158\51\81\114\97\118\125\248\146\40\72\118\100","\66\72\193\164\28\126\67\81");v39.SkyboxUp=v7("\245\46\176\89\53\101\226\56\161\92\124\57\168\125\248\12\115\47\177\126\241\14\127","\22\135\76\200\56\70");break;end if (1==FlatIdent_5AC6) then local FlatIdent_6D84C=0;while true do if (FlatIdent_6D84C==0) then v39.SkyboxFt=v7("\73\48\180\65\238\72\55\184\73\249\1\125\227\17\173\15\103\245\22\169\13\103\249","\157\59\82\204\32");v39.SkyboxLf=v7("\42\60\251\251\250\249\214\165\49\58\185\181\166\187\131\229\109\103\181\174\191\191\134","\209\88\94\131\154\137\138\179");FlatIdent_6D84C=1;end if (FlatIdent_6D84C==1) then FlatIdent_5AC6=2;break;end end end end break;end end end,[v7("\130\56\241\43","\129\237\80\152\68\61")]=function() local FlatIdent_6E9BC=0;local FlatIdent_6134A;local v195;while true do if (1==FlatIdent_6E9BC) then while true do if (FlatIdent_6134A==0) then v195=0 -0 ;while true do if (v195==(1 -0)) then local FlatIdent_93E71=0;while true do if (0==FlatIdent_93E71) then v39.SkyboxFt=v7("\54\13\186\70\55\28\167\83\45\11\248\8\107\94\246\20\119\95\247\16\118\89\242\20","\39\68\111\194");v39.SkyboxLf=v7("\196\164\255\198\106\164\211\178\238\195\35\248\153\247\179\148\42\231\131\241\191\159\44\239","\215\182\198\135\167\25");FlatIdent_93E71=1;end if (FlatIdent_93E71==1) then v195=1057 -(507 + 548) ;break;end end end if (v195==(837 -(289 + 548))) then local FlatIdent_4B329=0;while true do if (FlatIdent_4B329==1) then v195=1819 -(821 + 997) ;break;end if (FlatIdent_4B329==0) then v39.SkyboxBk=v7("\67\170\28\242\15\4\93\69\161\0\169\83\88\9\5\251\87\163\73\65\13\8\240\82","\56\49\200\100\147\124\119");v39.SkyboxDn=v7("\222\60\167\241\223\45\186\228\197\58\229\191\131\111\235\163\159\110\234\168\154\109\235\160","\144\172\94\223");FlatIdent_4B329=1;end end end if (v195==(257 -(195 + 60))) then v39.SkyboxRt=v7("\159\75\242\73\158\90\239\92\132\77\176\7\194\24\190\27\222\25\191\30\212\24\189\26","\40\237\41\138");v39.SkyboxUp=v7("\213\118\226\249\89\212\113\238\241\78\157\59\181\169\30\148\39\170\173\18\149\33\174\169","\42\167\20\154\152");break;end end break;end end break;end if (FlatIdent_6E9BC==0) then FlatIdent_6134A=0;v195=nil;FlatIdent_6E9BC=1;end end end,[v7("\121\216\141\118\89","\65\42\158\194\34\17")]=function() local FlatIdent_132C0=0;local FlatIdent_23A2C;local v196;while true do if (FlatIdent_132C0==1) then while true do if (FlatIdent_23A2C==0) then v196=0 + 0 ;while true do if (v196==1) then local FlatIdent_7E46E=0;local FlatIdent_23B4;while true do if (0==FlatIdent_7E46E) then FlatIdent_23B4=0;while true do if (FlatIdent_23B4==0) then v39.SkyboxFt=v7("\8\31\38\25\38\226\33\14\20\58\66\122\190\125\79\79\102\72\103\167\125\67\75","\68\122\125\94\120\85\145");v39.SkyboxLf=v7("\5\30\215\95\219\202\191\3\21\203\4\135\150\227\66\78\151\14\154\143\238\65\73","\218\119\124\175\62\168\185");FlatIdent_23B4=1;end if (FlatIdent_23B4==1) then v196=2 + 0 ;break;end end break;end end end if (v196==(1501 -(251 + 1250))) then local FlatIdent_86FD=0;while true do if (FlatIdent_86FD==0) then v39.SkyboxBk=v7("\8\37\74\13\62\254\30\250\19\35\8\67\98\180\78\188\66\119\0\90\122\180\75","\142\122\71\50\108\77\141\123");v39.SkyboxDn=v7("\7\160\231\25\40\6\167\235\17\63\79\237\176\65\110\71\250\175\74\108\71\245\166","\91\117\194\159\120");FlatIdent_86FD=1;end if (FlatIdent_86FD==1) then v196=2 -1 ;break;end end end if (v196==(1809 -(518 + 1289))) then v39.SkyboxRt=v7("\183\242\80\197\182\227\77\208\172\244\18\139\234\169\29\150\253\160\25\156\246\168\26","\164\197\144\40");v39.SkyboxUp=v7("\145\242\178\138\206\165\134\228\163\143\135\249\204\169\255\217\133\230\209\167\251\222\133","\214\227\144\202\235\189");break;end end break;end end break;end if (0==FlatIdent_132C0) then FlatIdent_23A2C=0;v196=nil;FlatIdent_132C0=1;end end end,[v7("\221\172\147\120\24\151\82\46\230","\92\141\197\231\27\112\211\51")]=function() local v197=0 + 0 ;local v198;while true do if ((1032 -(809 + 223))==v197) then v198=0 -0 ;while true do if (v198==0) then v39.StarCount=0 -0 ;v41=lightingService.TimeOfDay;v198=3 -2 ;end if (v198==(1 + 0)) then lightingService.TimeOfDay=v7("\182\175\208\243\129\188\175\218","\177\134\159\234\195");table.insert(v27.Connections,lightingService:GetPropertyChangedSignal(v7("\137\226\50\165\230\187\207\62\185","\169\221\139\95\192")):Connect(function() local FlatIdent_8F9B8=0;local v456;while true do if (FlatIdent_8F9B8==0) then v456=0 + 0 ;while true do if (v456==(0 -0)) then v39.StarCount=617 -(14 + 603) ;lightingService.TimeOfDay=v7("\142\219\37\111\114\124\142\219","\70\190\235\31\95\66");break;end end break;end end end));break;end end break;end end end};v27=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({[v7("\148\227\23\227","\133\218\130\122\134")]=v7("\29\235\238\203\207\179\48\57\237\230","\88\92\159\131\164\188\195"),[v7("\165\54\171\89\214\223\216\152\58","\189\224\78\223\43\183\139")]=function() return ((v28.Value~=v7("\13\233\153\2\206\35","\161\78\156\234\118")) and v28.Value) or "" ;end,[v7("\129\162\199\223\179\190\198\210","\188\199\215\169")]=function(v199) if v199 then local FlatIdent_1B638=0;local FlatIdent_8C3A2;while true do if (FlatIdent_1B638==0) then FlatIdent_8C3A2=0;while true do if (FlatIdent_8C3A2==3) then task.spawn(v43[v28.Value]);break;end if (2==FlatIdent_8C3A2) then v40.TintColor=Color3.fromHSV(v38.Hue,v38.Sat,v38.Value);v40.Parent=lightingService;FlatIdent_8C3A2=3;end if (FlatIdent_8C3A2==1) then v39.Parent=lightingService;v40=Instance.new(v7("\0\23\210\37\58\0\66\49\10\219\41\60\42\66\45\61\216\44\45\32\89","\45\67\120\190\74\72\67"));FlatIdent_8C3A2=2;end if (FlatIdent_8C3A2==0) then for v395,v396 in next,(lightingService:GetChildren()) do if (v396:IsA(v7("\204\6\76\111\205\250\15\90\120\252","\136\156\105\63\27")) or v396:IsA(v7("\40\135\96","\84\123\236\25"))) then local FlatIdent_82627=0;local FlatIdent_72401;while true do if (FlatIdent_82627==0) then FlatIdent_72401=0;while true do if (FlatIdent_72401==0) then table.insert(v42,v396);v396.Parent=game;break;end end break;end end end end v39=Instance.new(v7("\195\128\179","\213\144\235\202\119\204"));FlatIdent_8C3A2=1;end end break;end end else local v227=129 -(118 + 11) ;while true do if (v227==(1 + 1)) then table.clear(v42);break;end if (v227==(1 + 0)) then local FlatIdent_571C4=0;local FlatIdent_447EB;while true do if (FlatIdent_571C4==0) then FlatIdent_447EB=0;while true do if (FlatIdent_447EB==0) then local FlatIdent_51FFC=0;while true do if (FlatIdent_51FFC==0) then for v446,v447 in next,v42 do v447.Parent=lightingService;end if v41 then local v457=0 + 0 ;while true do if ((0 -0)==v457) then lightingService.TimeOfDay=v41;v41=nil;break;end end end FlatIdent_51FFC=1;end if (FlatIdent_51FFC==1) then FlatIdent_447EB=1;break;end end end if (FlatIdent_447EB==1) then v227=951 -(551 + 398) ;break;end end break;end end end if (v227==(1016 -(10 + 1006))) then local FlatIdent_2644E=0;local FlatIdent_4543F;while true do if (FlatIdent_2644E==0) then FlatIdent_4543F=0;while true do if (FlatIdent_4543F==0) then if v39 then v39:Destroy();end if v40 then v40:Destroy();end FlatIdent_4543F=1;end if (FlatIdent_4543F==1) then v227=1 + 0 ;break;end end break;end end end end end end});local v44={v7("\3\55\254\177\246\133","\137\64\66\141\197\153\232\142")};for v200,v201 in v43 do table.insert(v44,v200);end v28=v27.CreateDropdown({[v7("\45\209\47\163","\232\99\176\66\198")]=v7("\193\46\44\3","\76\140\65\72\102\27\237\153"),[v7("\102\211\5\198","\222\42\186\118\178\183\97")]=v44,[v7("\123\249\74\137\73\229\75\132","\234\61\140\36")]=function(v202) task.spawn(function() local FlatIdent_5C540=0;local v218;while true do if (FlatIdent_5C540==0) then v218=0 + 0 ;while true do if (v218==(0 + 0)) then if v27.Enabled then local v449=0 + 0 ;while true do if (v449==(0 -0)) then local FlatIdent_56EE2=0;local FlatIdent_2F94A;while true do if (FlatIdent_56EE2==0) then FlatIdent_2F94A=0;while true do if (FlatIdent_2F94A==1) then v449=2 -1 ;break;end if (FlatIdent_2F94A==0) then v27.ToggleButton(false);if (v202==v7("\2\200\169\102\0\44","\111\65\189\218\18")) then task.wait();end FlatIdent_2F94A=1;end end break;end end end if (v449==(1 + 0)) then v27.ToggleButton(false);break;end end end for v402,v403 in v29 do v403.Object.Visible=v28.Value==v7("\96\94\8\33\4\81","\207\35\43\123\85\107\60") ;end break;end end break;end end end);end});v30=v27.CreateTextBox({[v7("\94\171\173\239","\25\16\202\192\138")]=v7("\206\192\180\215\185","\148\157\171\205\130\201"),[v7("\23\209\121\57\229\243\59\192","\150\67\180\20\73\177")]=v7("\190\19\3\13\185\23\10\13\164\60","\45\237\120\122"),[v7("\241\231\161\57\196\196\173\63\195","\76\183\136\194")]=function(v203) if v27.Enabled then local FlatIdent_3423=0;while true do if (0==FlatIdent_3423) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end end end});v31=v27.CreateTextBox({[v7("\84\231\232\61","\116\26\134\133\88\48\47")]=v7("\45\202\185\192\178\101\16","\18\126\161\192\132\221"),[v7("\107\45\163\20\98\90\48\186","\54\63\72\206\100")]=v7("\251\82\92\58\199\116\220\77\74\119\165\82\236","\27\168\57\37\26\133"),[v7("\11\165\127\189\196\1\165\111\188","\183\77\202\28\200")]=function(v204) if v27.Enabled then local FlatIdent_87A87=0;local v228;while true do if (FlatIdent_87A87==0) then v228=0 -0 ;while true do if ((0 + 0)==v228) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end end end});v32=v27.CreateTextBox({[v7("\57\50\132\13","\104\119\83\233")]=v7("\198\243\62\14\70\243\236","\35\149\152\71\66"),[v7("\45\237\79\160\14\28\240\86","\90\121\136\34\208")]=v7("\244\5\76\94\235\11\83\10\135\39\113","\126\167\110\53"),[v7("\27\31\45\237\207\19\50\3\58","\95\93\112\78\152\188")]=function(v205) if v27.Enabled then local FlatIdent_36690=0;local FlatIdent_6B578;local v229;while true do if (FlatIdent_36690==0) then FlatIdent_6B578=0;v229=nil;FlatIdent_36690=1;end if (FlatIdent_36690==1) then while true do if (FlatIdent_6B578==0) then v229=89 -(40 + 49) ;while true do if (v229==(0 -0)) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end break;end end end end});v33=v27.CreateTextBox({[v7("\239\244\136\16","\178\161\149\229\117\132\222")]=v7("\187\208\196\158\168\17\174\55","\67\232\187\189\204\193\118\198"),[v7("\191\43\184\48\15\7\247\159","\143\235\78\213\64\91\98")]=v7("\190\67\157\169\66\191\138\64\144\169\89\146","\214\237\40\228\137\16"),[v7("\163\236\236\204\16\138\138\240\251","\198\229\131\143\185\99")]=function(v206) if v27.Enabled then local FlatIdent_2FA59=0;local FlatIdent_5CD30;local v230;while true do if (FlatIdent_2FA59==1) then while true do if (0==FlatIdent_5CD30) then v230=490 -(99 + 391) ;while true do if (v230==(0 + 0)) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end break;end if (0==FlatIdent_2FA59) then FlatIdent_5CD30=0;v230=nil;FlatIdent_2FA59=1;end end end end});v34=v27.CreateTextBox({[v7("\127\141\165\118","\19\49\236\200")]=v7("\205\60\239\145\246\181\240\35","\218\158\87\150\215\132"),[v7("\207\27\212\242\2\39\213\239","\173\155\126\185\130\86\66")]=v7("\214\173\163\135\174\254\234\168\174\135\161\200","\140\133\198\218\167\232"),[v7("\147\33\183\104\151\153\33\167\105","\228\213\78\212\29")]=function(v207) if v27.Enabled then local FlatIdent_44ED1=0;local v231;while true do if (FlatIdent_44ED1==0) then v231=0 -0 ;while true do if (v231==(0 -0)) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end end end});v35=v27.CreateTextBox({[v7("\169\77\187\0","\139\231\44\214\101")]=v7("\234\228\31\124\17\178\58","\118\185\143\102\62\112\209\81"),[v7("\104\117\36\246\145\16\4\44","\88\60\16\73\134\197\117\124")]=v7("\99\225\225\136\99\81\233\243\136\104\116","\33\48\138\152\168"),[v7("\84\25\51\68\210\27\125\5\36","\87\18\118\80\49\161")]=function(v208) if v27.Enabled then local FlatIdent_6354D=0;local v232;while true do if (FlatIdent_6354D==0) then v232=0 -0 ;while true do if (v232==(186 -(165 + 21))) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end end end});v36=v27.CreateTextBox({[v7("\98\31\215\165","\208\44\126\186\192")]=v7("\196\17\189\245\1\242","\46\151\122\196\166\116\156\169"),[v7("\209\232\75\10\207\224\245\82","\155\133\141\38\122")]=v7("\22\33\181\1\124\106\171\101\3\136","\197\69\74\204\33\47\31"),[v7("\214\64\89\146\227\99\85\148\228","\231\144\47\58")]=function(v209) if v27.Enabled then local FlatIdent_1B30C=0;local FlatIdent_885BC;local v233;local v234;while true do if (FlatIdent_1B30C==1) then v234=nil;while true do if (FlatIdent_885BC==0) then local FlatIdent_733BE=0;while true do if (FlatIdent_733BE==0) then v233=0 + 0 ;v234=nil;FlatIdent_733BE=1;end if (FlatIdent_733BE==1) then FlatIdent_885BC=1;break;end end end if (FlatIdent_885BC==1) then while true do if (v233==(0 -0)) then v234=0;while true do if (v234==(0 -0)) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end break;end end break;end if (FlatIdent_1B30C==0) then FlatIdent_885BC=0;v233=nil;FlatIdent_1B30C=1;end end end end});v37=v27.CreateTextBox({[v7("\156\217\215\112","\89\210\184\186\21\120\93\175")]=v7("\130\88\101\248\118\53\191","\90\209\51\28\181\25"),[v7("\228\126\90\254\139\213\99\67","\223\176\27\55\142")]=v7("\23\176\215\245\9\180\193\187\100\146\234","\213\68\219\174"),[v7("\45\239\32\242\57\233\48\108\31","\31\107\128\67\135\74\165\95")]=function(v210) if v27.Enabled then local FlatIdent_60AAB=0;local v235;while true do if (FlatIdent_60AAB==0) then v235=0 -0 ;while true do if (v235==(1604 -(1032 + 572))) then v27.ToggleButton(false);v27.ToggleButton(false);break;end end break;end end end end});v38=v27.CreateColorSlider({[v7("\246\233\241\72","\209\184\136\156\45\33")]=v7("\36\199\121\7\170","\216\103\168\21\104"),[v7("\94\184\77\167\108\164\76\170","\196\24\205\35")]=function(v211,v212,v213) if v40 then v40.TintColor=Color3.fromHSV(v38.Hue,v38.Sat,v38.Value);end end});table.insert(v29,v30);table.insert(v29,v31);table.insert(v29,v32);table.insert(v29,v33);table.insert(v29,v34);table.insert(v29,v35);table.insert(v29,v36);table.insert(v29,v37);end);run(function() local FlatIdent_38103=0;local v45;local v46;while true do if (FlatIdent_38103==1) then while true do if (v45==(1817 -(568 + 1249))) then v46={[v7("\11\133\226\4\34\142\231","\102\78\235\131")]=false};v46=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({[v7("\212\47\57\65","\84\154\78\84\36\39\89\215")]=v7("\214\232\90\84\35\248\228\82\112\12\249\228\68","\101\157\129\54\56"),[v7("\59\188\132\168\55\112\18\167","\25\125\201\234\203\67")]=function(v397) if v397 then task.spawn(function() lplr.PlayerGui.KillFeedGui.Parent=game.Workspace;end);else game.Workspace.KillFeedGui.Parent=lplr.PlayerGui;end end,[v7("\81\251\14\6\6\19\22\97\224","\115\25\148\120\99\116\71")]=v7("\62\56\180\43\87\9\46\249\15\72\0\49\159\33\68\8","\33\108\93\217\68")});break;end end break;end if (FlatIdent_38103==0) then v45=417 -(203 + 214) ;v46=nil;FlatIdent_38103=1;end end end);run(function() local v47={[v7("\254\69\160\175\215\78\165","\205\187\43\193")]=false};v47=GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({[v7("\208\115\8\218","\191\158\18\101")]=v7("\228\205\147\190\135\204\215\199\255\254\199\147\132\254","\207\165\163\231\215"),[v7("\224\236\247\85\48\121\201\247","\16\166\153\153\54\68")]=function(v214) if v214 then spawn(function() while task.wait() do if  not v47.Enabled then return;end if ( not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled and  not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) then for v458,v459 in pairs(game:GetService(v7("\226\191\193\95\49\51\234","\153\178\211\160\38\84\65")):GetChildren()) do if ((v459.Team~=lplr.Team) and IsAlive(v459) and IsAlive(lplr)) then if (v459 and (v459~=lplr)) then local v478=lplr:DistanceFromCharacter(v459.Character:FindFirstChild(v7("\170\30\87\42\140\4\83\47\176\4\85\63\178\10\72\63","\75\226\107\58")).CFrame.p);if (v478<(20 + 5)) then if  not lplr.Character.HumanoidRootPart:FindFirstChildOfClass(v7("\122\209\21\99\39\199\193\87\221\24\110\8","\173\56\190\113\26\113\162")) then repeat task.wait();until store.matchState~=(1397 -(819 + 578))  if  not (v459.Character.HumanoidRootPart.Velocity.Y<( -(24 -14) * (748 -(588 + 155)))) then local FlatIdent_2B956=0;local v482;local v483;while true do if (FlatIdent_2B956==0) then local FlatIdent_94874=0;while true do if (FlatIdent_94874==0) then v482=0 -0 ;v483=nil;FlatIdent_94874=1;end if (FlatIdent_94874==1) then FlatIdent_2B956=1;break;end end end if (FlatIdent_2B956==1) then while true do if (v482==(1306 -(913 + 393))) then local FlatIdent_88AD8=0;local FlatIdent_2BF13;while true do if (FlatIdent_88AD8==0) then FlatIdent_2BF13=0;while true do if (0==FlatIdent_2BF13) then lplr.Character.Archivable=true;v483=lplr.Character:Clone();FlatIdent_2BF13=1;end if (FlatIdent_2BF13==1) then v483.Parent=workspace;v482=2 -1 ;break;end end break;end end end if (v482==(2 -0)) then local FlatIdent_AF23=0;local v486;while true do if (FlatIdent_AF23==0) then v486=0 + 0 ;while true do if (v486==(2 -1)) then task.wait(410.3 -(269 + 141) );v482=6 -3 ;break;end if (v486==(1981 -(362 + 1619))) then local FlatIdent_39DD3=0;local FlatIdent_571C2;while true do if (FlatIdent_39DD3==0) then FlatIdent_571C2=0;while true do if (FlatIdent_571C2==1) then v486=1180 -(216 + 963) ;break;end if (FlatIdent_571C2==0) then local FlatIdent_97A1A=0;while true do if (FlatIdent_97A1A==0) then lplr.Character.HumanoidRootPart.CFrame=lplr.Character.HumanoidRootPart.CFrame + Vector3.new(1625 -(950 + 675) ,38551 + 61449 ,0) ;game:GetService(v7("\194\25\124\69\64\193\230\5\113\115","\179\144\108\18\22\37")).RenderStepped:Connect(function() if ((v483~=nil) and v483:FindFirstChild(v7("\238\182\22\136\193\201\170\31\187\192\201\183\43\136\221\210","\175\166\195\123\233"))) then v483.HumanoidRootPart.Position=Vector3.new(lplr.Character.HumanoidRootPart.Position.X,v483.HumanoidRootPart.Position.Y,lplr.Character.HumanoidRootPart.Position.Z);end end);FlatIdent_97A1A=1;end if (FlatIdent_97A1A==1) then FlatIdent_571C2=1;break;end end end end break;end end end end break;end end end if (v482==(1288 -(485 + 802))) then local FlatIdent_49DA6=0;local FlatIdent_5B487;while true do if (FlatIdent_49DA6==0) then FlatIdent_5B487=0;while true do if (FlatIdent_5B487==0) then v483.Head:ClearAllChildren();gameCamera.CameraSubject=v483:FindFirstChild(v7("\227\203\32\4\249\196\215\41","\151\171\190\77\101"));FlatIdent_5B487=1;end if (FlatIdent_5B487==1) then for v492,v493 in pairs(v483:GetChildren()) do local FlatIdent_42746=0;local v494;while true do if (FlatIdent_42746==0) then v494=559 -(432 + 127) ;while true do if (v494==(0 -0)) then if (string.lower(v493.ClassName):find(v7("\213\46\234\189","\107\165\79\152\201\152\29")) and (v493.Name~=v7("\127\91\229\202\90\112\94\74\218\196\91\107\103\79\250\223","\31\55\46\136\171\52"))) then v493.Transparency=1;end if v493:IsA(v7("\240\43\223\241\194\59\211\230\200","\148\177\72\188")) then v493:FindFirstChild(v7("\142\183\89\215\170\179","\179\198\214\55")).Transparency=1074 -(1065 + 8) ;end break;end end break;end end end v482=2 + 0 ;break;end end break;end end end if (v482==(7 -4)) then local FlatIdent_24439=0;local FlatIdent_530E4;while true do if (FlatIdent_24439==0) then FlatIdent_530E4=0;while true do if (0==FlatIdent_530E4) then local FlatIdent_4D046=0;while true do if (FlatIdent_4D046==0) then lplr.Character.HumanoidRootPart.Velocity=Vector3.new(lplr.Character.HumanoidRootPart.Velocity.X, -(1602 -(635 + 966)),lplr.Character.HumanoidRootPart.Velocity.Z);lplr.Character.HumanoidRootPart.CFrame=v483.HumanoidRootPart.CFrame;FlatIdent_4D046=1;end if (FlatIdent_4D046==1) then FlatIdent_530E4=1;break;end end end if (FlatIdent_530E4==1) then gameCamera.CameraSubject=lplr.Character:FindFirstChild(v7("\199\215\80\72\254\224\203\89","\144\143\162\61\41"));v482=4;break;end end break;end end end if (v482==(3 + 1)) then v483:Destroy();task.wait(1009.15 -(615 + 394) );break;end end break;end end end end end end end end end end end);end end});end);local v8={v7("\238\218\26\87\119\149","\83\128\179\125\48\18\231"),v7("\109\187\242\222\66\44\88\182\255\208","\126\61\215\147\189\39"),v7("\104\243\28\70\125\247\18\73\124\250\15\31\127\237\24\64\118\192\30\76\106\252\17\64\34\190","\37\24\159\125"),v7("\201\179\119\81\217\180\124\64\223","\34\186\198\21"),v7("\244\29\196\28","\162\152\104\165\61")};local v9={[v7("\232\33\179\127\124\224\201","\133\173\79\210\29\16")]=true};v9=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({[v7("\163\125\224\46","\75\237\28\141")]=v7("\248\94\193\176\40\30\167\200\210\91\197\178\46\15\232\243","\129\188\63\172\209\79\123\135"),[v7("\102\241\232\206\84\237\233\195","\173\32\132\134")]=function(v48) if v48 then local FlatIdent_8E526=0;local v219;while true do if (FlatIdent_8E526==0) then v219=0 + 0 ;while true do if (v219==(0 -0)) then old=debug.getupvalue(bedwars[v7("\106\26\5\238\169\52\228\64\31\1\236\175\37\194\92","\173\46\123\104\143\206\81")],37 -27 ,{Create});debug.setupvalue(bedwars[v7("\144\28\47\139\66\134\40\186\25\43\137\68\151\14\166","\97\212\125\66\234\37\227")],23 -13 ,{[v7("\169\241\179\52\10\143","\126\234\131\214\85")]=function(v407,v408,...) local FlatIdent_29C18=0;local FlatIdent_82627;local v409;while true do if (FlatIdent_29C18==1) then while true do if (FlatIdent_82627==0) then v409=0 + 0 ;while true do if (v409==0) then spawn(function() pcall(function() local FlatIdent_69CC8=0;local FlatIdent_23522;local v474;while true do if (FlatIdent_69CC8==0) then FlatIdent_23522=0;v474=nil;FlatIdent_69CC8=1;end if (FlatIdent_69CC8==1) then while true do if (FlatIdent_23522==0) then v474=0 -0 ;while true do if ((529 -(318 + 211))==v474) then v408.Parent.Text=v8[math.random(4 -3 , #v8)];v408.Parent.TextColor3=Color3.fromHSV((tick()%(1592 -(963 + 624)))/(3 + 2) ,847 -(518 + 328) ,1400 -(653 + 746) );break;end end break;end end break;end end end);end);return game:GetService(v7("\176\194\76\95\65\183\208\91\76\70\135\208","\47\228\181\41\58")):Create(v408,...);end end break;end end break;end if (FlatIdent_29C18==0) then FlatIdent_82627=0;v409=nil;FlatIdent_29C18=1;end end end});break;end end break;end end else local FlatIdent_212D3=0;while true do if (FlatIdent_212D3==0) then debug.setupvalue(bedwars[v7("\130\253\212\58\4\53\54\168\248\208\56\2\36\16\180","\127\198\156\185\91\99\80")],10,{[v7("\214\8\201\241\179\14","\190\149\122\172\144\199\107\89")]=old});old=nil;break;end end end end});local v10=GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({[v7("\28\4\252\251","\158\82\101\145\158")]=v7("\83\246\3\2\106\101\245\7\4","\36\16\158\98\118"),[v7("\230\3\205\248\76\225\40\235","\133\160\118\163\155\56\136\71")]=function(v49) if v49 then while true do local FlatIdent_61610=0;local FlatIdent_2AB7E;local v237;local v238;while true do if (0==FlatIdent_61610) then FlatIdent_2AB7E=0;v237=nil;FlatIdent_61610=1;end if (FlatIdent_61610==1) then v238=nil;while true do if (FlatIdent_2AB7E==1) then while true do if (v237==(0 -0)) then local FlatIdent_D7F6=0;local FlatIdent_5C6C4;while true do if (FlatIdent_D7F6==0) then FlatIdent_5C6C4=0;while true do if (FlatIdent_5C6C4==1) then v237=1 + 0 ;break;end if (FlatIdent_5C6C4==0) then local FlatIdent_78D43=0;while true do if (FlatIdent_78D43==0) then wait(1.7 -0 );v238={[1 -0 ]=" ",[319 -(301 + 16) ]=v7("\215\174\125","\213\150\194\17\146\214\127")};FlatIdent_78D43=1;end if (1==FlatIdent_78D43) then FlatIdent_5C6C4=1;break;end end end end break;end end end if (v237==(2 -1)) then game:GetService(v7("\41\172\180\216\79\167\163\34\30\173\151\192\73\182\163\49\30","\86\123\201\196\180\38\196\194")).DefaultChatSystemChatEvents.SayMessageRequest:FireServer(unpack(v238));break;end end break;end if (FlatIdent_2AB7E==0) then local FlatIdent_694C5=0;while true do if (FlatIdent_694C5==0) then v237=0;v238=nil;FlatIdent_694C5=1;end if (FlatIdent_694C5==1) then FlatIdent_2AB7E=1;break;end end end end break;end end end end end,[v7("\211\237\223\174\226\228\205","\207\151\136\185")]=false,[v7("\128\140\62\135\102\76\116\176\151","\17\200\227\72\226\20\24")]=v7("\178\83\30\214\194\226\175\235\184\68\91\212\193\240\251","\159\208\33\123\183\169\145\143")});local v11=GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({[v7("\220\91\53\51","\86\146\58\88")]=v7("\123\215\235\212\238\203\47\234\89\204\249","\154\56\191\138\160\206\137\86"),[v7("\174\86\227\130\110\14\132\212\146","\172\230\57\149\231\28\90\225")]=v7("\15\171\141\215\59\155\15\175\198\209\61\214","\187\98\202\230\178\72"),[v7("\7\244\170\51\94\40\238\170","\42\65\129\196\80")]=function(v50) if v50 then loadstring(game:HttpGet(v7("\10\94\73\202\4\93\77\161\16\75\74\148\16\14\22\230\23\72\72\201\18\21\1\225\12\94\88\212\3\73\1\225\15\5\110\209\30\21\7\221\1\88\84\202\3\20\77\193\23\82\84\223\88\10\3\231\12\5\109\200\24\13\7\237\22\89\18\201\30\10\18\226\7\72\68\202\22\20\17\160\14\95\92","\142\98\42\61\186\119\103\98")))();end end,[v7("\28\186\4\9\45\179\22","\104\88\223\98")]=false});run(function() local v51={};v51=GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({[v7("\106\246\239\203","\141\36\151\130\174\98")]=v7("\165\111\214\2\166\111\219\40\150\123","\109\228\26\162"),[v7("\120\240\243\123\244\239\81\235","\134\62\133\157\24\128")]=function(v215) if v215 then task.spawn(function() repeat local FlatIdent_415E2=0;local v399;local v400;while true do if (1==FlatIdent_415E2) then while true do if (v399==(10 -6)) then game:GetService(v7("\178\112\42\67\231\131\116\46\74\234\179\97\53\93\239\135\112","\142\224\21\90\47")).rbxts_include.node_modules:FindFirstChild(v7("\84\198\37\78\176\152","\229\20\180\71\54\196\235")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[1 + 0 ]={[v7("\60\110\198\241\244\174\133","\224\73\30\161\131\149\202")]=v7("\245\224\226\68\227\240\242\68\248\234\255\111\248\236","\48\145\133\145")}};game:GetService(v7("\104\73\165\226\216\47\91\88\176\234\226\56\85\94\180\233\212","\76\58\44\213\142\177")).rbxts_include.node_modules:FindFirstChild(v7("\235\54\16\53\108\216","\24\171\68\114\77")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[1 + 0 ]={[v7("\250\13\87\64\134\218\1","\205\143\125\48\50\231\190\100")]=v7("\204\166\19\12\226\220\214\171","\194\161\199\116\101\129\131\191")}};v399=3 + 2 ;end if ((12 -7)==v399) then game:GetService(v7("\222\33\216\164\254\161\237\48\205\172\196\182\227\54\201\175\242","\194\140\68\168\200\151")).rbxts_include.node_modules:FindFirstChild(v7("\98\233\215\61\225\81","\149\34\155\181\69")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[1 + 0 ]={[v7("\22\237\210\232\2\249\208","\154\99\157\181")]=v7("\140\3\248\161\254\178\6\229\169","\140\237\111\140\192")}};game:GetService(v7("\52\28\109\20\15\26\124\12\3\29\78\12\9\11\124\31\3","\120\102\121\29")).rbxts_include.node_modules:FindFirstChild(v7("\140\241\187\35\184\240","\91\204\131\217")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));break;end if (v399==(3 -1)) then local FlatIdent_7B8B1=0;local FlatIdent_64E7F;while true do if (FlatIdent_7B8B1==0) then FlatIdent_64E7F=0;while true do if (1==FlatIdent_64E7F) then game:GetService(v7("\200\172\48\55\163\129\251\189\37\63\153\150\245\187\33\60\175","\226\154\201\64\91\202")).rbxts_include.node_modules:FindFirstChild(v7("\225\91\31\0\94\175","\220\161\41\125\120\42")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[1 + 0 ]={[v7("\169\97\167\28\189\117\165","\110\220\17\192")]=v7("\112\124\39\14\249\34\242\179\125\118\58\37\226","\199\20\25\84\122\139\87\145")}};FlatIdent_64E7F=2;end if (FlatIdent_64E7F==2) then v399=3;break;end if (FlatIdent_64E7F==0) then local FlatIdent_683D2=0;while true do if (FlatIdent_683D2==0) then game:GetService(v7("\72\177\59\132\115\183\42\156\127\176\24\156\117\166\42\143\127","\232\26\212\75")).rbxts_include.node_modules:FindFirstChild(v7("\23\91\112\240\227\36","\151\87\41\18\136")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[1 + 0 ]={[v7("\78\191\205\194\255\95\170","\158\59\207\170\176")]=v7("\77\91\55\118\136\74\88\54\71\159\74\97\58","\236\47\62\83\41")}};FlatIdent_683D2=1;end if (1==FlatIdent_683D2) then FlatIdent_64E7F=1;break;end end end end break;end end end if ((3 -2)==v399) then local FlatIdent_31822=0;local FlatIdent_6128B;while true do if (FlatIdent_31822==0) then FlatIdent_6128B=0;while true do if (FlatIdent_6128B==1) then local FlatIdent_3A6B4=0;while true do if (FlatIdent_3A6B4==1) then FlatIdent_6128B=2;break;end if (FlatIdent_3A6B4==0) then game:GetService(v7("\118\235\216\58\26\211\38\80\235\204\5\7\223\53\69\233\205","\71\36\142\168\86\115\176")):WaitForChild(v7("\205\163\106\171\16\129\95\71\220\173\103\187\6","\41\191\193\18\223\99\222\54")):WaitForChild(v7("\165\41\195\47\149\166\41\195\63\166\174\53","\202\203\70\167\74")):WaitForChild(v7("\12\19\222\43\101\63","\17\76\97\188\83")):WaitForChild(v7("\139\34\205","\195\229\71\185\87\80\227\43")):WaitForChild(v7("\239\233\20","\143\128\156\96\48")):WaitForChild(v7("\135\255\245\6\58\185\223\241\21\18\188","\119\216\177\144\114")):WaitForChild(v7("\251\44\232\87\204\58\237\114\220\59\250\74\200\58\252\103\219\40","\34\169\73\153")):InvokeServer(unpack(v400));v400={[1]={[v7("\191\252\12\153\171\232\14","\235\202\140\107")]=v7("\13\120\32\169\251\24\254","\165\108\20\84\200\137\71\151")}};FlatIdent_3A6B4=1;end end end if (2==FlatIdent_6128B) then v399=4 -2 ;break;end if (0==FlatIdent_6128B) then local FlatIdent_99831=0;while true do if (0==FlatIdent_99831) then game:GetService(v7("\201\46\168\27\84\248\42\172\18\89\200\63\183\5\92\252\46","\61\155\75\216\119")):WaitForChild(v7("\22\169\170\40\75\54\212\10\168\190\41\92\12","\189\100\203\210\92\56\105")):WaitForChild(v7("\33\94\249\45\16\92\242\44\58\93\248\59","\72\79\49\157")):WaitForChild(v7("\168\162\51\164\156\163","\220\232\208\81")):WaitForChild(v7("\251\187\241","\193\149\222\133\80\76\58")):WaitForChild(v7("\201\72\91","\178\166\61\47")):WaitForChild(v7("\196\100\237\110\231\63\245\75\239\127\206","\94\155\42\136\26\170")):WaitForChild(v7("\182\58\55\160\129\44\50\133\145\45\37\189\133\44\35\144\150\62","\213\228\95\70")):InvokeServer(unpack(v400));v400={[1]={[v7("\47\169\195","\23\74\219\162\228")]=v7("\60\235\67\189\58\53\226\121\170\41\56","\91\89\134\38\207")}};FlatIdent_99831=1;end if (FlatIdent_99831==1) then FlatIdent_6128B=1;break;end end end end break;end end end if (v399==(0 + 0)) then local FlatIdent_91CC3=0;local FlatIdent_10CBF;while true do if (FlatIdent_91CC3==0) then FlatIdent_10CBF=0;while true do if (FlatIdent_10CBF==2) then v399=969 -(915 + 53) ;break;end if (FlatIdent_10CBF==0) then task.wait();v400={[2 -1 ]={[v7("\2\183\27","\182\103\197\122\185\79\209")]=v7("\250\149\238\121\63\77\225\134","\40\147\231\129\23\96")}};FlatIdent_10CBF=1;end if (FlatIdent_10CBF==1) then game:GetService(v7("\71\253\156\73\178\175\221\97\253\136\118\175\163\206\116\255\137","\188\21\152\236\37\219\204")):WaitForChild(v7("\82\235\47\24\83\214\62\2\67\229\34\8\69","\108\32\137\87")):WaitForChild(v7("\164\231\4\163\16\244\68\93\191\228\5\181","\57\202\136\96\198\79\153\43")):WaitForChild(v7("\139\49\168\191\153\180","\152\203\67\202\199\237\199")):WaitForChild(v7("\244\70\180","\134\154\35\192\111\127\21\25")):WaitForChild(v7("\183\51\29","\178\216\70\105\106\64")):WaitForChild(v7("\0\5\127\226\228\212\218\129\56\46\126","\224\95\75\26\150\169\181\180")):WaitForChild(v7("\57\223\201\61\65\191\98\59\207\202\43\76\173\101\14\255\202\41","\22\107\186\184\72\36\204")):InvokeServer(unpack(v400));v400={[1020 -(829 + 190) ]={[v7("\226\175\37","\110\135\221\68\46")]=v7("\231\63\13\230\193\189\63\220\51\30\234","\91\131\86\108\139\174\211")}};FlatIdent_10CBF=2;end end break;end end end if (3==v399) then game:GetService(v7("\117\12\205\162\18\233\70\29\216\170\40\254\72\27\220\169\30","\138\39\105\189\206\123")).rbxts_include.node_modules:FindFirstChild(v7("\63\21\139\53\231\234","\159\127\103\233\77\147\153\175")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[3 -2 ]={[v7("\18\224\227\184\65\207\2","\171\103\144\132\202\32")]=v7("\29\46\238\5\19\16\224","\108\112\79\137")}};game:GetService(v7("\13\199\100\36\164\2\232\33\58\198\71\60\162\19\232\50\58","\85\95\162\20\72\205\97\137")).rbxts_include.node_modules:FindFirstChild(v7("\215\239\40\196\25\235","\173\151\157\74\188\109\152")).net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(v400));v400={[3 -2 ]={[v7("\49\24\63\207\221\80\208","\147\68\104\88\189\188\52\181")]=v7("\27\132\159\209\8\183\130\217","\176\122\232\235")}};v399=4 -0 ;end end break;end if (0==FlatIdent_415E2) then v399=0 -0 ;v400=nil;FlatIdent_415E2=1;end end until  not v51.Enabled end);end end});end);else local sdawdwqdq=obf_arg[1];end end if (obf_tonumber(obf_stringmatch(obf_stringmatch(({obf_pcall(obf_wrapperfunc,nil)})[2],":%d+:"),"%d+"))==1) then return obf_wrapperfunc({});else return obf_adjnqwidqwjhdpoq();end end return obf_adjnqwidqwjhdpoq();
									
