--[[----------------------------------------------
    Circlular Avatar Mask
--------------------------------------------------]]
local PANEL = {}
local cos, sin, rad, render, draw = math.cos, math.sin, math.rad, render, draw

function PANEL:Init()
    self.Avatar = vgui.Create( 'AvatarImage', self )
    self.Avatar:SetPaintedManually( true )
    self.Circle = {}
    self.MaskSize = 24
end

function PANEL:PerformLayout( w, h )
    local radians = 0

    -- Adjust the size of the inner avatar to the parent
    self.Avatar:SetSize( w, h )
    self.MaskSize = w*0.5

    for i = 1, 360 do
        radians = rad( i )
        self.Circle[i] = { x = w/2 + cos(radians)*self.MaskSize, y = h/2 + sin(radians)*self.MaskSize }
    end
end

function PANEL:SetPlayer( id )
    -- Failsafe for bots
    self.Avatar:SetSteamID( id or '', self:GetWide() )
end

function PANEL:Paint( w, h )
    render.ClearStencil()
    render.SetStencilEnable( true )

    render.SetStencilWriteMask( 1 )
    render.SetStencilTestMask( 1 )

    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
    render.SetStencilPassOperation( STENCILOPERATION_ZERO )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
    render.SetStencilReferenceValue( 1 )

    draw.NoTexture()
    surface.SetDrawColor( color_white )
    surface.DrawPoly( self.Circle )

    render.SetStencilFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
    render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
    render.SetStencilReferenceValue( 1 )

    self.Avatar:SetPaintedManually( false )
    self.Avatar:PaintManual()
    self.Avatar:SetPaintedManually( true )

    render.SetStencilEnable(false)
    render.ClearStencil()
end

vgui.Register( 'CircularMaskedAvatar', PANEL )
