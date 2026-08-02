-- name: [CS] Il Piantissimo
-- description: A attempt to make a faitful \n\\#2cba1c\\Il \\#fc3b8b\\Piantissimo \\#ffffff\\for CoopDX with a similar level of polish as \nExtra Characters Plus\n\nWith a custom SMS inspired moveset based on:\nExtended Moveset by \\#fe7fff\\ TheGag96 \n\\#00e3ff\\Sunshine-esque\\#ffd500\\ Movement! by \\#29aaff\\BeckJack\\#ffffff\\ \nand slightly tweaked by Eiscreme \n\nCompatibility with Dynamic Lives Icon and SoRetro\n\nFeaturing:\nModeling from Eiscreme\nCustom SMB1 style Sprites made by\n\\#ff00ff\\PurpleCosmoStar\\#fff\\\nCustom Menu Animation made by \\#f8c771\\Bisonman\n\n\\#ff7777\\This Pack requires Character Select\nto use as a Library!


local TEXT_MOD_NAME = get_active_mod().name

-- Stops mod from loading if Character Select isn't on, Does not need to be touched
if not _G.charSelectExists then
    djui_popup_create(
        "\\#ffffdc\\\n" ..
        TEXT_MOD_NAME ..
        "\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!",
        6)
    return 0
end
--- Load Models ---
local E_MODEL_MONTEMAN = smlua_model_util_get_id("monteman_geo")      -- Located in "actors"

-- Icons
--if not r96lib then 
	--local lifeIcon = get_texture_info("il_piantisimo_HD_icon")
--else
	local lifeIcon = get_texture_info("il_piantisimo_icon")
--end
	


-- Graffiti
TEX_Monteman_CS_MENU_GRAFFITI = get_texture_info("Monte_Graffiti") -- Located in "textures"

-- Menu Music
--local E_SOUND = audio_stream_load("Racing Il Piantissimo.ogg")

