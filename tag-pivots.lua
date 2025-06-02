--@name Tag Pivot Setter
--@description Adds a context menu to set tag pivot points with preset options and preview
--@author You

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local PREVIEW_LAYER_NAME = "__PivotPreviewTemp"
local DEBUG = false
local function debugPrint(...)
  if DEBUG then print(...) end
end

local presets = {
  ["Center"] = function(s) return math.floor(s.width/2), math.floor(s.height/2) end,
  ["Top Left"] = function(s) return 0, 0 end,
  ["Top"] = function(s) return math.floor(s.width/2), 0 end,
  ["Top Right"] = function(s) return s.width-1, 0 end,
  ["Left"] = function(s) return 0, math.floor(s.height/2) end,
  ["Right"] = function(s) return s.width-1, math.floor(s.height/2) end,
  ["Bottom Left"] = function(s) return 0, s.height-1 end,
  ["Bottom"] = function(s) return math.floor(s.width/2), s.height-1 end,
  ["Bottom Right"] = function(s) return s.width-1, s.height-1 end,
  ["Custom"] = function(s) return nil, nil end
}

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

function ensurePreviewLayer(sprite)
  local layer = sprite.layers[PREVIEW_LAYER_NAME]
  if not layer then
    layer = sprite:newLayer()
    layer.name = PREVIEW_LAYER_NAME
    layer.isVisible = true
    layer.isEditable = true
  end
  return layer
end

--=============================================================================

function clearPreviewLayer(sprite)
  local layer = sprite.layers[PREVIEW_LAYER_NAME]
  if layer then sprite:deleteLayer(layer) end
end

--=============================================================================

function drawPreviewMarker(sprite, x, y)
  if not x or not y then return end
  local layer = ensurePreviewLayer(sprite)
  for _, cel in ipairs(layer.cels) do sprite:deleteCel(cel) end
  
  local img = Image(sprite.width, sprite.height)
  local red = Color{r=255, g=0, b=0, a=255}
  img:drawPixel(x, y, red)
  if x > 0 then img:drawPixel(x-1, y, red) end
  if x < sprite.width-1 then img:drawPixel(x+1, y, red) end
  if y > 0 then img:drawPixel(x, y-1, red) end
  if y < sprite.height-1 then img:drawPixel(x, y+1, red) end
  
  sprite:newCel(layer, app.activeFrame, img, Point(0, 0))
  app.refresh()
end

--=============================================================================

function getPreset(sprite, x, y)
  for name, fn in pairs(presets) do
    local px, py = fn(sprite)
    if px == x and py == y then
      return name
    end
  end
  return "Custom"
end

--=============================================================================

function getTagPivot(sprite, tag)
  local properties = tag.properties(PLUGIN_KEY)
  if properties and properties.pivot then
    return properties.pivot.x, properties.pivot.y
  end
  return presets["Bottom"](sprite)
end

--=============================================================================

function setTagPivot(sprite, tag, x, y)
  local properties = tag.properties(PLUGIN_KEY)
  if not properties then
    tag.properties(PLUGIN_KEY, {pivot = {}})
    properties = tag.properties(PLUGIN_KEY)
  end
  properties.pivot = {x = x, y = y}
end

--=============================================================================

function printTable(tbl, indent)
  indent = indent or 0
  local formatting = string.rep("  ", indent)
  
  for key, value in pairs(tbl) do
    local keyStr = tostring(key)
    if type(value) == "table" then
      print(formatting .. keyStr .. " = {")
      printTable(value, indent + 1)
      print(formatting .. "}")
    else
      print(formatting .. keyStr .. " = " .. tostring(value))
    end
  end
end

--=============================================================================

function afterCommandHandler(ev)
    if ev.name == "NewFrameTag" then
      -- Set all tags to have a default pivot if they don't have one
      local sprite = app.activeSprite
      if sprite and #sprite.tags > 0 then
        for _, tag in ipairs(sprite.tags) do
          local properties = tag.properties(PLUGIN_KEY)
          if not properties or not properties.pivot then
            local x, y = presets["Bottom"](sprite)
            setTagPivot(sprite, tag, x, y)
          end
        end
      end
    end
  end

--=============================================================================
-- INIT
--=============================================================================

