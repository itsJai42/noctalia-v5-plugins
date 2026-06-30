--!nonstrict
function update() noctalia.setUpdateInterval(60000); barWidget.setGlyph("calculator") end
function onClick() noctalia.togglePanel("noctalia/noctalia-calculator:calculator-panel") end
