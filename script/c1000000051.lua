--Amorphous The All-Seeing Terror
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	--1: Hand-Trap Ritual Summon using opponent's Level 6+ monster as tribute
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.ritcon)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)
	
	--2: Zone Shifting Effect (Monster to Field Zone, or Field Zone to Monster Zone)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE+LOCATION_FZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.shift_tg)
	e2:SetOperation(s.shift_op)
	c:RegisterEffect(e2)
	
	--3: Field Spell Status — Changes its card type to a pure Field Spell when in the Field Zone
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CHANGE_TYPE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetValue(TYPE_SPELL+TYPE_FIELD)
	c:RegisterEffect(e3)
	
	--4: Field Spell Status — Opponent plays with hand revealed
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_PUBLIC)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(0,LOCATION_HAND)
	c:RegisterEffect(e4)
	
	--5: Field Spell Status — No battle damage involving Special Summoned monsters
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(1,0)
	e5:SetCondition(s.damcon)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

--Checks if the opponent just special summoned a level 6 or higher monster
function s.ritfilter(c,tp)
	return c:IsSummonPlayer(1-tp) and c:IsLevelAbove(6) and c:IsReleasable()
end
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ritfilter,1,nil,tp)
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) end
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=eg:Filter(s.ritfilter,nil,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if tc and Duel.Release(tc,REASON_EFFECT)>0 then
		c:SetMaterial(Group.FromCards(tc))
		if Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			c:CompleteProcedure()
		end
	end
end

--Zone Shifting Target Logic
function s.shift_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if c:IsLocation(LOCATION_MZONE) then
			return Duel.GetFieldCard(tp,LOCATION_FZONE,0)==nil
		elseif c:IsLocation(LOCATION_FZONE) then
			return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
				and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		end
		return false
	end
	if c:IsLocation(LOCATION_FZONE) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_FZONE)
	end
end

--Zone Shifting Operation Logic
function s.shift_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if c:IsLocation(LOCATION_MZONE) then
		-- Move from Monster Zone to Field Zone cleanly
		if Duel.GetFieldCard(tp,LOCATION_FZONE,0)~=nil then return end
		Duel.MoveToField(c,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	elseif c:IsLocation(LOCATION_FZONE) then
		-- Special Summon itself back out of the Field Zone
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Damage Prevention Trigger Conditions
function s.damcon(e)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return (a and a:IsSpecialSummoned()) or (d and d:IsSpecialSummoned())
end
