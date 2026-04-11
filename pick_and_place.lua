sim = require 'sim'
simIK = require 'simIK'

function lerp(a,b,t)
    return a + (b-a)*t
end

function lerpVec(v1,v2,t)
    return {
        lerp(v1[1],v2[1],t),
        lerp(v1[2],v2[2],t),
        lerp(v1[3],v2[3],t)
    }
end

function moveIK(targetPos,targetQuat,duration)
    local startPos = sim.getObjectPosition(ikTarget,-1)
    local steps = math.max(1, math.floor(duration/stepTime))

    for i=1,steps,1 do
        local t = i/steps
        local p = lerpVec(startPos,targetPos,t)

        sim.setObjectPosition(ikTarget,-1,p)
        sim.setObjectQuaternion(ikTarget,-1,targetQuat)

        simIK.handleGroup(ikEnv,ikGroup,{syncWorlds=true})
        sim.step()
    end
end

function getJointTree(root)
    local all = sim.getObjectsInTree(root, sim.object_joint_type, 0)
    return all
end

function setGripper(openValue, duration)
    if not fingerJoints or #fingerJoints == 0 then return end

    local steps = math.max(1, math.floor(duration/stepTime))

    local startVals = {}
    for i=1,#fingerJoints,1 do
        startVals[i] = sim.getJointTargetPosition(fingerJoints[i])
        if startVals[i] == nil then
            startVals[i] = sim.getJointPosition(fingerJoints[i])
        end
    end

    local target = OPEN_POS + (CLOSE_POS - OPEN_POS) * openValue

    for s=1,steps,1 do
        local t = s/steps
        local v = lerp(startVals[1], target, t)

        for i=1,#fingerJoints,1 do
            sim.setJointTargetPosition(fingerJoints[i], v)
        end
        sim.step()
    end
end

function attachObject(obj, parent)
    sim.setObjectParent(obj, parent, true)
end

function detachObject(obj)
    sim.setObjectParent(obj, -1, true)
end

function sysCall_init()
    stepTime = sim.getSimulationTimeStep()

    base = sim.getObject('/UR5')
    cuboid = sim.getObject('/Cuboid')
    bowl = sim.getObject('/Bowl')

    hand = sim.getObject('/UR5/BarrettHand')
    attachPoint = sim.getObject('/UR5/attachPoint')

    local ok1,h1 = pcall(sim.getObject,'/ikTarget')
    if ok1 then
        ikTarget = h1
    else
        ikTarget = sim.createDummy(0.02)
        sim.setObjectAlias(ikTarget,'ikTarget')
    end

    local ok2,h2 = pcall(sim.getObject,'/ikTip')
    if ok2 then
        ikTip = h2
    else
        ikTip = sim.createDummy(0.015)
        sim.setObjectAlias(ikTip,'ikTip')
        sim.setObjectParent(ikTip,attachPoint,true)
        sim.setObjectPosition(ikTip,attachPoint,{0,0,0})
        sim.setObjectOrientation(ikTip,attachPoint,{0,0,0})
    end

    local eePos = sim.getObjectPosition(attachPoint,-1)
    local eeQuat = sim.getObjectQuaternion(attachPoint,-1)

    sim.setObjectPosition(ikTarget,-1,eePos)
    sim.setObjectQuaternion(ikTarget,-1,eeQuat)

    graspQuat = eeQuat
    homePos = eePos

    ikEnv = simIK.createEnvironment()
    ikGroup = simIK.createGroup(ikEnv)
    simIK.setGroupCalculation(ikEnv,ikGroup,simIK.method_damped_least_squares,0.05,10)
    simIK.addElementFromScene(ikEnv,ikGroup,base,ikTip,ikTarget,simIK.constraint_pose)

    fingerJoints = getJointTree(hand)

    OPEN_POS = 0.0
    CLOSE_POS = 0.55

    cubeHalfHeight = 0.025
    local minZ = sim.getObjectFloatParam(cuboid,sim.objfloatparam_objbbox_min_z)
    local maxZ = sim.getObjectFloatParam(cuboid,sim.objfloatparam_objbbox_max_z)
    if minZ and maxZ then
        cubeHalfHeight = (maxZ - minZ)/2
    end
end

function sysCall_thread()
    sim.setThreadAutomaticSwitch(true)

    setGripper(0.0, 1.0)

    local cubePos = sim.getObjectPosition(cuboid,-1)
    local bowlPos = sim.getObjectPosition(bowl,-1)

    local approachPick = {cubePos[1], cubePos[2], cubePos[3] + 0.18}
    local graspPick = {cubePos[1], cubePos[2], cubePos[3] + cubeHalfHeight + 0.02}
    local liftPick = {cubePos[1], cubePos[2], cubePos[3] + 0.24}

    -- edited bowl placement
    local approachPlace = {bowlPos[1], bowlPos[2], bowlPos[3] + 0.30}
    local releasePlace = {bowlPos[1], bowlPos[2], bowlPos[3] + 0.14}
    local retreatPlace = {bowlPos[1], bowlPos[2], bowlPos[3] + 0.32}

    moveIK(approachPick,graspQuat,2.2)
    moveIK(graspPick,graspQuat,1.3)

    setGripper(1.0, 1.0)
    attachObject(cuboid, attachPoint)
    sim.step()

    moveIK(liftPick,graspQuat,1.4)
    moveIK(approachPlace,graspQuat,2.5)
    moveIK(releasePlace,graspQuat,1.2)

    setGripper(0.0, 1.0)
    detachObject(cuboid)
    sim.step()

    moveIK(retreatPlace,graspQuat,1.2)
    moveIK(homePos,graspQuat,2.2)
end