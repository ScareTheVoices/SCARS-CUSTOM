--Emerald Light Magician
local s,id=GetID()
s.initial_effect=function(c)
	-- Reveal this and another "Emerald Light" monster in hand; Special Summon 1 of them
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Search "Emerald Light" Spell/Trap on Normal or Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Can be used as the entire requirement for Ritual Summon of exactly 1 Dragon Ritual Monster
	Ritual.AddWholeLevelTribute(c,aux.FilterBoolFunction(function(tc) return tc:IsRace(RACE_DRAGON) and tc:IsType(TYPE_RITUAL) end))
end

s.listed_series={0x4003}
s.listed_names={1000000000}



-- Filter for "Emerald Light" monsters in hand (excluding this card)
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x4003) and c:IsMonster() and not c:IsPublic() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Target: Reveal this and another "Emerald Light" monster in hand; Special Summon 1 of them
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and not c:IsPublic()
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,c,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,c,e,tp)
	g:AddCard(c)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

-- Operation: Special Summon 1 of the revealed monsters
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)==0 then return end
	local g=Duel.GetTargetCards(e)
	if #g~=2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Filter(Card.IsCanBeSpecialSummoned,nil,e,0,tp,false,false)
	local sc=sg:Select(tp,1,1,nil):GetFirst()
	if sc then
		Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
	end
end


-- Filter for "Emerald Light" Spell/Trap
function s.thfilter(c)
	return c:IsSetCard(0x4003) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Allow this card to be used as the only tribute for a Dragon Ritual Monster
function s.ritualmat(e,c)
	return c and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_RITUAL)
end
