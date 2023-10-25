--Laser Gun example mod

function init()
	--Register tool and enable it
	RegisterTool("ulelasergun", "ULE Laser Gun", ULE_modPath.."vox/lasergun.vox")
	SetBool("game.tool.ulelasergun.enabled", true)

	--Laser gun has 60 seconds of ammo. 
	--If played in sandbox mode, the sandbox script will make it infinite automatically
	SetFloat("game.tool.ulelasergun.ammo", 60)
	
	ready = 0
	fireTime = 0
	
	openSnd = LoadSound(ULE_modPath.."snd/open.ogg")
	closeSnd = LoadSound(ULE_modPath.."snd/close.ogg")
	laserSnd = LoadLoop(ULE_modPath.."snd/laser.ogg")
	hitSnd = LoadLoop(ULE_modPath.."snd/hit.ogg")
    
    ULE_name = "Laser Gun"
end

-- ULE_OnDestroy is called when a mod is destroyed using the function ULE_DestroyMod
function ULE_OnDestroy()
    SetBool("game.tool.ulelasergun.enabled", false)
end

--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function tick(dt)
	--Check if laser gun is selected
	if GetString("game.player.tool") == "ulelasergun" then
        --[[
        for k, v in pairs(ULE_mods) do
            DebugPrint("    "..tostring(k).." = "..tostring(v))
        end
        ]]--
    
		--Check if tool is firing
		if GetBool("game.player.canusetool") and InputDown("usetool") and GetFloat("game.tool.ulelasergun.ammo") > 0 then
			if ready == 0 then 
				PlaySound(openSnd) 
			end
			ready = math.min(1.0, ready + dt*4)
			if ready == 1.0 then
				PlayLoop(laserSnd)
				local t = GetCameraTransform()
				local fwd = TransformToParentVec(t, Vec(0, 0, -1))
				local maxDist = 20
				local hit, dist, normal, shape = QueryRaycast(t.pos, fwd, maxDist)
				if not hit then
					dist = maxDist
				end
				
				--Laser line start and end points
				local s = VecAdd(VecAdd(t.pos, Vec(0, -0.5, 0)),VecScale(fwd, 1.5))
				local e = VecAdd(t.pos, VecScale(fwd, dist))

				--Draw laser line in ten segments with random offset
				local last = s
				for i=1, 10 do
					local t = i/10
					local p = VecLerp(s, e, t)
					p = VecAdd(p, rndVec(0.2*t))
					DrawLine(last, p, 1, 0.5, 0.7)
					last = p
				end

				--Make damage and spawn particles
				if hit then
					PlayLoop(hitSnd, e)
					SpawnFire(e)
					MakeHole(e, 0.4, 0.2, 0.0, true)
					SpawnParticle("fire", e, rndVec(0.5), 0.5, 0.5)
					SpawnParticle("smoke", e, rndVec(0.5), 1.0, 1.0)
				end
				
				fireTime = fireTime + dt
				SetFloat("game.tool.ulelasergun.ammo", math.max(0, GetFloat("game.tool.ulelasergun.ammo")-dt))
				
				--Provide ammo display with one decimal
				SetString("game.tool.ulelasergun.ammo.display", math.floor(GetFloat("game.tool.ulelasergun.ammo")*10)/10)
			end
		else
			fireTime = 0
			if ready == 1 then
				PlaySound(closeSnd)
			end
			ready = math.max(0.0, ready - dt*4)
		end
	
		local b = GetToolBody()
		if b ~= 0 then
			local shapes = GetBodyShapes(b)

			--Control emissiveness
			for i=1, #shapes do
				SetShapeEmissiveScale(shapes[i], ready)
			end
	
			--Add some light
			if ready > 0 then
				local p = TransformToParentPoint(GetBodyTransform(body), Vec(0, 0, -2))
				PointLight(p, 1, 0.5, 0.7, ready * math.random(10, 15) / 10)
			end
			
			--Move tool
			local offset = VecScale(rndVec(0.01), ready*math.min(fireTime/5, 1.0))
			SetToolTransform(Transform(offset))
			
			--Animate 
			local t	= 1-ready
			t = t*t
			local offset = t*0.15
			
			if b ~= body then
				body = b
				--Get default transforms
				t0 = GetShapeLocalTransform(shapes[2])
				t1 = GetShapeLocalTransform(shapes[3])
			end

			t = TransformCopy(t0)
			t.pos = VecAdd(t.pos, Vec(offset))
			SetShapeLocalTransform(shapes[2], t)

			t = TransformCopy(t1)
			t.pos = VecAdd(t.pos, Vec(-offset))
			SetShapeLocalTransform(shapes[3], t)
		end
	end
end

