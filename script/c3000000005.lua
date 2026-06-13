-- Royal Sword Ember
local s,id=GetID()
local BARON_ID = 3000000002
local TOKEN_ID = 3000000003

function s.initial_effect(c)
    -- Standard Equip Spell mechanics initialization
    aux.AddEquipProcedure(c,nil,s.eqfilter)

    -- Effect 1: Static ATK Boost (+1000 ATK)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(1000)
    c:RegisterEffect(e1)

    -- Effect 2: Double Attack Condition while Wraith Token is present
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetCondition(s.atkcon)
    e2:SetValue(1) -- Grants 1 extra attack (Total of 2)
    c:RegisterEffect(e2)
end

-- Explicitly list the card footprints inside the script's tracking table
s.listed_names={BARON_ID,TOKEN_ID}

--================
-- Filter & Condition Subroutines
--================
function s.eqfilter(c)
    -- Forces the card to ONLY be allowed to equip onto Baron of Flame
    return c:IsCode(BARON_ID)
end

function s.atkcon(e)
    -- Checks if a Wraith Token (3000000003) is currently face-up on the field
    return Duel.IsExistingMatchingCard(Card.IsCode,e:GetHandlerPlayer(),LOCATION_MZONE,LOCATION_MZONE,1,nil,TOKEN_ID)
end
