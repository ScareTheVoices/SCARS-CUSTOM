--Soulcalled, Queen
local s, id = GetID()
-- Custom Token ID
local TOKEN_DARK_SOUL = 2000000005
function s.initial_effect(c)
    c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsCode,2000000002),LOCATION_MZONE)
    
    -- This card's original level is always treated as 6
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_MZONE + LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED)
    e0:SetCode(EFFECT_CHANGE_LEVEL)
    e0:SetValue(6)
    c:RegisterEffect(e0)

    -- Cannot be Normal Summoned
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e1)

    -- Add card to hand when destroyed or banished
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_LEAVE_FIELD)
    e2:SetCondition(s.retcon)
    e2:SetTarget(s.rettg)
    e2:SetOperation(s.retop)
    c:RegisterEffect(e2)

    -- Destroy a Spell/Trap when a monster with setcode 0x1317 is Summoned and place a Dark Soul Token
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetCategory(CATEGORY_DESTROY + CATEGORY_TOKEN)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.descon)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)

    local e4 = e3:Clone()
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e4)
end
s.listed_names={TOKEN_DARK_SOUL}

function s.retcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsReason(REASON_EFFECT + REASON_BATTLE)
end

function s.rettg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_GRAVE + LOCATION_DECK, 0, 1, nil, 2000000001) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_GRAVE + LOCATION_DECK)
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_GRAVE + LOCATION_DECK, 0, 1, 1, nil, 2000000001)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

function s.descon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(Card.IsSetCard, 1, nil, 0x1317)
end

function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsType, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil, TYPE_SPELL + TYPE_TRAP) end
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, tp, 0)
end

function s.desop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, Card.IsType, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil, TYPE_SPELL + TYPE_TRAP)
    if #g > 0 then
        if Duel.Destroy(g, REASON_EFFECT) ~= 0 then
            -- Check only for available SZONE space natively
            if Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 then
                local token = Duel.CreateToken(tp, TOKEN_DARK_SOUL)
                if token then
                    token:Level(1)
                    
                    local e1=Effect.CreateEffect(e:GetHandler())
                    e1:SetType(EFFECT_TYPE_SINGLE)
                    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                    e1:SetCode(EFFECT_SET_BASE_ATTACK)
                    e1:SetValue(0)
                    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e1)
                    
                    local e2=Effect.CreateEffect(e:GetHandler())
                    e2:SetType(EFFECT_TYPE_SINGLE)
                    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                    e2:SetCode(EFFECT_SET_BASE_DEFENSE)
                    e2:SetValue(0)
                    e2:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e2)
                    
                    local e3=Effect.CreateEffect(e:GetHandler())
                    e3:SetType(EFFECT_TYPE_SINGLE)
                    e3:SetCode(EFFECT_CHANGE_RACE)
                    e3:SetValue(RACE_FIEND)
                    e3:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e3)
                    
                    local e4=Effect.CreateEffect(e:GetHandler())
                    e4:SetType(EFFECT_TYPE_SINGLE)
                    e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
                    e4:SetValue(ATTRIBUTE_DARK)
                    e4:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e4)
                    
                    local e5=Effect.CreateEffect(e:GetHandler())
                    e5:SetType(EFFECT_TYPE_SINGLE)
                    e5:SetCode(EFFECT_CHANGE_TYPE)
                    e5:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
                    e5:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e5)
                    
                    Duel.MoveToField(token, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
                end
            end
        end
    end
end
