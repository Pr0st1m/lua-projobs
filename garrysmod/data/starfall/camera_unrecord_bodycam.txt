--@name Camera_unrecord_bodycam
--@author Pr0st1m

if CLIENT then
    
    // GITHUB:  https://github.com/Pr0st1m/lua-projobs/tree/main/garrysmod/data/starfall/Camera_unrecord_bodycam"; //:3
    
    local event            = hook
    local EventAdd         = event.add //to avoid recursion!
    local scrW, scrH       = render.getGameResolution(); //Screen size check
    local targetBone       = "ValveBiped.Bip01_Head1" //The name of the right arm bone
    local OWNER            = owner();
    local curAnim          = Angle();
    local LoadMaterial     = {};
    local recStartTime     = timer.curtime();
    
    ------------------------
    SIZE_EFFECT        = 1.15;      //Do not touch!
    MAX_DIST_CROSSHAOR = 155;
    MAX_DIST_HIDE      = 200;
    _FOV               = 150;       // setting FOV!
    X,Y,Z              = 10, -3, 3; //Camera view setting
    ------------------------
    
    if player() != OWNER then return end
    if player() == OWNER then enableHud(nil, true); end
    
    //list of materials:
    local mat_list = { "Lenseffect", "Icon1", "Icon2", "Icon3", "Icon4", "Icon5", "Icon6", "Icon7", "Icon8" };
    
    //I made a custom hook for conveniance:
    event.add = function( eventName, strName, func )
        EventAdd(eventName, strName, function( ... )
            return func( ... );
        end)
    end
    
    event.delete = function( eventName, strName )
        event.remove( eventName, strName );
    end
    
    event.run = function(eventName, ... )
        event.run(eventName, ... );
    end
    
    //Fish eye setting:
    local FloatParams = {
        ["$refractamount"] = -0.07,
        ["$model"]         = 1,
        ["$nodecal"]       = 1,
        ["$envmap"]        = 0,
        ["$envmapint"]     = 0,
        ["$ignorez"]       = 1,
        ["$flags"]         = 512 //bit or 512
    };

    local TextureParams = {
        ["basetexture"] = "_rt_fullframefb",
        ["$dudvmap"]    = "models/effects/fisheyelens_dudv",
        ["$normalmap"]  = "models/effects/fisheyelens_normal"
    };
    
    MaterialSetup = function(mat, textures, floats)
        for name, value in pairs(textures) do mat:setTexture(name, value); end
        for name, value in pairs(floats) do mat:setFloat(name, value); end
    end
    
    local FISHEYE_EFFECT = material.create("Refract_DX90");
    MaterialSetup( FISHEYE_EFFECT, TextureParams, FloatParams );
    
    //createRender list:
    local targetRender;
    for _, list in pairs(mat_list) do 
        targetRender = render.createRenderTarget( list );
    end
    
    //URL materials:
    local URLGITHUB = {
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/Battery_1.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/Battery_2.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/Battery_3.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/Battery_4.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/Battery_5.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/REC_1.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/REC_2.png",
        "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/169.png",
    };
    
    //Creating texture:
    for i, url in ipairs(URLGITHUB) do
        local mat = material.create("UnlitGeneric")
        if mat then
            mat:setTextureURL("$basetexture", url)
            LoadMaterial[i] = mat
        end
    end
    
    //Creating effect dirty lens:
    render.createRenderTarget("dirtyLens");
    local dirtyLens = material.create("gmodscreenspace");
    dirtyLens:setTextureURL("$basetexture", "https://raw.githubusercontent.com/Pr0st1m/lua-projobs/refs/heads/main/garrysmod/materials/proj/reaspack/icon_bodycam/DirtyLens.png");
    if dirtyLens then
        LoadMaterial["dirtyLens"] = dirtyLens;
    end
    
    //Creating texture:
    createMaterial = function( sh, key, name )
        local mat = material.create( sh );
        mat:setTextureRenderTarget( key, name );
        return mat;
    end
    
    //Timer:
    local function formatTime(time)
        local year = math.floor(time / 31536000);
        time = time % 31536000;
        local month = math.floor(time / 2592000);
        time = time % 2592000;
        local week = math.floor(time / 604800);
        time = time % 604800;
        local day = math.floor(time / 86400);
        return year .. ":" .. month .. ":" .. week .. ":" .. day .. ":";
    end
    
    //A function for creating Stencil Mask:
    local paintMask = function( mask )
        
        render.clearStencil()
        render.setStencilEnable(true)
        render.setStencilWriteMask(1)
        render.setStencilTestMask(1)
        render.setStencilFailOperation(STENCIL.REPLACE)
        render.setStencilPassOperation(STENCIL.ZERO)
        render.setStencilZFailOperation(STENCIL.ZERO)
        render.setStencilCompareFunction(STENCIL.NEVER)
        render.setStencilReferenceValue(1)

        mask();
    
        render.setStencilCompareFunction(STENCIL.EQUAL);
        render.setStencilReferenceValue(0);
        render.setStencilFailOperation(STENCIL.ZERO);
        render.setStencilPassOperation(STENCIL.REPLACE);
        
    end
    
    local popMask = function()
        render.setStencilEnable(false);
    end

    //Setting for camera smoothness:
    local lastEyeAng = render.getAngles();
    local MoveX      = 0;
    local MoveY      = 0;
    local LOOK_SCALE = 12;
    local SMOOTH     = 12;
    local MAX_MOVE   = 120;
    
    event.add("DrawHUD", "FisheyeEffect", function()
        
        render.updateScreenEffectTexture();
    
        local ang = render.getAngles();
        local delta = ang - lastEyeAng;
    
        delta.p = math.normalizeAngle(delta.p);
        delta.y = math.normalizeAngle(delta.y);
    
        local targetX = math.clamp(-delta.y * LOOK_SCALE, -MAX_MOVE, MAX_MOVE);
        local targetY = math.clamp(delta.p * LOOK_SCALE, -MAX_MOVE, MAX_MOVE);
    
        MoveX = MoveX + (targetX - MoveX) * math.min(SMOOTH * timer.frametime(), 1);
        MoveY = MoveY + (targetY - MoveY) * math.min(SMOOTH * timer.frametime(), 1);
    
        lastEyeAng = ang;
    
        local w = scrW * SIZE_EFFECT * 1.2;
        local h = scrH * SIZE_EFFECT * 1.2;
    
        render.setMaterial( FISHEYE_EFFECT );
        render.drawTexturedRect( (scrW - w) / 2 + MoveX, (scrH - h) / 2 + MoveY, w, h );
        ///   
              
    end)
    
    event.add("RenderOffscreen", "RenderTargets", function()
        
        for i = 1, 8 do
            render.selectRenderTarget("Icon" .. i) do
                render.clear(Color(0, 0, 0, 0))
                render.setMaterial(LoadMaterial[i])
                render.drawTexturedRect(0, 0, 1024, 1024)
            end
        end
        
        render.selectRenderTarget("dirtyLens") do
            render.clear(Color(0, 0, 0, 0))
            render.setMaterialEffectDownsample( FISHEYE_EFFECT, 2.15, 2 );
            render.setMaterialEffectBloom( FISHEYE_EFFECT, 0.1, 1, 0.4, 2 );
            render.drawTexturedRect( -200, -200, 1224, 1224 );
            render.drawBlurEffect( 12, 12, 5 );
            render.setMaterialEffectSub( dirtyLens );
            render.drawTexturedRect (0, 0, 1024, 1024 );
        end
        
        render.selectRenderTarget("Lenseffect") do
            
            render.clear(Color(0, 0, 0, 0));
            
            paintMask(function()
                local size = 400 * SIZE_EFFECT;
                render.drawFilledCircle( 512, 512, size );
            end);
            
            render.setMaterial( FISHEYE_EFFECT );
            render.drawTexturedRect( 100, 100, scrW, scrW );
            popMask();
            render.drawBlurEffect(5, 5, 10);
            
            paintMask(function()
                local size = 450 * SIZE_EFFECT;
                render.drawFilledCircle( 512, 512, size );
            end);
            
            render.setColor( Color(0, 0, 0, 255) );
            render.drawRect( 0, 0, scrW, scrH );
            popMask();
            render.drawBlurEffect( 3, 3, 10 );
        end

        render.selectRenderTarget();
        
    end)
    
    local lensRT = createMaterial( "UnlitGeneric","$basetexture", "Lenseffect" );
    local Icon = {};
    
    for i = 1, 8 do
        Icon[i] = createMaterial( "UnlitGeneric", "$basetexture", "Icon" .. i );
    end

    local DirtyLens = createMaterial( "UnlitGeneric", "$basetexture", "dirtyLens" );

    event.add("DrawHUD", "Lenseffect", function()
    
        local maxX = (scrW * SIZE_EFFECT - scrW) / 2;
        local maxY = (scrH * SIZE_EFFECT - scrH) / 2;
        
        local x = (scrW - scrW * SIZE_EFFECT) / 2 + math.clamp(MoveX, -maxX, maxX);
        local y = (scrH - scrH * SIZE_EFFECT) / 2 + math.clamp(MoveY, -maxY, maxY);
     
        render.setMaterial(lensRT);
        render.drawTexturedRect( x, y, scrW * SIZE_EFFECT, scrH * SIZE_EFFECT );
        
    end)
    
    local scale = math.min(scrW / 1920, scrH / 1080);
    local fontSize = math.floor(33 * scale);

    //CreateFont:
    local fontMono1 = render.createFont( "Roboto Mono", fontSize, 500, false, false, false, false, 0, false, 0 );
    local fontMono2 = render.createFont( "Roboto Mono", fontSize + 11, 500, false, false, false, false, 0, false, 0 );

    event.add("PostDrawHUD", "HideScreen", function()
        
        local maxX = (scrW * SIZE_EFFECT - scrW) / 2;
        local maxY = (scrH * SIZE_EFFECT - scrH) / 2;
        
        local x = (scrW - scrW * SIZE_EFFECT) / 2 + math.clamp(MoveX, -maxX, maxX);
        local y = (scrH - scrH * SIZE_EFFECT) / 2 + math.clamp(MoveY, -maxY, maxY);
        
        render.setMaterial( FISHEYE_EFFECT );
        render.drawTexturedRect( x, y, scrW * SIZE_EFFECT, scrH * SIZE_EFFECT );
        
        --render.setMaterialEffectAdd( lensRT );
        --render.drawTexturedRect( x, y, scrW * SIZE_EFFECT, scrH * SIZE_EFFECT );
        
        //Effect Dirty lens:
        render.setMaterialEffectAdd( DirtyLens );
        --render.setColor(Color(255, 255, 255, 120))
        render.drawTexturedRect( x, y, scrW * SIZE_EFFECT, scrH * SIZE_EFFECT );
        
        render.setMaterial( lensRT );
        render.drawTexturedRect( x, y, scrW * SIZE_EFFECT, scrH * SIZE_EFFECT );   
        
        //HUD HP:
        local size          = 255 * scale;
        local curHealth     = OWNER:getHealth();
        local maxHealth     = OWNER:getMaxHealth() or 100;
        local healthPercent = math.clamp(curHealth / maxHealth, 0, 1);
        local batteryX      = x + scrW - 200 * scale;
        local batteryY      = y + 255 * scale;
        
        render.setMaterial(Icon[1]);
        render.setColor(Color(255, 255, 255, 120));
        render.drawTexturedRectRotated( batteryX, batteryY, size, size, 0 );
    
        -- HP
        if healthPercent > 0 then
    
            local batteryLevel = 2 + math.floor((1 - healthPercent) * 4);
            batteryLevel = math.clamp(batteryLevel, 2, 5);

            if healthPercent <= 0.15 then
                local showBattery = math.floor(timer.curtime() * 4) % 2 == 0
                if showBattery then
                    render.setMaterial(Icon[5]);
                    render.setColor(Color(255, 255, 255, 120));
                    render.drawTexturedRectRotated( batteryX, batteryY, size, size, 0 );
                end
            else
                render.setMaterial(Icon[batteryLevel]);
                render.setColor(Color(255, 255, 255, 120));
                render.drawTexturedRectRotated( batteryX, batteryY, size, size, 0 );
            end
            
        end
    
        //DATE / TIME:
        local date = os.date("*t")
        local dateText = string.format( "%02d.%02d.%04d", date.day, date.month, date.year );
        local timeText = string.format( "%02d:%02d:%02d", date.hour, date.min, date.sec );
    
        render.setFont(fontMono1)
        render.drawText( batteryX, batteryY - 135 * scale, dateText );
        render.drawText( batteryX, batteryY - 105 * scale, timeText );
        
        //REC / TIMER:
        local recX = x + 400 * scale;
        local recY = y + 255 * scale;
        
        render.setMaterial(Icon[6]);
        render.setColor(Color(255, 255, 255, 120));
        render.drawTexturedRectRotated( recX, recY, size, size, 0 )
        
        if math.floor(timer.curtime() * 2) % 2 == 0 then
            render.setMaterial(Icon[7]);
            render.setColor(Color(255, 0, 0, 120));
            render.drawTexturedRectRotated( recX - 10, recY, size, size, 0 )
        end
        
        //TIMER:
        local recTime = math.max(timer.curtime() - recStartTime, 0)
        local hours = math.floor(recTime / 3600)
        local minutes = math.floor((recTime % 3600) / 60)
        local seconds = math.floor(recTime % 60)
        local recTimeText = string.format( "%02d:%02d:%02d", hours, minutes, seconds );
        
        render.setFont(fontMono2)
        render.setColor(Color(255, 255, 255, 120))
        render.drawText( recX + 1 * scale, recY - 125 * scale, recTimeText );
        
        render.setMaterial(Icon[8]);
        render.setColor(Color(255, 255, 255, 120));
        render.drawTexturedRectRotated( recX + 11, recY + 45, size + 35, size - 5, 0 )
        
        render.setFont(fontMono1)
        render.setColor(Color(255, 255, 255, 120))
        render.drawText( recX - 17 * scale, recY - 72 * scale, "1920x1080 FULL-HD 60 FPS" );
        
        local text    = "BODYCAM PROJOBS ACCESS V0.1.12 11/08/2026"; //:3

        render.setFont(fontMono1);
        render.setColor(Color(255, 255, 255, 120));
        
        local textW, textH = render.getTextSize( text );
        
        local textX = x + (scrW * SIZE_EFFECT) / 2 - textW / 2;
        local textY = y + scrH * SIZE_EFFECT - 140 * scale;
        
        render.drawText( textX, textY, text );
        
    end)
    
    //Cteated crosshair:   
    local drawCrosshair = function()
    
        local tr = OWNER:getEyeTrace();
        if not tr then return end
        local eyePos = render.getEyePos();
        local hitPos = tr.HitPos;
     
        if eyePos:getDistance(hitPos) > MAX_DIST_CROSSHAOR then
            return
        end
    
        local ang = (hitPos - eyePos):getAngle();
        local m = Matrix( ang + Angle(90, 0, 0), hitPos - ang:getForward() * 10 );
    
        m:rotate(Angle(0, -90, 0));
        render.pushMatrix(m);
        render.enableDepth(false);
        render.setColor(Color(255, 255, 255, 220));
    
        local length    = 2;
        local gap       = 0.3;
        local thickness = 0.3;
    
        render.drawRect( -thickness / 2, -gap - length, thickness, length );
        render.drawRect( -thickness / 2, gap, thickness, length );
        render.drawRect( -gap - length, -thickness / 2, length, thickness );
        render.drawRect( gap, -thickness / 2,length, thickness );
    
        render.popMatrix();
    
    end
    
    //HidePlayer:
    local hidePlayer = function()
        
        local eyePos = render.getEyePos();
        local players = find.byClass("player");
    
        for _, v in ipairs(players) do
            if v == OWNER or not v:isAlive() then
                goto cont;
            end
    
            local mins, maxs = v:getCollisionBounds();
            if not mins or not maxs then
                goto cont;
            end
    
            local height = maxs.z - mins.z;
            local width = math.max(maxs.x - mins.x, maxs.y - mins.y);
            width = width * 1.1;
            local playerPos = v:getPos() + Vector( 0,0, (mins.z + maxs.z) / 2 );
    
            local distance = eyePos:getDistance(playerPos);
    
            if distance > MAX_DIST_HIDE then
                goto cont
            end
    
            local ang = (playerPos - eyePos):getAngle();
            local m = Matrix( ang + Angle(90, 0, 0), playerPos - ang:getForward() * 10 );
    
            m:rotate(Angle(0, -90, 0));
                render.pushMatrix(m);
                render.enableDepth(false);
                render.setColor(Color(255, 255, 255, 220));
                render.drawRectOutline( -width / 2, -height / 2, width, height, 1 );
            render.popMatrix();
    
            ::cont::
        end
    end
    
    event.add("PostDrawTranslucentRenderables","Crosshair",drawCrosshair);
    event.add("PostDrawTranslucentRenderables","HidePlayer",hidePlayer);


    local offset = Vector( X, Y, Z );
    
    event.add("CalcView", "ViewHead", function( origin, angles, fov )
        
        if not isValid(OWNER) then
            return { origin = origin, angles = angles, fov = fov };
        end
        
        local boneIndex = OWNER:lookupBone( targetBone );
        
        if boneIndex then
            local bonePos, boneAng = OWNER:getBonePosition( boneIndex );
            if bonePos then 
                local finalPos = bonePos + boneAng:getForward() * offset.x + boneAng:getRight() * offset.y  + boneAng:getUp() * offset.z;
                return {
                    origin = finalPos, 
                    angles = angles, 
                    fov = _FOV or 0
                };
            end
        end
        
        return { origin = origin, angles = angles, fov = fov };
        
    end)
    
end