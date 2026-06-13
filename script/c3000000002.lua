-- Baron of Flame
local s,id=GetID()
local TOKEN_ID = 3000000003

function s.initial_effect(c)
    -- Effect 1: Discard to Special Summon from hand
    local e0=Effect.CreateEffect(c)
    e0:SetDescription(aux.Stringid(id,2)) 
    e0:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_HANDES)
    e0:SetType(EFFECT_TYPE_IGNITION)
    e0:SetRange(LOCATION_HAND)
    e0:SetCountLimit(1,id) 
    e0:SetCost(s.spcost)
    e0:SetTarget(s.sptg)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)

    -- Effect 2: Token Summon Quick Effect (Locked to a hard Once Per Turn)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)       
    e1:SetCode(EVENT_FREE_CHAIN)          
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id+1) -- FIXED: Removed chain limit parameter to make it a strict HOPT
    e1:SetTarget(s.tokentg)               
    e1:SetOperation(s.tokenop)            
    c:RegisterEffect(e1)

    -- Passive: Cannot be attack target while controlling Token
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.atkcon)
    e2:SetValue(aux.imval1)
    c:RegisterEffect(e2)

    -- Passive Trigger: Destroy replacement effect (Handles token protection substitution)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.desreptg)
    e3:SetValue(s.desrepval)
    e3:SetOperation(s.desrepop)
    c:RegisterEffect(e3)
end

--================
-- Special Summon from Hand Functions
--================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD,e:GetHandler())
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--================
-- Token Summon Target & Filtering Checks
--================
function s.tokenfilter(c)
    return c:IsCode(TOKEN_ID)
end

function s.tgfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and (Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_GRAVE,LOCATION_GRAVE,1,nil) or Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND,0,1,nil)) end
    
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,0)
end

--================
-- Token Operation (Banish + Cage Return Mechanic)
--================
function s.tokenop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    local g=Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_HAND+LOCATION_GRAVE,LOCATION_GRAVE,nil)
    if #g==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()

    if not tc then return end

    if tc:IsLocation(LOCATION_HAND) then
        Duel.ConfirmCards(1-tp,tc) 
    else
        Duel.HintSelection(sg)
    end

    if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT) == 0 then return end

    local token=Duel.CreateToken(tp,TOKEN_ID)
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

        -- Search Ignition effect
        local e4=Effect.CreateEffect(e:GetHandler())
        e4:SetDescription(aux.Stringid(id,4)) 
        e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
        e4:SetType(EFFECT_TYPE_IGNITION)
        e4:SetRange(LOCATION_MZONE)
        e4:SetCountLimit(1) 
        e4:SetTarget(s.searchtg)
        e4:SetOperation(s.searchop)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e4)

        -- Cage Clause Trigger Setup
        local e5=Effect.CreateEffect(e:GetHandler())
        e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
        e5:SetCode(EVENT_DESTROYED)
        e5:SetLabelObject(tc) 
        e5:SetOperation(s.ret_op)
        token:RegisterEffect(e5)

        if tc:IsType(TYPE_EFFECT) then
            token:SetStatus(STATUS_EFFECT_ENABLED,true)
        else
            token:SetStatus(STATUS_EFFECT_ENABLED,false)
        end
    end 
    Duel.SpecialSummonComplete()
end

--================
-- Return to Deck Subroutine
--================
function s.ret_op(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_REMOVED) then
        Duel.SendtoDeck(tc,nil,SEQ_DECKTOP,REASON_EFFECT)
    end
end

--================
-- Token Archetype Search Logic Subroutines
--================
function s.searchfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) 
        and (Card.ListsCode(c,3000000002) or Card.ListsCode(c,3000000003)) 
        and c:IsAbleToHand()
end

function s.searchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.searchfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.searchop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.searchfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--================
-- Destroy Replacement Functions
--================
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local token=Duel.GetFirstMatchingCard(function(tc) return tc:IsCode(TOKEN_ID) and tc:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
    if chk==0 then return not c:IsReason(REASON_REPLACE) and token end
    return Duel.SelectYesNo(tp,aux.Stringid(id,1))
end

function s.desrepval(e,c)
    return true 
end

function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
    local token=Duel.GetFirstMatchingCard(function(tc) return tc:IsCode(TOKEN_ID) and tc:IsFaceup() end,tp,LOCATION_MZONE,0,nil)
    if token then
        Duel.Destroy(token,REASON_EFFECT+REASON_REPLACE)
    end
end

--================
-- Battle Protection Condition
--================
function s.atkcon(e)
    return Duel.IsExistingMatchingCard(s.tokenfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
