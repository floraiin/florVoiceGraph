local PANEL = {}

local function outQuad( fraction, beginning, change )
  return -change * fraction * (fraction - 2) + beginning
end

local function drawCircle( x, y, r )
    local circle = {}

    for i = 1, 360 do
        radians = math.rad( i )
        circle[i] = { x = x + math.cos(radians)*r, y = y + math.sin(radians)*r }
    end

    return circle
end

function PANEL:Init()
    local width, height = VoiceChat.Theme[ 'BoxWidth' ], VoiceChat.Theme[ 'BoxHeight' ]
    local avatarSize = VoiceChat.Theme[ 'AvatarSize' ]
    local avatarMargin = height*0.5 - avatarSize*0.5
    self.boundX = VoiceChat.Theme[ 'BoxWidth' ]
    self.LabelName = ''

    self.graph = vgui.Create( 'VoiceChatGraph', self )
    self.graph:SetPos( 0, 0 )
    self.graph:SetSize( width, height )

    if VoiceChat.Theme[ 'DrawAvatarBorder' ] then
        self.AvatarBorder = VGUIRect( avatarMargin-2, avatarMargin-2, avatarSize+4, avatarSize+4 )
        self.AvatarBorder:SetParent( self )
        self.AvatarBorder.Paint = function( s, w, h )
            if not self.ply then return end
            if not IsValid( self.ply ) then return end

            local col = self.ply:GetFriendStatus() == 'friend' and Color( 46, 204, 113, 255 ) or Color( 52, 152, 219, 255 )

            if VoiceChat.Theme[ 'AvatarStyle' ] == 1 then
                local circle = circle or drawCircle( w*0.5, h*0.5, w*0.5 )
                draw.NoTexture()
                surface.SetDrawColor( col )
                surface.DrawPoly( circle )
            elseif VoiceChat.Theme[ 'AvatarStyle' ] == 2 or VoiceChat.Theme[ 'AvatarStyle' ] == 3 then
                draw.RoundedBox( 0, 0, 0, w, h, col )
            end
        end
    end

    if VoiceChat.Theme[ 'AvatarStyle' ] == 1 then
        self.Avatar = vgui.Create( 'CircularMaskedAvatar', self )
    elseif VoiceChat.Theme[ 'AvatarStyle' ] == 2 then
        self.Avatar = vgui.Create( 'AvatarImage', self )
    elseif VoiceChat.Theme[ 'AvatarStyle' ] == 3 then
        self.Avatar = vgui.Create( 'DModelPanel', self )
        self.Avatar.LayoutEntity = function( ent ) return end
    end

    self.Avatar:SetSize( avatarSize, avatarSize )
    self.Avatar:SetPos( avatarMargin, avatarMargin )

    if VoiceChat[ 'Murder' ] then
        self.ColorBlock = vgui.Create( 'DPanel', self )
        self.ColorBlock:SetSize( avatarSize, avatarSize )
        self.ColorBlock:SetPos( avatarMargin, avatarMargin )
    	self.ColorBlock.Paint = function( s, w, h )
    		if IsValid( s.Player ) and s.Player:IsPlayer() then
    			local col = s.Player:GetPlayerColor()
    			surface.SetDrawColor( Color( col.x * 255, col.y * 255, col.z * 255 ) )
    			surface.DrawRect( 0, 0, w, h )
    		end
    	end
    end

    self:SetSize( width, height )
    self:DockPadding( 4, 4, 4, 4 )
	self:DockMargin( 2, 2, 20, 2 )
	self:Dock( VoiceChat.Theme[ 'YStartPosition' ] )
end

