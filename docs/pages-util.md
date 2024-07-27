# Pages Util

Utility for dealing with roblox [`pages`](https://create.roblox.com/docs/reference/engine/classes/Pages) instances easily

```luau
local AvatarEditorService = game:GetService("AvatarEditorService")
local pagesutil = require("pages")

local params = CatalogSearchParams.new()
parms.AssetTypes = { Enum.AvatarAssetType.Hat }
params.SearchKeyword = "meow"

local pages = AvatarEditorService:SearchCatalog(params)

if success then
	local kitty_item

	pagesutil.iter(pages, function(_, asset_info)
		if 
			string.find(asset_info.Name, ":3",  1, true) or 
			string.find(asset_info.Description, ":3", 1, true)
		then
			kitty_item = asset_info
			return "break"
		end
		-- this has to be here, otherwise a type error occurs
		return
	end)
end

```

## Methods

### `iter`

Iterates through the [`pages`](https://create.roblox.com/docs/reference/engine/classes/Pages) instance until complete and calls the given callback for each entry.
`iter` will also stop iterating if the callback returns "break"

```luau
local AvatarEditorService = game:GetService("AvatarEditorService")

local params = CatalogSearchParams.new()
parms.AssetTypes = { Enum.AvatarAssetType.Hat }
params.SearchKeyword = "mrrp"

local pages = AvatarEditorService:SearchCatalog(params)

pagesutil.iter(pages, function(page_info, asset_info)
	local name = asset_info.Name

	if string.find(name, ":3",  1, true) then
		print(`{name} on page {page_info.page} at index {page_info.item_index}, is such a :3 item!!`)
	end
	return
end)
```

### `toarray`

Converts the [`pages`](https://create.roblox.com/docs/reference/engine/classes/Pages) instance into a flat array

```luau
local AvatarEditorService = game:GetService("AvatarEditorService")

local params = CatalogSearchParams.new()
parms.AssetTypes = { Enum.AvatarAssetType.Hat }
params.SearchKeyword = "miaow"

local pages = AvatarEditorService:SearchCatalog(params)

for _, asset_info in pagesutil.toarray(pages) do
	local name = asset_info.Name

	if string.find(name, "mrow",  1, true) then
		print(`{name} is such a :3 item!!`)
	end
end
```