--SoulCalled, Wild Runner
local s, id = GetID()
-- Custom Token ID
local TOKEN_DARK_SOUL = 2000000005
function s.initial_effect(c)
    c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsCode,2000000003),LOCATION_MZONE)
    
    -- This card's original level is always treated as 7
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_MZONE + LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED)
    e0:SetCode(EFFECT_CHANGE_LEVEL)
    e0:SetValue(7)
    c:RegisterEffect(e0)

    --Cannot be Normal Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e1)

    --Add card to hand when destroyed or banished
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_LEAVE_FIELD)
    e2:SetCondition(s.retcon)
    e2:SetTarget(s.rettg)
    e2:SetOperation(s.retop)
    c:RegisterEffect(e2)

    --Opponent sends cards from deck to graveyard once per Standby Phase
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e3:SetCategory(CATEGORY_DECKDES)
    e3:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.deckdescon)
    e3:SetTarget(s.deckdestg)
    e3:SetOperation(s.deckdesop)
    c:RegisterEffect(e3)
end
s.listed_names={TOKEN_DARK_SOUL}

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT + REASON_BATTLE)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_GRAVE + LOCATION_DECK,0,1,nil,2000000001) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE + LOCATION_DECK)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_GRAVE + LOCATION_DECK,0,1,1,nil,2000000001)
    if #g > 0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.deckdescon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp
end

-- Proper target registration for milling actions
function s.deckdestg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local ct=Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,TOKEN_DARK_SOUL)
    Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,1-tp,ct)
end

function s.deckdesop(e,tp,eg,ep,ev,re,r,rp)
    -- Counts all Dark Soul Tokens present on both sides of the field
    local ct=Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,TOKEN_DARK_SOUL)
    if ct>0 then
        Duel.DiscardDeck(1-tp,ct,REASON_EFFECT)
    end
end
