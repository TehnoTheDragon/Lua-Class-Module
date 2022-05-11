local function _create_tostring(value)
    return function() return value end
end

local function _create_class_metatable(self, class_name, call)
    return setmetatable(self, {
        __index = function (self, index)
            return rawget(self, index) or rawget(self.super, index)
        end,
        __name = class_name,
        __type = "class",
        __tostring = _create_tostring(class_name),
        __call = call or function() end
    })
end

local function _create_object_metatable(self, object_name, class)
    return setmetatable(self, {
        __index = function (self, index)
            return rawget(class, index) or rawget(class.super, index) or rawget(self, index)
        end,
        __name = object_name,
        __type = "object",
        __tostring = _create_tostring(object_name),
    })
end

local _class = _create_class_metatable({}, "class")

function _class.new(class_name, extend_class)
    local _new_class = {}
    _new_class.super = extend_class or {}

    _new_class = _create_class_metatable(_new_class, class_name, function (self, ...)
        local _new_object = _create_object_metatable({}, class_name, _new_class)
        _new_object:_init(...)
        return _new_object
    end)

    return _new_class
end

return _class