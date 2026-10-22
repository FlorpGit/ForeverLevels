-- ForeverLevels: route state machine.
-- A step's goals are quest IDs under accept / complete / turnin, plus an optional
-- level. A step is done when every goal that applies to the player is met.
-- Steps (or single goals) can be limited to classes and races.

local _, FL = ...

local Engine = {}
FL.Engine = Engine

local Quests = FL.Quests
local Contains = FL.Contains

Engine.route = nil
Engine.index = 1
Engine.hold = false   -- true after the player steps back manually; pauses auto-advance

local GOAL_TESTS = {
	accept = function(questID) return Quests.HasAccepted(questID) end,
	complete = function(questID) return Quests.IsObjectivesDone(questID) end,
	turnin = function(questID) return Quests.IsTurnedIn(questID) end,
}

local function GoalApplies(goal, player)
	if type(goal) ~= "table" then return true end
	return Contains(goal.class, player.class) and Contains(goal.race, player.race)
end

local function GoalQuestID(goal)
	return type(goal) == "table" and goal[1] or goal
end

function Engine.StepApplies(step, player)
	if not Contains(step.class, player.class) then return false end
	if not Contains(step.race, player.race) then return false end
	if step.faction and step.faction ~= player.faction then return false end
	return true
end

-- Returns a list of { kind, questID, done } for goals that apply to the player,
-- and whether the step declared any goals at all (before filtering).
function Engine.GetGoals(step, player)
	local goals, declared = {}, false
	for _, kind in ipairs(FL.Validator.GOAL_KINDS) do
		local list = step[kind]
		if list then
			for _, goal in ipairs(list) do
				declared = true
				if GoalApplies(goal, player) then
					local questID = GoalQuestID(goal)
					goals[#goals + 1] = { kind = kind, questID = questID, done = GOAL_TESTS[kind](questID) }
				end
			end
		end
	end
	if step.level then
		declared = true
		goals[#goals + 1] = { kind = "level", level = step.level, done = player.level >= step.level }
	end
	return goals, declared
end

-- "skip": step does not apply to this player (filtered by class/race, or all goals filtered).
-- "done": every applicable goal met.  "open": still to do.  "manual": no goals, needs Next.
function Engine.GetStepState(step, player)
	if not Engine.StepApplies(step, player) then return "skip" end
	local goals, declared = Engine.GetGoals(step, player)
	if #goals == 0 then
		return declared and "skip" or "manual"
	end
	for _, goal in ipairs(goals) do
		if not goal.done then return "open" end
	end
	return "done"
end

function Engine.GetStepText(step, player)
	if step.classText and step.classText[player.class] then
		local text = step.text and (step.text .. "\n") or ""
		return text .. step.classText[player.class]
	end
	return step.text or ""
end

------------------------------------------------------------------------
-- Route selection and progress
------------------------------------------------------------------------

function Engine:GetCurrentStep()
	return self.route and self.route.steps[self.index]
end

function Engine:SelectRoute(routeId, silent)
	local route = FL:GetRoute(routeId)
	if not route then
		FL:Print("unknown route:", tostring(routeId))
		return false
	end
	self.route = route
	self.hold = false
	FL.char.routeId = route.id
	local progress = FL:GetRouteProgress(route.id)
	self.index = math.min(math.max(progress.step or 1, 1), #route.steps)
	if not silent then
		FL:Print("route:", route.title)
	end
	self:Refresh(true)
	return true
end

function Engine:AutoSelectRoute()
	local saved = FL.char.routeId and FL:GetRoute(FL.char.routeId)
	if saved then
		return self:SelectRoute(saved.id, true)
	end
	if not FL.db.profile.autoSelectRoute then return false end
	local route = FL:FindRouteFor(FL.player)
	if route then
		return self:SelectRoute(route.id)
	end
	FL:Print("no installed route fits this character yet. Type /pathwise routes to see what is installed.")
	return false
end

local function SaveIndex(self)
	if self.route then
		FL:GetRouteProgress(self.route.id).step = self.index
	end
end

function Engine:IsSkipped(step)
	return FL:GetRouteProgress(self.route.id).skipped[step.id] and true or false
end

-- Moves forward past finished, skipped and non-applicable steps.
function Engine:Advance()
	local route = self.route
	if not route then return end
	local player = FL.player
	while self.index <= #route.steps do
		local step = route.steps[self.index]
		local state = Engine.GetStepState(step, player)
		if state == "open" or state == "manual" then
			if not self:IsSkipped(step) then break end
		end
		self.index = self.index + 1
	end
	if self.index > #route.steps then
		self.index = #route.steps
		self:FinishRoute()
	end
end

function Engine:FinishRoute()
	local route = self.route
	if self.finishedNotified == route.id then return end
	self.finishedNotified = route.id
	local nextRoute = route.next and FL:GetRoute(route.next)
	if nextRoute then
		FL:Print("finished", route.title, "- continuing with", nextRoute.title)
		self:SelectRoute(nextRoute.id, true)
	else
		FL:Print("finished", route.title .. ".", route.next and ("Next route '" .. route.next .. "' is not installed.") or "")
		FL:Fire("ROUTE_FINISHED", route.id)
	end
end

function Engine:Refresh(force)
	if not self.route then return end
	local before = self.index
	if not self.hold then
		self:Advance()
	end
	SaveIndex(self)
	if force or before ~= self.index then
		FL:Fire("STEP_CHANGED", self:GetCurrentStep(), self.index)
	end
	FL:Fire("STEP_UPDATED", self:GetCurrentStep(), self.index)
end

-- Manual navigation. Going back holds the guide on that step until Next.
function Engine:Next()
	if not self.route then return end
	local step = self:GetCurrentStep()
	local state = Engine.GetStepState(step, FL.player)
	if state == "open" and not self.hold then
		-- Leaving an unfinished step marks it skipped so it will not pull us back.
		FL:GetRouteProgress(self.route.id).skipped[step.id] = true
	end
	self.hold = false
	if self.index >= #self.route.steps then
		self:FinishRoute()
		return
	end
	self.index = self.index + 1
	self:Refresh(true)
end

function Engine:Prev()
	if not self.route then return end
	local player = FL.player
	local index = self.index - 1
	while index >= 1 and Engine.GetStepState(self.route.steps[index], player) == "skip" do
		index = index - 1
	end
	if index >= 1 then
		self.index = index
		self.hold = true
		local step = self.route.steps[index]
		FL:GetRouteProgress(self.route.id).skipped[step.id] = nil
		SaveIndex(self)
		FL:Fire("STEP_CHANGED", step, index)
		FL:Fire("STEP_UPDATED", step, index)
	end
end

function Engine:GoTo(index)
	if not self.route or not self.route.steps[index] then return end
	self.index = index
	self.hold = true
	SaveIndex(self)
	FL:Fire("STEP_CHANGED", self:GetCurrentStep(), index)
	FL:Fire("STEP_UPDATED", self:GetCurrentStep(), index)
end

function Engine:ResetRoute()
	if not self.route then return end
	FL.char.progress[self.route.id] = nil
	self.index = 1
	self.hold = false
	self.finishedNotified = nil
	self:Refresh(true)
end

-- Should automation act on this quest? Accept: only quests the route uses from the
-- current step onward. Turn-in: any quest the route turns in anywhere.
function Engine:IsWantedQuest(questID, kind)
	local route = self.route
	if not route or not questID then return false end
	local player = FL.player
	local first = (kind == "accept") and self.index or 1
	for i = first, #route.steps do
		local step = route.steps[i]
		if Engine.StepApplies(step, player) and step[kind] then
			for _, goal in ipairs(step[kind]) do
				if GoalQuestID(goal) == questID and GoalApplies(goal, player) then
					return true
				end
			end
		end
	end
	return false
end

FL:On("QUESTS_CHANGED", function() Engine:Refresh() end)
FL:On("PLAYER_CHANGED", function() Engine:Refresh() end)
