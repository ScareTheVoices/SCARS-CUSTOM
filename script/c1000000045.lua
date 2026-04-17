--Emerald Light Sovereign
--Made by ScareTheVoices
local s,id=GetID()
s.listed_series={0x4003}
s.listed_names={1000000000}

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

	--Cannot summon code 1000000000 while this card is face-up
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimitcode)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e4)

	--You cannot control code 1000000000 while this card is face-up
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_ADJUST)
	e5:SetRange(LOCATION_MZONE)
	e5:SetOperation(s.ctop)
	c:RegisterEffect(e5)

	--When this card leaves the field: revive code 1000000000 on your next Standby Phase
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCondition(s.rvcon)
	e6:SetOperation(s.rvop)
	c:RegisterEffect(e6)
end

function s.splimitcode(e,c)
	return c:IsCode(1000000000)
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

function s.ctfilter(c,tp)
	return c:IsFaceup() and c:IsCode(1000000000) and c:IsControler(tp) and c:IsAbleToGraveAsCost()
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ctfilter,tp,LOCATION_MZONE,0,nil,tp)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_RULE)
	end
end

function s.rvcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
end
function s.rvop(e,tp,eg,ep,ev,re,r,rp)
	tp=e:GetHandler():GetPreviousControler()
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetCountLimit(1)
	e1:SetLabel(Duel.GetTurnCount())
	e1:SetCondition(s.rvspcon)
	e1:SetTarget(s.rvsptg)
	e1:SetOperation(s.rvspop)
	e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN,2)
	Duel.RegisterEffect(e1,tp)
end
function s.rvspcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()~=e:GetLabel()
end
function s.rvspfilter(c,e,tp)
	return c:IsCode(1000000000) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
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
function s.apply_granted_effect(c)
	--Other Emerald Light monsters you control have ATK/DEF set to 0
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.zerotg)
	e1:SetValue(0)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1,true)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e2,true)

	--This card gains original ATK/DEF of all other Emerald Light monsters on the field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e3,true)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	e4:SetValue(s.defval)
	c:RegisterEffect(e4,true)

	--Other Emerald Light monsters cannot be destroyed by battle
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(LOCATION_MZONE,0)
	e5:SetTarget(s.indtg)
	e5:SetValue(1)
	e5:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e5,true)

	--No battle damage from battles involving your other Emerald Light monsters
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetTargetRange(1,0)
	e6:SetCondition(s.damcon)
	e6:SetValue(0)
	e6:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e6,true)
end
