--Baron of Flame
local s,id=GetID()
function s.initial_effect(c)
    -- Token Summon Quick Effect (Once per chain)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_QUICK_O)       -- Quick Effect
    e1:SetCode(EVENT_FREE_CHAIN)          -- Can activate anytime a chain can start
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_CHAIN) -- Once per chain
    e1:SetCondition(s.tokencon)           -- Only if you don't control a Token
    e1:SetTarget(s.tokentg)               -- Target a monster in either graveyard
    e1:SetOperation(s.tokenop)            -- Summon the Token and copy stats
    c:RegisterEffect(e1)

    -- Cannot be attack target while controlling Token
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.atkcon)
    e2:SetValue(aux.imval1)
    c:RegisterEffect(e2)

    -- Destroy replacement effect
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetTarget(s.desreptg)
    e3:SetValue(s.desrepval)
    e3:SetOperation(s.desrepop)
    c:RegisterEffect(e3)
end

--================
-- Token Summon Condition
--================
function s.tokenfilter(c)
    return c:IsCode(3000000003)
end
function s.tokencon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsExistingMatchingCard(s.tokenfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Target a monster in either graveyard
function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsType(TYPE_MONSTER) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,TYPE_MONSTER)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,TYPE_MONSTER)
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

--================
-- Token Operation
--================
function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    local token=Duel.CreateToken(tp,3000000003)
    if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP) then
        -- Copy ATK
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK)
        e1:SetValue(tc:GetAttack())
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e1)

        -- Copy DEF
        local e2=e1:Clone()
        e2:SetCode(EFFECT_SET_DEFENSE)
        e2:SetValue(tc:GetDefense())
        token:RegisterEffect(e2)

        -- Copy Level
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_CHANGE_LEVEL)
        e3:SetValue(tc:GetLevel())
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e3)

        -- Set as Effect or Normal
        if tc:IsType(TYPE_EFFECT) then
            token:SetStatus(STATUS_EFFECT_ENABLED,true)
        else
            token:SetStatus(STATUS_EFFECT_ENABLED,false)
        end

        -- Token protective effect
        local e4=Effect.CreateEffect(token)
        e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
        e4:SetCode(EFFECT_DESTROY_REPLACE)
        e4:SetRange(LOCATION_MZONE)
        e4:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk)
            local c=e:GetHandler()
            local barons=Duel.GetMatchingGroup(function(c) return c:IsCode(3000000002) and eg:IsContains(c) end,tp,LOCATION_MZONE,0,nil)
            if chk==0 then return #barons>0 and c:IsFaceup() and c:IsRelateToEffect(e) end
            return true
        end)
        e4:SetValue(function(e,c)
            return c:IsCode(3000000002)
        end)
        e4:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
            local c=e:GetHandler()
            Duel.Destroy(c,REASON_EFFECT)
            -- If the destroying effect was from a monster, destroy that monster and inflict damage
            local re=eg:GetFirst():GetReasonEffect() -- safer version
            if re and re:IsActiveType(TYPE_MONSTER) then
                local rc=re:GetHandler()
                if rc:IsRelateToEffect(re) then
                    local dam=rc:GetAttack()
                    Duel.Destroy(rc,REASON_EFFECT)
                    Duel.Damage(1-tp,dam,REASON_EFFECT)
                end
            end
        end)
        token:RegisterEffect(e4)
    end
    Duel.SpecialSummonComplete()
end

--================
-- Destroy Replacement Target
--================
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local token=Duel.GetFirstMatchingCard(function(tc) return tc:IsCode(3000000003) and tc:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
    if chk==0 then return token end
    return Duel.SelectYesNo(tp,aux.Stringid(id,1)) -- prompt: destroy Token instead?
end

function s.desrepval(e,c)
    return true -- always replace
end

function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
    local token=Duel.GetFirstMatchingCard(function(tc) return tc:IsCode(3000000003) and tc:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
    if token then
        Duel.Destroy(token,REASON_EFFECT)
        -- If destruction came from a monster effect, destroy that monster and deal damage
        if re and re:IsActiveType(TYPE_MONSTER) then
            local rc=re:GetHandler()
            if rc:IsRelateToEffect(re) then
                local dam=rc:GetAttack()
                Duel.Destroy(rc,REASON_EFFECT)
                Duel.Damage(1-tp,dam,REASON_EFFECT)
            end
        end
    end
end

--================
-- Battle Protection
--================
function s.atkcon(e)
    return Duel.IsExistingMatchingCard(s.tokenfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
