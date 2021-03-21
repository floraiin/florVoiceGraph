VoiceChat = VoiceChat or {}

function VoiceChat.CatmullRomSpline( points, steps )

	if #points < 3 then
		return points
	end

	local steps = steps or 5

	local spline = {}
	local count = #points - 1
	local p0, p1, p2, p3, x, y

	for i = 1, count do

		if i == 1 then
			p0, p1, p2, p3 = points[i], points[i], points[i + 1], points[i + 2]
		elseif i == count then
			p0, p1, p2, p3 = points[#points - 2], points[#points - 1], points[#points], points[#points]
		else
			p0, p1, p2, p3 = points[i - 1], points[i], points[i + 1], points[i + 2]
		end

		for t = 0, 1, 1 / steps do

			x = 0.5 * ( ( 2 * p1.x ) + ( p2.x - p0.x ) * t + ( 2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x ) * t * t + ( 3 * p1.x - p0.x - 3 * p2.x + p3.x ) * t * t * t )
			y = 0.5 * ( ( 2 * p1.y ) + ( p2.y - p0.y ) * t + ( 2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y ) * t * t + ( 3 * p1.y - p0.y - 3 * p2.y + p3.y ) * t * t * t )

			--prevent duplicate entries
			if not(#spline > 0 and spline[#spline].x == x and spline[#spline].y == y) then
				table.insert( spline , { x = x , y = y } )
			end

		end

	end

	return spline

end
