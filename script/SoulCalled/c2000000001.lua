--Soul Call (Quick-Play Spell)
local s,id=GetID()
function s.initial_effect(c)
    --Activate (Quick-Play Spell effect)
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- Filter for monsters with setcode 0x1317 that can be Special Summoned
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x1317) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Check for a valid monster to target on your field
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) end
    if chk==0 then 
        return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_MZONE,0,1,nil)
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

-- Resolve the Quick-Play Spell effect
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    
    -- Tribute and Special Summon immediately
    if tc:IsReleasable() and Duel.GetMZoneCount(tp,tc)>0 then
        if Duel.Release(tc,REASON_EFFECT)>0 then
            -- Read the exact printed stats directly from the card while it is in the GY
            local atk=tc:GetTextAttack()
            local def=tc:GetTextDefense()
            
            -- Handle cases where a monster has ? ATK/DEF in its card text
            if atk<0 then atk=0 end
            if def<0 then def=0 end

            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            -- Select 1 "0x1317" monster from Hand, Deck, or GY
            local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
            local sc=g:GetFirst()
            if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)>0 then
                -- Override the Special Summoned monster's original ATK/DEF
                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_SET_BASE_ATTACK)
                e2:SetValue(atk)
                e2:SetReset(RESET_EVENT+RESETS_STANDARD)
                sc:RegisterEffect(e2)
                
                local e3=e2:Clone()
                e3:SetCode(EFFECT_SET_BASE_DEFENSE)
                e3:SetValue(def)
                sc:RegisterEffect(e3)
            end
        end
    end
end
