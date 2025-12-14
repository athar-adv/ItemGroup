--!strict

export type Disconnect = () -> ()

local __extend
local __children
type ItemGroup<T = any> = {
	add: (ItemGroup<T>, T) -> Disconnect,
	add_many: (ItemGroup<T>, {T}) -> Disconnect,
	free: (ItemGroup<T>) -> (),
	extend: typeof(__extend),
	
	items: {T},
	cleanup_handler: (T) -> (),
	children: typeof(__children)
}

export type Self<T = any> = ItemGroup<T>

__children = {(nil::any)::ItemGroup}
function __extend<T>(self: any, new_cleanup_handler: (T) -> (), items: {T}?): ItemGroup<T> return nil::any end

local index = {}::ItemGroup
(index::any).__index = index

local function create<T>(cleanup_handler: (T) -> (), items: {T}?): ItemGroup<T>
	local items: {T} = if items ~= nil then table.clone(items) else {}
	
	return setmetatable({
		items = items,
		children = {},
		cleanup_handler = cleanup_handler,
	}, index)::any
end

function index:add(item)
	local items = self.items
	table.insert(items, item)
	
	return function()
		local idx = table.find(items, item)
		if idx then table.remove(items, idx) end
	end
end

function index:add_many(src)
	local items = self.items
	
	table.move(src, 1, #src, #items + 1, items)
	local clone = table.clone(src)
	return function()
		for _, item in clone do
			local idx = table.find(items, item)
			if idx then table.remove(items, idx) end
		end
	end
end

function index:free()
	local items = self.items
	local cleanup_handler = self.cleanup_handler
	local children = self.children
	
	for _, item in items do
		cleanup_handler(item)
	end
	table.clear(items)
	
	for _, child: any in children do
		child:free()
	end
end

function index:extend<A>(new_cleanup_handler: any)
	local new = create(new_cleanup_handler)
	table.insert(self.children, new)
	return new
end

return {
	create = create,
	cleanup = {
		disconnect = function(c: RBXScriptConnection)
			c:Disconnect()
		end,
		destroy = game.Destroy,
		call = function(f: () -> ())
			f()
		end,
	}
}