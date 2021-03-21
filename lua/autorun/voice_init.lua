-- Global table for all addon related things
VoiceChat = VoiceChat or {}
THEME = THEME or {}

-- Add all the files to the client download list.
if SERVER then
    AddCSLuaFile()
    AddCSLuaFile( 'voice_chat_config.lua' )
    AddCSLuaFile( 'core/voice_main.lua' )
    AddCSLuaFile( 'core/catmull-rom_spline.lua' )
else
    include( 'core/catmull-rom_spline.lua' )
end

include( 'voice_chat_config.lua' )

-- After the config is loaded, add the theme and
-- start the addon.
if SERVER then
    AddCSLuaFile( 'voicethemes/' .. VoiceChat[ 'Theme' ] .. '.lua' )
else
    THEME = {}
    include( 'voicethemes/' .. VoiceChat[ 'Theme' ] .. '.lua' )
    VoiceChat.Theme = THEME

    include( 'core/voice_main.lua' )
end
