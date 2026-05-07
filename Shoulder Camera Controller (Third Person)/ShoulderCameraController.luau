-- ============================================================
-- CameraController (LocalScript)
-- Third-person over-shoulder camera with:
--   • Center-screen aim alignment
--   • Wall collision zoom (pulls camera in when blocked)
--   • Look-back (V key) and mobile touch support
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
	-- Camera positioning
	CAMERA_OFFSET    = Vector3.new(2, 2.5, 10),  -- X: side offset | Y: height | Z: max zoom distance
	CENTER_OFFSET    = Vector2.new(2, 0),          -- Aim-point shift from screen center (pixels)

	-- Sensitivity
	SENSITIVITY_PC     = 0.2,
	SENSITIVITY_MOBILE = 0.5,

	-- Vertical look clamp (degrees)
	PITCH_LIMIT = 80,

	-- Mobile: right portion of screen used for camera swipe (0–1)
	TOUCH_ZONE_RATIO = 0.5,

	-- When true, character body rotates to match aim direction
	ALIGN_CHAR_WITH_CAMERA = true,

	-- Collision
	COLLISION_PULL_BACK = 0.3,  -- Studs to pull away from the wall surface
}

-- ============================================================
-- REFERENCES & STATE
-- ============================================================
local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

local angleX        = 0      -- Yaw  (horizontal rotation, degrees)
local angleY        = 0      -- Pitch (vertical rotation,   degrees)
local activeTouchID = nil    -- Tracks the active camera-swipe touch
local isLookingBack = false  -- True while V is held

-- Lock mouse on PC
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
if not isMobile then
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

-- Shared RaycastParams for wall collision (filtered per frame)
local collisionParams = RaycastParams.new()
collisionParams.FilterType = Enum.RaycastFilterType.Exclude

-- ============================================================
-- INPUT HANDLING
-- ============================================================

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Look-back toggle
	if input.KeyCode == Enum.KeyCode.V then
		isLookingBack = true
	end

	-- Capture the first touch that lands in the right-side camera zone
	if input.UserInputType == Enum.UserInputType.Touch then
		local rightZoneStart = camera.ViewportSize.X * CONFIG.TOUCH_ZONE_RATIO
		if input.Position.X > rightZoneStart and activeTouchID == nil then
			activeTouchID = input
		end
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	-- PC mouse delta
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		angleX = angleX - input.Delta.X * CONFIG.SENSITIVITY_PC
		angleY = math.clamp(
			angleY - input.Delta.Y * CONFIG.SENSITIVITY_PC,
			-CONFIG.PITCH_LIMIT,
			CONFIG.PITCH_LIMIT
		)

		-- Mobile swipe delta (only for the tracked camera touch)
	elseif input.UserInputType == Enum.UserInputType.Touch and input == activeTouchID then
		angleX = angleX - input.Delta.X * CONFIG.SENSITIVITY_MOBILE
		angleY = math.clamp(
			angleY - input.Delta.Y * CONFIG.SENSITIVITY_MOBILE,
			-CONFIG.PITCH_LIMIT,
			CONFIG.PITCH_LIMIT
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.V then isLookingBack = false end
	if input == activeTouchID            then activeTouchID  = nil   end
end)

-- ============================================================
-- HELPERS
-- ============================================================

--- Builds the base camera CFrame from current yaw/pitch angles.
-- @param rootPos  Vector3  world position of HumanoidRootPart
-- @param yawDeg   number   horizontal angle in degrees
-- @param pitchDeg number   vertical angle in degrees
-- @return CFrame
local function buildBaseRotation(rootPos, yawDeg, pitchDeg)
	return CFrame.new(rootPos)
		* CFrame.Angles(0, math.rad(yawDeg), 0)
		* CFrame.Angles(math.rad(pitchDeg), 0, 0)
end

--- Casts a ray from the shoulder origin toward the desired camera position.
-- If the ray hits a wall, the camera is pulled back to the hit surface
-- plus a small COLLISION_PULL_BACK buffer so it never clips through.
-- @param desiredCF  CFrame    the uncollided camera CFrame
-- @param character  Model     the player character (excluded from raycast)
-- @return CFrame  safe camera CFrame (may be closer than desired)
local function applyWallCollision(desiredCF, rootPos, character)
	-- Cast from shoulder height, not ground, for better accuracy
	local origin    = rootPos + Vector3.new(0, CONFIG.CAMERA_OFFSET.Y, 0)
	local targetPos = desiredCF.Position
	local direction = targetPos - origin

	collisionParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(origin, direction, collisionParams)

	if hit then
		-- Place camera just in front of the wall surface
		local safeDistance = math.max(0, (hit.Position - origin).Magnitude - CONFIG.COLLISION_PULL_BACK)
		local safePosition = origin + direction.Unit * safeDistance

		-- Preserve the original rotation, only move the position
		return CFrame.new(safePosition) * (desiredCF - desiredCF.Position)
	end

	return desiredCF  -- No obstruction; use original position
end

-- ============================================================
-- CAMERA LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end

	local root     = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Base rotation is always derived from the true camera angles
	local baseRotation = buildBaseRotation(root.Position, angleX, angleY)

	-- ── Desired (uncollided) camera position ──────────────────
	local desiredCF
	if isLookingBack then
		-- Flip yaw by 180° so we peek over the front shoulder
		local frontRotation = buildBaseRotation(root.Position, angleX + 180, angleY)
		desiredCF = frontRotation * CFrame.new(CONFIG.CAMERA_OFFSET)
	else
		desiredCF = baseRotation * CFrame.new(CONFIG.CAMERA_OFFSET)
	end

	-- ── Wall collision: zoom in if path is blocked ─────────────
	camera.CFrame = applyWallCollision(desiredCF, root.Position, character)

	-- ── Character body alignment ──────────────────────────────
	if CONFIG.ALIGN_CHAR_WITH_CAMERA then
		if isLookingBack then
			-- Keep character facing forward while peeking backward
			local forwardDir = baseRotation.LookVector * Vector3.new(1, 0, 1)
			root.CFrame = CFrame.new(root.Position, root.Position + forwardDir)
		else
			-- Rotate character toward the screen aim-point (corrects shoulder offset)
			local viewport  = camera.ViewportSize
			local aimScreen = Vector2.new(
				viewport.X / 2 + CONFIG.CENTER_OFFSET.X,
				viewport.Y / 2 + CONFIG.CENTER_OFFSET.Y
			)
			local aimRay = camera:ViewportPointToRay(aimScreen.X, aimScreen.Y)
			local aimDir = Vector3.new(aimRay.Direction.X, 0, aimRay.Direction.Z).Unit
			root.CFrame = CFrame.new(root.Position, root.Position + aimDir)
		end
	end
end)
