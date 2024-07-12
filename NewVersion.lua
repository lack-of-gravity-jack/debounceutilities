local dbu :DebounceUtilities = {}
	dbu.__index = dbu

	export type debouncer = {
		check			:(self, id :any) -> boolean,
	}

	type DebounceUtilities = {
		CreateAdmitter	:(AdmitUntilThisLimit :number, TimeOut :number) -> debouncer,
		CreateRejecter	:(RejectPastThisLimit :number, TimeOut :number) -> debouncer,
	}

	function dbu.CreateAdmitter(AdmitUntilThisLimit :number, TimeOut :number) :debouncer
		if not AdmitUntilThisLimit then AdmitUntilThisLimit = 1 end
		if not TimeOut then TimeOut = false end

		local NewDebouncer :debouncer = setmetatable({}, dbu)
		NewDebouncer.list = {}
		NewDebouncer.threshold = AdmitUntilThisLimit
		NewDebouncer.TimeOut = TimeOut
		NewDebouncer.ResetThreadActive = false
		NewDebouncer.invert = false
		if not TimeOut then NewDebouncer.ResetThreadActive = true end --Never reset if no timeout provided
		return NewDebouncer
	end

	function dbu.CreateRejecter(RejectPastThisLimit :number, TimeOut :number) :debouncer
		local NewDebouncer = dbu.CreateAdmitter(RejectPastThisLimit, TimeOut)
		NewDebouncer.invert = true
		return NewDebouncer
	end

	local function SpawnResetThread(db :debouncer)
		if db.ResetThreadActive then return end
		db.ResetThreadActive = true
		task.defer(function()
			task.wait(db.TimeOut)
			db.list = {}
			db.ResetThreadActive = false
		end)
	end

	function dbu:check(id :any) :boolean
		local checks = self.list[id]
		if not checks then checks = 0 end
		local pass = checks < self.threshold
		self.list[id] = checks + 1
		SpawnResetThread(self)
		if self.invert then return not pass end
		return pass
	end

return dbu
