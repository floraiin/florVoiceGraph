VoiceChat.VoicePanels = VoiceChat.VoicePanels or {}
VOICE = VOICE or {}

CreateClientConVar( 'voice_chat_graph', VoiceChat[ 'DefaultOn' ] and 1 or 0, true, false )

-- Called when a player starts talking
function VoiceChat.PlayerStartVoice( ply )
    local client = LocalPlayer()

    if not IsValid( VoiceChat.VoicePanelList ) then return end
    if not IsValid( client ) then return end

    -- Remove the extra from voice_loopback
    VoiceChat.PlayerEndVoice( ply )

    if IsValid( VoiceChat.VoicePanels[ ply ] ) then
        -- If its currently animating out, stop it
        if VoiceChat.VoicePanels[ ply ].animOut then
			VoiceChat.VoicePanels[ ply ].animOut:Stop()
			VoiceChat.VoicePanels[ ply ].animOut = nil
		end

        -- If its already animating in, return
        if VoiceChat.VoicePanels[ ply ].animIn then return end

        -- Run the in animation
        VoiceChat.VoicePanels[ ply ].animIn = Derma_Anim( 'VoiceAnimIn', VoiceChat.VoicePanels[ ply ], VoiceChat.VoicePanels[ ply ].AnimationIn )
        VoiceChat.VoicePanels[ ply ].animIn:Start( 1 )

        return
    end

    if not IsValid( ply ) then return end

    -- Wanky ass TTT spaghetti code
    if VoiceChat[ 'TTT' ] then
        -- Tell server this is global
        if client == ply then
            if client:IsActiveTraitor() then
                if (not client:KeyDown(IN_SPEED)) and (not client:KeyDownLast(IN_SPEED)) then
                    client.traitor_gvoice = true
                    RunConsoleCommand("tvog", "1")
                else
                    client.traitor_gvoice = false
                    RunConsoleCommand("tvog", "0")
                end
            end

            VOICE.SetSpeaking(true)
        end
    end

    local panel = VoiceChat.VoicePanelList:Add( 'VoiceChatBox' )
    panel:Setup( ply )

    -- Wanky ass TTT spaghetti code
    if VoiceChat[ 'TTT' ] then
        if client:IsActiveTraitor() then
            if ply == client then
                if not client.traitor_gvoice then
                    panel.Color = Color(200, 20, 20, 255)
                end
            elseif ply:IsActiveTraitor() then
                if not ply.traitor_gvoice then
                    panel.Color = Color(200, 20, 20, 255)
                end
            end
        end

        if ply:IsActiveDetective() then
            panel.Color = Color(20, 20, 200, 255)
        end
    end

    VoiceChat.VoicePanels[ ply ] = panel

    -- Wanky ass TTT spaghetti code
    -- run ear gesture
    if VoiceChat[ 'TTT' ] then
        if not (ply:IsActiveTraitor() and (not ply.traitor_gvoice)) then
            ply:AnimPerformGesture(ACT_GMOD_IN_CHAT)
        end
    end
end


-- Called when a player stops talking
function VoiceChat.PlayerEndVoice( ply, no_reset )
	if IsValid( VoiceChat.VoicePanels[ ply ] ) then
        -- If its animating in, stop it
        if VoiceChat.VoicePanels[ ply ].animIn then
            VoiceChat.VoicePanels[ ply ].animIn:Stop()
            VoiceChat.VoicePanels[ ply ].animIn = nil
        end

        -- If its already animating out, return
        if VoiceChat.VoicePanels[ ply ].animOut then return end

        -- Start the out animation
		VoiceChat.VoicePanels[ ply ].animOut = Derma_Anim( 'VoiceAnimOut', VoiceChat.VoicePanels[ ply ], VoiceChat.VoicePanels[ ply ].AnimationOut )
		VoiceChat.VoicePanels[ ply ].animOut:Start( 0.7 )
	end

    if VoiceChat[ 'TTT' ] then
        if IsValid(ply) and not no_reset then
            ply.traitor_gvoice = false
        end

        if ply == LocalPlayer() then
            VOICE.SetSpeaking(false)
        end
    end
end


-- Create the panel that will hold all the other
-- voice panels.
hook.Add( 'InitPostEntity', 'VoiceChat.CreateVoiceVGUI', function()
    local padding = VoiceChat.Theme[ 'YStartPadding' ]
    local xPosition = VoiceChat.Theme[ 'XStartPosition' ] == RIGHT and  ScrW() - VoiceChat.Theme[ 'BoxWidth' ] or 0
    local yPosition = VoiceChat.Theme[ 'YStartPosition' ] == TOP and padding or -padding

    local panel = vgui.Create( 'DPanel' )
    panel:ParentToHUD()
    panel:SetPos( xPosition, yPosition )
    panel:SetSize( VoiceChat.Theme[ 'BoxWidth' ], ScrH() )
    panel:SetDrawBackground( false )

    VoiceChat.VoicePanelList = panel
end )

-- A simple cleanup timer to remove panels for players
-- that no longer exist.
timer.Create( 'VoiceClean', 10, 0, function()
    for ply, panel in pairs( VoiceChat.VoicePanels ) do
		if not IsValid( ply ) then
			VoiceChat:PlayerEndVoice( ply )
		end
	end
end )

-- Taken from TTT gamemode for override use.
local function ReceiveVoiceState()
   local idx = net.ReadUInt(7) + 1 -- we -1 serverside
   local state = net.ReadBit() == 1

   -- prevent glitching due to chat starting/ending across round boundary
   if GAMEMODE.round_state != ROUND_ACTIVE then return end
   if (not IsValid(LocalPlayer())) or (not LocalPlayer():IsActiveTraitor()) then return end

   local ply = player.GetByID(idx)
   if IsValid(ply) then
      ply.traitor_gvoice = state

      if IsValid(VoiceChat.VoicePanels[ply]) then
         VoiceChat.VoicePanels[ply].Color = state and Color(0,200,0) or Color(200, 0, 0)
      end
   end
end

-- Add the voicechat hooks as well as deleting the default voice chat hook
-- for gamemode compatability.
hook.Add( 'PostGamemodeLoaded', 'VoiceChat.HookLineAndSinker', function()
    hook.Add( 'PlayerEndVoice', 'VoiceChat.OverrideDefaultEndVoice', VoiceChat.PlayerEndVoice )
    hook.Add( 'PlayerStartVoice', 'VoiceChat.OverrideDefaultStartVoice', VoiceChat.PlayerStartVoice )
    hook.Remove( 'InitPostEntity', 'CreateVoiceVGUI' )

    if VoiceChat[ 'TTT' ] then
        net.Receive("TTT_TraitorVoiceState", ReceiveVoiceState)
    end
end )
