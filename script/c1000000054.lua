--Accel Sovereign
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

-- Hand Locking Verification Logic
function s.actlimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsMonsterEffect() and rc:IsLocation(LOCATION_HAND) and not rc:IsType(TYPE_RITUAL)
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

-- On-Summon Mass Banishment & Burn Filters
function s.excludefilter(c,sc)
	return c~=sc and c:IsAbleToRemove()
end
function s.burnfilter(c)
	return c:IsLocation(LOCATION_REMOVED) and c:IsSetCard(0x4003)
end
function s.banishtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.excludefilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler(),e:GetHandler()) end
	local g=Duel.GetMatchingGroup(s.excludefilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler(),e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end
function s.banishop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.excludefilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c,c)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
		local bg=Duel.GetOperatedGroup():Filter(s.burnfilter,nil)
		if #bg>0 then
			local dam=bg:GetSum(Card.GetBaseAttack)
			if dam>0 then
				Duel.Damage(1-tp,dam,REASON_EFFECT)
			end
		end
	end
end

-- Gained Quick Effect Negation Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
end
function s.tdfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsAbleToDeck()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.SetTargetCard(eg)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE+CATEGORY_TODECK,nil,1,tp,LOCATION_REMOVED)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=eg:GetFirst()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then
			Duel.HintSelection(g)
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
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

	-- Lock Hand Triggers: Only Ritual monsters can activate from hand
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetCode(EFFECT_CANNOT_ACTIVATE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(1,1)
	e4:SetValue(s.actlimit)
	e4:SetReset(reset_flag)
	c:RegisterEffect(e4,true)

	-- Gained Effect: On Special Summon, banish all other cards on the field, and inflict damage equal to combined ATK of banished 0x4003 cards
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) 
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetReset(reset_flag)
	e5:SetTarget(s.banishtg)
	e5:SetOperation(s.banishop)
	c:RegisterEffect(e5,true)

	-- Gained Once Per Turn Quick Effect: Negate Enemy Monster & Recycle Banish Pile
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetCategory(CATEGORY_DISABLE+CATEGORY_TODECK)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.negcon)
	e6:SetTarget(s.negtg)
	e6:SetOperation(s.negop)
	e6:SetReset(reset_flag)
	c:RegisterEffect(e6,true)
end
