crab_passive = class({})

LinkLuaModifier("modifier_crab_passive", "heroes/crab_passive.lua", LUA_MODIFIER_MOTION_NONE)

function crab_passive:GetIntrinsicModifierName()
    return "modifier_crab_passive"
end

modifier_crab_passive = class({})

function modifier_crab_passive:IsHidden()
    return true
end

function modifier_crab_passive:IsPurgable()
    return false
end

function modifier_crab_passive:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(1/30)
end

function modifier_crab_passive:CheckState()
    return {
      [MODIFIER_STATE_FLYING] = true,
    }
end

function modifier_crab_passive:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_crab_passive:GetModifierMoveSpeed_Max( params )
    return 10000
end

function modifier_crab_passive:GetModifierMoveSpeed_Limit( params )
    return 10000
end


function modifier_crab_passive:OnIntervalThink()
    if not IsServer() then return end
    local parent = self:GetParent()

    if not parent:IsAlive() then return end

    -- if we're close enough to an enemy hero, blow up
    local enemyHeroes = FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetOrigin(),
        nil,
        100,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_CLOSEST,
        false)

    local enemies = {}
    for _, enemy in pairs(enemyHeroes) do
        if enemy:GetUnitName() ~= "npc_dota_hero_nyx_assassin" then
            table.insert(enemies, enemy)
        end
    end

    if #enemies > 0 then
        self:BlowUp(enemies)
    end
end

function modifier_crab_passive:BlowUp(heroes)
    local parent = self:GetParent()

    local explosion_radius = 100

    local particleName = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 2, Vector(explosion_radius, 1, 1))
    ParticleManager:ReleaseParticleIndex(particle)

    -- play a sound
    EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_NyxAssassin.Impale.Target", parent)
    
    for _, hero in pairs(heroes) do
        self:AttachCrabPart(hero)
        
        local crabDebuff = hero:AddNewModifier(hero, nil, "modifier_carcinisation", {})
        crabDebuff:SetStackCount(crabDebuff:GetStackCount() + 1)
        
        -- -- if the hero has 10 crab parts, turn them into a crab
        if (crabDebuff:GetStackCount() >= 10) then
            -- become_boat(hero, "npc_dota_hero_nyx_assassin")
        end
        
        break
    end

    parent:AddNoDraw()
    parent:ForceKill(true)
end

function modifier_crab_passive:AttachCrabPart(hero)
    local crabParts = {
        "models/crabparts/anuxi_cerci_tail.vmdl",
        "models/crabparts/defiledstinger_back.vmdl",
        "models/crabparts/sand_king_ti7_immortal_arms.vmdl",
        "models/crabparts/sandking_shrimp_king_arms_v2.vmdl",
    }

    local model = GetRandomTableElement(crabParts)
    local size = RandomFloat(1, 3) * (1 / hero:GetModelScale())
    local attachment = Attachments:AttachProp(hero, "attach_hitloc", model, size, {
        pitch = RandomInt(0, 360),
        yaw = RandomInt(0, 360),
        roll = RandomInt(0, 360),
        YPos = 0,
    })
    hero.crab_parts = hero.crab_parts or {}
    table.insert(hero.crab_parts, attachment)
end

LinkLuaModifier("modifier_carcinisation", "heroes/crab_passive.lua", LUA_MODIFIER_MOTION_NONE)

modifier_carcinisation = class({})

function modifier_carcinisation:IsHidden()
    return false
end

function modifier_carcinisation:IsPurgable()
    return false
end

function modifier_carcinisation:IsDebuff()
    return true
end

function modifier_carcinisation:GetTexture()
    return "nyx_assassin_spiked_carapace"
end

function modifier_carcinisation:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    for _, part in pairs(parent.crab_parts) do
        part:RemoveSelf()
    end
end