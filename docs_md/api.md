# ItemGroup API Reference

## Types

### `Disconnect`
```luau
export type Disconnect = () -> ()
```
A function type that represents a cleanup/disconnection callback. When called, it removes the associated item from the group.

### `ItemGroup<T>`
```luau
type ItemGroup<T = any> = {
	add: (ItemGroup<T>, T) -> Disconnect,
	add_many: (ItemGroup<T>, {T}) -> Disconnect,
	free: (ItemGroup<T>) -> (),
	extend: <A>(ItemGroup<T>, (A) -> (), {A}?) -> ItemGroup<A>,
	
	items: {T},
	cleanup_handler: (T) -> (),
	children: {ItemGroup<any>}
}
```
The main ItemGroup type that manages a collection of items with automatic cleanup.

**Type Parameters:**
- `T` - The type of items stored in the group (defaults to `any`)

**Fields:**
- `items: {T}` - The array of items currently in the group
- `cleanup_handler: (T) -> ()` - Function called on each item during cleanup
- `children: {ItemGroup}` - Child ItemGroups created via `extend()`

**Methods:**
- `add` - Adds a single item to the group
- `add_many` - Adds multiple items to the group
- `free` - Cleans up all items and children
- `extend` - Creates a child ItemGroup with a different cleanup handler

### `Self<T>`
```luau
export type Self<T = any> = ItemGroup<T>
```
Alias for `ItemGroup<T>`, useful for type annotations.

---

## Functions

### `create`
```luau
function create<T>(cleanup_handler: (T) -> (), items: {T}?): ItemGroup<T>
```
Creates a new ItemGroup instance.

**Parameters:**
- `cleanup_handler: (T) -> ()` - Function to call on each item when cleaning up
- `items: {T}?` - Optional initial array of items to add to the group

**Returns:**
- `ItemGroup<T>` - A new ItemGroup instance

**Example:**
```luau
local group = ItemGroup.create(ItemGroup.cleanup.disconnect)
```

---

## Methods

### `add`
```luau
function add(self: ItemGroup<T>, item: T): Disconnect
```
Adds a single item to the group.

**Parameters:**
- `item: T` - The item to add

**Returns:**
- `Disconnect` - A function that removes this specific item from the group when called

**Example:**
```luau
local disconnect = group:add(connection)
-- Later:
disconnect() -- Removes the connection from the group
```

### `add_many`
```luau
function add_many(self: ItemGroup<T>, src: {T}): Disconnect
```
Adds multiple items to the group at once.

**Parameters:**
- `src: {T}` - Array of items to add

**Returns:**
- `Disconnect` - A function that removes all added items from the group when called

**Example:**
```luau
local disconnect = group:add_many({conn1, conn2, conn3})
-- Later:
disconnect() -- Removes all three connections
```

### `free`
```luau
function free(self: ItemGroup<T>): ()
```
Cleans up all items in the group and recursively frees all child groups.

**Behavior:**
1. Calls `cleanup_handler` on each item in `items`
2. Recursively calls `free()` on all child ItemGroups in `children`

**Example:**
```luau
group:free() -- Disconnects all connections and cleans up children
```

### `extend`
```luau
function extend<A>(self: ItemGroup<T>, new_cleanup_handler: (A) -> (), items: {A}?): ItemGroup<A>
```
Creates a child ItemGroup with a different cleanup handler.

**Type Parameters:**
- `A` - The type of items for the new child group

**Parameters:**
- `new_cleanup_handler: (A) -> ()` - Cleanup function for the child group
- `items: {A}?` - Optional initial items for the child group

**Returns:**
- `ItemGroup<A>` - A new child ItemGroup that will be freed when the parent is freed

**Example:**
```luau
local connections = ItemGroup.create(ItemGroup.cleanup.disconnect)
local instances = connections:extend(ItemGroup.cleanup.destroy)
-- When connections:free() is called, instances will also be freed
```

---

## Built-in Cleanup Handlers

The module exports common cleanup handlers under the `cleanup` table:

### `cleanup.disconnect`
```luau
function disconnect(c: RBXScriptConnection): ()
```
Disconnects an RBXScriptConnection.

**Usage:**
```luau
local group = ItemGroup.create(ItemGroup.cleanup.disconnect)
```

### `cleanup.destroy`
```luau
function destroy(instance: Instance): ()
```
Destroys a Roblox Instance (alias for `game.Destroy`).

**Usage:**
```luau
local group = ItemGroup.create(ItemGroup.cleanup.destroy)
```

### `cleanup.call`
```luau
function call(f: () -> ()): ()
```
Calls a function (useful for storing cleanup callbacks).

**Usage:**
```luau
local group = ItemGroup.create(ItemGroup.cleanup.call)
group:add(function()
	print("Cleaning up!")
end)
```