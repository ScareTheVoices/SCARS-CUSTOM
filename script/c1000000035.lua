--Emerald Light Protection
local s,id=GetID()
function s.initial_effect(c)
	--Activate (flip face-up)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Protect one chosen Emerald Sovereign Ritual Dragon or Emerald Light monster
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end
s.listed_series={0x4003}
s.listed_names={1000000000}

--Filter for monsters to protect (ID 1000000000 or setcode 0x4003)
function s.repfilter(c,tp)
	return c:IsFaceup() and (c:IsCode(1000000000) or c:IsSetCard(0x4003))
		and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) and c:IsReason(REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

--Filter for monsters to destroy instead
function s.desfilter(c,protected)
	return c:IsFaceup() and c:IsSetCard(0x4003) and c:IsDestructable() and not protected:IsContains(c)
end

--Target for replacement effect
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsFaceup() and eg:IsExists(s.repfilter,1,nil,tp)
		and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_MZONE,0,1,nil,Group.CreateGroup()) end
	if not Duel.SelectEffectYesNo(tp,e:GetHandler()) then return false end
	local g=eg:FilterSelect(tp,s.repfilter,1,1,nil,tp)
	if #g==0 then return false end
	e:SetLabelObject(g)
	return true
end

--Value for replacement effect (protect only the chosen monster)
function s.repval(e,c)
	return e:GetLabelObject():IsContains(c)
end

--Operation to destroy a card instead
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local protected=e:GetLabelObject()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil,protected)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT+REASON_REPLACE)
	end
end
