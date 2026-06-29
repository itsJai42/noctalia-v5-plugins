--!nonstrict
function update() noctalia.setUpdateInterval(60000); barWidget.setGlyph("note") end
function onClick() noctalia.togglePanel("noctalia/sticky-notes:notes-panel") end
