local HttpService   = game:GetService("HttpService")
local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")

local isStudio      = RunService:IsStudio()

type ServiceData = {
    Name: string,
    Client: {[any]: any}?,
    [any]: any,
}

type Service = {
    Name: string,
    Client: ServiceClient,
    [any]: any,
}

type ServiceClient = {
    Server: Service,
    [any]: any,
}


local OverlordServer = {
    DebugMode = true,
}
OverlordServer.__index = OverlordServer

function OverlordServer.new()
    local self = setmetatable({}, OverlordServer)
    
    self.OverlordStatus = {
        Started                         = false,
        TranslationRequestees           = {},
    }

    self.EventTranslationFunc           = Instance.new("RemoteFunction")
    self.EventTranslationFunc.Name      = "Overlord:RequestEventTranslation"
    self.EventTranslationFunc.Parent    = script.Parent

    self.EventsFolder                   = script.Parent:FindFirstChild("Events") or Instance.new("Folder")
    self.EventsFolder.Name              = "Events"
    self.EventsFolder.Parent            = script.Parent

    local GlobalEventsFolder            = Instance.new("Folder")
    GlobalEventsFolder.Name             = "GlobalEvents"
    GlobalEventsFolder.Parent           = self.EventsFolder

    local BindableEventsFolder          = Instance.new("Folder")
    BindableEventsFolder.Name           = "BindableEvents"
    BindableEventsFolder.Parent         = self.EventsFolder

    self.EventTranslations              = {}

    self.Services                       = {}

    Players.PlayerRemoving:Connect(function(Player)
        if self.OverlordStatus.TranslationRequestees[Player] then
            self.OverlordStatus.TranslationRequestees[Player] = nil
        end
    end)

    self.EventTranslationFunc.OnServerInvoke = function(requestingPlayer: Player)
        if self.OverlordStatus.TranslationRequestees[requestingPlayer] == nil then
            self.OverlordStatus.TranslationRequestees[requestingPlayer] = true
            return self.EventTranslations
        else
            warn("OVERLORD SECURITY ALERT: " .. requestingPlayer.Name .. " [" .. tostring(requestingPlayer.UserId) .. "] tried to request an event translation, but already had requested one!")
            requestingPlayer:Kick("OverlordFrameworkSecurity: Possible Exploits Detected!")
            return
        end
    end

    return self
end

function OverlordServer:AddService(newService: Service)
    newService.Overlord = self
    self.Services[newService.Name] = newService
end

function OverlordServer:GetService(serviceName: string): Service
    if self.Services[serviceName] then
        return self.Services[serviceName]
    else
        warn("OVERLORD ALERT: " .. serviceName .. " is not a valid service!")
        return
    end
end

local RobloxScriptEventTypes = {
    ["RemoteEvent"]         = "GlobalEvents",
    ["RemoteFunction"]      = "GlobalEvents",
    ["BindableEvent"]       = "BindableEvents",
    ["BindableFunction"]    = "BindableEvents",
}

function OverlordServer:Start()

    if self.OverlordStatus.Started == true then
        warn("Overlord already started, come back later!")
        return
    end
    self.OverlordStatus.Started = true

    for _,service in pairs(self.Services) do
        service.Overlord = self
        for eventName,eventType in pairs(service.Client) do
           if RobloxScriptEventTypes[eventType] ~= nil then
                local newEvent                      = Instance.new(eventType)

                local securityKey                   = HttpService:GenerateGUID(false)

                if isStudio == true and self.DebugMode == true then
                    securityKey = eventName
                end

                newEvent.Name                       = securityKey
                
                local eventParent do
                    if RobloxScriptEventTypes[eventType] == true then
                        eventParent = self.EventsFolder
                    else
                        eventParent = self.EventsFolder:FindFirstChild(RobloxScriptEventTypes[eventType])
                    end
                end

                newEvent.Parent                     = eventParent

                service.Client[eventName]           = newEvent
                self.EventTranslations[securityKey] = eventName
           end
        end
    end

    local servicesThatFailedToInit = {}

    for _,service in pairs(self.Services) do
        if service.OverlordInit then
            local serviceFinishedInit, response = pcall(service.OverlordInit, service)
            if not serviceFinishedInit then
                warn("OverlordFramework: " .. service.Name .. " failed to init! " .. response)
                servicesThatFailedToInit[service.Name] = true
            end
        end
    end

    for _,service in pairs(self.Services) do
        if servicesThatFailedToInit[service.Name] then
            continue
        else
            if service.OverlordStart then
                local serviceFinishedStart, response = pcall(service.OverlordStart, service)
                if not serviceFinishedStart then
                    warn("OverlordFramework: " .. service.Name .. " failed to start! " .. response)
                end
            end
        end
    end

    local serverStarted     = Instance.new("BoolValue")
    serverStarted.Name      = "OverlordServerStarted"
    serverStarted.Value     = true
    serverStarted.Parent    = script.Parent

    local returnTable = {}

    function returnTable:andThen(callBack)
        callBack()
    end

    return returnTable
end

function OverlordServer.BuildService(passedServiceData: ServiceData): Service
    assert(type(passedServiceData) == "table","Service must be a table! We got " .. type(passedServiceData))
    assert(type(passedServiceData.Name) == "string","Service.Name must be a string! We got " .. type(passedServiceData.Name))
    assert(#passedServiceData.Name > 0, "Service.Name must not be an empty string.")

    local newService = passedServiceData
    newService.__index = newService
    setmetatable({}, newService)

    if type(newService.Client) ~= "table" then
        newService.Client = {
            Server = newService,
        }
    else
        if newService.Client.Server ~= newService then
            newService.Client.Server = newService
        end
    end

    return newService
end

return OverlordServer