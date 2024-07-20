--!native

-- linked list
-- a doubly-linked list impl in luau, easily inserts and deletes arbitrarily without reordering. 
-- a reference to the entry to insert or delete at is required. References to the front and back of
-- the list always exist.
-- originally made by last talon, uh heavily modified by me (kalrnlo) because im a nitpicker
-- w a changed up api to directly expose the nodes and also not create a new closure
-- for every node created
-- og: https://github.com/LastTalon/linked-list

type NodePrototype<V> = {
	__call: (self: Node<V>) -> V,
}

export type Node<V> = typeof(setmetatable({} :: {
	next: Node<V>?,
	prev: Node<V>?,
	value: V,
}, {} :: NodePrototype<V>))

type LinkedListPrototype<V> = {
	reverse_iter: (self: LinkedList<V>) -> () -> (number, Node<V>),
	iter: (self: LinkedList<V>) -> () -> (number, Node<V>),
	unshift: (self: LinkedList<V>, value: V) -> Node<V>,
	remove: (self: LinkedList<V>, node: Node<V>) -> V,
	push: (self: LinkedList<V>, value: V) -> Node<V>,
	shift: (self: LinkedList<V>) -> Node<V>?,
	pop: (self: LinkedList<V>) -> Node<V>?,
	clear: (self: LinkedList<V>) -> (),

	__iter: (self: LinkedList<V>) -> () -> (number, Node<V>),
	__len: (self: LinkedList<V>) -> number,
	__index: LinkedListPrototype<V>
}

export type LinkedList<V> = typeof(setmetatable({} :: {
	front: Node<V>?,
	back: Node<V>?,
	len: number,
}, {} :: LinkedListPrototype<V>))

local function remove_node<V>(list: LinkedList<V>, node: Node<V>): V
	local prev_node = node.prev
	local next_node = node.next

	if prev_node then
		prev_node.next = next_node
	else
		list.front = next_node
	end

	if next_node then
		next_node.prev = prev_node
	else
		list.back = prev_node
	end
	list.len -= 1
	return node.value
end

local node_mt = {
	__call = function<V>(node: Node<V>): V
		return node.value
	end,
}
node_mt.__index = node_mt
table.freeze(node_mt)

local function create_node<V>(value: V): Node<V>
	return setmetatable({
		value = value,
		next = nil,
		prev = nil
	}, node_mt)
end

local linkedlist = {} :: LinkedListPrototype<any>
(linkedlist :: any).__index = linkedlist

function linkedlist.push(list, value)
	local node = create_node(value)
	local back = list.back

	node.prev = back

	if back then
		back.next = node
	else
		list.front = node
	end
	list.back = node
	list.len += 1

	return node
end

function linkedlist.unshift(list, value)
	local node = create_node(value)
	local front = list.front

	node.next = front

	if front then
		front.prev = node
	else
		list.back = node
	end
	list.front = node

	return node
end

function linkedlist.shift(list)
	local node = list.front

	if node then
		remove_node(list, node)
		return node
	else
		return nil
	end
end

function linkedlist.pop(list)
	local node = list.back

	if node then
		remove_node(list, node)
		return node
	else
		return nil
	end
end

function linkedlist.iter(list)
	local node = list.front
	local index = 0

	return function()
		if not node then
			return nil :: any, nil :: any
		end

		local current_node = node
		node = node.next
		index += 1
		return index, current_node
	end
end

function linkedlist.reverse_iter(list)
	local node = list.back
	local index = list.len + 1

	return function()
		if not node then
			return nil :: any, nil :: any
		end

		local current = node
		node = node.prev
		index -= 1
		return index, current
	end
end

function linkedlist.clear(list)
	list.front = nil
	list.back = nil
	list.len = 0
end

function linkedlist.__len(list)
	return list.len
end

linkedlist.__iter = linkedlist.iter
table.freeze(linkedlist)

@checked
local function create<V>(): LinkedList<V>
	return setmetatable({
		front = nil,
		back = nil,
		len = 0,
	}, linkedlist)
end

return create
