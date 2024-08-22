
-- datetime
-- a mock version of robloxs datetime for lune
-- because robloxs uses pascal case and lune uses camel case

local datetime = require("@lune/datetime")

type RbxDateTimePrototype = {
	FormatUniversalTime: (self: RbxDateTime, format: string, locale: string) -> string,
	FormatLocalTime: (self: RbxDateTime, format: string, locale: string) -> string,
	ToUniversalTime: (self: RbxDateTime) -> { any },
	ToLocalTime: (self: RbxDateTime) -> { any },
	ToIsoDate: (self: RbxDateTime) -> string,
	__index: RbxDateTimePrototype,
}

type RbxDateTime = typeof(setmetatable({} :: {
	UnixTimestampMillis: number,
	UnixTimestamp: number,
	dt: datetime.DateTime,
}, {} :: RbxDateTimePrototype))

local rbx_datetime = {} :: RbxDateTimePrototype
rbx_datetime.__index = rbx_datetime

function rbx_datetime.FormatUniversalTime(self, format, locale)
	return self.dt:formatUniversalTime(format, locale :: any)
end

function rbx_datetime.FormatLocalTime(self, format, locale)
	return self.dt:formatLocalTime(format, locale :: any)
end

function rbx_datetime.ToUniversalTime(self)
	return self.dt:toLocalTime()
end

function rbx_datetime.ToLocalTime(self)
	return self.dt:toLocalTime()
end

function rbx_datetime.ToIsoDate(self)
	return self.dt:toIsoDate()
end

local rbx_datetime_module = {}

function rbx_datetime_module.FromUniversalTime(values: { [any]: any }): RbxDateTime
	local dt = datetime.fromUniversalTime(values)

	return table.freeze(setmetatable({
		UnixTimestampMillis = dt.unixTimestampMillis,
		UnixTimestamp = dt.unixTimestamp,
		dt = dt,
	}, rbx_datetime))
end

function rbx_datetime_module.FromLocalTime(values: { [any]: any }): RbxDateTime
	local dt = datetime.fromLocalTime(values)

	return table.freeze(setmetatable({
		UnixTimestampMillis = dt.unixTimestampMillis,
		UnixTimestamp = dt.unixTimestamp,
		dt = dt,
	}, rbx_datetime))
end

function rbx_datetime_module.FromUnixTimestamp(timestamp: number): RbxDateTime
	local dt = datetime.fromUnixTimestamp(timestamp)

	return table.freeze(setmetatable({
		UnixTimestampMillis = dt.unixTimestampMillis,
		UnixTimestamp = dt.unixTimestamp,
		dt = dt,
	}, rbx_datetime))
end

function rbx_datetime_module.now(): RbxDateTime
	local dt = datetime.now()

	return table.freeze(setmetatable({
		UnixTimestampMillis = dt.unixTimestampMillis,
		UnixTimestamp = dt.unixTimestamp,
		dt = dt,
	}, rbx_datetime))
end

function rbx_datetime_module.FromIsoDate(iso: string): RbxDateTime
	local dt = datetime.fromIsoDate(iso)

	return table.freeze(setmetatable({
		UnixTimestampMillis = dt.unixTimestampMillis,
		UnixTimestamp = dt.unixTimestamp,
		dt = dt,
	}, rbx_datetime))
end

table.freeze(rbx_datetime)
return table.freeze(rbx_datetime_module)