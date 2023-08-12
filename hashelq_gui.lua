local direction = {
  HORIZONTAL = nil,
  VERTICAL = 1
}

local function Color(r, g, b, a)
  return { r = r, g = g, b = b, a = a }
end

local function Padding(top, right, bottom, left)
  return { top = top, right = right, bottom = bottom, left = left }
end

local function Component()
  local c = { cornerRadius = 0, padding = Padding(0, 0, 0, 0), fillColor = Color(0, 0, 0, 0) }

  function c:WithPadding(padding)
    self.padding = padding

    return self
  end

  function c:WithCornerRadius(cornerRadius)
    self.cornerRadius = cornerRadius

    return self
  end

  function c:WithFillColor(fillColor)
    self.fillColor = fillColor
    return self
  end

  function c:ToContainer()
    return __HASHELQ_HIDDEN_SECRETS_Container(self)
  end

  function c:ToSpace()
    return __HASHELQ_HIDDEN_SECRETS_Space(self)
  end

  function c:ToText()
    return __HASHELQ_HIDDEN_SECRETS_Text(self)
  end

  function c:GetSize()
    return { width = 0, height = 0 }
  end

  function c:Render(ctx, x, y, mW, mH)
    local size = c:GetSize()
    local w = size.width
    local h = size.height

    if w > mW or h > mH then
      return nil
    end

    local padding = c.padding
    ctx:FillRoundedRect(self.cornerRadius, x, y, w, h, self.fillColor)
  end

  return c
end

local function Text(component)
  if component == nil then
    component = Component()
  end

  component.type = "text"

  component.text = text
  component.font = ""
  component.textColor = Color(0, 0, 0, 255)

  function component:ApplyText()
    surface.SetFont(self.font)
    local Width, Height = surface.GetTextSize(self.text)
    local padding = self.padding
    local size = { width = Width + padding.left + padding.right, height = Height + padding.top + padding.bottom }

    self.size = size

    return self
  end

  function component:WithContent(text)
    self.text = text
    return self
  end

  function component:WithFont(font)
    self.font = font
    return self
  end

  function component:WithTextColor(textColor)
    self.textColor = textColor

    return self
  end

  function component:GetSize()
    return self.size
  end

  local Render = component.Render
  function component:Render(ctx, x, y, mW, mH)
    Render(component, ctx, x, y, mW, mH)

    local padding = component.padding
    ctx:FillText(self.text, self.font, x + padding.left, y + padding.top, self.textColor)
  end

  return component
end

local function Space(component)
  if component == nil then
    component = Component()
  end

  component.type = space
  component.size = { width = 0, height = 0 }
  component.material = nil
  component.materialColor = Color(255, 255, 255, 255)

  function component:WithMaterial(material)
    self.material = material

    return self
  end

  function component:WithMaterialColor(materialColor)
    self.materialColor = materialColor

    return self
  end

  function component:WithSize(size)
    self.size = size

    return self
  end

  function component:GetSize()
    local sz = self.size
    local pad = self.padding
    local r = { width = sz.width + pad.left + pad.right, height = sz.height + pad.top + pad.bottom }

    return r
  end

  local Render = component.Render
  function component:Render(ctx, x, y, w, h)
    Render(component, ctx, x, y, w, h)

    if self.material then
      local padding = self.padding
      local size = self.size
 
      ctx:FillTexturedRect(self.material, self.materialColor, x + padding.left, y + padding.top, size.width, size.height)
    end
  end

  return component
end

local function Container(component)
  if gap == nil then
    gap = 0
  end

  if component == nil then
    component = Component()
  end

  component.type = "container"
  component.cachedSize = nil

  function component:WithElements(elements)
    self.elements = elements

    return self
  end

  function component:WithDirection(direction)
    self.direction = direction

    return self
  end

  function component:WithGap(gap)
    self.gap = gap

    return self
  end

  function component:Reverse()
    self.reversed = not self.reversed

    return self
  end

  component.gap = 0
  component.direction = direction.HORIZONTAL
  component.reversed = false
  component.elements = {}

  local Render = component.Render

  function component:Recalc()
    self.cachedSize = nil

    self:GetSize()

    for _, v in pairs(component.elements) do
      local f = v.Recalc

      if f ~= nil then
        f(v)
      end
    end
  end

  function component:GetSize()
    if self.cachedSize ~= nil then
      return self.cachedSize
    end

    local base = 0
    local max = 0
    local gap = self.gap

    for _, v in pairs(component.elements) do
      local size = v:GetSize(w, h)

      if size ~= nil then
        if component.direction == direction.HORIZONTAL then
          if size.height > max then max = size.height end
          base = base + size.width + gap
        else
          if size.width > max then max = size.width end
          base = base + size.height + gap
        end
      end
    end

    if #self.elements then
      base = base - gap
    end

    local result

    if component.direction == direction.HORIZONTAL then
      result = { width = base, height = max }
    else
      result = { width = max, height = base }
    end

    self.cachedSize = result

    return result
  end

  function component:Render(ctx, sx, sy, mW, mH)
    local rW = component.padding.left + component.padding.right
    local rH = component.padding.top + component.padding.bottom
    local gap = component.gap

    local x = 0
    local y = 0

    if self.reversed then
      local size = self:GetSize()

      if self.direction == direction.HORIZONTAL then
        Render(component, ctx, sx - rW + mW - size.width, sy, mW, mH)
      else
        Render(component, ctx, sx, sy - rH + mH - size.height, mW, mH)
      end
    else
      Render(component, ctx, sx, sy, mW, mH)
    end

    local w, h = mW, mH 

    for _, v in pairs(component.elements) do
      local size = v:GetSize(w, h) 

      if size ~= nil then
        preX = x
        preY = y

        if component.direction == direction.HORIZONTAL then
          if size.width > w - rW then break end
          w = w - size.width
          x = x + size.width + gap
        else
          if size.height > h - rH then break end
          h = h - size.height
          y = y + size.height + gap
        end

        if self.reversed then
          if self.direction == direction.HORIZONTAL then
            v:Render(ctx, sx + mW - rW - x + gap + component.padding.left, sy + preY + component.padding.right, size.width, size.height)
          else

            v:Render(ctx, sx + preX + component.padding.left, sy + mH - rH - y + gap + component.padding.right, size.width, size.height)
          end
        else
          v:Render(ctx, sx + preX + component.padding.left, sy + preY + component.padding.right, size.width, size.height)
        end
      end
    end
  end

  return component
end

__HASHELQ_HIDDEN_SECRETS_Container = Container
__HASHELQ_HIDDEN_SECRETS_Space = Space
__HASHELQ_HIDDEN_SECRETS_Text = Text

return {
  Direction = direction,
  Color = Color,
  Padding = Padding,
  Component = Component,
  Container = Container,
  Text = Text,
  Space = Space
}
