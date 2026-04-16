--Into The Emerald Light
local s, id=GetID()
s.outsidedeck={
    {31764700,2}, -- Yubel - The Ultimate Nightmare
    {4779091,2}, -- Yubel - Terror Incarnate
    {51402908,2}, -- The Supremacy Sun
    {78371393,2}, -- Yubel
    {90829280,3}, -- Spirit of Yubel
    {26913989,2}, -- Geistgrinder Golem
    {50263751,2}, -- Greed Quasar
    {40460013,2}, -- Zalamander Catalyzer
    {62318994,3}, -- Samsara D Lotus
    {5288597,1}, -- Transmodify
    {24094653,2}, -- Polymerization
    {65261141,3}, -- Nightmare Pain
    {92650749,3}, -- Mature Chronicle
    {93729896,3}, -- Nightmare Throne
    {27551,2}, -- Limit Reverse
    {80560728,3}, -- Dimension Mirage
    {87532344,3} -- Eternal Favorite
}
function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then return true end
    local c=e:GetHandler()
    local og=Duel.GetOverlayGroup(tp, 1, 0)
    if #og>0 then
        Duel.SendtoGrave(og, REASON_COST)
    end
    local g=Duel.GetMatchingGroup(aux.True, tp, LOCATION_ALL, 0, nil)
    if #g>0 then
        Duel.SendtoDeck(g, tp, -2, REASON_COST)
    end
end
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk==0 then return true end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, 1)
    if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
        Duel.SetChainLimit(aux.FALSE)
    end
end
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local c=e:GetHandler()
    Duel.BreakEffect()
    local g=Group.CreateGroup()
    for _,entry in ipairs(s.outsidedeck) do
        local code,count=entry[1],entry[2]
        for i=1,count do
            g:AddCard(Duel.CreateToken(tp,code))
        end
    end
    if #g>0 then
        Duel.SendtoDeck(g,tp,SEQ_DECKSHUFFLE,REASON_EFFECT)
        Duel.ShuffleDeck(tp)
        Duel.BreakEffect()
        Duel.Draw(tp,5,REASON_EFFECT)
    end
    Duel.BreakEffect()
    c:CancelToGrave()
end