-- Voice Table
local VOICETABLE_MONTEMAN = {
    [CHAR_SOUND_OKEY_DOKEY] =        'Laugh.ogg', -- Starting game
	[CHAR_SOUND_LETS_A_GO] =         'Laugh.ogg', -- Starting level
	[CHAR_SOUND_GAME_OVER] =         'Sad.ogg', -- Game Overed
	[CHAR_SOUND_PUNCH_YAH] =         {'Huh.ogg', 'Wao.ogg'}, -- Punch 1
	[CHAR_SOUND_PUNCH_WAH] =         {'Huh.ogg', 'Wao.ogg'}, -- Punch 2
	[CHAR_SOUND_PUNCH_HOO] =         'Laugh.ogg', -- Punch 3
	[CHAR_SOUND_YAH_WAH_HOO] =       {'Huh.ogg', 'Wao.ogg', 'Huh.ogg', 'Wao.ogg'}, -- First Jump Sounds
	[CHAR_SOUND_HOOHOO] =            {'Huh.ogg', 'Wao.ogg'}, -- Second jump sound
	[CHAR_SOUND_YAHOO_WAHA_YIPPEE] = {'Huh.ogg', 'Wao.ogg'}, -- Triple jump sounds
	[CHAR_SOUND_UH] =                'Sad.ogg', -- Soft wall bonk
	--[CHAR_SOUND_UH2] =               'CharLedgeGetUp.ogg',  Quick ledge get up
	--[CHAR_SOUND_UH2_2] =             'CharLongJumpLand.ogg',  Landing after long jump
	[CHAR_SOUND_DOH] =               'Sad.ogg', -- Hard wall bonk
	[CHAR_SOUND_OOOF] =              'Sad.ogg', -- Attacked in air
	[CHAR_SOUND_OOOF2] =             'Sad.ogg', -- Land from hard bonk
	[CHAR_SOUND_HAHA] =              'Laugh.ogg', -- Landing triple jump
	[CHAR_SOUND_HAHA_2] =            'Laugh.ogg', -- Landing in water from big fall
	[CHAR_SOUND_YAHOO] =             {'Huh.ogg', 'Wao.ogg'}, -- Long jump
	[CHAR_SOUND_DOH] =               'Sad.ogg', -- Long jump wall bonk
	[CHAR_SOUND_WHOA] =              {'Huh.ogg', 'Wao.ogg'}, -- Grabbing ledge
	[CHAR_SOUND_EEUH] =              {'Huh.ogg', 'Wao.ogg'}, -- Climbing over ledge
	[CHAR_SOUND_WAAAOOOW] =          'Sad.ogg', -- Falling a long distance
	[CHAR_SOUND_TWIRL_BOUNCE] =      {'Huh.ogg', 'Wao.ogg'}, -- Bouncing off of a flower spring
	[CHAR_SOUND_GROUND_POUND_WAH] =  {'Huh.ogg', 'Wao.ogg'}, -- Ground Pound after startup
	[CHAR_SOUND_WAH2] =              {'Huh.ogg', 'Wao.ogg'}, -- Throwing something
	[CHAR_SOUND_HRMM] =              {'Huh.ogg', 'Wao.ogg'}, -- Lifting something
	[CHAR_SOUND_HERE_WE_GO] =        'Laugh.ogg', -- Star get
	[CHAR_SOUND_SO_LONGA_BOWSER] =   'Laugh.ogg', -- Throwing Bowser
--DAMAGE
	[CHAR_SOUND_ATTACKED] =          'Sad.ogg', -- Damaged
	--[CHAR_SOUND_PANTING] =           'CharPanting.ogg',  Low health
	--[CHAR_SOUND_PANTING_COLD] =      'CharPanting.ogg',  Getting cold
	[CHAR_SOUND_ON_FIRE] =           'Sad.ogg', -- Burned
--SLEEP SOUNDS
	--[CHAR_SOUND_IMA_TIRED] =         'CharTired.ogg', -- Mario feeling tired
	--[CHAR_SOUND_YAWNING] =           'CharYawn.ogg', -- Mario yawning before he sits down to sleep
	--[CHAR_SOUND_SNORING1] =          'CharSnore.ogg', -- Snore Inhale
	--[CHAR_SOUND_SNORING2] =          'CharExhale.ogg', -- Exhale
	--[CHAR_SOUND_SNORING3] =          'CharSleepTalk.ogg', -- Sleep talking / mumbling
--COUGHING (USED IN THE GAS MAZE)
	--[CHAR_SOUND_COUGHING1] =         'CharCough1.ogg', -- Cough take 1
	--[CHAR_SOUND_COUGHING2] =         'CharCough2.ogg', -- Cough take 2
	--[CHAR_SOUND_COUGHING3] =         'CharCough3.ogg', -- Cough take 3
--DEATH
	[CHAR_SOUND_DYING] =             'Sad.ogg', -- Dying from damage
	[CHAR_SOUND_DROWNING] =          'Sad.ogg', -- Running out of air underwater
	--[CHAR_SOUND_MAMA_MIA] =          'Sad.ogg' -- Booted out of level
}

-- Cap Models
local CAPTABLE_MONTEMAN = {
    normal = smlua_model_util_get_id("monteman_normal_mask_geo"),
    wing = smlua_model_util_get_id("monteman_wing_mask_normal_geo"),
    metal = smlua_model_util_get_id("monteman_metal_mask_geo"),
	metalWing = smlua_model_util_get_id("monteman_metal_mask_geo"),
}

--Pallettes
local PALETTE_MONTEMAN = {
    [PANTS]  = "D66BBD",
    [SHIRT]  = "ffffff",
    [GLOVES] = "D66BBD",
    [SHOES]  = "D66BBD",
    [HAIR]   = "421808",
    [SKIN]   = "8C6329",
    [CAP]    = "D66BBD",
	[EMBLEM] = "28C228"
}
local PALETTE_MARATHONMAN = {
	 
    [PANTS]  = "ffffff",
    [SHIRT]  = "ffffff",
    [GLOVES] = "ffde8c",
    [SHOES]  = "631800",
    [HAIR]   = "8c3908",
    [SKIN]   = "ffde8c",
    [CAP]    = "ff0000",
	[EMBLEM] = "210800"
}

local PALETTE_MAREWOMAN = {
	 
    [PANTS]  = "ffdab1",
    [SHIRT]  = "000000",
    [GLOVES] = "6bacd8",
    [SHOES]  = "6bacd8",
    [HAIR]   = "421808",
    [SKIN]   = "8C6329",
    [CAP]    = "6bacd8",
	[EMBLEM] = "98ffff"
}

