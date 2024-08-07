
-- types
-- a seperate file for all the types because god knows theres way too many

export type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

export type TransformerCallback<Value, A...> = (value: Value, A...) -> (Value?)

export type Operation<Value = JSONAcceptable> = {
	callback: TransformerCallback<Value, ...any>,
	thread_to_resume: thread?,
	args: { any }?,
}

export type GlobalUpdateInfo = {
	userids_changed: boolean?,
	value_changed: boolean?,
}

export type SaveInfo = {
	global_update_info: GlobalUpdateInfo?,
	is_locked: boolean,
	lock_uuid: string,
	timestamp: number,
	version: number,
}

export type KeyInfo<Value = JSONAcceptable> = ({
	callbacks: {
		on_close: { KeyLifecycleCallbackInfo<Value> },
		on_save: { KeyLifecycleCallbackInfo<Value> },
	},
	threads_to_spawn_after_save: { thread },
	update_queue: { Operation<Value> },
	userids: { number },
	saveinfo: SaveInfo,
	is_saving: boolean,
	modified: boolean,
	last_save: number,
	value: Value,
})

export type ValueInfo<Value = JSONAcceptable> = {
	default_value_getter: nil,
	default_value: Value,
} | {
	default_value_getter: (key: string) -> Value,
	default_value: nil,
}

export type ChestInfo<Value = JSONAcceptable> = ValueInfo<Value> & {
	time_between_attempts: number?,
	min_save_interval: number?,
	retry_exponent: number?,
	save_interval: number?,
	max_attempts: number?,
}

export type VersionInfo<
	Value = JSONAcceptable,
	Migrate = nil
> = ValueInfo<Value> & {
	-- TODO: type out the migrate function
	previous_version: string?,
	migrate: Migrate,
}

export type RawUpdateAsyncCallback<Value, A...> = (
	global_value: Value,
	global_saveinfo: SaveInfo,
	global_userids: {number}?,
	A...
) -> (Value?, SaveInfo?, { number }?)

export type MigrationCallback<
	Value = JSONAcceptable, 
	PreviousValue = JSONAcceptable
> = (prev_value: PreviousValue) -> Value

export type KeyLifecycleCallback<Value = JSONAcceptable> = (value: Value) -> ()
export type KeyLifecycleCallbackInfo<Value = JSONAcceptable> = { KeyLifecycleCallback<Value> }

export type ChestLifecycleCallback<Value = JSONAcceptable, Migrate = nil> = (gem: Gem<Value, Migrate>) -> ()
export type ChestLifecycleCallbackInfo<Value = JSONAcceptable, Migrate = nil> = { ChestLifecycleCallback<Value, Migrate> }

export type GemRevert<Gem> = ((self: Gem, time: number, auto_migrate: boolean?) -> (true, nil)) & 
	((self: Gem, time: number, auto_migrate: boolean?) -> (false, string))

export type GemDatastoreVersion<Gem, Value> = ((self: Gem, time: number) -> (true, Value)) & 
	((self: Gem, time: number) -> (false, string))

export type GemResultFunc<Gem = any, Result = nil> = ((self: Gem) -> (true, Result)) &
	((self: Gem) -> (false, string))

export type BaseGemPrototype<Value = JSONAcceptable, Migrate = nil> = {
	datastore_version: GemDatastoreVersion<BaseGem<Value, Migrate>, Value>,
	revert: GemRevert<BaseGem<Value, Migrate>>,
}

export type BaseGem<Value = JSONAcceptable, Migrate = nil> = typeof(setmetatable({} :: {
	chest: Chest<Value, Migrate>,
	version: string,
	global: boolean,
	name: string,
}, {} :: BaseGemPrototype<Value, Migrate>))

export type GlobalGemPrototype<Value = JSONAcceptable, Migrate = nil> = {
	transform_async: <A...>(self: GlobalGem<Value, Migrate>, transform: TransformerCallback<Value, A...>, A...) -> boolean,
	detach_user: ((self: GlobalGem<Value, Migrate>, id: number) -> (true, nil)) & 
		((self: GlobalGem<Value, Migrate>, id: number) -> (false, string)),
	attach_user: ((self: GlobalGem<Value, Migrate>, id: number) -> (true, nil)) &
		((self: GlobalGem<Value, Migrate>, id: number) -> (false, string)),
	datastore_version: GemDatastoreVersion<GlobalGem<Value, Migrate>, Value>,
	users: GemResultFunc<GlobalGem<Value, Migrate>, { number }>,
	value: GemResultFunc<GlobalGem<Value, Migrate>, Value>,
	revert: GemRevert<GlobalGem<Value, Migrate>>,
	__index: GlobalGemPrototype<Value, Migrate>,
}

