--debounceutilities
--CarefreeCarrot 2024

local db = {}

	--STATIC MEMBERS------------
	db.log = {}
	db.__index = db
	----------------------------

	--MEMBER VARIABLES---------------------------
	db.maxrequestsperid = 1

	--false for no resetting
	--otherwise number in seconds since last reset that must pass for it to reset again
	db.resetduration = false

	--auto reset thread closes itself when specific debouncer has been inactive
	--for a while, starts again upon next call to debouncer
	db.resetthreadactive = false
	
	---------------------------------------------

	--------------STATIC MEMBER FUNCTIONS------------------------------------
	function db.new(maxreqperid, resetdur) --returns reference to new anonymous debouncer
		local debouncer = setmetatable({}, db)
		
		--MEMBER VARIABLE (placed here because lua doesn't deep copy tables when metatable templating)
		--reset completely erases id references from list table to prevent memory leaks
		--when players enter and leave over time
		debouncer.list = {}

		--if no params supplied, give default debouncer
		--default debouncer doesn't reset and maxes at 1 req per id
		if type(maxreqperid) == "number" then
			debouncer.maxrequestsperid = maxreqperid
		end
		if type(resetdur) == "number" then
			debouncer.resetduration = resetdur
		end
		return debouncer
	end

	--Gets reference to specific global key-binded debouncer if it already exists
	--Otherwise makes new debouncer and binds to key
	function db.getglobaldebouncer(key)
		if db.log[key] then
			return db.log[key]
		end
		local newdebouncer = db.new()
		db.log[key] = newdebouncer
		return newdebouncer
	end

	function db.destroyglobaldebouncer(key)
		if db.log[key] then
			db.log[key] = nil
		end
	end

	-------------------------------------------------------------------------

	--=================INDIVIDUAL DEBOUNCER OBJECT METHODS=============================
	

	function db:reset()
		for k,v in pairs(self.list) do
			self.list[k] = nil
		end
	end

	--If specific debouncer doesn't reset or reset thread is already active
	--then this method does nothing
	function db:spawnresetthread()
		if (not self.resetduration) or (self.resetthreadactive) then
			return
		end
		self.resetthreadactive = true
		task.defer(function()
			task.wait(self.resetduration)
			self:reset()
			self.resetthreadactive = false
		end)
	end

	function db:check(id)
		--if a reset occurs in the middle of a check, existing value for an id
		--does not get garbage collected as long as a singular reference exists
		--thus, check function creates a temporary reference
		local checks = self.list[id]
		local canproceed = false
		if checks == nil then
			checks = 0 --make into number so incrementation doesn't error
			canproceed = true
		elseif checks < self.maxrequestsperid then
			canproceed = true
		end
		checks = checks + 1

		--spawn reset thread to wait a specific duration of time, then reset
		--list for this specific debouncer object
		--or do nothing if resetting is disabled
		self.list[id] = checks
		self:spawnresetthread()
		return canproceed
	end

	--=======================================================================


return db
