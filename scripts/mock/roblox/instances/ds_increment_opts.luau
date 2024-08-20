
-- ds_increment_opts
-- implements a mock datastore increment options instance for lune

local serde = require("@lune/serde")
local impl = require("../impl")

return impl("DataStoreIncrementOptions")
	:rprop("Metadata", "")
	:method("SetMetadata", function(instance, new_metadata)
		impl.set_rprop(
			"DataStoreIncrementOptions",
			instance,
			"Metadata",
			serde.encode("json", new_metadata)
		)
	end)
	:method("GetMetadata", function(instance)
		return serde.decode("json", instance.Metadata)
	end)
