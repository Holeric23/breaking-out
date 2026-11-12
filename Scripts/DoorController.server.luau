-- Each door contains its own controller so the asset can be copied on its own.
local TweenService = game:GetService("TweenService")

local door = script.Parent
local control = door:WaitForChild("DoorControl")
local prompt = control:WaitForChild("DoorPrompt")
local travel = control:WaitForChild("TravelDistance").Value
local isDouble = control:WaitForChild("DoubleDoor").Value
local centerOffset = control:WaitForChild("CenterOffset").Value
local axis = control.CFrame.RightVector
local center = control.Position - axis * centerOffset
local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local pieces = {}
for _, instance in ipairs(door:GetDescendants()) do
	if instance:IsA("BasePart") and instance ~= control then
		instance.Anchored = true
		local direction = -1
		if isDouble and (instance.Position - center):Dot(axis) >= 0 then
			direction = 1
		end
		table.insert(pieces, {part = instance, closed = instance.CFrame, direction = direction})
	elseif instance:IsA("WeldConstraint") or instance:IsA("JointInstance") then
		-- Parts are anchored and moved together. A joint between two leaves of
		-- a double door must not prevent them from moving in opposite directions.
		instance.Enabled = false
	end
end
control.Anchored = true
local closedControl = control.CFrame
local isOpen = false
local moving = false

prompt.Triggered:Connect(function()
	if moving then
		return
	end
	moving = true
	prompt.Enabled = false
	local shouldOpen = not isOpen

	for _, entry in ipairs(pieces) do
		local offset = if shouldOpen then axis * travel * entry.direction else Vector3.zero
		TweenService:Create(entry.part, tweenInfo, {CFrame = entry.closed + offset}):Play()
	end

	-- The prompt lives on this invisible part and follows the left leaf.
	local controlOffset = if shouldOpen then -axis * travel else Vector3.zero
	local controlTween = TweenService:Create(control, tweenInfo, {CFrame = closedControl + controlOffset})
	controlTween:Play()
	controlTween.Completed:Wait()

	isOpen = shouldOpen
	prompt.ActionText = if isOpen then "Закрыть" else "Открыть"
	prompt.Enabled = true
	moving = false
end)
