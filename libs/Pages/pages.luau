--!optimize 2

-- pagesutil
-- utility for dealing with roblox page instancs easily
-- @kalrnlo
-- 23/06/2024

export type PagesArray<T> = { { T } }
export type PageInfo = {
	item_index: number,
	page_len: number,
	page: number,
}

local function iter(pages: Pages, f: (info: PageInfo, item: { [any]: any }) -> ("continue" | "break")?)
	local page = pages:GetCurrentPage()
	local page_info = {
		page_len = #page,
		item_index = 0,
		page = 1,
	}
	
	for item_index, item in page do
		page_info.item_index += 1
		local result = f(page_info, item)

		if result == "break" then
			return
		end
	end

	if not pages.IsFinished then
		repeat
			pages:AdvanceToNextPageAsync()

			local page = pages:GetCurrentPage()
			page_info.page_len = #page
			page_info.item_index = 0
			page_info.page += 1

			for item_index, item in page do
				page_info.item_index += 1
				local result = f(page_info, item)
	
				if result == "break" then
					return
				end
			end
		until pages.IsFinished
	end
end

local function toarray(self: unknown, pages: Pages): { { { [any]: any } } }
	local contents = { pages:GetCurrentPage() }

	if not pages.IsFinished then
		repeat
			pages:AdvanceToNextPageAsync()
			table.insert(contents, pages:GetCurrentPage())
		until pages.IsFinished
	end
	return contents
end

local function to_flat_array(pages: Pages): { { [any]: any } }
	local contents = pages:GetCurrentPage()

	if not pages.IsFinished then
		repeat
			pages:AdvanceToNextPageAsync()
			local current_page = pages:GetCurrentPage()
			table.move(current_page, 1, #current_page, #contents + 1, contents)
		until pages.IsFinished
	end
	return contents
end

local to_array_mt = {
	__call = toarray
}
to_array_mt.__index = to_array_mt

local exports = table.freeze {
	toarray = table.freeze(setmetatable({ flat = to_flat_array }, to_array_mt)),
	iter = iter,
} :: {
	toarray: typeof(setmetatable({ flat = to_flat_array }, { __call = toarray })),
	iter: typeof(iter)
}

return exports
