
-- first release date
-- a datetime representing the first release of luauberries

local datetime = require("@lune/datetime")

return datetime.fromUniversalTime({
	year = 2024, day = 24, month = 6, 
	hour = 8, minute = 0, second = 0,
}).unixTimestamp