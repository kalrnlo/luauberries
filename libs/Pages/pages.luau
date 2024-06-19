--!optimize 2

-- pagesutil
-- utility for dealing with roblox page instancs easily
-- @kalrnlo
-- 04/06/2024

export type PagesArray<T> = { { T } }
export type PageInfo = {
	item_index: number,
	page_len: number,
	page: number,
}

local function iter(pages: Pages): () -> (PageInfo, any)
	local page = pages:GetCurrentPage()
	local page_len = #page
	local one_page_over = page_len + 1
	local item_index = 0
	local page_num = 1
	local page_info = {
		page_len = page_len,
		page = page_num,
		item_index = 1,
	}

	if page_len == 0 then
		-- makes the iterator not iterate at all
		return function() end :: any
	elseif page_len == 1 then
		return function()
			return page_info, page[1]
		end
	else
        -- its ok if this has the possibly of returning no values
        -- as thats good because then the loop wont run again when were done iterating
		return function()
            item_index += 1
			-- detecting if its one over, so we dont skip the last item
            local is_at_end_of_page = one_page_over == item_index

            if not (pages.IsFinished and is_at_end_of_page) then
			    if is_at_end_of_page then
				    pages:AdvanceToNextPageAsync()
				    page = pages:GetCurrentPage()
				    page_len = #page
					one_page_over = page_len + 1
				    item_index = 1
				    page_num += 1

				    page_info.page_len = page_len
				    page_info.page = page_num
			    end

			    page_info.item_index = item_index
			    return page_info, page[item_index]
            end
		end
	end
end

local function toarray(pages: Pages): { { any } }
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
