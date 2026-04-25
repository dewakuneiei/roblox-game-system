-- CameraController (LocalScript)
-- Third-person over-shoulder camera with center-screen aim alignment

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- CONFIG
-- ==========================================
local CONFIG = {
	CAMERA_OFFSET    = Vector3.new(2, 2, 8), -- Shoulder offset (X: side, Y: height, Z: zoom)
	CENTER_OFFSET    = Vector2.new(8, 0),  -- Aim point offset from screen center (pixels)
	SENSITIVITY_PC   = 0.2,
	SENSITIVITY_MOBILE = 0.5,
	PITCH_LIMIT      = 80,                   -- Max vertical look angle (degrees)
	TOUCH_ZONE_RATIO = 0.5,                  -- Right % of screen used for camera swipe
	ALIGN_CHAR_WITH_CAMERA = true,           -- Character body follows aim direction
}

-- ==========================================
-- STATE
-- ==========================================
local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

local angleX      = 0
local angleY      = 0
local activeTouchID  = nil
local isLookingBack  = false

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
if not isMobile then
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

-- ==========================================
-- INPUT
-- ==========================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.V then
		isLookingBack = true
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		local rightZone = camera.ViewportSize.X * CONFIG.TOUCH_ZONE_RATIO
		if input.Position.X > rightZone then
			activeTouchID = input
		end
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		angleX -= input.Delta.X * CONFIG.SENSITIVITY_PC
		angleY  = math.clamp(angleY - input.Delta.Y * CONFIG.SENSITIVITY_PC, -CONFIG.PITCH_LIMIT, CONFIG.PITCH_LIMIT)

	elseif input.UserInputType == Enum.UserInputType.Touch and input == activeTouchID then
		angleX -= input.Delta.X * CONFIG.SENSITIVITY_MOBILE
		angleY  = math.clamp(angleY - input.Delta.Y * CONFIG.SENSITIVITY_MOBILE, -CONFIG.PITCH_LIMIT, CONFIG.PITCH_LIMIT)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.V       then isLookingBack = false end
	if input == activeTouchID                then activeTouchID  = nil   end
end)

-- ==========================================
-- CAMERA LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end

	local root     = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Base rotation from camera angles
	local baseRotation = CFrame.new(root.Position)
		* CFrame.Angles(0, math.rad(angleX), 0)
		* CFrame.Angles(math.rad(angleY), 0, 0)

	-- Camera position: peek front (V) or normal shoulder view
	if isLookingBack then
		local frontRotation = CFrame.new(root.Position)
			* CFrame.Angles(0, math.rad(angleX + 180), 0)
			* CFrame.Angles(math.rad(angleY), 0, 0)
		camera.CFrame = frontRotation * CFrame.new(CONFIG.CAMERA_OFFSET)
	else
		camera.CFrame = baseRotation * CFrame.new(CONFIG.CAMERA_OFFSET)
	end

	-- Align character body to aim direction
	if CONFIG.ALIGN_CHAR_WITH_CAMERA then
		if isLookingBack then
			-- Hold character facing forward while peeking
			local dir = baseRotation.LookVector * Vector3.new(1, 0, 1)
			root.CFrame = CFrame.new(root.Position, root.Position + dir)
		else
			-- Rotate character toward center of screen (accounts for shoulder offset)
			local viewport = camera.ViewportSize
			local aimPoint = Vector2.new(
				viewport.X / 2 + CONFIG.CENTER_OFFSET.X,
				viewport.Y / 2 + CONFIG.CENTER_OFFSET.Y
			)
			local aimRay = camera:ViewportPointToRay(aimPoint.X, aimPoint.Y)
			local aimDir = Vector3.new(aimRay.Direction.X, 0, aimRay.Direction.Z).Unit
			root.CFrame = CFrame.new(root.Position, root.Position + aimDir)
		end
	end
end)