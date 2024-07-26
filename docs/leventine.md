# Leventine

A fast levenstein distance library for luau, based on [fastest-levenstein](https://github.com/ka-weihe/fastest-levenshtein) and [fzy-lua](https://github.com/swarn/fzy-lua)

```luau
local leventine = require("leventine")
local list = { "meow", "mrrp", "mrrow", ":3" }
local closest_list = leventine.map("mrow", list)

print(table.concat(closest_list, ", ")) -- "meow", "mrrow", "mrrp", ":3"
```

## Types

### `MapInfo`

```luau
type MapInfo = {
	case_sensitive: boolean?,
	min_score: number?,
}
```
* `case_sensitive` - if not true, every string will be lowered before being mapped
* `min_score` - the minimum score for a string in the list to be included in the mapped list (defualt: 0)

## Methods


### `score`

Gets the distance between 2 strings, includes a optional `case_sensitive` arg that is false by defualt

```luau
local score = leventine.score("meow", "mrrp")
print(score) -- 4
```

### `closest`

Gets the closest string to `str` from `t` and returns the closest string and closest distance, includes a optional `case_sensitive` arg that is false by defualt

```luau
local list = { "meow", "mrrp", "mrrow", ":3" }
local closest, closest_score = leventine.closest("mrow", list)

print(closest, closest_score) -- "meow", 3
```

### `map`

Returns a mapped version of `t` thats sorted based on how close each string in `t` is to `str`,
has an optional arg for providing a [`MapInfo`](#mapinfo) struct

```luau
local list = { "meow", "mrrp", "mrrow", ":3" }
local closest_list = leventine.map("mrow", list)

print(table.concat(closest_list, ", ")) -- "meow", "mrrow", "mrrp", ":3"
```

### `has_match`

Finds an exact match of `match_aginst` in `str`, includes a optional `case_sensitive` arg that is false by defualt

```luau
local matches = leventine.has_match("meow", "mrrp")
print(matches) -- false
```