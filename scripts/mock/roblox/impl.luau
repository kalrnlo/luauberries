
-- impl
-- a wrapper for easily implementing properties and methods
-- in lune to mock roblox stuffs

local roblox = require("@lune/roblox")

type GenericInstance<I> = roblox.Instance & I

type PropertySetter<I, P> = (instance: GenericInstance<I>, new_value: unknown) -> P

type ImplPrototype<I> = {
	rwprop: (<P>(self: Impl<I>, name: string, setter: PropertySetter<I, P>, default: P) -> Impl<I>) &
		(<P>(self: Impl<I>, name: string, default: P) -> Impl<I>),
	rprop: <P>(self: Impl<I>, name: string, default: P) -> Impl<I>,
	method: <A..., R...>(self: Impl<I>, name: string, f: (instance: GenericInstance<I>, A...) -> R...) -> Impl<I>,
	__index: ImplPrototype<I>,
}

export type Impl<I> = typeof(setmetatable({} :: {
	propstores: { [string]: { [GenericInstance<I>]: any } },
	name: string,
}, {} :: ImplPrototype<I>))

local CANNOT_SET_ERR_FORMAT = "[IMPL] cannot set property \"%s\" on class \"%s\" to a value that isn't of type \"%s?\""
local CLASSES_IMPLEMENTED = {} :: { [string]: boolean }

local function rwprop<I, P, D>(
	impl: Impl<I>,
	propname: string,
	default_or_setter: P | PropertySetter<I, P>,
	default: P
): Impl<I>
	local propstores = impl.propstores
	local classname = impl.name
	local propstore = {}

	propstores[propname] = propstore

	if type(default_or_setter) == "function" and default then
		roblox.implementProperty(
			classname, 
			propname,
			function(instance: any)
				local value = propstore[instance]

				if value then
					return value
				else
					propstore[instance] = default
					return default
				end
			end,
			function(instance: any, new_value)
				local new_value = default_or_setter(instance, new_value)
				propstore[instance] = new_value
			end
		)
	else
		local type = typeof(default_or_setter)
		local cannot_set_err = string.format(
			CANNOT_SET_ERR_FORMAT, propname, 
			classname, type
		)

		roblox.implementProperty(
			classname, 
			propname,
			function(instance: any)
				local value = propstore[instance]

				if value then
					return value
				else
					propstore[instance] = default_or_setter
					return default_or_setter
				end
			end,
			function(instance: any, new_value)
				if typeof(new_value) == type then
					propstore[instance] = new_value
				elseif new_value == nil then
					propstore[instance] = nil
				else
					error(cannot_set_err)
				end
			end
		)
	end
	return impl
end

local function rprop<I, P, D>(
	impl: Impl<I>,
	propname: string,
	default: P
): Impl<I>
	local propstores = impl.propstores
	local classname = impl.name
	local propstore = {}
	
	propstores[propname] = propstore

	roblox.implementProperty(
		classname, 
		propname,
		function(instance: any)
			local value = propstore[instance]

			if value then
				return value
			else
				propstore[instance] = default
				return default
			end
		end
	)
	return impl
end

local function method<I, P, A..., R...>(
	impl: Impl<I>, 
	method_name: string, 
	f: (instance: GenericInstance<I>, A...) -> R...
): Impl<I>
	roblox.implementMethod(impl.name, method_name, f :: any)
	return impl
end

local impl = {
	method = method,
	rwprop = rwprop,
	rprop = rprop,
}
impl.__index = impl
table.freeze(impl)

local function create<I>(name: string): Impl<I>
	if CLASSES_IMPLEMENTED[name] then
		error(`[IMPL] class "{name}" has already been implemented`)
	end
	CLASSES_IMPLEMENTED[name] = true

	return table.freeze(setmetatable({
		propstores = {},
		name = name,
	}, impl :: any))
end

return create
