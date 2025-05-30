--@name Tag Pivot Setter
--@description Adds a context menu to set tag pivot points with preset options and preview
--@author You

local Dialog = Dialog
local PLUGIN_KEY = "tag-pivot"
local PREVIEW_LAYER_NAME = "__PivotPreviewTemp"

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

function drawPreviewMarker(sprite, x, y)
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

function clearPreviewLayer(sprite)
  local layer = sprite.layers[PREVIEW_LAYER_NAME]
  if layer then sprite:deleteLayer(layer) end
end

function init(plugin)
  plugin:newCommand{
    id = "SetTagPivot",
    title = "Set Pivot Point",
    group = "tag_popup_properties",
    onclick = function()
      local sprite = app.activeSprite
      if not sprite or #sprite.tags == 0 then
        app.alert("This sprite has no tags.")
        return
      end
      
      -- Build tag options
      local tagNames = {}
      local tagMap = {}
      for _, t in ipairs(sprite.tags) do
        table.insert(tagNames, t.name)
        tagMap[t.name] = t
      end
      local tagName = tagNames[1]
      local tag = tagMap[tagName]

      local existing = tag.data["pivot"] or {}
      local defaultX, defaultY = presets["Bottom"](sprite)
      local pivotX = tonumber(existing.x) or defaultX
      local pivotY = tonumber(existing.y) or defaultY

      -- Determine preset name
      local selectedPreset = "Custom"
      for name, fn in pairs(presets) do
        if name ~= "Custom" then
          local x, y = fn(sprite)
          if x == pivotX and y == pivotY then
            selectedPreset = name
            break
          end
        end
      end

      drawPreviewMarker(sprite, pivotX, pivotY)

      local dlg = Dialog{
        title = "Set Pivot",
        onclose = function()
          app.refresh()
        end
      }

      -- Select tag
      dlg:combobox{
        id = "tag",
        label = "Tag",
        option = tagName,
        options = tagNames,
        onchange = function()
          tagName = dlg.data.tag
          tag = tagMap[tagName]
          -- Change frame if outside selected tag
          local currentFrame = app.activeFrame.frameNumber
          if currentFrame < tag.fromFrame.frameNumber or currentFrame > tag.toFrame.frameNumber then
            app.activeFrame = tag.fromFrame.frameNumber
          end

          -- Update preview marker if needed
          local existing = tag.properties(PLUGIN_KEY).pivot or {}
          local defaultX, defaultY = presets["Bottom"](sprite)
          local pivotX = tonumber(existing.x) or defaultX
          local pivotY = tonumber(existing.y) or defaultY
          drawPreviewMarker(sprite, pivotX, pivotY)
        end
      }

      local function updateFields()
        local choice = dlg.data.preset
        if choice ~= "Custom" then
          local px, py = presets[choice](sprite)
          dlg:modify{id="x", text=tostring(px), enabled=false}
          dlg:modify{id="y", text=tostring(py), enabled=false}
          drawPreviewMarker(sprite, px, py)
        else
          dlg:modify{id="x", enabled=true}
          dlg:modify{id="y", enabled=true}
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
        onchange = updateFields
      }
      dlg:number{
        id = "x", label = "Pivot X", text = tostring(pivotX),
        enabled = (selectedPreset == "Custom"),
        onchange = function()
          if dlg.data.preset == "Custom" then
            local x = tonumber(dlg.data.x or pivotX)
            local y = tonumber(dlg.data.y or pivotY)
            drawPreviewMarker(sprite, x, y)
          end
        end
      }
      dlg:number{
        id = "y", label = "Pivot Y", text = tostring(pivotY),
        enabled = (selectedPreset == "Custom"),
        onchange = function()
          if dlg.data.preset == "Custom" then
            local x = tonumber(dlg.data.x or pivotX)
            local y = tonumber(dlg.data.y or pivotY)
            drawPreviewMarker(sprite, x, y)
          end
        end
      }
      dlg:button{
        text = "OK",
        onclick = function()
          local preset = dlg.data.preset
          local x, y
          if preset ~= "Custom" then
            x, y = presets[preset](sprite)
          else
            x = tonumber(dlg.data.x)
            y = tonumber(dlg.data.y)
          end

          -- Print current scoped pivot value
          print("Tag Pivot Data (before):", tag.properties(PLUGIN_KEY).pivot.x, tag.properties(PLUGIN_KEY).pivot.y)

          -- Set pivot scoped to this plugin
          tag.properties(PLUGIN_KEY).pivot = {x = x, y = y}

          clearPreviewLayer(sprite)
          app.alert("Pivot saved: (" .. x .. ", " .. y .. ")")
        end
      }
      dlg:button{
        text = "Cancel",
        onclick = function()
          clearPreviewLayer(sprite)
        end
      }

      app.refresh()
      dlg:show()
      clearPreviewLayer(sprite)
    end
  }
end

function exit(plugin)
  --print("Exiting Tag Pivot Setter")
end
