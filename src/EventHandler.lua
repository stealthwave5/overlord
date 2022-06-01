local eventHandler = {}
eventHandler.__index = eventHandler

local executeNameChange 	= true
local executeParentChange 	= true

local RS = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")


if RS:IsStudio() then
	executeNameChange 	= false
	executeParentChange = false
end


local LettersTable 	= {"a","b","c","d","A","B","C","D","Ҵ","Ӂ","Ѭ","П","∆","□","₸","§",">","1","4","8","9","!","?","-","]","❤️","😷","👀"," ", "   ", "  ","/",}

local ParentsTable	= {game.ReplicatedFirst,game.ReplicatedStorage,game.LocalizationService,game.Lighting}

function eventHandler.new(eventPath,translationFunc)
	local self = setmetatable({},eventHandler)
	
	self.Translation = translationFunc:InvokeServer()

	self.Events = {}
	
	for i,v in pairs(eventPath:GetDescendants()) do
		if self.Translation[v.Name] then
			self.Events[self.Translation[v.Name]] = v
		end
	end

	print(self.Translation,self.Events)
	
	table.insert(ParentsTable,eventPath)
	
	
	if executeNameChange == true then
		task.defer(function()
			local num = 1
			while task.wait(1) do
				for i,v in pairs(self.Events) do
					if num == 1 then
						v.Name = "OVERLORD_SECURITY"
					elseif num == 2 then
						v.Name = "OVERLORD_보안"
					else
						v.Name = "OVERLORD_EVENTS"
					end
				end
				
				num += 1
				if num > 3 then
					num = 1
				end
			end
		end)
	end

	if executeParentChange == true then
		task.defer(function()
			while true do
				for _,v in pairs(self.Events) do
					v.Parent = ParentsTable[math.random(1,#ParentsTable)]
				end
				task.wait()
			end
		end)
	end
	
	return self
end

function eventHandler:GetEvent(Name)
	return self.Events[Name] or nil
end

return eventHandler