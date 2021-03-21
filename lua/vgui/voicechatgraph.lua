local PANEL = {}

function surface.DrawLineEx( x1, y1, x2, y2, w, col )
	w = w or 1
	col = col
	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))
	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5
	draw.NoTexture()
	surface.SetDrawColor(col)
	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function PANEL:Init()
    self.segments = {}
    self.nextSegment = true
	self.iterations = 0
end

function PANEL:SetPlayer( ply )
    self.ply = ply
end

function PANEL:LineGraph( w, h )
    for k, segment in pairs( self.segments ) do
        if k == self.segments[ #self.segments ] then continue end
        local nextSegment = self.segments[ k+1 ] or { x = segment.x, v = segment.v }

        local p1 = { x = segment.x, y = h } -- bottom left
        local p2 = { x = segment.x, y = h - segment.v * VoiceChat.Theme[ 'VoiceChatGraphAmp' ] } -- top left
        local p3 = { x = nextSegment.x, y = h - nextSegment.v * VoiceChat.Theme[ 'VoiceChatGraphAmp' ] } -- top right
        local p4 = { x = nextSegment.x, y = h } -- bottom right

		local col = VoiceChat.Theme[ 'VoiceChatGraphColor' ]( segment.v )

		if VoiceChat.Theme[ 'VoiceChatGraphBorder' ] then
        	surface.DrawLineEx( p2.x, p2.y, p3.x, p3.y, 2, col )
		end

        draw.NoTexture()
        surface.SetDrawColor( ColorAlpha( col, math.max( col.a - 20, 1 ) ) )
        surface.DrawPoly({
            { x = p1.x, y = p1.y, u = 0, v = 0 },
			{ x = p2.x, y = p2.y, u = 0, v = 1 },
			{ x = p3.x, y = p3.y, u = 1, v = 1 },
			{ x = p4.x, y = p4.y, u = 1, v = 0 }
        })
    end
end

function PANEL:BarGraph( w, h )
    for k, segment in pairs( self.segments ) do
        draw.RoundedBox( 0, segment.x, h - segment.v * VoiceChat.Theme[ 'VoiceChatGraphAmp' ], VoiceChat.Theme[ 'VoiceChatGraphSize' ], segment.v * VoiceChat.Theme[ 'VoiceChatGraphAmp' ], VoiceChat.Theme[ 'VoiceChatGraphColor' ]( segment.v ) )
    end
end

function PANEL:ConvertSegmentsToPoints()
	local points = {}

	for k, segment in pairs( self.segments ) do
		points[ #points + 1 ] = {
			x = segment.x,
			y = segment.v * VoiceChat.Theme[ 'VoiceChatGraphAmp' ]
		}
	end

	return points
end

function PANEL:CurvedLineGraph( w, h )
	if #self.segments < 3 then return end

	local points = self:ConvertSegmentsToPoints()
	local spline = VoiceChat.CatmullRomSpline( points )

	local lastPoint = spline[ 1 ]
	for k, point in pairs( spline ) do
		if k == 1 then continue end

		local p1 = { x = lastPoint.x, y = h } -- bottom left
		local p2 = { x = lastPoint.x, y = h - lastPoint.y } -- top left
		local p3 = { x = point.x, y = h - point.y } -- top right
		local p4 = { x = point.x, y = h } -- bottom right

		local col = VoiceChat.Theme[ 'VoiceChatGraphColor' ]( point.y / VoiceChat.Theme[ 'VoiceChatGraphAmp' ] )

		if VoiceChat.Theme[ 'VoiceChatGraphBorder' ] then
			surface.DrawLineEx( p2.x, p2.y, p3.x, p3.y, 2, col )
		end

		draw.NoTexture()
        surface.SetDrawColor( ColorAlpha( col, math.max( col.a - 20, 1 ) ) )
        surface.DrawPoly({
            { x = p1.x, y = p1.y, u = 0, v = 0 },
			{ x = p2.x, y = p2.y, u = 0, v = 1 },
			{ x = p3.x, y = p3.y, u = 1, v = 1 },
			{ x = p4.x, y = p4.y, u = 1, v = 0 }
        })

		lastPoint = point
	end

end

function PANEL:Paint( w, h )
    if not IsValid( self.ply ) then return end
	if VoiceChat.Theme[ 'VoiceChatGraphType' ] == 0 then return end
	if GetConVar( 'voice_chat_graph' ):GetInt() == 0 then return end

    -- Move each segment over
    for k, segment in pairs( self.segments ) do
        segment.x = segment.x - VoiceChat.Theme[ 'VoiceChatGraphSpeed' ]
        if segment.x < -VoiceChat.Theme[ 'VoiceChatGraphSize' ] then self.segments[ k ] = nil end
    end

	-- Check if another segment can be made
	local totalSpacing = VoiceChat.Theme[ 'VoiceChatGraphSize' ] + VoiceChat.Theme[ 'VoiceChatGraphSpacing' ]
	self.iterations = self.iterations + VoiceChat.Theme[ 'VoiceChatGraphSpeed' ]
	if self.iterations >= totalSpacing then
		self.nextSegment = true
		self.iterations = 0
	end

    -- Draw the correct graph
    if VoiceChat.Theme[ 'VoiceChatGraphType' ] == 1 then
        self:LineGraph( w, h )
    elseif VoiceChat.Theme[ 'VoiceChatGraphType' ] == 2 then
        self:BarGraph( w, h )
    elseif VoiceChat.Theme[ 'VoiceChatGraphType' ] == 3 then
        self:CurvedLineGraph( w, h )
    end
end

function PANEL:Think()
    if not self.nextSegment then return end
	if not IsValid( self.ply ) then return end
	if VoiceChat.Theme[ 'VoiceChatGraphType' ] == 0 then return end
	if GetConVar( 'voice_chat_graph' ):GetInt() == 0 then return end

    -- Create a new segment
    local volume = self.ply:VoiceVolume()
    table.insert( self.segments, {
        x = self:GetWide(),
        v = volume
    } )

    self.nextSegment = false
end

vgui.Register( 'VoiceChatGraph', PANEL )
