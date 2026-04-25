local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- CONFIGURATION
-- ==========================================
local CONFIG = {
	CAMERA_OFFSET = Vector3.new(2, 2, 8), -- X: Right bias, Y: Height, Z: Zoom distance
	SENSITIVITY_PC = 0.2,
	SENSITIVITY_MOBILE = 0.5,             -- INCREASED: Adjust this for faster/slower mobile swipe
	PITCH_LIMIT = 80,                     -- Max up/down camera angle (degrees)
	TOUCH_ZONE_RATIO = 0.5,               -- 0.5 means the right 50% of screen handles rotation
	ALIGN_CHAR_WITH_CAMERA = true         -- Character always faces camera direction
}

-- ==========================================
-- VARIABLES
-- ==========================================
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cameraAngleX = 0
local cameraAngleY = 0
local activeTouchID = nil

-- Check if device relies purely on touch
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Initialize Mouse for PC
if not isMobile then
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

-- ==========================================
-- INPUT HANDLING
-- ==========================================

-- 1. Handle touch start (Mobile only)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Touch then
		local screenWidth = camera.ViewportSize.X

		-- Only register touch on the defined right side of the screen, ignoring UI
		if input.Position.X > (screenWidth * CONFIG.TOUCH_ZONE_RATIO) and not gameProcessed then
			activeTouchID = input
		end
	end
end)

-- 2. Handle camera rotation (PC & Mobile)
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	-- PC: Mouse Movement
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		cameraAngleX -= input.Delta.X * CONFIG.SENSITIVITY_PC
		cameraAngleY = math.clamp(cameraAngleY - (input.Delta.Y * CONFIG.SENSITIVITY_PC), -CONFIG.PITCH_LIMIT, CONFIG.PITCH_LIMIT)

		-- Mobile: Touch Swipe
	elseif input.UserInputType == Enum.UserInputType.Touch then
		if input == activeTouchID then
			cameraAngleX -= input.Delta.X * CONFIG.SENSITIVITY_MOBILE
			cameraAngleY = math.clamp(cameraAngleY - (input.Delta.Y * CONFIG.SENSITIVITY_MOBILE), -CONFIG.PITCH_LIMIT, CONFIG.PITCH_LIMIT)
		end
	end
end)

-- 3. Handle touch end (Mobile only)
UserInputService.InputEnded:Connect(function(input)
	if input == activeTouchID then
		activeTouchID = nil -- Clear the active touch tracking
	end
end)

-- ==========================================
-- CAMERA UPDATE LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	-- Stop updating if dead or missing parts
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	-- Enforce custom camera control
	camera.CameraType = Enum.CameraType.Scriptable

	-- Calculate new Camera CFrame
	local startCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(cameraAngleX), 0) * CFrame.Angles(math.rad(cameraAngleY), 0, 0)
	local cameraCFrame = startCFrame:ToWorldSpace(CFrame.new(CONFIG.CAMERA_OFFSET))

	-- Apply CFrame
	camera.CFrame = cameraCFrame

	-- Force Character to align with camera look direction
	if CONFIG.ALIGN_CHAR_WITH_CAMERA then
		-- Modify only the Y-axis rotation so the character doesn't tilt up/down
		rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + startCFrame.LookVector * Vector3.new(1, 0, 1))
	end
end)