local PALETTE_GIBO = {
	 
    [PANTS]  = "2d6ea8",
    [SHIRT]  = "bbbbb1",
    [GLOVES] = "2d6ea8",
    [SHOES]  = "2d6ea8",
    [HAIR]   = "2e0418",
    [SKIN]   = "6c4325",
    [CAP]    = "2d6ea8",
	[EMBLEM] = "3da616"
}

-- Health Meter
local HEALTH_METER_MONTEMAN = {
    label = {
        left = get_texture_info("monteman_healthleft"),
        right = get_texture_info("monteman_healthright"),
    },
	pie = {
        [1] = get_texture_info("Pie1"),
        [2] = get_texture_info("Pie2"),
        [3] = get_texture_info("Pie3"),
        [4] = get_texture_info("Pie4"),
        [5] = get_texture_info("Pie5"),
        [6] = get_texture_info("Pie6"),
        [7] = get_texture_info("Pie7"),
        [8] = get_texture_info("Pie8"),
    }
}

CS_ANIM_MENU = CHAR_ANIM_MAX + 1

-- Animation Table
local animsMONTEMAN = {
    --[CHAR_ANIM_STAR_DANCE] = "StarDance",
    --[CHAR_ANIM_RETURN_FROM_STAR_DANCE] = "StarDanceEnd",
    [_G.charSelect.CS_ANIM_MENU] = "anim_Monte_Menu",
}
local CSloaded = false
-- Character Registration
local function on_character_select_load()

    CT_MONTEMAN = _G.charSelect.character_add(
        "Il Piantissimo",
        "A arrogant footracer from Isle Delphino. Always wanting to prove his speed over those slow clam-chompers.",
        "Eiscreme",
        "D66BBD",
        E_MODEL_MONTEMAN,
        CT_MARIO,
        lifeIcon,
        1,
        0
    )

   --[[ for i = 1, #COSTUMETABLE do
        local costume = COSTUMETABLE[i]

        if i > 1 then
            _G.charSelect.character_add_costume(
                CT_CHARACTER,
                costume.name,
                nil,
                costume.credit,
                nil,
                costume.model
            )
        end]]

    _G.charSelect.character_add_voice(E_MODEL_MONTEMAN, VOICETABLE_MONTEMAN)
		
    _G.charSelect.character_add_caps(E_MODEL_MONTEMAN, CAPTABLE_MONTEMAN)

       --[[ for p = 1, #costume.palettes do
            local palette = costume.palettes[p]
            _G.charSelect.character_add_palette_preset(
                costume.model,
                palette,
                palette.name
            )
        end]]
		
		_G.charSelect.character_add_palette_preset(E_MODEL_MONTEMAN, PALETTE_MONTEMAN, "Default")
		_G.charSelect.character_add_palette_preset(E_MODEL_MONTEMAN, PALETTE_MARATHONMAN, "Hyrulean")
		_G.charSelect.character_add_palette_preset(E_MODEL_MONTEMAN, PALETTE_MAREWOMAN, "Mare")
		_G.charSelect.character_add_palette_preset(E_MODEL_MONTEMAN, PALETTE_GIBO, "Gibo")
		
		_G.charSelect.character_add_animations(E_MODEL_MONTEMAN, animsMONTEMAN)

        _G.charSelect.character_add_health_meter(CT_MONTEMAN, HEALTH_METER_MONTEMAN)
		
		_G.charSelect.character_add_graffiti(CT_MONTEMAN, TEX_Monteman_CS_MENU_GRAFFITI)
		
		if retroCharAPI then
		_G.charSelect.character_set_nickname(CT_MONTEMAN, "Monteman")
		end
		--_G.charSelect.character_add_menu_instrumental(CT_MONTEMAN, E_SOUND)
    end

    _G.charSelect.credit_add(TEXT_MOD_NAME, "Eiscreme", "Coder, Modeler, Lead")
	_G.charSelect.credit_add(TEXT_MOD_NAME, "PurpleCosmoStar", "Spriter")
    _G.charSelect.credit_add(TEXT_MOD_NAME, "Bisonman", "Menu Animation")


hook_event(HOOK_ON_MODS_LOADED, on_character_select_load)