/// <reference types="@rbxts/types" />
/// <reference types="@rbxts/compiler-types" />
/**
 * # Grouper
 *
 * Used for getting the latest group rank or role of a player on the server.
 */
declare namespace grouper {
	type FireRankChanged = (send_to_player: Player, player_whose_rank_changed: Player, rank: number, role: string) => void;
	type FireAllRankChanged = (player_whose_rank_changed: Player, rank: number, role: string) => void;
	type ReplicateRankUpdateCallback = (player: Player, rank: number, role: string) => void;
	type RankChangedCallback = (player: Player, new_rank: number, old_rank: number) => void;
	export type ClientConfig = {
		connect_rank_changed: (callback: ReplicateRankUpdateCallback) -> void
	};
	export type ServerConfig = {
		fire_all_rank_changed: undefined;
		fire_rank_changed: undefined;
		rank_refresh_rate?: number;
		groupid: number;
	} | {
		fire_all_rank_changed: FireAllRankChanged;
		fire_rank_changed: FireRankChanged;
		rank_refresh_rate?: number;
		groupid: number;
	};
	
    export function get_rank_and_role(player: Player): LuaTuple<[number, string]>;
	export function on_rank_changed(callback: RankChangedCallback): () => void;
    export function is_in_group(player: Player): boolean;
	export function rank(player: Player): number;
    export function role(player: Player): string;
	export namespace init {
		export function client(conifg: ClientConfig): void;
		export function server(conifg: ServerConfig): void;
	};
    export {};
}
export = grouper;
