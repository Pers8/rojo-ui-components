--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local UI = ReplicatedStorage:WaitForChild("UI")
local RippleCardsDemo = require(UI.components.RippleCardsDemo)

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(React.createElement("ScreenGui", {
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
	}, {
		App = React.createElement(RippleCardsDemo),
	}))

	return function()
		root:unmount()
	end
end
]]