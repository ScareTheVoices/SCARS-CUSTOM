--Machine Factory
local s,id=GetID()
function s.initial_effect(c)
	--Ritual Summon (Uses traditional Levels, summons from Hand/GY)
	local e1=Ritual.AddProcGreater({
		handler=c,
		filter=s.ritualfil,
		lv=Card.GetLevel,
		matfilter=s.matfilter,
		location=LOCATION_HAND|LOCATION_GRAVE,
		desc=aux.Stringid(id,0)
	})
	--Grant effect to the summoned monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetLabelObject(e1)
	e2:SetCondition(s.effcon)
	e2:SetOperation(s.effop)
	Duel.RegisterEffect(e2,0)
end

--Filters what monsters can be Ritual Summoned (Any Machine Ritual monster)
function s.ritualfil(c)
	return c:IsRace(RACE_MACHINE) and c:IsRitualMonster()
end

--Filters what monsters can be tributed as Material (Any Machine monster)
function s.matfilter(c)
	return c:IsRace(RACE_MACHINE)
end

--Checks if the monster was summoned by this card's ritual effect
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local rge=e:GetLabelObject()
	return re==rge and eg:IsExists(s.ritualfil,1,nil)
end

--Applies the continuous "Gain Effect" to the summoned monster
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.ritualfil,nil)
	for tc in aux.Next(g) do
		--Granted Effect: Add 1 Machine from GY to hand when destroying a monster by battle
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_TOHAND)
		e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e1:SetCode(EVENT_BATTLE_DESTROYING)
		e1:SetCondition(aux.bdcon)
		e1:SetTarget(s.thtg)
		e1:SetOperation(s.thop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1,true)
		if not tc:IsType(TYPE_EFFECT) then
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_ADD_TYPE)
			e2:SetSetValue(TYPE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2,true)
		end
	end
end

--Filters Machine monsters in the GY to add back to hand
function s.thfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsAbleToHand()
end

--Targeting logic for the granted salvage effect
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

--Operation logic for the granted salvage effect
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
