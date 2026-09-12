-- Custom Card: Accel Ritual
-- Structure synchronized with Gateway to the Emerald Light
local s,id=GetID()
function s.initial_effect(c)
	--1. Activate & Search/Recover (Once per turn limit)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--2. Continuous Ritual Summon Engine (Using the clean Ritual library system)
	local e2=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_GREATER,
		filter=s.ritfilter,
		location=LOCATION_HAND
	})
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	c:RegisterEffect(e2)
	
	--3. The Self-Destruct Clause (Triggers when leaving the field face-up)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCondition(s.descon)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- Filter: Any generic Ritual Monster in Deck or GY
function s.thfilter(c)
	return c:IsRitualMonster() and c:IsAbleToHand()
end

-- Target: Search/Recover confirmation
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- Operation: Move card to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Ritual Filter: Any valid Ritual Monster can be summoned
function s.ritfilter(c)
	return c:IsRitualMonster()
end

-- Condition: Verify card was face-up on the field before leaving
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:GetPreviousLocation()==LOCATION_SZONE
end

-- Operation: Destroy all monsters the controller owns
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