function PANEL:Setup( ply )
    self.ply = ply

    if VoiceChat[ 'Murder' ] then
        self:CheckBystanderState()
        self.Avatar:SetVisible( false )
        self.ColorBlock.Player = ply
    end

    if VoiceChat.Theme[ 'AvatarStyle' ] == 1 then
        self.Avatar:SetPlayer( self.ply:SteamID64() )
    elseif VoiceChat.Theme[ 'AvatarStyle' ] == 2 then
        self.Avatar:SetSteamID( self.ply:SteamID64(), 32 )
    elseif VoiceChat.Theme[ 'AvatarStyle' ] == 3 then
        self.Avatar:SetModel( self.ply:GetModel() )

        local mdl = self.Avatar:GetEntity()
        local bone = mdl:LookupBone('ValveBiped.Bip01_Head1')

        if not bone then return end

		local headPos = mdl:GetBonePosition( bone )

		mdl:SetEyeTarget( Vector( 20, 00, 65 ) )
		self.Avatar:SetCamPos( Vector( 15, 0, 65 ) )
        self.Avatar:SetAnimated( false )
		if headPos then
			self.Avatar:SetLookAt( headPos )
		else
			self.Avatar:SetCamPos( Vector( 30, 10, 75 ) )
		end
    end

    self.graph:SetPlayer( self.ply )

    self:InvalidateLayout()
end

function PANEL:Paint( w, h )
    VoiceChat.Theme[ 'VoiceChatBoxPaint' ]( self, w, h )
end

function PANEL:PaintOver( w, h )
    VoiceChat.Theme[ 'VoiceChatBoxPaintOver' ]( self, w, h )
end

function PANEL:CheckBystanderState( state )
	if IsValid(self.ply) then
		local newBystanderState = false
		local client = LocalPlayer()
		if !IsValid(client) then
			newBystanderState = true
		else
			if client:Team() == 2 && client:Alive() then
				newBystanderState = true
			else
				if self.ply:Team() == 2 && self.ply:Alive() then
					newBystanderState = true
				end
			end
		end

		if self.Bystander != newBystanderState then
			self:SetBystanderState(newBystanderState)
		end
		if newBystanderState then
			local col = self.ply:GetPlayerColor()
			if col != self.PrevColor then
				local color = Color(col.x * 255, col.y * 255, col.z * 255)
				self.Color = color
			end
			self.PrevColor = col
		end
	end
end

function PANEL:SetBystanderState( state )
	local col = self.ply:GetPlayerColor()
	local color = Color(col.x * 255, col.y * 255, col.z * 255)
	self.Color = color

	self.Bystander = state
	if state then
		self.LabelName = self.ply:GetBystanderName()
		self.ColorBlock:SetVisible( true )
		self.Avatar:SetVisible( false )
	else
		self.LabelName = self.ply:Nick()
		self.ColorBlock:SetVisible( false )
		self.Avatar:SetVisible( true )
	end
end

function PANEL:AnimationOut( anim, delta, data )
    local x, y = self:GetPos()
    local dist = VoiceChat.Theme[ 'XStartPosition' ] == RIGHT and self.boundX - x or -self.boundX + x

    if anim.Finished then
        if IsValid( VoiceChat.VoicePanels[ self.ply ] ) then
            VoiceChat.VoicePanels[ self.ply ]:Remove()
            VoiceChat.VoicePanels[ self.ply ] = nil
            return
        end
    end

    self:SetAlpha( 255 - ( 255 * delta ) )
    self:SetPos( outQuad( delta, x, dist ), y )
end

function PANEL:AnimationIn( anim, delta, data )
    local x, y = self:GetPos()
    local dist = VoiceChat.Theme[ 'XStartPosition' ] == RIGHT and -x or 0

    if anim.Finished then
        if IsValid( VoiceChat.VoicePanels[ self.ply ] ) then
            VoiceChat.VoicePanels[ self.ply ].animIn = nil
        end
    end

    self:SetAlpha( 255 )
    self:SetPos( outQuad( delta, x, dist ), y )
end

function PANEL:Think()
    if self.animOut then self.animOut:Run() end
    if self.animIn then self.animIn:Run() end

    if VoiceChat[ 'Murder' ] then
        self:CheckBystanderState()
    end
end

derma.DefineControl( 'VoiceChatBox', '', PANEL, 'DPanel' )
