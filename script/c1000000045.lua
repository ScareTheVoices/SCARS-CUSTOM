--Emerald Light Sovereign
--Made by ScareTheVoices
local s,id=GetID()
function s.initial_effect(c)
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
end

function s.reqfilter(c)
	return c:IsCode(1000000000) and c:IsDestroyable()
end
function s.ritfilter(c,ex)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c:IsType(TYPE_RITUAL) and c:IsDestroyable() and c~=ex
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.reqfilter,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 or not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectMatchingCard(tp,s.reqfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_MZONE,0,1,1,tc1)
	local tc2=g2:GetFirst()
	if not tc2 then return end
	g1:Merge(g2)
	Duel.HintSelection(g1,true)
	if Duel.Destroy(g1,REASON_EFFECT)==2 and c:IsRelateToEffect(e) then
		if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
			s.apply_granted_effect(c)
		end
	end
end

function s.zerotg(e,c)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c~=e:GetHandler()
end
function s.gainfilter(c,sc)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c~=sc
end
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.gainfilter,c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil,e:GetHandler())
	return g:GetSum(Card.GetAttack)
end
function s.defval(e,c)
	local g=Duel.GetMatchingGroup(s.gainfilter,c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil,e:GetHandler())
	return g:GetSum(Card.GetDefense)
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

	--This card gains ATK/DEF of all Emerald Light monsters on the field
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
