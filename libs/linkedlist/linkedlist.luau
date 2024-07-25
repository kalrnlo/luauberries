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


export type LinkedList<V> = {
	front: Node<V>?,
	back: Node<V>?,
	len: number,
}

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

local node_mt = table.freeze({
	__call = function<V>(node: Node<V>): V
		return node.value
	end,
})

local function create_node<V>(value: V): Node<V>
	return setmetatable({
		value = value,
		next = nil,
		prev = nil
	}, node_mt) :: any
end

local linkedlist = {
	remove = remove_node
}

function linkedlist.push<V>(list: LinkedList<V>, value)
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

function linkedlist.unshift<V>(list: LinkedList<V>, value: V): Node<V>
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

function linkedlist.shift<V>(list: LinkedList<V>): Node<V>?
	local node = list.front

	if node then
		remove_node(list, node)
		return node
	else
		return nil
	end
end

function linkedlist.pop<V>(list: LinkedList<V>): Node<V>?
	local node = list.back

	if node then
		remove_node(list, node)
		return node
	else
		return nil
	end
end

function linkedlist.iter<V>(list: LinkedList<V>): () -> (number, Node<V>)
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

function linkedlist.reverse_iter<V>(list: LinkedList<V>): () -> (number, Node<V>)
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

function linkedlist.clear<V>(list: LinkedList<V>)
	list.front = nil
	list.back = nil
	list.len = 0
end

local list_mt = {
	__call = function<S, V>(self: S): LinkedList<V>
		return {
			front = nil,
			back = nil,
			len = 0,
		}
	end
}

return table.freeze(setmetatable(linkedlist, table.freeze(list_mt)))