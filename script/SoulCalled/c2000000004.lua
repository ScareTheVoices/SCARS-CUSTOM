--Soulcalled, Booster
local s, id = GetID()
local CARD_SOUL_CALL = 2000000001

function s.initial_effect(c)
    c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsCode,id),LOCATION_MZONE)
    
    -- Cannot be Normal Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e1)
    
    -- Discard to tribute a monster and summon a Soulcalled monster from Hand/Deck/GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    -- Add Soul Call to hand if sent to GY (except by its own effect cost)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end
s.listed_names={CARD_SOUL_CALL}

-- Filter out legal Soulcalled targets to summon
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x1317) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

-- Cost function: Discard Booster first
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsDiscardable() end
    Duel.SendtoGrave(c,REASON_COST + REASON_DISCARD)
end

-- Target function: Look for a monster to tribute from Hand or Field
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    -- Group together available tribute fodder from hand or field
    local g=Duel.GetReleaseGroup(tp,true):Filter(Card.IsCanBeReleased,nil)
    local hand=Duel.GetMatchingGroup(Card.IsCanBeReleased,tp,LOCATION_HAND,0,e:GetHandler())
    g:Merge(hand)
    
    if chk==0 then 
        return #g>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE,0,1,nil,e,tp) 
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

-- Operation function: Execute Tribute, Summon, and Stat inheritance
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetReleaseGroup(tp,true):Filter(Card.IsCanBeReleased,nil)
    local hand=Duel.GetMatchingGroup(Card.IsCanBeReleased,tp,LOCATION_HAND,0,nil)
    g:Merge(hand)
    
    if #g==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local rg=g:Select(tp,1,1,nil)
    local tc=rg:GetFirst()
    
    -- Cache original stats before tribute processing
    local atk=tc:GetBaseAttack()
    local def=tc:GetBaseDefense()
    
    if Duel.Release(tc,REASON_EFFECT)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE,0,1,1,nil,e,tp)
        local sc=sg:GetFirst()
        
        if sc and Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)>0 then
            -- Set Summoned Monster's Base ATK to match the tributed host
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_SET_BASE_ATTACK)
            e1:SetValue(atk)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            sc:RegisterEffect(e1)
            
            -- Set Summoned Monster's Base DEF to match the tributed host
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e2:SetCode(EFFECT_SET_BASE_DEFENSE)
            e2:SetValue(def)
            e2:SetReset(RESET_EVENT + RESETS_STANDARD)
            sc:RegisterEffect(e2)
        end
    end
end

-- Soul Call Search Condition (Fails if sent to GY as a cost parameter)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return not e:GetHandler():IsReason(REASON_COST)
end

function s.thfilter(c)
    return c:IsCode(CARD_SOUL_CALL) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK + LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK + LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK + LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
