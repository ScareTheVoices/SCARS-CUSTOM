--Baron Of Flame
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon Token
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1) -- Once per chain restriction
    e1:SetCondition(s.tokencon)
    e1:SetTarget(s.tokentg)
    e1:SetOperation(s.tokenop)
    c:RegisterEffect(e1)
    
    --Cannot be attack target while controlling token
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.atkcon)
    e2:SetValue(aux.imval1)
    c:RegisterEffect(e2)
end

-- Condition: You do not control a Token with ID 3000000003
function s.tokenfilter(c)
    return c:IsCode(3000000003)
end
function s.tokencon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsExistingMatchingCard(s.tokenfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Targeting a monster in either graveyard
function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsType(TYPE_MONSTER) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,TYPE_MONSTER)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,TYPE_MONSTER)
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

-- Special Summon Token with copied stats/effect
function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        local token=Duel.CreateToken(tp,3000000003)
        -- Copy ATK/DEF
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK)
        e1:SetValue(tc:GetAttack())
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_SET_DEFENSE)
        e2:SetValue(tc:GetDefense())
        token:RegisterEffect(e2)
        -- Copy original effects
        if tc:IsType(TYPE_EFFECT) then
            local code=tc:GetOriginalCode()
            local eff=tc:GetCardEffectList()
            for _,ex in ipairs(eff) do
                token:RegisterEffect(ex)
            end
        end
        Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Condition: You control a token with ID 3000000003
function s.atkcon(e)
    return Duel.IsExistingMatchingCard(s.tokenfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
