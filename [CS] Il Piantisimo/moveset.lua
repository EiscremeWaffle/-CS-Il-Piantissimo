-- This moveset requires Character Select and only runs for Monteman.
if not charSelectExists then return end
local enable_extended_moveset = true

------------------------------
-- Localize engine functions --
------------------------------

local allocate_mario_action, atan2s, sins, coss, mario_set_forward_vel, set_mario_action, queue_rumble_data_mario, play_mario_sound, play_sound, common_slide_action, play_mario_landing_sound_once, common_air_action_step, is_anim_at_end, update_sliding, mario_check_object_grab, mario_grab_used_object =
    allocate_mario_action, atan2s, sins, coss, mario_set_forward_vel, set_mario_action, queue_rumble_data_mario, play_mario_sound, play_sound, common_slide_action, play_mario_landing_sound_once, common_air_action_step, is_anim_at_end, update_sliding, mario_check_object_grab, mario_grab_used_object
local math_min, math_max, math_floor, math_abs = math.min, math.max, math.floor, math.abs
local ACT_AIR_KICK = rawget(_G, "ACT_AIR_KICK")
local ACT_GROUND_POUND_JUMP = rawget(_G, "ACT_GROUND_POUND_JUMP")
local ACT_WALL_SLIDE = rawget(_G, "ACT_WALL_SLIDE")
local ACT_WATER_GROUND_POUND = rawget(_G, "ACT_WATER_GROUND_POUND")
local ACT_SPIN_POUND_LAND = rawget(_G, "ACT_SPIN_POUND_LAND")
local ACT_WATER_GROUND_POUND_LAND = rawget(_G, "ACT_WATER_GROUND_POUND_LAND")
-- The dive slide is grounded, so its action callback does not apply gravity.
local function no_gravity()
    return 0
end

local ANGLE_QUEUE_SIZE = 9
local SPIN_TIMER_SUCCESSFUL_INPUT = 4
-- Custom actions used by the Monteman moveset.
local ACT_SPIN_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
local ACT_CUSTOM_DIVE_SLIDE = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_DIVING | ACT_FLAG_ATTACKING)

_G.ACT_SPIN_JUMP = ACT_SPIN_JUMP

local gMarioStateExtras = {}
for i = 0, MAX_PLAYERS - 1 do
    gMarioStateExtras[i] = {}
    local e = gMarioStateExtras[i]
    e.angleDeltaQueue = {}
    for j = 0, ANGLE_QUEUE_SIZE - 1 do
        e.angleDeltaQueue[j] = 0
    end
    e.rotAngle = 0
    e.stickLastAngle = 0
    e.spinDirection = 0
    e.spinBufferTimer = 0
    e.spinInput = 0
    e.lastIntendedMag = 0
    -- These fields temporarily replace pound-land actions for other systems.
    e.fakeSavedAction = 0
    e.fakeSavedPrevAction = 0
    e.fakeSavedActionTimer = 0
    e.fakeWroteAction = 0
    e.fakeSaved = false
end

local function limit_angle(a)
    return (a + 0x8000) % 0x10000 - 0x8000
end

-- Air kicks are reserved for input held mostly opposite Monteman's facing.
local function is_backward_air_kick(m)
    if (m.input & INPUT_NONZERO_ANALOG) == 0 then
        return false
    end

    local inputAngle = math_abs(limit_angle(m.intendedYaw - m.faceAngle.y))
    return inputAngle > 0x6000 and inputAngle < 0xA000
end

local lastAction = {}
local hasUsedAirDive = {}

----------------------------
-- Spin input and movement --
----------------------------

