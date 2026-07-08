--Fafnir, Dragon Sin of Greed
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Contact Fusion Procedure (Sends materials strictly from YOUR field to GY)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)
	
	--Continuous Check: Capture and track material count upon successful Contact Summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.regcon)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)
	
	--Tier 1 (1+ Monsters): Draw 1 card per turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.drawcon)
	e3:SetTarget(s.drawtg)
	e3:SetOperation(s.drawop)
	c:RegisterEffect(e3)
	
	--Tier 2 (2+ Monsters): Gain 500 ATK per material monster
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.atkcon)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
	
	--Tier 3 (4+ Monsters): Cannot be targeted by opponent's card effects
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.tgtcon)
	e5:SetValue(aux.tgoval)
	c:RegisterEffect(e5)
	
	--Tier 4 (5+ Monsters): Snatch 1 random card from opponent's hand on battle destruction
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_TOHAND)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_BATTLE_DESTROYING)
	e6:SetCondition(s.handcon)
	e6:SetTarget(s.handtg)
	e6:SetOperation(s.handop)
	c:RegisterEffect(e6)
end

--Filters for the required "Greed" component
function s.greedfilter(c)
	return c:IsFaceup() and c:IsCode(1000000049) and c:IsAbleToGraveAsCost() -- Replace with your actual "Greed" card ID code
end

--Filters for the monster components
function s.matfilter(c)
	return c:IsAbleToGraveAsCost()
end

--Contact Fusion Check Logic (FIXED FOR OWN FIELD ONLY)
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.greedfilter,tp,LOCATION_ONFIELD,0,nil)
	local g2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	return #g1>0 and #g2>1
end

--Contact Fusion Processing (FIXED FOR OWN FIELD ONLY)
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(s.greedfilter,tp,LOCATION_ONFIELD,0,nil)
	local g2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg1=g1:Select(tp,1,1,nil)
	if #sg1==0 then return false end
	
	g2:Remove(Card.InGroup,nil,sg1)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg2=g2:Select(tp,1,99,nil)
	if #sg2==0 then return false end
	
	sg1:Merge(sg2)
	c:SetMaterial(sg1)
	e:SetLabel(#sg2) 
	return true
end

function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=c:GetMaterial()
	Duel.SendtoGrave(g,REASON_COST)
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD,0,1,e:GetLabel())
end

--Retrieves and locks the material count value permanently onto the monster
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local labels={c:GetFlagEffectLabel(id)}
	c:SetLabel(labels)
end

--Effect Tier Condition Handlers
function s.drawcon(e)
	return e:GetHandler():GetLabel()>=1
end
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

function s.atkcon(e)
	return e:GetHandler():GetLabel()>=2
end
function s.atkval(e,c)
	return (c:GetLabel() + 1) * 500
end

function s.tgtcon(e)
	return e:GetHandler():GetLabel()>=4
end

function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetLabel()>=5 and aux.bdcon(e,tp,eg,ep,ev,re,r,rp)
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
