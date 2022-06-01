
type ControllerData = {
    Name: string,
    [any]: any,
}

type Controller = {
    Name: string,
    [any]: any,
}

type Service = {
    [any]: any,
}



local OverlordClient = {}
OverlordClient.__index = OverlordClient

function OverlordClient.new()
    local self = setmetatable({}, OverlordClient)

    self.OverlordStatus = {
        Started                         = false,
    }

    repeat
        task.wait()
    until script.Parent:FindFirstChild("Events") and script.Parent:FindFirstChild("Overlord:RequestEventTranslation") and script.Parent:FindFirstChild("OverlordServerStarted")

    self.EventTranslationFunc           = script.Parent:WaitForChild("Overlord:RequestEventTranslation")

    self.EventsFolder                   = script.Parent:WaitForChild("Events")

    self.EventHandler                   = require(script.Parent:WaitForChild("EventHandler"))
    self.EventHandler                   = self.EventHandler.new(self.EventsFolder,self.EventTranslationFunc)

    self.Controllers                    = {}

    return self
end

function OverlordClient:GetEvent(eventName: string): any
    return self.EventHandler:GetEvent(eventName)
end

function OverlordClient:Start()
    if self.OverlordStatus.Started == true then
        warn("Overlord already started, come back later!")
        return
    end
    self.OverlordStatus.Started = true

    local controllersThatFailedToInit = {}

    for _,controller in pairs(self.Controllers) do
        if controller.OverlordInit then
            local controllerFinishedInit, response = pcall(controller.OverlordInit, controller)
            if not controllerFinishedInit then
                warn("OverlordFramework: " .. controller.Name .. " failed to init! " .. response)
                controllersThatFailedToInit[controller.Name] = true
            end
        end
    end

    for _,controller in pairs(self.Controllers) do
        if controllersThatFailedToInit[controller.Name] then
            continue
        else
            if controller.OverlordStart then
                local controllerFinishedStart, response = pcall(controller.OverlordStart, controller)
                if not controllerFinishedStart then
                    warn("OverlordFramework: " .. controller.Name .. " failed to start! " .. response)
                end
            end
        end
    end

    local returnTable = {}

    function returnTable:andThen(callBack)
        callBack()
    end

    return returnTable
end

local LettersTable 	= {"a","b","c","d","A","B","C","D","Ҵ","Ӂ","Ѭ","П","∆","□","₸","§",">","1","4","8","9","!","?","-","]","❤️","😷","👀"," ", "   ", "  ","/",}

function OverlordClient:Secure()
    task.defer(function()

        if game:GetService("RunService"):IsStudio() then
            return
        end

        local translationFunction   = script.Parent:WaitForChild("Overlord:RequestEventTranslation")
        local eventHandler          = script.Parent:WaitForChild("EventHandler")
        local clientScript          = script

        translationFunction:Destroy()
        eventHandler:Destroy()
        clientScript:Destroy()

        while true do
            task.wait()
            eventHandler.Name           = LettersTable[math.random(1,#LettersTable)]
            clientScript.Name           = LettersTable[math.random(1,#LettersTable)]
            translationFunction.Name    = LettersTable[math.random(1,#LettersTable)]
        end
    end)
end

function OverlordClient:AddController(newController: Controller)
    newController.Overlord = self
    self.Controllers[newController.Name] = newController
end

function OverlordClient:GetController(controllerName: string): Controller
    if self.Controllers[controllerName] then
        return self.Controllers[controllerName]
    else
        warn("Controller " .. controllerName .. " does not exist")
        return {}
    end
end

function OverlordClient.BuildController(newController: ControllerData): Controller
    assert(type(newController) == "table","Controller must be a table! We got " .. type(newController))
    assert(type(newController.Name) == "string","Controller.Name must be a string! We got " .. type(newController.Name))
    assert(#newController.Name > 0, "Controller.Name must not be an empty string.")

    local controller = newController
    controller.__index = controller
    setmetatable({}, controller)

    return controller
end

return OverlordClient