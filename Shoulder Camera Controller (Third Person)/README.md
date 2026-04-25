# CameraController

Third-person over-shoulder camera for Roblox with center-screen aim alignment and front-peek support.

---

## Installation

1. Open **Roblox Studio**
2. In the **Explorer** panel, navigate to:
   
   ```
   StarterPlayer > StarterPlayerScripts
   ```
3. Right-click `StarterPlayerScripts` → **Insert Object** → select `LocalScript`
4. Rename the script to `CameraController`
5. Paste the full script code inside

---

## Configuration

All settings are at the top of the script inside the `CONFIG` table.

```lua
local CONFIG = {
    CAMERA_OFFSET          = Vector3.new(2, 2, 8),
    CENTER_OFFSET          = Vector2.new(150, 0),
    SENSITIVITY_PC         = 0.2,
    SENSITIVITY_MOBILE     = 0.5,
    PITCH_LIMIT            = 80,
    TOUCH_ZONE_RATIO       = 0.5,
    ALIGN_CHAR_WITH_CAMERA = true,
}
```

| Property                 | Type      | Description                                                                             |
| ------------------------ | --------- | --------------------------------------------------------------------------------------- |
| `CAMERA_OFFSET`          | `Vector3` | Shoulder position offset. `X` = side, `Y` = height, `Z` = zoom distance                 |
| `CENTER_OFFSET`          | `Vector2` | Shifts the aim point from true screen center in pixels. `X` = left/right, `Y` = up/down |
| `SENSITIVITY_PC`         | `number`  | Mouse sensitivity                                                                       |
| `SENSITIVITY_MOBILE`     | `number`  | Touch swipe sensitivity                                                                 |
| `PITCH_LIMIT`            | `number`  | Max vertical look angle in degrees                                                      |
| `TOUCH_ZONE_RATIO`       | `number`  | Fraction of screen width used for camera swipe on mobile. `0.5` = right 50%             |
| `ALIGN_CHAR_WITH_CAMERA` | `bool`    | If `true`, character body rotates to face the aim direction                             |

---

## Controls

| Input            | Action                     |
| ---------------- | -------------------------- |
| Mouse move       | Rotate camera (PC)         |
| Right-side swipe | Rotate camera (Mobile)     |
| Hold `V`         | Peek at front of character |

---

## Tuning Tips

### Aim not centered?

Adjust `CENTER_OFFSET.X` to shift aim left or right until it lines up with your crosshair.

```lua
CENTER_OFFSET = Vector2.new(150, 0)  -- shift aim right by 150px
CENTER_OFFSET = Vector2.new(-50, 0)  -- shift aim left by 50px
```

### Change camera shoulder side

Set `CAMERA_OFFSET.X` negative to move camera to the left shoulder.

```lua
CAMERA_OFFSET = Vector3.new(-2, 2, 8)  -- left shoulder
CAMERA_OFFSET = Vector3.new(2, 2, 8)   -- right shoulder
```

### Zoom in or out

Change `CAMERA_OFFSET.Z`.

```lua
CAMERA_OFFSET = Vector3.new(2, 2, 5)   -- closer
CAMERA_OFFSET = Vector3.new(2, 2, 12)  -- further
```

---

## Notes

- This script **disables the default Roblox camera** by setting `CameraType = Scriptable`
- Works on both **PC and Mobile**
- Place only inside `StarterPlayerScripts` — not `StarterCharacterScripts`
