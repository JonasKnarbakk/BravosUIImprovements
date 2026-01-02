function BUII_GetFontPath()
  local fontName = "Expressway"
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    local font = LSM:Fetch("font", fontName)
    if font then
      return font
    end
  end
  -- Fallback
  local filename = GameFontHighlight:GetFont()
  return filename
end