local function monteman_update_spin_input(m)
    local e = gMarioStateExtras[m.playerIndex]
    local rawAngle = atan2s(-m.controller.stickY, m.controller.stickX)
    e.spinInput = 0

    -- Ignore input that has just left the analog dead zone.
    if e.lastIntendedMag > 0.5 and m.intendedMag > 0.5 then
        local angleOverFrames = 0
        local thisFrameDelta = 0
        local newDirection = e.spinDirection
        local signedOverflow = 0

        if rawAngle < e.stickLastAngle then
            if e.stickLastAngle - rawAngle > 0x8000 then
                signedOverflow = 1
            end
            if signedOverflow ~= 0 then
                newDirection = 1
            else
                newDirection = -1
            end
        elseif rawAngle > e.stickLastAngle then
            if rawAngle - e.stickLastAngle > 0x8000 then
                signedOverflow = 1
            end
            if signedOverflow ~= 0 then
                newDirection = -1
            else
                newDirection = 1
            end
        end

        if e.spinDirection ~= newDirection then
            for i=0,(ANGLE_QUEUE_SIZE-1) do
                e.angleDeltaQueue[i] = 0
            end
            e.spinDirection = newDirection
        else
            for i=(ANGLE_QUEUE_SIZE-1),1,-1 do
                e.angleDeltaQueue[i] = e.angleDeltaQueue[i-1]
                angleOverFrames = angleOverFrames + e.angleDeltaQueue[i]
            end
        end

        if e.spinDirection < 0 then
            if signedOverflow ~= 0 then
                thisFrameDelta = math_floor((1.0*e.stickLastAngle + 0x10000) - rawAngle)
            else
                thisFrameDelta = e.stickLastAngle - rawAngle
            end
        elseif e.spinDirection > 0 then
            if signedOverflow ~= 0 then
                thisFrameDelta = math_floor(1.0*rawAngle + 0x10000 - e.stickLastAngle)
            else
                thisFrameDelta = rawAngle - e.stickLastAngle
            end
        end

        e.angleDeltaQueue[0] = thisFrameDelta
        angleOverFrames = angleOverFrames + thisFrameDelta

        if angleOverFrames >= 0xA000 then
            e.spinBufferTimer = SPIN_TIMER_SUCCESSFUL_INPUT
        end

		

        -- Keep a short buffer so the player can switch directions after a full spin.
        if e.spinBufferTimer > 0 then
            e.spinInput = 1
            e.spinBufferTimer = e.spinBufferTimer - 1
        end
    else
        e.spinDirection = 0
        e.spinBufferTimer = 0
    end

    e.stickLastAngle = rawAngle
    e.lastIntendedMag = m.intendedMag
end

local function act_spin_jump(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        -- Store the direction chosen by the analog input.
        if e.spinDirection < 0 then
            m.actionState = 1
        end
    end

    local spinDirFactor = 1  -- negative for clockwise, positive for counter-clockwise
    if m.actionState == 1 then
        spinDirFactor = -1
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_DIVE, 0)
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)

        m.vel.y = -50.0
        mario_set_forward_vel(m, 0.0)

        -- Face the analog direction, or the current spin direction without input.
        if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
            m.faceAngle.y = m.intendedYaw
        else
            m.faceAngle.y = limit_angle(e.rotAngle)
        end

        return set_mario_action(m, ACT_GROUND_POUND, m.actionState)
    end

    play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, CHAR_SOUND_YAHOO)

    common_air_action_step(m, ACT_DOUBLE_JUMP_LAND, MARIO_ANIM_TWIRL,
                           AIR_STEP_CHECK_HANG)

    e.rotAngle = e.rotAngle + 0x5000
    if (e.rotAngle >  0x10000) then e.rotAngle = e.rotAngle - 0x10000 end
    if (e.rotAngle < -0x10000) then e.rotAngle = e.rotAngle + 0x10000 end
    m.marioObj.header.gfx.angle.y = limit_angle(m.marioObj.header.gfx.angle.y + (e.rotAngle * spinDirFactor))

    m.actionTimer = m.actionTimer + 1

    return false
end

local function act_spin_jump_gravity(m)
    -- Apply wing flutter when available; otherwise use the custom jump gravity.
    if (m.flags & MARIO_WING_CAP) ~= 0 and m.vel.y < 0.0 and (m.input & INPUT_A_DOWN) ~= 0 then
        m.marioBodyState.wingFlutter = 1
        m.vel.y = m.vel.y - 0.7
        if m.vel.y < -37.5 then
            m.vel.y = m.vel.y + 1.4
            if m.vel.y > -37.5 then
                m.vel.y = -37.5
            end
        end
    else
        if m.vel.y > 0 then
            m.vel.y = m.vel.y - 4
        else
            m.vel.y = m.vel.y - 0.5
        end

        if m.vel.y < -75.0 then
            m.vel.y = -75.0
        end
    end

    return 0
end

-----------------------------------
-- Dive slide and dive transitions --
-----------------------------------