function init(plugin)
  plugin:newCommand{
    id = "SetTagPivot",
    title = "Set Pivot Point",
    group = "tag_popup_properties",
    onclick = function()

      -- Get the active sprite
      local sprite = app.activeSprite
      if not sprite or #sprite.tags == 0 then
        app.alert("This sprite has no tags.")
        return
      end
      
      -- Build all tag options
      local tagNames = {}
      local tagMap = {}
      for _, t in ipairs(sprite.tags) do
        table.insert(tagNames, t.name)
        tagMap[t.name] = t
      end

      -- Default selection to tag that contains the current frame otherwise first tag
      local currentFrame = app.activeFrame.frameNumber
      local selectedTag = nil
      for _, tag in ipairs(sprite.tags) do
        if currentFrame >= tag.fromFrame.frameNumber and currentFrame <= tag.toFrame.frameNumber then
          selectedTag = tag
          break
        end
      end
      if not selectedTag then
        selectedTag = sprite.tags[1]
      end

      -- Get pivot for selected tag
      local pivotX, pivotY = getTagPivot(sprite, selectedTag)

      -- Determine preset name from pivot
      local selectedPreset = getPreset(sprite, pivotX, pivotY)

      -- Initial draw of the preview marker
      drawPreviewMarker(sprite, pivotX, pivotY)

      -- Create the dialog box
      local dlg = Dialog{
        title = "Set Pivot",
        onclose = function()
          clearPreviewLayer(sprite)
          app.refresh()
        end
      }

      -- Select tag dropdown
      dlg:combobox{
        id = "tag",
        label = "Tag",
        option = selectedTag.name,
        options = tagNames,
        onchange = function()
          selectedTag = tagMap[dlg.data.tag]
          -- Change frame if outside selected tag
          local currentFrame = app.activeFrame.frameNumber
          if currentFrame < selectedTag.fromFrame.frameNumber or currentFrame > selectedTag.toFrame.frameNumber then
            app.activeFrame = selectedTag.fromFrame.frameNumber
          end
          
          -- Update pivot and preset values
          pivotX, pivotY = getTagPivot(sprite, selectedTag)
          selectedPreset = getPreset(sprite, pivotX, pivotY)
          dlg:modify{id="preset", option=selectedPreset}
          dlg:modify{id="x", text=tostring(pivotX)}
          dlg:modify{id="y", text=tostring(pivotY)}

          -- Update preview marker
          drawPreviewMarker(sprite, pivotX, pivotY)
        end
      }
      
      -- Update field helper for when we change presets 
      local function onPresetChanged()
        local choice = dlg.data.preset
        if choice ~= "Custom" then
          local px, py = presets[choice](sprite)
          dlg:modify{id="x", text=tostring(px), enabled=false}
          dlg:modify{id="y", text=tostring(py), enabled=false}
        else
          dlg:modify{id="x", enabled=true}
          dlg:modify{id="y", enabled=true}
        end
        drawPreviewMarker(sprite, tonumber(dlg.data.x), tonumber(dlg.data.y))
      end

      -- Update preview helper whenever number fields change
      local function onPivotChanged()
          if dlg.data.preset == "Custom" then
            local x = tonumber(dlg.data.x or pivotX)
            local y = tonumber(dlg.data.y or pivotY)
            drawPreviewMarker(sprite, x, y)
          end
        end

      dlg:combobox{
        id = "preset",
        label = "Preset",
        option = selectedPreset,
        options = {
          "Center", "Top Left", "Top", "Top Right",
          "Left", "Right", "Bottom Left", "Bottom",
          "Bottom Right", "Custom"
        },
        onchange = onPresetChanged
      }
      dlg:number{
        id = "x", label = "Pivot X", text = tostring(pivotX),
        enabled = (selectedPreset == "Custom"),
        onchange = onPivotChanged
      }
      dlg:number{
        id = "y", label = "Pivot Y", text = tostring(pivotY),
        enabled = (selectedPreset == "Custom"),
        onchange = onPivotChanged
      }
      dlg:button{
        text = "Apply",
        onclick = function()
          local preset = dlg.data.preset
          local x, y
          if preset ~= "Custom" then
            x, y = presets[preset](sprite)
          else
            x = tonumber(dlg.data.x)
            y = tonumber(dlg.data.y)
          end

          -- Set pivot 
          setTagPivot(sprite, selectedTag, x, y)

          -- Update the info label
          dlg:modify{
            id = "info",
            text = "Pivot saved: (" .. x .. ", " .. y .. ")",
            color = Color{ r=0, g=180, b=0 }
          }
        end
      }

      -- Add this label below the buttons (add it after the buttons)
      dlg:label{
        id = "info",
        label = "",
        text = string.rep(" ", 25),
        color = Color{ r=0, g=180, b=0 }
      }

      app.refresh()
      dlg:show()
      clearPreviewLayer(sprite)
    end
  }

  app.events:on('aftercommand', afterCommandHandler)
end

--=============================================================================
-- EXIT
--=============================================================================

function exit(plugin)
  app.events:off('aftercommand', afterCommandHandler)
end
