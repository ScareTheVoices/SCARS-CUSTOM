--Fafnir, Dragon Sin of Greed
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Special Summon Condition (Copied exactly from the Yubel filter sequence layout)
	Fusion.AddProcMixRep(c,true,true,s.ffilter1,1,99,s.ffilter2)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,true)

	--Gains these effects based on the number of monster materials used for this card
	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1a:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1a:SetOperation(s.effop)
	c:RegisterEffect(e1a)

	--Track the number of monster materials used (Excludes the Greed trap card from the material count)
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_SINGLE)
	e1b:SetCode(EFFECT_MATERIAL_CHECK)
	e1b:SetValue(function(e,c) e1a:SetLabel(c:GetMaterial():FilterCount(s.ffilter1,nil)) end)
	c:RegisterEffect(e1b)
end

function s.ffilter1(c)
	return c:IsType(TYPE_MONSTER)
end

function s.ffilter2(c)
	return c:IsCode(89405199) and c:IsType(TYPE_TRAP+TYPE_CONTINUOUS) and c:IsFaceup()
end

function s.contactfil(tp)
	return Duel.GetMatchingGroup(s.ffilter1,tp,LOCATION_MZONE,0,nil)
		+ Duel.GetMatchingGroup(s.ffilter2,tp,LOCATION_ONFIELD,0,nil)
end

function s.contactop(g)
	Duel.SendtoGrave(g,REASON_COST+REASON_MATERIAL+REASON_FUSION)
end

--Dynamic Effect Injection Framework (Driven cleanly by material checks)
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local monster_mats_count=e:GetLabel()

	--● 1+: Once per turn, Draw 1 card
	if monster_mats_count>=1 then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,0))
		e2:SetCategory(CATEGORY_DRAW)
		e2:SetType(EFFECT_TYPE_IGNITION)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1)
		e2:SetTarget(s.drawtg)
		e2:SetOperation(s.drawop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	--● 2+: Gain 500 ATK per monster material used
	if monster_mats_count>=2 then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UPDATE_ATTACK)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e3:SetRange(LOCATION_MZONE)
		e3:SetValue(monster_mats_count*500)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e3)
	end

	--● 4+: Cannot be targeted by opponent's card effects
	if monster_mats_count>=4 then
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e4:SetRange(LOCATION_MZONE)
		e4:SetValue(aux.tgoval)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e4)
	end

	--● 5+: Add 1 random card from opponent's hand to yours on battle destroy
	if monster_mats_count>=5 then
		local e5=Effect.CreateEffect(c)
		e5:SetDescription(aux.Stringid(id,1))
		e5:SetCategory(CATEGORY_TOHAND)
		e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e5:SetCode(EVENT_BATTLE_DESTROYING)
		e5:SetCondition(aux.bdcon)
		e5:SetTarget(s.handtg)
		e5:SetOperation(s.handop)
		e5:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e5)
	end
end

-- --- SUPPORT TARGETING & OPERATION FUNCTIONS ---
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

function s.handtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_HAND)
end

function s.handop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.SendtoHand(sg,tp,REASON_EFFECT)
	end
end
