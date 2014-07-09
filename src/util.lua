local bit = require "bit"

local function round(num, idp)
  return tonumber(string.format("%."..(idp or 0).."f", num))
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return {
  roll = function(ceil)
    return round(math.random() * ceil) == 0
  end,

  round = round,

  deepcopy = deepcopy,

  bor = function(...)
    args = {...}
    local mask = 0

    for key, value in pairs(args) do
      mask = bit.bor(mask, value)
    end

    return mask
  end,

  getKBLayout = function()
    if MOAIEnvironment.OS_BRAND_LINUX then
      local dvorak = os.execute("setxkbmap -print | awk -F\"+\" '/xkb_symbols/ {print $2}' |grep dvorak")
      if dvorak == 0 then
        return "dvorak"
      else
        return "en"
      end
    else
      return "en"
    end
  end,

  nextTick = function(self, cb)
    MOAIThread:new():run(function()
      cb(self)
    end)
  end
}