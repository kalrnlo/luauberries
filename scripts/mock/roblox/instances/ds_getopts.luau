
-- ds_getopts
-- implements a mock datastore get options instance for lune

local impl = require("../impl")

return impl("DataStoreGetOptions")
	:rwprop("UseCache", true)