local function act_dive_slide(m)
    if (m.input & INPUT_ABOVE_SLIDE) == 0 and (m.input & INPUT_A_PRESSED) ~= 0 then
        queue_rumble_data_mario(m, 5, 80)
        if m.forwardVel > 0 then
            return set_mario_action(m, ACT_FORWARD_ROLLOUT, 0)
        else
            return set_mario_action(m, ACT_BACKWARD_ROLLOUT, 0)
        end
    end

    if (m.input & INPUT_ABOVE_SLIDE) == 0 then
        if (m.input & INPUT_B_PRESSED) ~= 0 then
            -- Press B during a slide to perform a short dive hop.
            m.vel.y = 21.0
            return set_mario_action(m, ACT_DIVE, 1)
        end
    end

    play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)

    -- Check object pickup before the slide action can finish so the correct
    -- pickup animation is selected.

    if update_sliding(m, 8.0) ~= 0 and is_anim_at_end(m) ~= 0 then
        mario_set_forward_vel(m, 0.0)
        set_mario_action(m, ACT_STOMACH_SLIDE_STOP, 0)
    end

    if mario_check_object_grab(m) ~= 0 then
        mario_grab_used_object(m)
        if m.heldObj ~= 0 then
            m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
        end
        return true
    end

    common_slide_action(m, ACT_STOMACH_SLIDE_STOP, ACT_FREEFALL, MARIO_ANIM_DIVE)
    return false
end

local function monteman_update_dive_actions(m)
    -- This helper runs before the regular spin update and may change actions.
    local inWater = (m.action & ACT_FLAG_SWIMMING) ~= 0
    local bPressed = (m.controller.buttonPressed & B_BUTTON) ~= 0
    -- Reset the one-use air dive after landing.
    if (m.action & ACT_FLAG_AIR) == 0 then
        hasUsedAirDive[m.playerIndex] = false
    end

    -- Allow a dive to transition directly into a ground pound.
    local zPressed = (m.controller.buttonPressed & Z_TRIG) ~= 0

    if zPressed
    and m.action == ACT_DIVE
    and not inWater
    then
        set_mario_action(m, ACT_GROUND_POUND, 0)
        return
    end

    -- Allow a rollout wall kick only when approaching the wall head-on.
    if m.action == ACT_FORWARD_ROLLOUT and m.wall ~= nil then
        local wallYaw = atan2s(m.wall.normal.z, m.wall.normal.x)
        local approachYaw = limit_angle(m.faceAngle.y - wallYaw)
        local absApproach = math_abs(approachYaw)
        local VALID_ANGLE = 0x2000
        local validWallKick =
            absApproach > (0x8000 - VALID_ANGLE) and
            absApproach < (0x8000 + VALID_ANGLE)

        if validWallKick then
            set_mario_action(m, ACT_WALL_KICK_AIR, 0)
            m.vel.y = 35
            m.forwardVel = math_max(m.forwardVel, 30)
            return
        end
    end

    -- Add ground-pound and dive transitions to selected jump states.
    if not inWater then
        if zPressed and (
            m.action == ACT_TOP_OF_POLE_JUMP or
            m.action == ACT_STEEP_JUMP or
            m.action == ACT_LONG_JUMP or
            m.action == ACT_WATER_JUMP
        ) then
            set_mario_action(m, ACT_GROUND_POUND, 0)
            return
        end

        if bPressed and (
            m.action == ACT_TOP_OF_POLE_JUMP or
            m.action == ACT_WATER_JUMP
        ) then
            m.forwardVel = math_max(m.forwardVel + 30, 30)
            m.vel.y = 15
            set_mario_action(m, ACT_DIVE, 0)
            return
        end
    end

    -- Allow one buffered air dive after a backflip transition. An air kick
    -- remains available only when the analog stick is held mostly backward.
    local prevAction = lastAction[m.playerIndex] or 0
    local isGoodieJumpTransition = prevAction == ACT_BACKFLIP
    local isBackwardAirKick = m.action == ACT_AIR_KICK and is_backward_air_kick(m)

    if bPressed and
        (m.action & ACT_FLAG_AIR) ~= 0 and
        not inWater and
        m.forwardVel <= 30 and
        not hasUsedAirDive[m.playerIndex] and
        isGoodieJumpTransition and
        not isBackwardAirKick then
        m.forwardVel = m.forwardVel + 30
        m.vel.y = 15
        set_mario_action(m, ACT_DIVE, 0)
        hasUsedAirDive[m.playerIndex] = true
        return
    end

    -- Boost a grounded dive when moving fast enough.
    if bPressed and
        m.forwardVel > 10 and
        (m.action & ACT_FLAG_AIR) == 0 and
        not inWater then
        m.forwardVel = math_min(m.forwardVel + 20, 70)
        m.vel.y = 25
        set_mario_action(m, ACT_DIVE, 0)
        return
    end

    lastAction[m.playerIndex] = m.action
end

