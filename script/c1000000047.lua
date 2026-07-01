--Darkest-Eyes Void Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Absorption/Destruction Quick Effect (Targeting via Alternative Blue-Eyes logic)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
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

	-- Effect 3: THE NAGLFAR BLUEPRINT REWRITE - Field/Continuous Destroy Replace Loop
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD) -- Field scale interceptor matching Naglfar
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.desreptg)
	e4:SetValue(s.desrepval)
	e4:SetOperation(s.desrepop)
	c:RegisterEffect(e4)
end

-- --- EFFECT 1 FUNCTIONS (Equip or Destroy) ---
function s.statfilter(c,id)
	return c:GetFlagEffect(id)>0
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	
	local has_equip = c:GetEquipGroup():IsExists(s.statfilter,1,nil,id)
	
	if tc:IsType(TYPE_RITUAL) and not has_equip and Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,2)) then
		if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
		if not Duel.Equip(tp,tc,c,false) then return end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_OWNER_RELATE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetValue(s.eqlimit)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	else
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

-- --- NAGLFAR ARCHITECTURE IMPLEMENTATION ---
function s.repfilter(c,e)
	-- Targets only this handler card, checking if it is facing destruction
	return c==e:GetHandler() and c:IsLocation(LOCATION_MZONE)
		and c:IsReason(REASON_BATTLE|REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end
function s.desfilter(c,e)
	-- Verifies the shield card is valid, destructible, and not already designated for death
	return s.statfilter(c,id) and c:IsDestructable(e)
		and not c:IsStatus(STATUS_DESTROY_CONFIRMED)
end
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=c:GetEquipGroup()
	
	-- Evaluation layer confirming the check event targets Void-Eyes and a valid shield card exists
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,e)
		and g:IsExists(s.desfilter,1,nil,e) end
		
	-- Triggers player choice popup box interface safely inside continuous scope
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
		local sg=g:FilterSelect(tp,s.desfilter,1,1,nil,e)
		e:SetLabelObject(sg:GetFirst())
		Duel.HintSelection(sg)
		-- Safety flag states to the game engine that this item is locked for sacrifice resolution
		sg:GetFirst():SetStatus(STATUS_DESTROY_CONFIRMED,true)
		return true
	else 
		return false 
	end
end
function s.desrepval(e,c)
	-- Standard Naglfar passback validating targeted item relation properties
	return s.repfilter(c,e)
end
function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc then
		-- Remove safety confirmation locks and cleanly apply substitution rules execution
		tc:SetStatus(STATUS_DESTROY_CONFIRMED,false)
		Duel.Destroy(tc,REASON_EFFECT|REASON_REPLACE)
	end
end

