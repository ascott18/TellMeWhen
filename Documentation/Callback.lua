
-- Documentation skeleton for TMW's callback system.

--- Registers a callback.
-- 
-- The second and third parameters can be one of the following:
-- * (function, nil) to register a specific function not registered for a specific object.
-- ** Callback will be called with signature (event, ...)
-- * (function, (non-nil identifier)) to register a specific function with a specific identifier.
-- ** Callback will be called with signature (identifier, event, ...)
-- * (table, nil) to register an object's method whose name is the event being registered.
-- ** Callback will be called with signature (table, event, ...)
-- * (table, string) to register an object's named method.
-- ** Callback will be called with signature (table, event, ...)
-- 
-- @paramsig event, ...
-- @param event [String] The event that the callback will be unregisted from.
-- @param ... [...] See above.
function TMW:RegisterCallback(event, func, arg1)

end

--- Unregisters a callback.
-- 
-- The second and third parameters can be one of the following:
-- * (function, nil) to unregister a specific function not registered for a specific object.
-- * (function, (non-nil value)) to unregister a specific function that was registered with the non-nil value as an identifier.
-- * (table, nil) to unregister a method whose name is the event being unregistered from an object.
-- * (table, string) to unregister a named method from an object.
-- 
-- @paramsig event, ...
-- @param event [String] The event that the callback will be unregisted from.
-- @param ... [...] See above.
function TMW:UnregisterCallback(event, func, arg1)

end

--- Unregisters all callbacks registered for a certain event.
-- 
-- Should only be used after firing an event that is guaranteed to only be fired once.
-- @param event [String] The event to unregister all callbacks for.
function TMW:UnregisterAllCallbacks(event)

end

--- Fires an event.
-- @param event [String] The event to fire.
-- @param ... [...] The event parameters that will be passed to the callbacks registered for the event.
function TMW:Fire(event, ...)

end
