if CLIENT then

	local event            = hook
	local frameTime        = FrameTime
	local curTime          = CurTime
	local createFont       = surface.CreateFont
    local drawRect         = surface.DrawRect
	local drawOutlinedRect = surface.DrawOutlinedRect
	local drawSimpleText   = draw.SimpleText
    local drawMaterial     = surface.SetMaterial
    local setDrawColor     = surface.SetDrawColor
	local drawTextures     = surface.DrawTexturedRectRotated
    local scrw, scrh       = ScrW(), ScrH();
	--local playSound        = surface.PlaySound
	local format           = string.format
	local clamp            = math.Clamp
	local round            = math.Round
	local floor            = math.floor
	local ceil             = math.ceil
	local sin              = math.sin
	local lerp             = Lerp
	local ply              = LocalPlayer();
	local deathMove        = DeathMove or 0;
	--local cmdAdd           = concommand.Add

	--Main tablelibrs;
	local PRS = {};
	local IMtrls = {};
	--data
	--------------------------------
	LAST_HEALTH              = 100;
	DAMAGE_FLASH_TIME_HP     = 0;
	DAMAGE_FLASH_DURATION_HP = 0.5;
	LAST_ARMOR               = 100;
	DAMAGE_FLASH_TIME_AR     = 0;
	DAMAGE_FLASH_DURATION_AR = 0.5;
	--------------------------------
	--boolean data
	--------------------------------
	ALL_READY_MATERIAL       = true;
	--------------------------------
	--data for the timer
	PRS.MOVEMENT_TIMER = { startTime = 0, active = false, time = 0 };
	--I made a custom hook for convenience
	PRS.event = PRS.event or {};
    PRS.event.add = function( eventName, identifier, func )
        event.Add( eventName, identifier, function(...)
            return func(...);
        end)
    end
	PRS.event.delete = function( eventName, identifier )
		event.Remove( eventName, identifier );
	end
	PRS.event.run = function(eventName, ...)
    	event.Run(eventName, ...);
	end
	--Data on names and numbers
	PRS.identifier = { "PRSHud:dead", "PRSHud:hud", "PRSHud:setting", "" };
	--date of materials
	IMtrls.FILE_ARMOR     = "proj/reaspack/".."icon_armor/";
	IMtrls.FILE_HEALTH    = "proj/reaspack/".."icon_health/";
	IMtrls.FILE_SETTING   = "proj/reaspack/".."icon_setting/";
	IMtrls.FILE_LINE      = "proj/reaspack/".."icon_line/";
	IMtrls.FILE_EFFECT    = "proj/reaspack/".."effects/";
	IMtrls.FILE_CAT       = "proj/reaspack/".."icon_cat/";
	IMtrls.FILE_LOGO      = "proj/reaspack/".."icon_logo/";
	IMtrls.FILE_AMMO      = "proj/reaspack/".."icon_ammo/";
	IMtrls.FILE_CROSSHAIR = "proj/reaspack/".."icon_crosshair/"
	--function editor
    DrawRects = function( x, y, sizeX, sizeY, color )
        setDrawColor( color ); drawRect( x, y, sizeX, sizeY );
    end
	DrawTexturedRects = function( color, material, x, y, sizeX, sizeY, rotation )
		setDrawColor( color ); drawMaterial( material ); drawTextures( x, y, sizeX, sizeY, rotation );
	end
	DrawOutlinedRects = function( x, y, sizeX, sizeY, color )
		setDrawColor( color ); drawOutlinedRect( x, y, sizeX, sizeY );
	end
	--function for checking a table with materials
	function LoadMaterial( path, flags )
		local mat = Material( path, flags or "noclamp smooth da :3" );
		if mat:IsError() then
			print( "[ERROR] Failed to load material:", path );
			ALL_READY_MATERIAL = false;
			return Material( "error" );
		end
		return mat;
	end
	--method for creating text blurring
	DrawTextShadow = function( text, font, x, y, color, shadowColor, shadowOffset, blur, alignX, alignY )
    shadowOffset = shadowOffset or 2;
    blur = blur or 2;
    if blur > 0 then
        local shadowAlpha = shadowColor.a or 150;
        for bx = -blur, blur do
			for by = -blur, blur do
			local dist = math.sqrt( bx*bx + by*by );
				if dist <= blur then
				local alpha = shadowAlpha * ( 1 - dist/blur );
				drawSimpleText( text, font, x + shadowOffset + bx, y + shadowOffset + by, 
				Color( shadowColor.r, shadowColor.g, shadowColor.b, alpha), alignX, alignY );
				end
			end
        end
    else
        drawSimpleText( text, font, x + shadowOffset, y + shadowOffset, shadowColor, alignX, alignY );
	end
    	drawSimpleText( text, font, x, y, color, alignX, alignY );
	end
	--func-custom formatting an integers
	FormatNumber = function( number, digits )
		digits, number = digits or 3, math.max(0, number); --default, 3 digits...
		local format = tostring( number );
		while #format < digits do
			format = "0" .. format;
		end
		return format;
	end
	--converting time to MM:SS.mm format
	FormatTime = function( time )
		if time <= 0 then return "00:00.00"; end
		local min = floor( time / 60 );
		local sec = floor( time % 60 );
		local mil = floor( ( time * 100 ) % 100 );
		return format( "%02d:%02d.%02d", min, sec, mil );
	end
	--func to get the player's speed
	GetPlayerSpeed = function( ply )
		if not IsValid( ply ) then return 0; end
		return round( ply:GetVelocity():Length() );
	end
	--fun for the cartridge counter
	GetAmmo1 = function( ammo )
		return tostring( math.max(ammo, 0) );
	end
	--the Screen of Death:
    PRS.AddAnimDead = function( boolean, size, speed, r, g, b )
        if boolean or nil and "toka tuta :3" then

		createFont( "textDead",{ font = 'Arial', size = 45*size, weight = 999 , antialias = true , scanlines = 1 } );
		createFont( "textOnly",{ font = 'Arial', size = 20*size, weight = 999 , antialias = true , scanlines = 1 } );

        PRS.event.add( "HUDPaint", PRS.identifier[1], function()

			if (ALL_READY_MATERIAL) and not ply:Alive() then
				--parameters: animation and coordinates
				deathMove = math.min(200, (deathMove) + frameTime() * 155);
				local x, y = ( scrw / 2 ), ( scrh / 3.2 );
				local sizeW, sizeH = ( 255 * size ), ( 255 * size );
				local lerpMove = sin( curTime() * speed ) * 2;
				local lerpLag = sin( curTime() * 90 ) * 2;
				local color = Color( r or 0, g or 0, b or 0, 55 + deathMove or 0 );
				local moveDist = math.random( 80, 455 ) * ( frameTime() * 0.5 );
				--Calling a method for drawing
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_EFFECT.."fon_effect.png"), x, y-15, sizeW*1.2+lerpMove*2.2, sizeH*1.2+lerpMove*2.2, 0 );
				DrawRects( scrw/scrw, scrh/scrh, scrw, scrh, Color( 0, 0, 0, 0.5 + deathMove) );
				DrawTexturedRects( Color( 255, 255, 255, 55 + deathMove ), LoadMaterial(IMtrls.FILE_EFFECT.."fon_shadow.png"), scrw/scrw-1, scrh/2, scrw*2, scrh, 0 );
				DrawTexturedRects( Color( 255, 255, 255, 55 + deathMove), LoadMaterial(IMtrls.FILE_EFFECT.."fon_shadow.png"), scrw/scrw-1, scrh/2, scrw*2, scrh, 180 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_CAT.."icon_cat_whites.png"), x, y-15, sizeW, sizeH + 1 * lerpMove, - 0 + lerpMove );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_CAT.."icon_cat_fon.png"), x, y-15, sizeW, sizeH + 1 * lerpMove, 0 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_CAT.."icon_cat_1.png"), x, y - 16 + lerpMove, sizeW, sizeH, 0.1 + lerpMove );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_CAT.."icon_cat_2.png"), x, y - 15 - lerpMove, sizeW, sizeH, 0.1 + lerpMove );
				DrawTexturedRects( Color( r, g, b, 222 - deathMove ), LoadMaterial(IMtrls.FILE_EFFECT.."icon_break.png"), x-25, y-45, 190, 190, 0 );
				DrawTexturedRects( Color( 255, 255, 255, 76 + lerpLag), LoadMaterial(IMtrls.FILE_EFFECT.."icon_lag.png"), x + lerpLag, y+110*size-lerpLag, x / 2 * lerpLag * 1.2, y * 0.9*size, 0 );
				DrawTextShadow("YOU'RE DEAD", 'textDead', x + moveDist, y+80*size + moveDist, Color(r, g, b, clamp(155, sin(curTime() * 255) * 255, 255)), 
				Color( r- 55, g- 55, b- 55, 15), 2, 8, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTE );
				drawSimpleText("PRESS ANY BUTTON",'textOnly', x, y+155*size, Color( r, g, b, 0 + clamp(13,145 * sin(curTime() * 4) * 2,255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawRects( x-85, y+165*size, 170*size, y / 100, Color( r, g, b, 0 + clamp(13, 145 * sin(curTime() * 4) * 2,255)) );

			else
				deathMove = math.max(0, deathMove - frameTime() * 300);
			end

		end)
		else
			PRS.event.delete( "HUDPaint", PRS.identifier[1] );
		end
	end
	--the Screen of hud
	PRS.AddHud = function( boolean, size, singUp, _, r, g, b, alpha, _, r2, g2, b2, alpha2, SizeBlur, _, r3, g3, b3, _, r4, g4, b4, _, light, _, sizeCRSHair, r5, g5, b5, alpha3 )

		createFont( "textStatistic",{ font = 'Arial', size = 20*size, weight = 999 , antialias = true , scanlines = 1 } );
		createFont( "textHUD",{ font = 'Default', size = 35*size, weight = 999 , antialias = true , scanlines = 1, additive = true  } );
		createFont( "textVitals",{ font = 'Default', size = 45*size, weight = 999 , antialias = true , scanlines = 1, additive = true } );
		createFont( "textSymbol",{ font = 'Default', size = 35*size, weight = 999 , antialias = true , scanlines = 1, symbol = true } );
		createFont( "textHR",{ font = 'Arial', size = 35*size, weight = 999 , antialias = true , scanlines = 1, additive = true } );

		if boolean or nil and "toka tuta :3" then
			PRS.event.add( "HUDPaint", PRS.identifier[2], function()

				--local x, y = (scrw/100), (scrh/1.1);
				local signX, signY = (scrw/2), (scrh/1.05);
				local color = Color( r or 0, g or 0, b or 0, alpha or 0 );
				local colHealth, colArmor = Color( r3, g3, b3, alpha+light ), Color( r4, g4, b4, alpha+light );
				local colBlur = Color( r2 or 255, g2 or 255, b2 or 255, alpha2 or 15 );
				local checkVitals = ply:IsValid() and ply:IsPlayer() and ply:Alive();

				if (ALL_READY_MATERIAL) and (checkVitals) then

				--DrawTexturedRects( Color( r, g, b, 200), LoadMaterial(IMtrls.FILE_EFFECT.."fon_shadow.png"), x, y, scrw*100, 255, 0 );
				--DrawTexturedRects( Color( r, g, b, 200), LoadMaterial(IMtrls.FILE_EFFECT.."fon_shadow.png"), x, y/10, scrw*100, 255, 180 );

				DrawTexturedRects( Color( 0, 0, 0, 155 ), LoadMaterial(IMtrls.FILE_LINE.."icon_lineHealthArmor.png"), signX, signY*singUp-15*size, 502*size, 175*size, 0 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_LINE.."icon_lineHealthArmor.png"), signX, signY*singUp-13*size, 500*size, 175*size, 0 );
				DrawTexturedRects( Color( 0, 0, 0, 155 ), LoadMaterial(IMtrls.FILE_LINE.."icon_lineHud_1.png"), signX-355*size, signY*singUp-42*size, 224*size, 101*size, 0 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_LINE.."icon_lineHud_1.png"), signX-355*size, signY*singUp-40*size, 225*size, 100*size, 0 );
				DrawTexturedRects( Color( 0, 0, 0, 155 ), LoadMaterial(IMtrls.FILE_LINE.."icon_lineHud_2.png"), signX+355*size, signY*singUp-42*size, 224*size, 101*size, 0 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_LINE.."icon_lineHud_2.png"), signX+355*size, signY*singUp-40*size, 225*size, 100*size, 0 );
				--DrawTexturedRects( Color( 0, 0, 0, 155), LoadMaterial(IMtrls.FILE_LINE.."icon_indicator.png"), signX-173*size, signY*singUp+15*size, 36*size, 36*size, 0 );
				--DrawTexturedRects( Color( r, g, b, 255), LoadMaterial(IMtrls.FILE_LINE.."icon_indicator.png"), signX-175*size, signY*singUp+15*size, 32*size, 32*size, 0 );
				--DrawTexturedRects( Color( 0, 0, 0, 155), LoadMaterial(IMtrls.FILE_LINE.."icon_indicator.png"), signX+173*size, signY*singUp+15*size, 36*size, 36*size, 180 );
				--DrawTexturedRects( Color( r, g, b, 255), LoadMaterial(IMtrls.FILE_LINE.."icon_indicator.png"), signX+175*size, signY*singUp+15*size, 32*size, 32*size, 180 );
				DrawTexturedRects( Color( 255, 255, 255, 100 ), LoadMaterial(IMtrls.FILE_LOGO.."PROJOBS-4-23-2024.png"), signX*size, signY*singUp+34*size, 290*size, 55*size, 0 );

				--draw_icon_health
				DrawTextShadow("".. FormatNumber( ply:Health() ), 'textVitals', signX-380*size, signY*singUp-35*size, colHealth,
				Color( 225, 180, 0, 15), 0, SizeBlur, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER );
				DrawTextShadow("HP", 'textVitals', signX-340*size, signY*singUp-35*size, colHealth,
				Color( 225, 180, 0, 15), 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_HEALTH.."icon_health_shadow_line.png"), signX-245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
				DrawTexturedRects( Color( r3, g3, b3, 22 ), LoadMaterial(IMtrls.FILE_HEALTH.."icon_health.png"), signX-245*size, signY*singUp-25*size, 135*size, 135*size, 0 );

				IMtrls.ICON_HEALTH = {};
				for i = 1, 10 do
					local strIndex = tostring(i);
					IMtrls.ICON_HEALTH[strIndex] = LoadMaterial( IMtrls.FILE_HEALTH .. "icon_health_" .. i .. ".png");
				end
				local curHealth, maxHealth = ply:Health(), ply:GetMaxHealth() or 100;
				local healthPercent = round((curHealth / maxHealth) * 100);
				--sound effect on damage
				--is the damage received or not
				if curHealth < LAST_HEALTH then
					DAMAGE_FLASH_TIME_HP = curTime() + DAMAGE_FLASH_DURATION_HP;
				--   playSound("hl1/fvox/boop.wav");
				end
				LAST_HEALTH = curHealth; --saves for the next frame

				if curHealth > 0 and healthPercent > 0 then

					local iconIndexHP = ceil(healthPercent / 10);
					iconIndexHP = clamp(iconIndexHP, 1, 10);
					local strIconIndexHP = tostring(iconIndexHP);
					local healthMaterial = IMtrls.ICON_HEALTH[strIconIndexHP];

					if healthMaterial then
						local drawColor_hp = colHealth;
						--Calculate the animation progress (from 1 to 0)
						if curTime() < DAMAGE_FLASH_TIME_HP then
							local prog = ( DAMAGE_FLASH_TIME_HP - curTime() ) / DAMAGE_FLASH_DURATION_HP;
							prog = clamp( prog, 0, 1 );
							--flashing effect
							local flashInt = sin( curTime() * 20 ) * 0.5;
							flashInt = flashInt * prog;
							drawColor_hp = Color(
								lerp(flashInt, colHealth.r, 255),  --red
                				lerp(flashInt, colHealth.g, 50),   --green 
                				lerp(flashInt, colHealth.b, 50),   --blue
                			colHealth.a
							);
						end
						DrawTexturedRects( drawColor_hp, healthMaterial, signX-245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
					end
				else
					local emptyMaterial = LoadMaterial(IMtrls.FILE_HEALTH.."icon_health.png");
					DrawTexturedRects( Color( 0, 0, 0, 0 ), emptyMaterial, signX-245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
				end

				--draw_icon_armor
				DrawTextShadow(""..FormatNumber( ply:Armor() ), 'textVitals', signX+380*size, signY*singUp-35*size, colArmor,
				Color( 0, 180, 225, 15), 0, SizeBlur, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER );
				DrawTextShadow("AR", 'textVitals', signX+340*size, signY*singUp-35*size, colArmor,
				Color( 0, 180, 225, 15), 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_ARMOR.."icon_armor_shadow_line.png"), signX+245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
				DrawTexturedRects( Color( r4, g4, b4, 22 ), LoadMaterial(IMtrls.FILE_ARMOR.."icon_armor.png"), signX+245*size, signY*singUp-25*size, 135*size, 135*size, 0 );

				IMtrls.ICON_ARMOR = {};
				for i = 1, 10 do
					local strIndex = tostring(i);
					IMtrls.ICON_ARMOR[strIndex] = LoadMaterial( IMtrls.FILE_ARMOR .. "icon_armor_" .. i .. ".png");
				end
				local curArmor, maxArmor = ply:Armor(), ply:GetMaxArmor() or 100;
				local armorPercent = round((curArmor / maxArmor) * 100);
				--sound effect on damage
				--is the damage received or not
				if curArmor < LAST_ARMOR then
					DAMAGE_FLASH_TIME_AR = curTime() + DAMAGE_FLASH_DURATION_AR;
				--    playSound("hl1/fvox/boop.wav");
				end
				LAST_ARMOR = curArmor; --saves for the next frame

				if curArmor > 0 and armorPercent > 0 then
					local iconIndexAR = ceil( armorPercent / 10 );
					iconIndexAR = clamp( iconIndexAR, 1, 10 );
					local strIconIndexAR = tostring(iconIndexAR);
					local armorhMaterial = IMtrls.ICON_ARMOR[strIconIndexAR];
					if armorhMaterial then
						local drawColor_ar = colArmor;
						--calculate the animation progress (from 1 to 0)
						if curTime() < DAMAGE_FLASH_TIME_AR then
							local prog = ( DAMAGE_FLASH_TIME_AR - curTime() ) / DAMAGE_FLASH_DURATION_AR;
							prog = clamp( prog, 0, 1 );
							--flashing effect
							local flashInt = sin( curTime() * 20 ) * 0.5;
							flashInt = flashInt * prog;
							drawColor_ar = Color(
								lerp(flashInt, colArmor.r, 255),  --red
								lerp(flashInt, colArmor.g, 50),   --green 
								lerp(flashInt, colArmor.b, 50),   --blue
							colArmor.a
							);
						end
						DrawTexturedRects( drawColor_ar, armorhMaterial, signX+245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
					end
				else
					local emptyMaterial = LoadMaterial(IMtrls.FILE_ARMOR.."icon_armor.png");
					DrawTexturedRects( Color (0, 0, 0, 0 ), emptyMaterial, signX+245*size, signY*singUp-25*size, 135*size, 135*size, 0 );
				end
				--draw icon_ammo
				local weapon = LocalPlayer():GetActiveWeapon();
				if not weapon:IsValid() then return end

				DrawTexturedRects( Color( 0, 0, 0, 155 ), LoadMaterial(IMtrls.FILE_AMMO.."icon_ammo.png"), signX+341*size, signY*singUp+19*size, 47*size, 45*size, 0 );
				DrawTexturedRects( color, LoadMaterial(IMtrls.FILE_AMMO.."icon_ammo.png"), signX+340*size, signY*singUp+19*size, 44*size, 42*size, 0 );
				if weapon.Clip1 then
					local ammo1 = GetAmmo1( weapon:Clip1() );
					DrawTextShadow(ammo1, 'textVitals', signX+365*size, signY*singUp+19*size, Color( 255, 255, 255, 255),
					Color( 255, 255, 255, 15), 0, SizeBlur, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER );
				end

				local fps = clamp( round( 1 / frameTime() ), 0, 9999 );
				local ping = clamp( ply:Ping(), 0, 9999 );
				local speed = GetPlayerSpeed( ply );

				DrawTextShadow( speed .. "", 'textVitals', signX, signY*singUp-44*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );

				local movingNow = speed > 0;
				--timer start/stop logic
				if movingNow then
					if not PRS.MOVEMENT_TIMER.active then
						PRS.MOVEMENT_TIMER.startTime = curTime();
						PRS.MOVEMENT_TIMER.active = true;
					end
					PRS.MOVEMENT_TIMER.time = curTime() - PRS.MOVEMENT_TIMER.startTime;
				else
					if PRS.MOVEMENT_TIMER.active then
						PRS.MOVEMENT_TIMER.active = false;
					end
					PRS.MOVEMENT_TIMER.time = 0;
				end
				--counter timer
				local timer = "TIME SP:| " .. FormatTime( PRS.MOVEMENT_TIMER.time ) .. " |";
				--draw unfo
				DrawTextShadow( timer, 'textStatistic', signX-180*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER );
				DrawTextShadow("FPS:|", 'textStatistic', signX+3*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTextShadow( fps .. "", 'textStatistic', signX+46*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTextShadow("|", 'textStatistic', signX+69*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTextShadow("PING:|", 'textStatistic', signX+104*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTextShadow( ping .. "", 'textStatistic', signX+151*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				DrawTextShadow("|", 'textStatistic', signX+174*size, signY*singUp+7*size, Color(r, g, b, 155),
				colBlur, 0, SizeBlur, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER );
				--draw crosshair
				local scr_x, scr_y = (scrw/2), (scrh/2);
				local CRSHair_col = Color( r5, g5, b5, alpha3 );
				DrawTexturedRects( Color( 0, 0, 0, 100), LoadMaterial( IMtrls.FILE_CROSSHAIR.. "icon_crosshair.png" ), scr_x+0*sizeCRSHair, scr_y+0*sizeCRSHair, 225*sizeCRSHair, 125*sizeCRSHair, 0 );
				DrawTexturedRects( CRSHair_col, LoadMaterial( IMtrls.FILE_CROSSHAIR.. "icon_crosshair.png" ), scr_x+0*sizeCRSHair, scr_y+0*sizeCRSHair, 220*sizeCRSHair, 120*sizeCRSHair, 0 );
				if ply:KeyDown( IN_ATTACK ) then
					DrawTexturedRects( Color( 0, 0, 0, 100), LoadMaterial( IMtrls.FILE_CROSSHAIR.. "icon_crosshair_click.png" ), scr_x+0*sizeCRSHair, scr_y+0*sizeCRSHair, 225*sizeCRSHair, 148*sizeCRSHair, 0 );
					DrawTexturedRects( CRSHair_col, LoadMaterial( IMtrls.FILE_CROSSHAIR.. "icon_crosshair_click.png" ), scr_x+0*sizeCRSHair, scr_y+0*sizeCRSHair, 220*sizeCRSHair, 144*sizeCRSHair, 0 );
				else return; end

				end

			end)
		else
			PRS.event.delete( "HUDPaint", PRS.identifier[2] );
		end
	end
	--calling the method
	PRS.AddAnimDead( true, 1, 8, 255, 255, 255 );
	PRS.AddHud( true, 1, 1, "Color", 255, 255, 255, 200,
	"Blur", 255, 255, 255, 15, 4,
	"health", 225, 180, 0,
	"armor", 0, 180, 225,
	"HPARlight", 20,
	"CrossHair", 1, 255, 255, 255, 155
	);
	--disable the hook
	local hide = {
		["CHudHealth"] = true,
		["CHudBattery"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudCrosshair"] = true
	}
	hook.Add( "HUDShouldDraw", "HideHUD", function( name )
		if ( hide[ name ] ) then
			return false
		end
	end )
	PRS.event.add("HUDShouldDraw", "HideDeathScreen", function(name)
    if name == "CHudDeathNotice" or name == "CHudDamageIndicator" then
			return false;
		end
	end);

end