export type GlobalGem<Value = JSONAcceptable, Migrate = nil> = typeof(setmetatable({} :: {
	chest: Chest<Value, Migrate>,
	version: number,
	name: string,
}, {} :: GlobalGemPrototype<Value, Migrate>))

export type GemPrototype<Value = JSONAcceptable, Migrate = nil> = {
	transform: <A...>(self: Gem<Value, Migrate>, transform: TransformerCallback<Value, A...>, A...) -> Gem<Value, Migrate>,
	on_close: (self: Gem<Value, Migrate>, f: KeyLifecycleCallback<Value>) -> () -> (),
	on_save: (self: Gem<Value, Migrate>, f: KeyLifecycleCallback<Value>) -> () -> (),
	detach_user: (self: Gem<Value, Migrate>, id: number) -> Gem<Value, Migrate>,
	attach_user: (self: Gem<Value, Migrate>, id: number) -> Gem<Value, Migrate>,
	datastore_version: GemDatastoreVersion<Gem<Value, Migrate>, Value>,
	users: (self: Gem<Value, Migrate>) -> { number },
	save: GemResultFunc<Gem<Value, Migrate>, nil>,
	value: (self: Gem<Value, Migrate>) -> Value,
	revert: GemRevert<Gem<Value, Migrate>>,
	__index: GemPrototype<Value, Migrate>,
}

export type Gem<Value = JSONAcceptable, Migrate = nil> = typeof(setmetatable({} :: {
	chest: Chest<Value, Migrate>,
	version: number,
	name: string,
}, {} :: GemPrototype<Value, Migrate>))

export type LoadStatus = "DATASTORE ERROR" | "MIGRATION ERROR" | "LOCKED" | "SAVE VERSION TOO HIGH" | 
	"MIGRATION NEXT VERSION NOT FOUND" | "MIGRATION CALLBACK ERROR" | "SUCCESS" | "TRANSFORM CALLBACK ERROR"

export type ChestLoad<Chest, Gem> = ((self: Chest, key: string) -> (LoadStatus, Gem)) &
	((self: Chest, key: string) -> (LoadStatus, string))

export type ChestPrototype<Value = JSONAcceptable, Migrate = nil> = {
	-- need recurive changing generics to type add_version right,,
	add_version: <Version, NewValue>(self: Chest<Value, Migrate>, version: Version & string, info: VersionInfo) -> Chest<Value, Migrate>,
	lock: ((self: Chest<Value, Migrate>, global_gem: GlobalGem<Value, Migrate>) -> (true, Gem<Value, Migrate>)) &
		((self: Chest<Value, Migrate>, global_gem: GlobalGem<Value, Migrate>) -> (false, string)),
	view: ((self: Chest<Value, Migrate>, key: string) -> (true, Value, { number }?)) &
		((self: Chest<Value, Migrate>, key: string) -> (false, string, nil, nil)),
	load: ChestLoad<Chest<Value, Migrate>, GlobalGem<Value, Migrate>>,
	locknload: ChestLoad<Chest<Value, Migrate>, Gem<Value, Migrate>>,
	steal: ChestLoad<Chest<Value, Migrate>, Gem<Value, Migrate>>,
	-- TODO: type out the iter_keys callback
	iter_keys: ((self: Chest<Value, Migrate>, f: any) -> (true, nil)) & 
		((self: Chest<Value, Migrate>, f: any) -> (false, string)),

	on_close: (self: Chest<Value, Migrate>, f: ChestLifecycleCallback<Value, Migrate>) -> () -> (),
	on_save: (self: Chest<Value, Migrate>, f: ChestLifecycleCallback<Value, Migrate>) -> () -> (),
	remove: (self: Chest<Value, Migrate>, gem_or_key: Gem<Value, Migrate> | GlobalGem<Value, Migrate> | string) -> (),
	unload: (self: Chest<Value, Migrate>, gem: Gem<Value, Migrate>) -> (),
	__index: ChestPrototype<Value, Migrate>,
}

export type Chest<Value = JSONAcceptable, Migrate = nil> = typeof(setmetatable({} :: {
	global_gems: { [string]: GlobalGem<Value, Migrate> },
	local_keys: { [string]: KeyInfo<Value> },
	default_value_getter: ((key: string) -> Value)?,
	callbacks: {
		on_close: { ChestLifecycleCallbackInfo<Value, Migrate> },
		on_save: { ChestLifecycleCallbackInfo<Value, Migrate> },
	},
	migrations: {
		-- [VERSION]: migration function
		[number]: MigrationCallback
	},
	time_between_attempts: number,
	min_save_interval: number,
	retry_exponent: number,
	save_interval: number,
	default_value: Value?,
	datastore: DataStore,
	max_attempts: number,
	version: number,
	scope: string,
	name: string,
}, {} :: ChestPrototype<Value, Migrate>))

return nil