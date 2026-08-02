if not retroCharAPI then return end

SMB_RED = retroCharAPI.SMB_RED
SMB_WHITE = retroCharAPI.SMB_WHITE
SMB_DEFAULT_SKIN = retroCharAPI.SMB_DEFAULT_SKIN
SMB_PINK = retroCharAPI.SMB_PINK
SMB_SHIRT = SHIRT * EMBLEM

function setup_retro_sprites()
    retroCharAPI.add_cs_character_sprites(CT_MONTEMAN, get_texture_info("monteman_0"), get_texture_info("monteman_1"))


    retroCharAPI.add_cs_character_palette(CT_MONTEMAN, {SKIN, PANTS, SMB_SHIRT}, {SKIN, SMB_WHITE, SMB_RED}, 1, 2)

end

hook_event(HOOK_ON_MODS_LOADED, setup_retro_sprites)