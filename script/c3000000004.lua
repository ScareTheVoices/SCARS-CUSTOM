-- Wraith Claw! (Art-Matched)
local s,id=GetID()
local BARON_ID = 3000000002
local TOKEN_ID = 3000000003

function s.initial_effect(c)
    -- Equip standard setup
    aux.AddEquipProcedure(c,nil,s.eqfilter)

    -- Effect 1: Blazing Core (Burn 500 + Gain 500 ATK ignition)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0)) -- Prompt: Ignite Core
    e1:SetCategory(CATEGORY_DAMAGE+CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.burntg)
    e1:SetOperation(s.burnop)
    c:RegisterEffect(e1)

    -- Effect 2: Searing Claws (Armades/Ancient Gear battle locking trap seal)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(0,1)
    e2:SetCondition(s.actcon)
    e2:SetValue(s.actval)
    c:RegisterEffect(e2)

    -- Effect 3: Total Incineration (Send 1 card to GY on battle victory)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1)) -- Prompt: Incinerate 1 card
    e3:SetCategory(CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_BATTLE_DESTROYING)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1,id+1)
    e3:SetCondition(s.tgcon)
    e3:SetTarget(s.tgtg)
    e3:SetOperation(s.tgop)
    c:RegisterEffect(e3)
end

s.listed_names={BARON_ID,TOKEN_ID}

function s.eqfilter(c)
    return c:IsCode(BARON_ID) or c:IsCode(TOKEN_ID)
end

--================
-- Blazing Core Subroutines
--================
function s.burntg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():GetEquippedItem() ~= nil end
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,500)
end

function s.burnop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local ec=c:GetEquippedItem()
    -- 1. Inflict 500 Burn Damage first
    if Duel.Damage(1-tp,500,REASON_EFFECT) > 0 and ec and ec:IsFaceup() then
        -- 2. Give the equipped monster +500 ATK until end of turn
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(500)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        ec:RegisterEffect(e1)
    end
end

--================
-- Searing Claws Battle Lock Subroutines
--================
function s.actcon(e)
    local ec=e:GetHandler():GetEquippedItem()
    -- Active only when your equipped card is fighting
    return ec and (Duel.GetAttacker()==ec or Duel.GetAttackTarget()==ec)
end

function s.actval(e,re,tp)
    -- Blocks all card activations completely
    return true
end

--================
-- Total Incineration Subroutines
--================
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    local ec=e:GetHandler():GetEquippedItem()
    return ec and eg:IsContains(ec) and ec:IsStatus(STATUS_OPPO_BATTLE)
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    -- Non-targeting send to GY to bypass targeting immunities
    if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g > 0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end
