local function _create_tostring(value)
    return function() return value end
end

local function _create_interface_metatable(self, interface_name, call)
    return setmetatable(self, {
        __index = function (self, index)
            return rawget(self, index) or rawget(self.super, index)
        end,
        __name = interface_name,
        __type = "interface",
        __tostring = _create_tostring(interface_name),
        __call = call or function() end
    })
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

local function _create_object_metatable(self, object_name, interface)
    return setmetatable(self, {
        __index = function (self, index)
            return rawget(interface, index) or rawget(interface.super, index) or rawget(self, index)
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

local _interface = _create_interface_metatable({}, "interface")
function _interface.new(interface_name)
    local _new_interface = {}
    _new_interface.super = {}
    _new_interface._virtuals = {}

    function _new_interface.virtual(field_name)
        table.insert(_new_interface._virtuals, field_name)
    end

    _new_interface = _create_interface_metatable(_new_interface, interface_name, function (self, object)
        local _new_object = _create_object_metatable({}, interface_name, _new_interface)

        local _is_all_implemented = true
        local _not_implemented = ""
        
        for _, field_name in ipairs(_new_interface._virtuals) do
            local value = object[field_name]

            if value == nil then
                _is_all_implemented = false
                _not_implemented = _not_implemented .. ("\t\"%s\" is not implemented.\n"):format(field_name)
            else
                if type(value) == "function" then
                    _new_object[field_name] = function (_, ...)
                        return value(object, ...)
                    end
                else
                    _new_object[field_name] = value
                end
            end
        end

        if not _is_all_implemented then
            error(("Not all virtual fields is implemented into class \"%s\".\n%s"):format(tostring(object), _not_implemented))
        end

        return _new_object
    end)

    return _new_interface
end

return {
    class = _class,
    interface = _interface
}