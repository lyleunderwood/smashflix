RNListView = {}



local function fieldChangedListener(self, key, value)

    getmetatable(self).__object[key] = value
    self = getmetatable(self).__object
end


local function fieldAccessListener(self, key)

    local object = getmetatable(self).__object

    return getmetatable(self).__object[key]
end



function RNListView:new(o)
    local tab = RNListView:innerNew(o)
    local proxy = setmetatable({}, { __newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab })
    return proxy, tab
end


function RNListView:innerNew(o)

    o = o or {
    }
    setmetatable(o, self)
    self.__index = self
    return o
end


function RNListView:setParentGroup()
    --mocked for group adding see RNGroup
  print("yo")
end

list = RNListView:new()

list:setParentGroup()
