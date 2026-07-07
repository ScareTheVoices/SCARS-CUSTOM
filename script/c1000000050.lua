--Mecha Machine Plant
local s,id=GetID()
function s.initial_effect(c)
	--Search or Send to GY on Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
end

--Filter function for any Machine monster to search or dump
function s.filter(c)
	return c:IsRace(RACE_MACHINE)
end

--Targeting verification logic
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

--Resolution operation logic
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- Pulls all face-up Machines on your field, then EXCLUDES Mecha Machine Plant itself from the group
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local machine_group=g:Filter(Card.IsRace,nil,RACE_MACHINE)
	if c:IsLocation(LOCATION_MZONE) then
		machine_group:RemoveCard(c)
	end
	
	-- IF THERE ARE NO OTHER MACHINES ON YOUR FIELD: Add to Hand
	if #machine_group == 0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	-- OTHERWISE: Send to Graveyard
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoGrave(sg,REASON_EFFECT)
		end
	end
end
