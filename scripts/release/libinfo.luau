
-- libinfo
-- utility func for reading LIBINFO.json files
-- and providing types for LIBINFOs

local serde = require("@lune/serde")
local fs = require("@lune/fs")

type LibInfo = {
	tags: { string },
	version: string,
	runtime: {
		optional: { string }?,
		main: string,
	}?
}

local function libinfo(lib: string): LibInfo
	return serde.decode("yaml", fs.readFile(`libs/{lib}/LIBRARY.yml`))
end

return libinfo