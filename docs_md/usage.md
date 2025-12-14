# Overview

ItemGroup is a Luau utility for managing collections of items that need cleanup. It's particularly useful for managing Roblox connections, instances, and custom cleanup callbacks with automatic lifecycle management.

---

## Basic Usage

### Creating an ItemGroup

Create an ItemGroup by specifying a cleanup handler:

```luau
local cleanup = ItemGroup.cleanup
-- For RBXScriptConnections
local connections = ItemGroup.create(cleanup.disconnect)

-- For Instances
local instances = ItemGroup.create(cleanup.destroy)

-- For custom cleanup functions
local callbacks = ItemGroup.create(cleanup.call)
```

### Adding Items

```luau
local cleanup = ItemGroup.cleanup
local connections = ItemGroup.create(cleanup.disconnect)

-- Add a single connection
local conn = workspace.ChildAdded:Connect(function(child)
	print("Child added:", child.Name)
end)
connections:add(conn)

-- Add multiple connections at once
local conn1 = workspace.ChildRemoved:Connect(handler1)
local conn2 = game.Players.PlayerAdded:Connect(handler2)
connections:add_many({conn1, conn2})
```

### Cleaning Up

```luau
-- Clean up all items and children
connections:free()
-- All connections are now disconnected
```

---

## Common Patterns

### Managing Component Lifecycle

```luau
local cleanup = ItemGroup.cleanup
local MyComponent = {}
MyComponent.__index = MyComponent

function MyComponent.new()
	local self = setmetatable({}, MyComponent)
	self._cleanup = ItemGroup.create(cleanup.disconnect)
	
	-- Add connections
	self._cleanup:add(workspace.ChildAdded:Connect(function(child)
		self:onChildAdded(child)
	end))
	
	return self
end

function MyComponent:destroy()
	self._cleanup:free() -- Disconnects all connections
end
```

### Mixed Resource Types with `extend()`

When you need to manage different types of resources, use `extend()` to create child groups:

```luau
local cleanup = ItemGroup.cleanup

local connections = ItemGroup.create(cleanup.disconnect)

-- Create child group for instances
local instances = connections:extend(cleanup.destroy)

-- Create child group for custom callbacks
local callbacks = connections:extend(cleanup.call)

-- Add different resource types
connections:add(workspace.ChildAdded:Connect(handler))
instances:add(Instance.new("Part"))
callbacks:add(function()
	print("Custom cleanup!")
end)

-- Free everything at once
connections:free()
-- This cleans up:
-- 1. All connections in the main group
-- 2. All instances in the child group
-- 3. All callbacks in the callback group
```

### Scoped Cleanup with Disconnect Functions

The `add()` and `add_many()` methods return disconnect functions for granular control:

```luau
local group = ItemGroup.create(ItemGroup.cleanup.disconnect)

-- Add a temporary connection
local disconnect = group:add(workspace.ChildAdded:Connect(handler))

-- Later, remove just this connection
disconnect()
-- The connection is removed from the group (but other items remain)
-- This means the connection will no longer be cleaned up when group:free() is called
```

### Temporary Event Listening

```luau
local cleanup = ItemGroup.cleanup
local connections = ItemGroup.create(cleanup.disconnect)

local function setupTemporaryListeners()
	connections:add_many({
		workspace.ChildAdded:Connect(handler1),
		workspace.ChildRemoved:Connect(handler2),
	})
	
	task.delay(10, connections.free, connections) -- After 10 seconds, free everything
end
```

---

## Advanced Usage

### Nested Resource Management

```luau
local cleanup = ItemGroup.cleanup
local root = ItemGroup.create(cleanup.call)

-- Create subsystems with their own cleanup
local networkCleanup = root:extend(cleanup.disconnect)
local uiCleanup = root:extend(cleanup.destroy)
local timerCleanup = root:extend(cleanup.call)

-- Each subsystem manages its own resources
networkCleanup:add(replicatedStorage.RemoteEvent.OnClientEvent:Connect(handler))
uiCleanup:add(screenGui)
timerCleanup:add(function()
	-- Cancel timers or other cleanup
end)

-- Free everything with one call
root:free()
```

