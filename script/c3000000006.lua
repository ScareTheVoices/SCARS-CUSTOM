-- Embers Needs a Hero!
local s,id=GetID()
local BARON_ID = 3000000002
local TOKEN_ID = 3000000003

function s.initial_effect(c)
    -- Effect 1: Summon Baron of Flame from Deck/GY on direct attack
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0)) -- Prompt: Summon Baron of Flame
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_ATTACK_ANNOUNCEMENT)
    e1:SetCondition(s.sumcon)
    e1:SetTarget(s.sumtg)
    e1:SetOperation(s.sumop)
    c:RegisterEffect(e1)

    -- Effect 2: GY Banish to summon Wraith Token
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1)) -- Prompt: Summon Wraith Token from GY
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id) -- Hard Once Per Turn
    e2:SetCost(aux.bfgcost) -- Banishes itself as cost
    e2:SetTarget(s.tktg)
    e2:SetOperation(s.tkop)
    c:RegisterEffect(e2)
end

s.listed_names={BARON_ID,TOKEN_ID}

--================
-- Effect 1: Baron Summon Subroutines
--================
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
    -- True only if the opponent's monster is attacking your LP directly
    return Duel.GetAttacker():GetControler()~=tp and Duel.GetAttackTarget()==nil
end

function s.spfilter(c,e,tp)
    return c:IsCode(BARON_ID) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

--================
-- Effect 2: Token Summon Subroutines
--================
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ID,0,TYPES_TOKEN,2200,0,4,RACE_PYRO,ATTRIBUTE_FIRE) end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    -- Forcefully spawns a Token with your exact requested baseline configurations [1]
    local token=Duel.CreateToken(tp,TOKEN_ID)
    if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP) then
        -- 1. Hardcode Pyro/FIRE nature [1]
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CHANGE_RACE)
        e1:SetValue(RACE_PYRO)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e1)
        
        local e2=e1:Clone()
        e2:SetCode(EFFECT_CHANGE_ATTRIBUTE)
        e2:SetValue(ATTRIBUTE_FIRE)
        token:RegisterEffect(e2)

        -- 2. Hardcode Level 4/ATK 2200/DEF 0 parameters [1]
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_CHANGE_LEVEL)
        e3:SetValue(4)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e3)

        local e4=Effect.CreateEffect(e:GetHandler())
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_SET_ATTACK)
        e4:SetValue(2200)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e4)

        local e5=e4:Clone()
        e5:SetCode(EFFECT_SET_DEFENSE)
        e5:SetValue(0)
        token:RegisterEffect(e5)

        -- 3. Token Effect A: Once per turn Archetype S/T Search
        local e6=Effect.CreateEffect(e:GetHandler())
        e6:SetDescription(aux.Stringid(id,2)) -- Prompt: Add 1 Spell/Trap to hand
        e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
        e6:SetType(EFFECT_TYPE_IGNITION)
        e6:SetRange(LOCATION_MZONE)
        e6:SetCountLimit(1) 
        e6:SetTarget(s.searchtg)
        e6:SetOperation(s.searchop)
        e6:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e6)

        -- 4. Token Effect B: Float Search Baron when Destroyed
        local e7=Effect.CreateEffect(e:GetHandler())
        e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
        e7:SetCode(EVENT_DESTROYED)
        e7:SetOperation(s.floatop)
        token:RegisterEffect(e7)

        token:SetStatus(STATUS_EFFECT_ENABLED,true)
    end
    Duel.SpecialSummonComplete()
end

--================
-- Token Search & Float Logic Helper Functions
--================
function s.searchfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) 
        and (Card.ListsCode(c,BARON_ID) or Card.ListsCode(c,TOKEN_ID)) 
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

function s.baronfilter(c)
    return c:IsCode(BARON_ID) and c:IsAbleToHand()
end

function s.floatop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.IsExistingMatchingCard(s.baronfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.baronfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end

