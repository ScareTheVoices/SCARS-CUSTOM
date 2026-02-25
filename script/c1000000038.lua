--Emerald Light Gateway
local s,id=GetID()
function s.initial_effect(c)
	--Activate and add 1 Emerald Light monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	--When a setcode 0x4003 monster is Special Summoned, add 1 Emerald Sovereign Ritual Dragon from Deck or Banished Zone to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

end
s.listed_series={0x4003}
s.listed_names={1000000000}

--Filter for Special Summon condition
function s.thconfilter(c)
	return c:IsSetCard(0x4003) and c:IsMonster()
end

--Condition for Special Summon search effect
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.thconfilter,1,nil)
end

--Filter for monsters to add to hand (Special Summon effect)
function s.thfilter(c)
	return c:IsCode(1000000000) and c:IsAbleToHand()
end

--Target for Special Summon search effect
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_REMOVED)
end

--Operation for Special Summon search effect
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Filter for monsters to add to hand (Activation effect)
function s.actfilter(c)
	return c:IsSetCard(0x4003) and c:IsMonster() and c:IsAbleToHand()
end

--Target for activation search effect
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Operation for activation search effect
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Filter for Ritual Monster
function s.ritfilter(c,e,tp)
	return c:IsCode(1000000000) and c:IsRitualMonster() and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

--Filter for tribute monsters
function s.tribfilter(c)
	return c:IsSetCard(0x4003) and c:IsMonster() and c:IsReleasable() and c:GetLevel()>0
end

--Target for Ritual Summon effect
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_MZONE+LOCATION_HAND,0,nil)
		local tc=Duel.GetFirstMatchingCard(s.ritfilter,tp,LOCATION_HAND,0,nil,e,tp)
		if not tc then return false end
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1 and s.RitualCheck(mg,tc)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,0,tp,LOCATION_MZONE+LOCATION_HAND)
end

-- Replicate Ritual.AddProcGreaterCode tribute logic
function s.RitualCheck(mg,tc)
	local lv=tc:GetLevel()
	-- Check for whole tribute monsters
	for m in aux.Next(mg) do
		local le=m:IsHasEffect(EFFECT_RITUAL_LEVEL)
		if le then
			local val=le:GetValue()(le,tc)
			if val and (val>>16)==lv then return true end
		end
	end
	-- Standard tribute check
	return mg:CheckWithSumGreater(Card.GetLevel,lv)
end

--Operation for Ritual Summon effect
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #tg==0 then return end
	local tc=tg:GetFirst()
	local mg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_MZONE+LOCATION_HAND,0,nil)
	local lv=tc:GetLevel()
	-- Gather all possible tribute groups: single whole-tribute monsters and standard combinations
	local tributeGroups = {}
	for m in aux.Next(mg) do
		local le=m:IsHasEffect(EFFECT_RITUAL_LEVEL)
		if le then
			local val=le:GetValue()(le,tc)
			if val and (val>>16)==lv then
				local g=Group.CreateGroup()
				g:AddCard(m)
				table.insert(tributeGroups, g)
			end
		end
	end
	-- Add standard tribute group
	local stdGroup=mg:SelectWithSumGreater(tp,Card.GetLevel,lv)
	if #stdGroup>0 then table.insert(tributeGroups, stdGroup) end
	if #tributeGroups==0 then return end
	-- Let the player choose which tribute group to use
	local chosenGroup
	if #tributeGroups==1 then
		chosenGroup=tributeGroups[1]
	else
		-- Present options to the player
		local allCards=Group.CreateGroup()
		for _,g in ipairs(tributeGroups) do allCards:Merge(g) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		chosenGroup=allCards:Select(tp,tributeGroups[1]:GetCount(),tributeGroups[#tributeGroups]:GetCount(),nil)
	end
	if chosenGroup and #chosenGroup>0 then
		tc:SetMaterial(chosenGroup)
		Duel.ReleaseRitualMaterial(chosenGroup)
		Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
		tc:CompleteProcedure()
	end
end
