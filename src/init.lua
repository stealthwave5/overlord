if game:GetService("RunService"):IsServer() then
	return require(script.OverlordServer)
else
	local OverlordServer = script:FindFirstChild("OverlordServer")
	if OverlordServer then
		OverlordServer:Destroy()
	end
	return require(script.OverlordClient)
end