### Pre-populating with Initial Items

```luau
local existingConnections = {conn1, conn2, conn3}

-- Create group with initial items
local group = ItemGroup.create(ItemGroup.cleanup.disconnect, existingConnections)

-- All three connections are already in the group
group:free() -- Disconnects conn1, conn2, and conn3
```

### Custom Cleanup Handlers

```luau
-- Define a custom cleanup handler
local function cleanupCustomResource(resource)
	resource:shutdown()
	resource:release()
end

-- Use it with ItemGroup
local resources = ItemGroup.create(cleanupCustomResource)
resources:add(myCustomResource)
resources:free() -- Calls cleanupCustomResource(myCustomResource)
```

### Managing Game State

```luau
local cleanup = ItemGroup.cleanup
local GameState = {}

function GameState.new()
	local self = {}
	self._cleanup = ItemGroup.create(cleanup.disconnect)
	self._instances = self._cleanup:extend(cleanup.destroy)
	
	-- Setup connections
	self._cleanup:add(game.Players.PlayerAdded:Connect(function(player)
		self:onPlayerJoined(player)
	end))
	
	-- Track instances
	local leaderboard = Instance.new("ScreenGui")
	self._instances:add(leaderboard)
	
	return self
end

function GameState:cleanup()
	self._cleanup:free() -- Cleans up connections and instances
end
```

---

## Best Practices

1. **Use specific cleanup handlers**: Choose the appropriate cleanup handler for your resource type
   - `cleanup.disconnect` for connections
   - `cleanup.destroy` for instances
   - `cleanup.call` for functions
   - If none of these fit your resource type, make your own using a custom callback!

2. **Organize by resource type**: Use `extend()` to create separate groups for different resource types

3. **Store at component/object level**: Keep ItemGroups as instance variables for automatic cleanup in `:destroy()` methods

4. **Free on cleanup**: Always call `free()` in your component's destructor or cleanup method

5. **Use disconnect functions sparingly**: Only use the returned disconnect functions when you need to remove specific items before the full cleanup

6. **Avoid manual item management**: Let ItemGroup handle the lifecycle instead of manually tracking arrays

---

## Common Pitfalls

### ❌ Forgetting to call `free()`
```luau
local cleanup = ItemGroup.create(ItemGroup.cleanup.disconnect)
cleanup:add(connection)
-- Memory leak: connection is never disconnected
```

### ✅ Always cleanup
```luau
local cleanup = ItemGroup.create(ItemGroup.cleanup.disconnect)
cleanup:add(connection)
cleanup:free() -- Properly cleaned up
```

### ❌ Wrong cleanup handler
```luau
local instances = ItemGroup.create(ItemGroup.cleanup.disconnect)
instances:add(Instance.new("Part")) -- Won't destroy the part!
```

### ✅ Correct cleanup handler
```luau
local instances = ItemGroup.create(ItemGroup.cleanup.destroy)
instances:add(Instance.new("Part")) -- Part will be destroyed
```

---

## Type Safety

ItemGroup is fully typed with Luau's `--!strict` mode:

```luau
-- Type-safe usage
local connections: ItemGroup.ItemGroup<RBXScriptConnection> = 
	ItemGroup.create(ItemGroup.cleanup.disconnect)

-- TypeScript-like generic inference
local cleanup = ItemGroup.create(ItemGroup.cleanup.call) -- ItemGroup<() -> ()>
```

---

## Performance Considerations

- **Adding items**: O(1) amortized time
- **Removing items**: O(n) where n is the number of items in the group
- **Freeing**: O(n + m) where n is items and m is children
- **Memory**: Minimal overhead per item (just array storage)

For most use cases, ItemGroup's performance is negligible compared to the resources it manages.