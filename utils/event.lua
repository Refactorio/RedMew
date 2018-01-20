--Event Capture
--A 3Ra Gaming revision, original from Factorio-Stdlib by Afforess
-- @module Event

function fail_if_missing(var, msg)
	if not var then
		if msg then
			error(msg, 3)
		else
			error("Missing value", 3)
		end
	end
	return false
end


Event = {
	_registry = {},
	core_events = {
		init = -1,
		load = -2,
		configuration_changed = -3,
		_register = function(id)
			if id == Event.core_events.init then
				script.on_init(function()
					Event.dispatch({ name = Event.core_events.init, tick = game.tick })
				end)
			elseif id == Event.core_events.load then
				script.on_load(function()
					Event.dispatch({ name = Event.core_events.load, tick = -1 })
				end)
			elseif id == Event.core_events.configuration_changed then
				script.on_configuration_changed(function(data)
					Event.dispatch({ name = Event.core_events.configuration_changed, tick = game.tick, data = data })
				end)
			end
		end
	}
}

--- Registers a function for a given event
-- @param event or array containing events to register
-- @param handler Function to call when event is triggered
-- @return #Event
function Event.register(event, handler)
	fail_if_missing(event, "missing event argument")

	if type(event) == "number" then
		event = { event }
	end

	for _, event_id in pairs(event) do
		fail_if_missing(event_id, "missing event id")
		if handler == nil then
			Event._registry[event_id] = nil
			script.on_event(event_id, nil)
		else
			if not Event._registry[event_id] then
				Event._registry[event_id] = {}

				if event_id >= 0 then
					script.on_event(event_id, Event.dispatch)
				else
					Event.core_events._register(event_id)
				end
			end
			table.insert(Event._registry[event_id], handler)
		end
	end
	return Event
end

--- Calls the registerd handlers
-- @param event LuaEvent as created by game.raise_event
function Event.dispatch(event)
	fail_if_missing(event, "missing event argument")
	if Event._registry[event.name] then
		for _, handler in pairs(Event._registry[event.name]) do
			local metatbl = { __index = function(tbl, key) if key == '_handler' then return handler else return rawget(tbl, key) end end }
			setmetatable(event, metatbl)
			local success, err = pcall(handler, event)
			if not success then
				-- may be nil in on_load
				local identifier = event.name
				for i,v in pairs(defines.events) do
					if v == event.name then
						identifier = i
					end
				end
				err = string.gsub(err, "\n", " : ")
				if event.name < -1 or global.last_error ~= identifier then
					print("output$Error in event "..identifier..": \""..err.."\".")
					log("Error in event "..identifier..": \""..err.."\".")
					if event.name > -2 then
						global.last_error = identifier
					end
				end
			end
		end
	end
end

--- Removes the handler from the event
-- @param event event or array containing events to remove the handler
-- @param handler to remove
-- @return #Event
function Event.remove(event, handler)
	fail_if_missing(event, "missing event argument")
	fail_if_missing(handler, "missing handler argument")

	if type(event) == "number" then
		event = { event }
	end

	for _, event_id in pairs(event) do
		fail_if_missing(event_id, "missing event id")
		if Event._registry[event_id] then
			for i = #Event._registry[event_id], 1, -1 do
				if Event._registry[event_id][i] == handler then
					table.remove(Event._registry[event_id], i)
				end
			end
			if #Event._registry[event_id] == 0 then
				Event._registry[event_id] = nil
				script.on_event(event_id, nil)
			end
		end
	end
	return Event
end
return Event
