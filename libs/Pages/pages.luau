--!optimize 2

-- pagesutil
-- utility for dealing with roblox page instancs easily
-- @kalrnlo
-- 19/06/2024

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

			for item_index, item in pages:GetCurrentPage() do
				page_info.item_index += 1
				local result = f(page_info, item)
	
				if result == "break" then
					return
				end
			end
		until pages.IsFinished
	end
end

local function toarray(pages: Pages): { { { [any]: any } } }
	local contents = { pages:GetCurrentPage() }

	if not pages.IsFinished then
		repeat
			pages:AdvanceToNextPageAsync()
			table.insert(contents, pages:GetCurrentPage())
		until pages.IsFinished
	end
	return contents
end

local exports = table.freeze {
	toarray = toarray,
	iter = iter,
}

return exports
