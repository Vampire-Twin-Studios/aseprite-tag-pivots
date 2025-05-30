--@name Tag Pivot Setter
--@description Adds a context menu to set tag pivot points, defaulting to bottom center and previewing pivot while editing
--@author You

local Dialog = Dialog

local PREVIEW_LAYER_NAME = "__PivotPreviewTemp"

function getBottomCenter(sprite)
  return math.floor(sprite.width / 2), sprite.height
end

function ensurePreviewLayer(sprite)
  -- Get or create preview layer
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

  -- Clear any previous preview cels
  for _, cel in ipairs(layer.cels) do
    sprite:deleteCel(cel)
  end

  -- Draw crosshair in a new image
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
  if layer then
    sprite:deleteLayer(layer)
  end
end

function init(plugin)
  plugin:newCommand{
    id = "SetTagPivot",
    title = "Set Pivot Point",
    group = "tag_popup_properties",
    onclick = function()
      local sprite = app.activeSprite
      local tag = app.activeTag

      if not sprite or not tag then
        app.alert("You must select a tag.")
        return
      end

      local defaultX, defaultY = getBottomCenter(sprite)
      local existing = tag.data["pivot"] or {}
      local pivotX = tonumber(existing.x) or defaultX
      local pivotY = tonumber(existing.y) or defaultY

      -- Draw initial preview
      drawPreviewMarker(sprite, pivotX, pivotY)

      local dlg = Dialog("Set Pivot for Tag: " .. tag.name)
      local onchangecallback = function()
          local x = tonumber(dlg.data.x or pivotX)
          local y = tonumber(dlg.data.y or pivotY)
          drawPreviewMarker(sprite, x, y)
        end
      dlg:number{
        id = "x", label = "Pivot X", text = tostring(pivotX), onchange = onchangecallback 
      }
      dlg:number{
        id = "y", label = "Pivot Y", text = tostring(pivotY), onchange = onchangecallback
      }
      dlg:button{
        text = "OK",
        onclick = function()
          local x = tonumber(dlg.data.x)
          local y = tonumber(dlg.data.y)
          tag.data["pivot"] = {x = x, y = y}
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
      -- Also clear preview if they close the dialog manually (e.g. via X)
      clearPreviewLayer(sprite)
    end
  }
end

function exit(plugin)
  print("Exiting Tag Pivot Setter")
end
