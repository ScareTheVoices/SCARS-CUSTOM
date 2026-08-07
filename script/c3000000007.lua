-- Alexander The Great
local s, id = GetID()
local TOKEN_ID = 3000000003
local CARD_BARON_OF_FLAME = 3000000002

function s.initial_effect(c)
    -- Effect 1: Change name to "Baron of Flame" on the field
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.namecond)
    e1:SetValue(CARD_BARON_OF_FLAME)
    c:RegisterEffect(e1)
    
    -- Effect 2: Special Summon from hand
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1, id) -- Hard once per turn
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- Effect 3: Banish GY monster, spawn Token, and Equip (Inspired layout)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 1))
    e3:SetCategory(CATEGORY_REMOVE + CATEGORY_TOKEN + CATEGORY_SPECIAL_SUMMON + CATEGORY_EQUIP)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1) -- Soft once per turn
    e3:SetTarget(s.eqtg)
    e3:SetOperation(s.eqop)
    c:RegisterEffect(e3)

    -- Effect 4: Gain ATK/DEF of equipped Wraith Tokens
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)
    local e5 = e4:Clone()
    e5:SetCode(EFFECT_UPDATE_DEFENSE)
    e5:SetValue(s.defval)
    c:RegisterEffect(e5)
end

-- Condition: Checks if any equipped card is the specific Wraith Token
function s.namecond(e)
    local c = e:GetHandler()
    local eg = c:GetEquipGroup()
    return eg and eg:IsExists(Card.IsCode, 1, nil, TOKEN_ID)
end

-- Target Function (Effect 2)
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc:IsCode(CARD_BARON_OF_FLAME) end
    local c = e:GetHandler()
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
            and Duel.IsExistingTarget(Card.IsCode, tp, LOCATION_GRAVE, 0, 1, nil, CARD_BARON_OF_FLAME) 
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp, Card.IsCode, tp, LOCATION_GRAVE, 0, 1, 1, nil, CARD_BARON_OF_FLAME)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, 1, 0, 0)
end

-- Operation Function (Effect 2)
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
        if tc and tc:IsRelateToEffect(e) then
            Duel.ShuffleDeck(tp)
            Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
        end
    end
end

-- Target Function (Effect 3): Targets a monster in either Graveyard
function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsType(TYPE_MONSTER) end
    if chk == 0 then 
        return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
            and Duel.IsExistingTarget(Card.IsType, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, nil, TYPE_MONSTER)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, Card.IsType, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, 1, nil, TYPE_MONSTER)
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, nil, 1, tp, 0)
end

-- Operation Function (Effect 3): Banishes target, copies stats, Equips to Alexander
function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    
    -- Stop if Alexander left the field or Spell/Trap Zone has no space
    if not c:IsRelateToEffect(e) or c:IsFacedown() or Duel.GetLocationCount(tp, LOCATION_SZONE) <= 0 then return end
    
    if tc and tc:IsRelateToEffect(e) then
        -- Read stats before banishing
        local atk = tc:GetAttack()
        local def = tc:GetDefense()
        
        -- Banish the target monster
        if Duel.Remove(tc, POS_FACEUP, REASON_EFFECT) > 0 then
            -- Generate the Token in memory
            local token = Duel.CreateToken(tp, TOKEN_ID)
            
            -- Apply ATK/DEF modification exactly like Baron of Flame
            local e1 = Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK)
            e1:SetValue(atk)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD)
            token:RegisterEffect(e1)
            
            local e2 = e1:Clone()
            e2:SetCode(EFFECT_SET_DEFENSE)
            e2:SetValue(def)
            token:RegisterEffect(e2)
            
            -- Move the token to the Spell/Trap Zone and bind it as an Equip Card
            if Duel.SpecialSummonStep(token, 0, tp, tp, false, false, POS_FACEUP) then
                if Duel.Equip(tp, token, c, true) then
                    -- Establish engine equip restriction rules
                    local e3 = Effect.CreateEffect(c)
                    e3:SetType(EFFECT_TYPE_SINGLE)
                    e3:SetCode(EFFECT_EQUIP_LIMIT)
                    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                    e3:SetValue(s.eqlimit)
                    e3:SetReset(RESET_EVENT + RESETS_STANDARD)
                    token:RegisterEffect(e3)
                end
                Duel.SpecialSummonComplete()
            end
        end
    end
end

-- Rules binder restricting the Token's equip state to Alexander
function s.eqlimit(e, c)
    return c == e:GetOwner()
end

-- Continuous Calculator: Updates Alexander's ATK using the equipped Token's modified ATK
function s.atkval(e, c)
    local eg = c:GetEquipGroup()
    if not eg then return 0 end
    local tg = eg:Filter(Card.IsCode, nil, TOKEN_ID)
    return tg:GetSum(Card.GetAttack)
end

-- Continuous Calculator: Updates Alexander's DEF using the equipped Token's modified DEF
function s.defval(e, c)
    local eg = c:GetEquipGroup()
    if not eg then return 0 end
    local tg = eg:Filter(Card.IsCode, nil, TOKEN_ID)
    return tg:GetSum(Card.GetDefense)
end
