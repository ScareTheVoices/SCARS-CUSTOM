--Soulcalled, Gravedigger
local s, id = GetID()
-- Custom Token ID
local TOKEN_DARK_SOUL = 2000000005
function s.initial_effect(c)
    c:SetUniqueOnField(1,0,aux.FilterBoolFunction(Card.IsCode,2000000000),LOCATION_MZONE)
    
    -- This card's original level is always treated as 8
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_MZONE + LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE + LOCATION_REMOVED)
    e0:SetCode(EFFECT_CHANGE_LEVEL)
    e0:SetValue(8)
    c:RegisterEffect(e0)

    -- Cannot be Normal Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e1)
    
    -- Banish opponent's monster in battle, then place 1 "Dark Soul Token" in the Spell/Trap Zone
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_REMOVE + CATEGORY_TOKEN)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_BATTLE_START)
    e2:SetTarget(s.bantg)
    e2:SetOperation(s.banop)
    c:RegisterEffect(e2)
    
    -- Add card to hand when destroyed or banished
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_LEAVE_FIELD)
    e4:SetCondition(s.retcon)
    e4:SetTarget(s.rettg)
    e4:SetOperation(s.retop)
    c:RegisterEffect(e4)
end
s.listed_names={id,TOKEN_DARK_SOUL}

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if bc and bc:IsFaceup() and bc:GetAttack() < c:GetAttack() then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
        Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
    end
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if bc and bc:IsRelateToBattle() and bc:IsFaceup() and bc:GetAttack() < c:GetAttack() then
        -- Execute the banish step
        if Duel.Remove(bc,POS_FACEUP,REASON_EFFECT) > 0 then
            -- Check for open space in the Spell & Trap Zone
            if Duel.GetLocationCount(tp,LOCATION_SZONE) > 0 then
                
                local token = Duel.CreateToken(tp,TOKEN_DARK_SOUL)
                
                -- FIXED: Added absolute nil check to prevent traceback crashes if database entry 2000000005 isn't found
                if token then
                    -- Force all requested custom card configurations explicitly
                    token:Level(1)
                    
                    local e1=Effect.CreateEffect(c)
                    e1:SetType(EFFECT_TYPE_SINGLE)
                    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                    e1:SetCode(EFFECT_SET_BASE_ATTACK)
                    e1:SetValue(0)
                    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e1)
                    
                    local e2=Effect.CreateEffect(c)
                    e2:SetType(EFFECT_TYPE_SINGLE)
                    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                    e2:SetCode(EFFECT_SET_BASE_DEFENSE)
                    e2:SetValue(0)
                    e2:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e2)
                    
                    local e3=Effect.CreateEffect(c)
                    e3:SetType(EFFECT_TYPE_SINGLE)
                    e3:SetCode(EFFECT_CHANGE_RACE)
                    e3:SetValue(RACE_FIEND)
                    e3:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e3)
                    
                    local e4=Effect.CreateEffect(c)
                    e4:SetType(EFFECT_TYPE_SINGLE)
                    e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
                    e4:SetValue(ATTRIBUTE_DARK)
                    e4:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e4)
                    
                    -- Changes the Token type structure safely to a Continuous Spell at runtime
                    local e5=Effect.CreateEffect(c)
                    e5:SetType(EFFECT_TYPE_SINGLE)
                    e5:SetCode(EFFECT_CHANGE_TYPE)
                    e5:SetValue(TYPE_SPELL + TYPE_CONTINUOUS)
                    e5:SetReset(RESET_EVENT|RESETS_STANDARD)
                    token:RegisterEffect(e5)
                    
                    -- Moves the Token to the field directly into the Spell & Trap Zone face-up
                    Duel.MoveToField(token,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
                end
            end
        end
    end
end

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
