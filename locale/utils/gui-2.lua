-- GUI Helper Module
-- Common GUI functions
-- @author Denis Zholob (DDDGamer)
-- github: https://github.com/DDDGamer/factorio-dz-softmod
-- ======================================================= --

GUI = {}

-- Destroyes the children of a GUI element
-- @param el <- element to toggle destroy childen of
function GUI.clear_element( el )
  if el ~= nil then
    for i, child in pairs(el.children_names) do
      el[child].destroy()
    end
  end
end

-- Toggles element on off (visibility)
-- @param el <- element to toggle visibility
function GUI.toggle_element( el )
  if el ~= nil then
    if el.style.visible == false then
      el.style.visible = true
    else
      el.style.visible = false 
    end 
  end
end

return GUI
