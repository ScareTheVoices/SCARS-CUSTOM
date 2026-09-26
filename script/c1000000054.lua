--True Sovereign
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
		s.apply_granted_effect(c)
		if Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)>0 then
			c:CompleteProcedure()
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
	e1:SetDescription(aux.Stringid(id,1))
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

-- Count face-up Ritual cards on the field and Ritual cards in your GY
function s.ritfilter(c)
	return c:IsType(TYPE_RITUAL) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.ritcount(tp)
	return Duel.GetMatchingGroupCount(s.ritfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD,nil)
end
function s.rmfilter(c)
	return c:IsAbleToRemove()
end
function s.banishtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ritual_count=s.ritcount(tp)
	local opponent_count=Duel.GetMatchingGroupCount(s.rmfilter,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return ritual_count>0 and opponent_count>0 end
	local count=math.min(ritual_count,opponent_count)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,count,1-tp,LOCATION_ONFIELD)
end
function s.banishop(e,tp,eg,ep,ev,re,r,rp)
	local count=math.min(s.ritcount(tp),Duel.GetMatchingGroupCount(s.rmfilter,tp,0,LOCATION_ONFIELD,nil))
	if count>0 then
		local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,0,LOCATION_ONFIELD,1,count,nil)
		if #g>0 then Duel.Remove(g,POS_FACEUP,REASON_EFFECT) end
	end
end

function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

function s.desfilter(c)
	return c:IsDestructable()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local is_ritual=tc:IsOriginalType(TYPE_MONSTER) and tc:IsOriginalType(TYPE_RITUAL)
	local atk=tc:GetBaseAttack()
	if Duel.Destroy(tc,REASON_EFFECT)>0 and is_ritual and tc:IsLocation(LOCATION_GRAVE) then
		if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 then
			Duel.Damage(1-tp,atk,REASON_EFFECT)
		end
	end
end

function s.apply_granted_effect(c)
	local reset_flag = RESET_EVENT+(RESETS_STANDARD&~RESET_TOFIELD)

	-- Name becomes "Emerald Sovereign Ritual Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1000000000)
	e1:SetReset(reset_flag)
	c:RegisterEffect(e1,true)

	-- Cannot summon another code 1000000000 while this card is out
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimitcode)
	e2:SetReset(reset_flag)
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
	e3:SetReset(reset_flag)
	c:RegisterEffect(e3,true)
	-- When this card is Special Summoned, banish opponent's cards based on the Ritual count
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) 
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetReset(reset_flag)
	e5:SetTarget(s.banishtg)
	e5:SetOperation(s.banishop)
	c:RegisterEffect(e5,true)

	-- Unaffected by opponent's card effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.immval)
	e6:SetReset(reset_flag)
	c:RegisterEffect(e6,true)

	-- Once per turn, target and destroy an opponent's card
	local e7=Effect.CreateEffect(c)
	e7:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1,id+1)
	e7:SetTarget(s.destg)
	e7:SetOperation(s.desop)
	e7:SetReset(reset_flag)
	c:RegisterEffect(e7,true)
end
