if not dynamicHudAPI then return end

function setup_recolor_icons()
    local FEATURE = dynamicHudAPI.FEATURE
    local NONE = dynamicHudAPI.NONE
	dynamicHudAPI.add_head_for_cs(CT_MONTEMAN, nil, get_texture_info("recolor_icon_monteman"),
        { SKIN, HAIR, CAP, NONE, EMBLEM, NONE, NONE, FEATURE },
        { NONE, NONE, NONE, SKIN, NONE, HAIR, FEATURE, NONE },
        nil, nil, {metal_sheet_x = 8, metal_capless_sheet_x = 9} -- legacy
		
    )
	end
	
hook_event(HOOK_ON_MODS_LOADED, setup_recolor_icons)