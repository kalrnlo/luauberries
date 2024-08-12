
-- libinfo
-- utility func for reading LIBINFO.json files
-- and providing types for LIBINFOs

local serde = require("@lune/serde")
local fs = require("@lune/fs")

type LibInfo = {
	topics: { string },
	version: string,
}

local function libinfo(lib: string): LibInfo
	return serde.decode("json", fs.readFile(`libs/{lib}/LIBINFO.json`))
end

return libinfo