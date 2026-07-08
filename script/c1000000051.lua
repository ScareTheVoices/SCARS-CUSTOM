--Amorphous the All-Seeing Terror
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	--1: Hand-Trap Summon (Tributes opponent's monster to summon itself)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.ritcon)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)
	
	--2: Zone Shifting Effect (HARD ONCE-PER-TURN QUICK EFFECT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE+LOCATION_SZONE)
	e2:SetCountLimit(1,id) -- FIXED: Tied hardcoded turn restriction count to this specific card ID
	e2:SetTarget(s.shift_tg)
	e2:SetOperation(s.shift_op)
	c:RegisterEffect(e2)
	
	--3: Spell Status — Changes its card type to a Continuous Spell when in the Spell & Trap Zone
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CHANGE_TYPE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
	c:RegisterEffect(e3)
	
	--4: Spell Status — Opponent plays with hand revealed
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_PUBLIC)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(0,LOCATION_HAND)
	c:RegisterEffect(e4)
	
	--5: Spell Status — No battle damage involving Special Summoned monsters
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_SZONE)
	e5:SetTargetRange(1,0)
	e5:SetCondition(s.damcon)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

--Checks if any opponent monster special summoned is level 6 or higher
function s.ritfilter(c,tp)
	return c:IsSummonPlayer(1-tp) and c:IsLevelAbove(6) and c:IsReleasable()
end
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ritfilter,1,nil,tp)
end

--Targeting logic to process hand-trap special summon
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	local g=eg:Filter(s.ritfilter,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
end

--Resolution operation logic: Tributes threat and summons itself safely
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=eg:Filter(s.ritfilter,nil,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if tc and Duel.Release(tc,REASON_EFFECT)>0 then
		c:SetMaterial(Group.FromCards(tc))
		if Duel.SpecialSummonStep(c,SUMMON_TYPE_RITUAL,tp,tp,true,true,POS_FACEUP) then
			c:SetStatus(STATUS_PROC_COMPLETE,true)
		end
		Duel.SpecialSummonComplete()
	end
end

--Zone Shifting Target Logic
function s.shift_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if c:IsLocation(LOCATION_MZONE) then
			return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		elseif c:IsLocation(LOCATION_SZONE) then
			return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		end
		return false
	end
	if c:IsLocation(LOCATION_SZONE) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_SZONE)
	end
end

--Zone Shifting Operation Logic
function s.shift_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if c:IsLocation(LOCATION_MZONE) then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	elseif c:IsLocation(LOCATION_SZONE) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		if Duel.SpecialSummonStep(c,0,tp,tp,true,true,POS_FACEUP) then
			Duel.SpecialSummonComplete()
		end
	end
end

--Damage Prevention Trigger Conditions
function s.damcon(e)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return (a and a:IsSpecialSummoned()) or (d and d:IsSpecialSummoned())
end
