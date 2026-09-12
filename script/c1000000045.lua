--Emerald Light Dreadnought Sovereign
--Made by ScareTheVoices
local s,id=GetID()
s.listed_series={0x4003} 
s.listed_names={1000000000} -- Emerald Sovereign Ritual Dragon

function s.selfspcon(e)
	return e and e:GetHandler() and e:GetHandler():IsCode(id) and e:GetLabel()==id
end
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_RITUAL)==SUMMON_TYPE_RITUAL or s.selfspcon(se)
end
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Special Summon limitation
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--Special Summon from hand by destroying required cards
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--When this card leaves the field: prepare the background tracker
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS) -- Continuous means it triggers without prompting you
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCondition(s.rvcon)
	e2:SetOperation(s.rvop)
	c:RegisterEffect(e2)
end

function s.reqfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsCode(1000000000) and c:IsDestructable()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.reqfilter,tp,LOCATION_ONFIELD,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 or not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectMatchingCard(tp,s.reqfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	Duel.HintSelection(g1,true)
	if Duel.Destroy(g1,REASON_EFFECT)~=0 and c:IsRelateToEffect(e) then
		e:SetLabel(id)
		if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)>0 then
			c:CompleteProcedure()
			s.apply_granted_effect(c)
		end
		e:SetLabel(0)
	end
end

function s.rvcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
end
-- Quietly registers an optional Graveyard trigger for the next Standby Phase
function s.rvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2)) -- Assumes string index 2 or generic message
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) -- Optional prompt
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1)
	e1:SetLabel(Duel.GetTurnCount())
	e1:SetCondition(s.rvspcon)
	e1:SetTarget(s.rvsptg)
	e1:SetOperation(s.rvspop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN,2)
	c:RegisterEffect(e1)
end
function s.rvspcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()~=e:GetLabel()

end
function s.rvspfilter(c,e,tp)
	return c:IsCode(1000000000) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
-- Prompt checks condition here during the Standby Phase
function s.rvsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.rvspfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.rvspop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.rvspfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Targets and filters for granted continuous aura effects
function s.zerotg(e,c)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c~=e:GetHandler()
end
function s.gainfilter(c,sc)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c:IsControler(sc:GetControler()) and c~=sc
end
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.gainfilter,c:GetControler(),LOCATION_MZONE,0,nil,e:GetHandler())
	return g:GetSum(Card.GetBaseAttack)
end
function s.defval(e,c)
	local g=Duel.GetMatchingGroup(s.gainfilter,c:GetControler(),LOCATION_MZONE,0,nil,e:GetHandler())
	return g:GetSum(Card.GetBaseDefense)
end
function s.indtg(e,c)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c~=e:GetHandler()
end
function s.damcon(e)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if a and a:IsControler(c:GetControler()) and a:IsFaceup() and a:IsSetCard(0x4003) and a~=c then
		return true
	end
	if d and d:IsControler(c:GetControler()) and d:IsFaceup() and d:IsSetCard(0x4003) and d~=c then
		return true
	end
	return false
end

-- "Control Only 1" Rule Filter
function s.splimitcode(e,c)
	return c:IsCode(1000000000) and c~=e:GetHandler()
end
function s.ctfilter(c,tp)
	return c:IsFaceup() and c:IsCode(1000000000) and c:IsControler(tp)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.ctfilter,tp,LOCATION_MZONE,0,nil,tp)
	if #g>1 and g:IsContains(c) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,c)
		Duel.SendtoGrave(sg,REASON_RULE)
	end
end

-- Destruction Effect Targets/Filters (Bypasses the archetype loss from the name-change)
function s.desfilter(c,e)
	return (c:IsFaceup() or c:IsLocation(LOCATION_HAND)) 
		and (c:IsSetCard(0x4003) or (e and c==e:GetHandler())) 
		and c:IsDestructable()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_ONFIELD+LOCATION_HAND,0,1,nil,e)
		and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_ONFIELD+LOCATION_HAND,0,nil,e)
	local og=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,og,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local max_my_cards = Duel.GetMatchingGroupCount(s.desfilter,tp,LOCATION_ONFIELD+LOCATION_HAND,0,nil,e)
	local max_opp_cards = Duel.GetMatchingGroupCount(nil,tp,0,LOCATION_ONFIELD,nil)
	local max_count = math.min(max_my_cards, max_opp_cards)
	if max_count==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_ONFIELD+LOCATION_HAND,0,1,max_count,nil,e)
	if #g>0 then
		Duel.HintSelection(g,true)
		local count = Duel.Destroy(g,REASON_EFFECT)
		if count>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local og=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,count,count,nil)
			if #og>0 then
				Duel.HintSelection(og,true)
				Duel.Destroy(og,REASON_EFFECT)
			end
		end
	end
end

function s.apply_granted_effect(c)
	-- Name becomes "Emerald Sovereign Ritual Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1000000000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1,true)

	-- Cannot summon another code 1000000000 while this card is out
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimitcode)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e2,true)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e2b,true)
	local e2c=e2:Clone()
	e2c:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e2c,true)

	-- You can only control 1 "Emerald Sovereign Ritual Dragon" Rule Enforcer
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ADJUST)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.ctop)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e3,true)

	-- Other Emerald Light monsters you control have ATK/DEF set to 0
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_SET_ATTACK_FINAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.zerotg)
	e4:SetValue(0)
	e4:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e4,true)
	local e4b=e4:Clone()
	e4b:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e4b,true)

	-- This card gains original ATK/DEF of your other Emerald Light monsters
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.atkval)
	e5:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e5,true)
	local e5b=e5:Clone()
	e5b:SetCode(EFFECT_UPDATE_DEFENSE)
	e5b:SetValue(s.defval)
	c:RegisterEffect(e5b,true)

	-- Other Emerald Light monsters cannot be destroyed by battle
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(LOCATION_MZONE,0)
	e6:SetTarget(s.indtg)
	e6:SetValue(1)
	e6:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e6,true)

	-- No battle damage from battles involving your other Emerald Light monsters
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e7:SetTargetRange(1,0)
	e7:SetCondition(s.damcon)
	e7:SetValue(0)
	e7:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e7,true)

	-- Once per turn: Destroy "Emerald Light" cards on your field/hand (including itself), then destroy opponent's cards equal to that amount
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_IGNITION)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetTarget(s.destg)
	e8:SetOperation(s.desop)
	e8:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e8,true)
end
