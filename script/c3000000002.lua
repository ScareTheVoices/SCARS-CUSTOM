-- Baron of Flame
local s,id=GetID()
local TOKEN_ID = 3000000003

function s.initial_effect(c)
    -- Summon from hand if you control no monsters (Discard Cost)
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

    -- Token Summon Quick Effect (Hand/GY selection + Choose any Type)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)       
    e1:SetCode(EVENT_FREE_CHAIN)          
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_CHAIN) 
    e1:SetCondition(s.tokencon)           
    e1:SetTarget(s.tokentg)               
    e1:SetOperation(s.tokenop)            
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

    -- Destroy replacement effect (Handles token destruction, counter-kill, and burn)
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
    -- Checks if you have at least 1 card in your hand to discard
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
-- Token Summon Condition & Target
--================
function s.tokenfilter(c)
    return c:IsCode(TOKEN_ID)
end

function s.tokencon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsExistingMatchingCard(s.tokenfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.tgfilter(c)
    return c:IsType(TYPE_MONSTER)
end

function s.tokentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and (Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_GRAVE,LOCATION_GRAVE,1,nil) or Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND,0,1,nil)) end
    
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

--================
-- Token Operation (With Multiclass Class Perks!)
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
        if Duel.SendtoGrave(tc,REASON_EFFECT) == 0 then return end 
    else
        Duel.HintSelection(sg)
    end

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

        -- Announce Type Selection (RACE_ALL)
        local race = Duel.AnnounceRace(tp,1,RACE_ALL)
        local e4=Effect.CreateEffect(e:GetHandler())
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_CHANGE_RACE)
        e4:SetValue(race)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e4)

        ---------------------------------------------------------
        -- CLASS PERK 1: SPELLCASTER (Burn 500 when your S/T hits GY)
        ---------------------------------------------------------
        if race == RACE_SPELLCASTER then
            local sc1=Effect.CreateEffect(e:GetHandler())
            sc1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            sc1:SetCode(EVENT_TO_GRAVE)
            sc1:SetRange(LOCATION_MZONE)
            sc1:SetCondition(s.spellcaster_con)
            sc1:SetOperation(s.spellcaster_op)
            sc1:SetReset(RESET_EVENT+RESETS_STANDARD)
            token:RegisterEffect(sc1)
        
        ---------------------------------------------------------
        -- CLASS PERK 2: WARRIOR (Ignition: Destroy enemy monster + Level x 200 Burn)
        ---------------------------------------------------------
        elseif race == RACE_WARRIOR then
            local wa1=Effect.CreateEffect(e:GetHandler())
            wa1:SetDescription(aux.Stringid(id,3)) 
            wa1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
            wa1:SetType(EFFECT_TYPE_IGNITION)
            wa1:SetRange(LOCATION_MZONE)
            wa1:SetCountLimit(1) 
            wa1:SetTarget(s.warrior_tg)
            wa1:SetOperation(s.warrior_op)
            wa1:SetReset(RESET_EVENT+RESETS_STANDARD)
            token:RegisterEffect(wa1)

        ---------------------------------------------------------
        -- CLASS PERK 3: BEAST (Conditional Direct Attack)
        ---------------------------------------------------------
        elseif race == RACE_BEAST then
            local be1=Effect.CreateEffect(e:GetHandler())
            be1:SetType(EFFECT_TYPE_SINGLE)
            be1:SetCode(EFFECT_DIRECT_ATTACK)
            be1:SetCondition(s.beast_dircon) 
            be1:SetReset(RESET_EVENT+RESETS_STANDARD)
            token:RegisterEffect(be1)

            local be2=Effect.CreateEffect(e:GetHandler())
            be2:SetType(EFFECT_TYPE_SINGLE)
            be2:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
            be2:SetCondition(s.beast_dircon) 
            be2:SetValue(aux.ChangeBattleDamage(1,HALF_DAMAGE))
            be2:SetReset(RESET_EVENT+RESETS_STANDARD)
            token:RegisterEffect(be2)
        end

        if tc:IsType(TYPE_EFFECT) then
            token:SetStatus(STATUS_EFFECT_ENABLED,true)
        else
            token:SetStatus(STATUS_EFFECT_ENABLED,false)
        end
    end -- THIS WAS THE MISSING END CALL THAT FIXED THE CRASH
    Duel.SpecialSummonComplete()
end

--================
-- Spellcaster Logic Subroutines
--================
function s.scfilter(c,tp)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsControler(tp)
end
function s.spellcaster_con(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.scfilter,1,nil,tp)
end
function s.spellcaster_op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.Damage(1-tp,500,REASON_EFFECT)
end

--================
-- Warrior Logic Subroutines (Updated with Level Burn!)
--================
function s.warrior_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_MZONE,1,nil,TYPE_MONSTER) end
    local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0) 
end
function s.warrior_op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_MZONE,1,1,nil,TYPE_MONSTER)
    local tc=g:GetFirst()
    if tc then
        local lv=tc:GetLevel()
        if Duel.Destroy(tc,REASON_EFFECT)>0 and lv>0 then
            Duel.Damage(1-tp,lv*200,REASON_EFFECT)
        end
    end
end

--================
-- Beast Condition Subroutine
--================
function s.beast_dircon(e)
    return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),0,LOCATION_MZONE)>0
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
    if token and Duel.Destroy(token,REASON_EFFECT+REASON_REPLACE) > 0 then
        local reason_effect = e:GetHandler():GetReasonEffect()
        if reason_effect and reason_effect:IsActiveType(TYPE_MONSTER) then
            local rc = reason_effect:GetHandler()
            if rc and rc:IsRelatableToField() then

                local dam = rc:GetAttack()
                if Duel.Destroy(rc,REASON_EFFECT) > 0 and dam > 0 then
                    Duel.Damage(1-tp,dam,REASON_EFFECT)
                end
            end
        end
    end
end
--================
-- Attack Target Protection Condition
--================
function s.atkcon(e)
    return Duel.IsExistingMatchingCard(s.tokenfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
