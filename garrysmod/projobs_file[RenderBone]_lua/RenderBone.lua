if CLIENT then
	
	local event  = hook
	local target = nil;
	
    --I made a custom hook for convenience
	event.add = function( eventName, identifier, func )
        event.Add( eventName, identifier, function(...)
            return func(...);
        end)
    end
    
	event.delete = function( eventName, identifier )
		event.Remove( eventName, identifier );
	end
	
	event.run = function(eventName, ...)
    	event.Run(eventName, ...);
	end
	--list of bones:
	local Bones = {
		[1] = "ValveBiped.Bip01_Head1",
	    [2] = "ValveBiped.Bip01_Neck1",
	    [3] = "ValveBiped.Bip01_Spine4",
	    [4] = "ValveBiped.Bip01_Spine2",
	    [5] = "ValveBiped.Bip01_Spine1",
	    [6] = "ValveBiped.Bip01_Spine",
	    [7] = "ValveBiped.Bip01_L_Clavicle",
	    [8] = "ValveBiped.Bip01_L_UpperArm",
	    [9] = "ValveBiped.Bip01_L_Forearm",
	    [10] = "ValveBiped.Bip01_L_Hand",
	    [11] = "ValveBiped.Bip01_R_Clavicle",
	    [12] = "ValveBiped.Bip01_R_UpperArm",
	    [13] = "ValveBiped.Bip01_R_Forearm",
	    [14] = "ValveBiped.Bip01_R_Hand",
	    [15] = "ValveBiped.Bip01_L_Thigh",
	    [16] = "ValveBiped.Bip01_L_Calf",
	    [17] = "ValveBiped.Bip01_L_Foot",
	    [18] = "ValveBiped.Bip01_R_Thigh",
	    [19] = "ValveBiped.Bip01_R_Calf",
	    [20] = "ValveBiped.Bip01_R_Foot",
	};

	event.add( "HUDPaint", "RenderBone", function()
		
		local ply = LocalPlayer();
	    if not IsValid( ply ) then return end
	    
	    for _, players in ipairs( player.GetAll() ) do
	    	
		    if not IsValid( players ) then continue end
			if players == LocalPlayer() then continue end

		    local headBone = players:LookupBone( Bones[1] );
		    if not headBone then continue end
		
		    local headPos = players:GetBonePosition( headBone );
		    if not headPos then continue end
		
		    local screen = ( headPos + Vector( 0, 0, 8 ) ):ToScreen();
		    
			local name = players:GetName();
			local w1, h1 = surface.GetTextSize( name );
			
	    	draw.SimpleText( name, "Default", screen.x, screen.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM );
	    	surface.SetDrawColor( 255, 255, 255, 55 );
	    	surface.DrawOutlinedRect( screen.x - w1 / 2 -4, screen.y - h1, w1 + 8, h1 + 4 );
	    	
			local pos = players:GetPos();
			local textPos = string.format( "X: %.0f  Y: %.0f  Z: %.0f", pos.x, pos.y, pos.z );

			local w2, h2 = surface.GetTextSize( textPos );
			
			draw.SimpleText( textPos, "Default", screen.x, screen.y - 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP );
			surface.DrawOutlinedRect( screen.x - w2/2 - 4, screen.y - 30 - 2, w2 + 8, h2 + 4 );
			
			local dist = ply:GetPos():Distance( players:GetPos() ) * 0.0254; //measurement in meters
			
			if dist > 10 then
				local textDist = string.format("Dist: %.1f m", dist);
				local w3, h3 = surface.GetTextSize( textDist );
				
				draw.SimpleText( textDist, "Default", screen.x, screen.y + 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP );
				surface.SetDrawColor( 255, 255, 255, 55 );
		    	surface.DrawOutlinedRect( screen.x - w3 / 2 -4, screen.y + 8, w3 + 8, h3 + 4 );
			end
				
		end
	    
	    local tr = ply:GetEyeTrace();
	    local target = tr.Entity;
	    
		if IsValid(LastTarget) and LastTarget ~= target then
			LastTarget:SetRenderMode( RENDERMODE_NORMAL );
			LastTarget:SetColor( Color( 255, 255, 255, 255 ) );
			LastTarget = nil;
		end
			
	    if IsValid( tr.Entity ) and tr.Entity:IsPlayer() then
			
			target:SetRenderMode(RENDERMODE_TRANSALPHA);
		    target:SetColor( Color( 255, 255, 255, 200 ) );
		    LastTarget = target;
		    
	    	for _, boneName in ipairs( Bones ) do
				
		        local bone = target:LookupBone( boneName );
		        if not bone then continue end
		
		        local parent = target:GetBoneParent( bone );
		        if parent < 0 then continue end
		
		        local pos1 = target:GetBonePosition( bone );
		        local pos2 = target:GetBonePosition( parent );
		
		        if not pos1 or not pos2 then continue end
		
		        local point1 = pos1:ToScreen();
		        local point2 = pos2:ToScreen();
	
		        surface.SetDrawColor( 255, 255, 255, 255 );
		        surface.DrawLine( point1.x, point1.y, point2.x, point2.y );
		        surface.DrawRect( point1.x-2, point1.y-2, 4, 4 );
		        
		        local radius = 10 + math.sin( CurTime() * 6 ) * 3;
		        
		        if boneName == Bones[1] then
    				surface.DrawCircle(point1.x, point1.y, radius, Color( 255, 255, 255, 255 ) );
    			end
    			
    			local bone = target:LookupBone(boneName)
    			if not bone then continue end
    			
    			if boneName == Bones[1] then
    				
    				local headPos = target:GetBonePosition( bone );
    				
    				if headPos then
    					
    					local stPos = headPos;
    					local endPos = headPos + target:EyeAngles():Forward() * 25;
    					
    					local point1 = stPos:ToScreen();
        				local point2 = endPos:ToScreen();
        				
    					surface.SetDrawColor( 255, 255, 255, 255 );
        				surface.DrawLine( point1.x, point1.y, point2.x, point2.y );
        				
        				local ang  = target:EyeAngles();
        				local textAng = string.format( "P: %.1f\nY: %.1f", ang.p, ang.y );
        				
						local w1 = surface.GetTextSize( string.format( "P: %.1f", ang.p ) );
						local w2 = surface.GetTextSize( string.format( "Y: %.1f", ang.y ) );
						
						local w = math.max( w1, w2 );
						local h = select( 2, surface.GetTextSize( "A" ) ) * 3;
						
						surface.SetDrawColor( 255, 255, 255, 55 );
						surface.DrawOutlinedRect( point2.x - w / 2 - 3, point2.y - h / 1.2 - 2, w + 8, h - 4 );
						
						draw.DrawText( textAng, "Default", point2.x, point2.y - h/1.2, color_white, TEXT_ALIGN_CENTER );
						surface.SetDrawColor( 255, 255, 255, 255 );
						surface.DrawRect( point2.x, point2.y, 3, 3 );
						
					end
				
				end
				
	    	end

    	end
	    
	end)
	
	//event.delete("HUDPaint","RenderBone");
end