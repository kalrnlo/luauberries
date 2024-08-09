
-- ansi
-- module for adding ansi colors around strings

local ansi = {}

function ansi.boldred(str: string): string
	return `\27[1;31m{str}\27[0m`
end

return table.freeze(ansi)