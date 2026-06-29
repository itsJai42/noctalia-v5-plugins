--!nonstrict
function update() noctalia.setUpdateInterval(60000); barWidget.setGlyph("sparkles"); barWidget.setTooltip(noctalia.tr("title")) end
function onClick() noctalia.togglePanel("noctalia/claude-code-panel:claude-panel") end