local function monteman_update(m)
    -- Keep dive transitions first; the old separate callback returned early here.
    monteman_update_dive_actions(m)
    if not enable_extended_moveset then return end
    local e = gMarioStateExtras[m.playerIndex]

    monteman_update_spin_input(m)
    -- Convert a successful spin input into a spin jump.
    if (m.action == ACT_JUMP or
        m.action == ACT_WALL_KICK_AIR or
        m.action == ACT_DOUBLE_JUMP or
        m.action == ACT_BACKFLIP or
        m.action == ACT_SIDE_FLIP) and e.spinInput ~= 0 then
        set_mario_action(m, ACT_SPIN_JUMP, 1)
        e.spinInput = 0
    end

    -- Present custom pound-land actions as the standard action to other systems.
    if m.action == ACT_SPIN_POUND_LAND or m.action == ACT_WATER_GROUND_POUND_LAND then
        e.fakeSavedAction = m.action
        e.fakeSavedPrevAction = m.prevAction
        e.fakeSavedActionTimer = m.actionTimer

        m.action = ACT_GROUND_POUND_LAND
        e.fakeWroteAction = m.action
        e.fakeSaved = true
    end
end

local function monteman_on_set_action(m)
    -- Adjust movement immediately after an action is assigned.
    if not enable_extended_moveset then return end
    local e = gMarioStateExtras[m.playerIndex]

    if e.spinInput ~= 0 and (m.input & INPUT_ABOVE_SLIDE) == 0 then
        if m.action == ACT_JUMP or
           m.action == ACT_DOUBLE_JUMP or
           m.action == ACT_TRIPLE_JUMP or
           m.action == ACT_SPECIAL_TRIPLE_JUMP or
           m.action == ACT_SIDE_FLIP or
           m.action == ACT_BACKFLIP then
            set_mario_action(m, ACT_SPIN_JUMP, 1)
            m.vel.y = 75.5
            m.faceAngle.y = m.intendedYaw
        end
    end

    if m.action == ACT_GROUND_POUND_JUMP then
        m.vel.y = 70.0
    elseif m.action == ACT_WATER_PLUNGE and m.prevAction == ACT_GROUND_POUND then
        return set_mario_action(m, ACT_WATER_GROUND_POUND, 1)
    elseif m.action == ACT_WALL_SLIDE then
        m.vel.y = 0.0
    elseif m.action == ACT_GROUND_POUND and m.prevAction == ACT_SIDE_FLIP then
        -- Correct the animation orientation after a side-flip ground pound.
        m.marioObj.header.gfx.angle.y = limit_angle(m.marioObj.header.gfx.angle.y - 0x8000)
    elseif m.action == ACT_LEDGE_GRAB then
        e.rotAngle = m.forwardVel
    end
end

local function monteman_before_update(m)
    if not enable_extended_moveset then return end
    local e = gMarioStateExtras[m.playerIndex]
    -- Restore the original pound-land action after other systems inspect it.
    if e.fakeSaved then
        if m.action == e.fakeWroteAction and m.prevAction == e.fakeSavedPrevAction and m.actionTimer == e.fakeSavedActionTimer then
            m.action = e.fakeSavedAction
        end
        e.fakeSaved = false
    end
end

local convert_actions = {
    [ACT_DIVE_SLIDE] = ACT_CUSTOM_DIVE_SLIDE,
}

local function monteman_before_set_action(m, action)
    -- Replace the stock dive slide with the version that supports dive hopping.
    if not enable_extended_moveset then return action end

    return convert_actions[action] or action
end

local function on_chat_command(msg)
    -- Toggle the optional spin and action overrides without unloading the mod.
    if msg:lower() == 'off' then
        enable_extended_moveset = false
        djui_chat_message_create("Extended moveset is now disabled")
    elseif msg:lower() == 'on' then
        enable_extended_moveset = true
        djui_chat_message_create("Extended moveset is now enabled")
    end
    return true
end

---------------------
-- Hook registration --
---------------------

local function register_moveset()
    -- Character Select limits these callbacks to Monteman.
    charSelect.character_hook_moveset(CT_MONTEMAN, HOOK_BEFORE_MARIO_UPDATE, monteman_before_update)
    charSelect.character_hook_moveset(CT_MONTEMAN, HOOK_MARIO_UPDATE, monteman_update)
    charSelect.character_hook_moveset(CT_MONTEMAN, HOOK_ON_SET_MARIO_ACTION, monteman_on_set_action)
    charSelect.character_hook_moveset(CT_MONTEMAN, HOOK_BEFORE_SET_MARIO_ACTION, monteman_before_set_action)
end

hook_event(HOOK_ON_MODS_LOADED, register_moveset)
hook_mario_action(ACT_SPIN_JUMP,                 { every_frame = act_spin_jump, gravity = act_spin_jump_gravity })
hook_mario_action(ACT_CUSTOM_DIVE_SLIDE,                { every_frame = act_dive_slide, gravity = no_gravity })
hook_chat_command('ext-moveset', "Turn extended moveset [on|off]", on_chat_command)