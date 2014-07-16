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

function split(str, pat)
 local t = {}  -- NOTE: use {n = 0} in Lua-5.0
 local fpat = "(.-)" .. pat
 local last_end = 1
 local s, e, cap = str:find(fpat, 1)
 while s do
   if s ~= 1 or cap ~= "" then
     table.insert(t,cap)
   end
   last_end = e+1
   s, e, cap = str:find(fpat, last_end)
 end
 if last_end <= #str then
   cap = str:sub(last_end)
   table.insert(t, cap)
 end
 return t
end

local function randInt(ceil)
  return round(math.random() * ceil)
end

return {
  roll = function(ceil)
    return randInt(ceil) == 0
  end,

  randInt = randInt,

  round = round,

  deepcopy = deepcopy,

  split = split,

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
  end,

  afterDelay = function(delay, cb)
    local timer = MOAITimer:new()
    timer:setSpan(delay)
    timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, cb)
    timer:start()

    return timer
  end
}