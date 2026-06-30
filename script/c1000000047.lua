-- Custom Monster: Void-Eyes Empty Dragon
-- Card ID: 100000001
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Absorption/Destruction Quick Effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)
	
	-- Effect 2: Gain ATK/DEF from equipped cards
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)

	-- Effect 3: Substitute destruction by destroying equipped card
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.subtg)
	e4:SetValue(s.subval)
	c:RegisterEffect(e4)
end

-- --- EFFECT 1 FUNCTIONS (Equip or Destroy) ---
function s.eqfilter(c)
	return c:IsFaceUp()
end
function s.statfilter(c,id)
	return c:GetFlagEffect(id)>0
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.eqfilter(chkc) end
	if chk then return Duel.IsExistingTarget(s.eqfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,0,LOCATION_MZONE,1,1,nil)
	
	local tc=g:GetFirst()
	-- If target is Ritual but we ALREADY have a Ritual card equipped by this effect, it cannot be targeted
	if tc and tc:IsType(TYPE_RITUAL) and e:GetHandler():GetEquipGroup():IsExists(s.statfilter,1,nil,id) then
		return false
	end

	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	
	-- Check if it's a Ritual Monster AND we don't already have one equipped
	if tc:IsType(TYPE_RITUAL) then
		if c:GetEquipGroup():IsExists(s.statfilter,1,nil,id) then return end -- Safety double check
		if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
		if not Duel.Equip(tp,tc,c,false) then return end
		-- Add Equipping rules & relation flags
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_OWNER_RELATE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetValue(s.eqlimit)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		-- Flag to mark it was equipped by THIS card's effect
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	else
		-- Otherwise, Destroy
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
function s.eqlimit(e,c)
	return e:GetOwner()==c
end

-- --- EFFECT 2 FUNCTIONS (Gain ATK/DEF) ---
function s.atkval(e,c)
	local g=c:GetEquipGroup():Filter(s.statfilter,nil,id)
	local atk=0
	for tc in aux.Next(g) do
		local catk=tc:GetTextAttack()
		if catk<0 then catk=0 end
		atk=atk+catk
	end
	return atk
end
function s.defval(e,c)
	local g=c:GetEquipGroup():Filter(s.statfilter,nil,id)
	local def=0
	for tc in aux.Next(g) do
		local cdef=tc:GetTextDefense()
		if cdef<0 then cdef=0 end
		def=def+cdef
	end
	return def
end

-- --- EFFECT 3 FUNCTIONS (Destruction Substitute) ---
function s.subtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk then 
		return not c:IsReason(REASON_REPLACE) 
			and c:GetEquipGroup():IsExists(s.statfilter,1,nil,id)
	end
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=c:GetEquipGroup():FilterSelect(tp,s.statfilter,1,1,nil,id)
		Duel.SetTargetCard(g)
		return true
	end
	return false
end
function s.subval(e,c)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	if g and g:IsContains(c) then
		Duel.Destroy(c,REASON_EFFECT+REASON_REPLACE)
		return true
	end
	return false
end
