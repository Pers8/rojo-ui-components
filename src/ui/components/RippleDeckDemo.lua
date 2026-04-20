local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages.React)
local Ripple = require(Packages.Ripple)

local e = React.createElement

local INITIAL_CARDS = {
	{
		id = "nova",
		title = "Nova",
		subtitle = "Burst damage",
		accent = Color3.fromRGB(90, 180, 255),
		fill = Color3.fromRGB(18, 28, 44),
	},
	{
		id = "ember",
		title = "Ember",
		subtitle = "Aggressive ignite",
		accent = Color3.fromRGB(255, 128, 80),
		fill = Color3.fromRGB(42, 24, 20),
	},
	{
		id = "aether",
		title = "Aether",
		subtitle = "Control field",
		accent = Color3.fromRGB(200, 150, 255),
		fill = Color3.fromRGB(32, 22, 46),
	},
	{
		id = "verdant",
		title = "Verdant",
		subtitle = "Sustain engine",
		accent = Color3.fromRGB(110, 235, 170),
		fill = Color3.fromRGB(20, 40, 30),
	},
	{
		id = "luxe",
		title = "Luxe",
		subtitle = "Tempo burst",
		accent = Color3.fromRGB(255, 220, 120),
		fill = Color3.fromRGB(45, 36, 20),
	},
}

local CARD_W = 170
local CARD_H = 235

local CENTER_X = 520
local CENTER_Y = 320
local SPACING = 145

local THROW_DISTANCE = 240
local DRAG_LIFT = 54

local function cloneArray(tbl)
	local out = {}
	for i, v in ipairs(tbl) do
		out[i] = v
	end
	return out
end

local function findIndex(cards, id)
	for i, card in ipairs(cards) do
		if card.id == id then
			return i
		end
	end
	return nil
end

local function removeById(cards, id)
	local out = {}
	for _, card in ipairs(cards) do
		if card.id ~= id then
			table.insert(out, card)
		end
	end
	return out
end

local function baseLayoutFor(index, total, mode)
	local center = (total + 1) / 2
	local offset = index - center

	if mode == "stack" then
		return {
			x = CENTER_X + offset * 26,
			y = CENTER_Y + offset * 4,
			rotation = offset * 2.5,
		}
	end

	return {
		x = CENTER_X + offset * SPACING,
		y = CENTER_Y + math.abs(offset) * 12,
		rotation = offset * 6,
	}
end

local function createCardSpring()
	return Ripple.createSpring({
		x = 0,
		y = 0,
		size = 0,
		rotation = 0,
		glow = 0,
		opacity = 1,
	}, {
		tension = 220,
		friction = 20,
		mass = 1,
		start = true,
	})
end

local function createFlashSpring()
	return Ripple.createSpring({
		opacity = 0,
		scale = 0.8,
	}, {
		tension = 260,
		friction = 18,
		mass = 0.9,
		start = true,
	})
end

local function DeckCard(props)
	local card = props.card
	local bindings = props.bindings

	return e("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = bindings.position,
		Size = bindings.size,
		Rotation = bindings.rotation,
		BackgroundColor3 = card.fill,
		BackgroundTransparency = bindings.bgTransparency,
		AutoButtonColor = false,
		Text = "",
		ZIndex = props.zIndex,

		[React.Change.GuiState] = function(rbx)
			if not props.isDragging then
				if rbx.GuiState == Enum.GuiState.Hover then
					props.onHover(card.id)
				elseif rbx.GuiState == Enum.GuiState.Idle then
					props.onHover(nil)
				elseif rbx.GuiState == Enum.GuiState.Press then
					props.onHover(card.id)
				end
			end
		end,

		[React.Event.MouseButton1Down] = function()
			props.onStartDrag(card.id)
		end,

		[React.Event.MouseButton1Click] = function()
			props.onSelect(card.id)
		end,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 22),
		}),

		UIStroke = e("UIStroke", {
			Color = card.accent,
			Thickness = bindings.strokeThickness,
			Transparency = bindings.strokeTransparency,
		}),

		Glow = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = bindings.glowSize,
			BackgroundColor3 = card.accent,
			BackgroundTransparency = bindings.glowTransparency,
			ZIndex = props.zIndex - 1,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 28),
			}),
		}),

		TopBar = e("Frame", {
			Position = UDim2.fromOffset(14, 14),
			Size = UDim2.new(1, -28, 0, 8),
			BackgroundColor3 = card.accent,
			BorderSizePixel = 0,
			ZIndex = props.zIndex + 1,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		Orb = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.72, 0.3),
			Size = UDim2.fromOffset(86, 86),
			BackgroundColor3 = card.accent,
			BackgroundTransparency = 0.16,
			ZIndex = props.zIndex + 1,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		Title = e("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 114),
			Size = UDim2.new(1, -32, 0, 34),
			Text = card.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			TextSize = 26,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			ZIndex = props.zIndex + 1,
		}),

		Subtitle = e("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 148),
			Size = UDim2.new(1, -32, 0, 24),
			Text = card.subtitle,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(215, 220, 232),
			ZIndex = props.zIndex + 1,
		}),

		Tag = e("TextLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9,
			Position = UDim2.fromOffset(16, 186),
			Size = UDim2.fromOffset(108, 28),
			Text = props.isDragging and "DRAGGING" or (props.isSelected and "SELECTED" or "CARD"),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			ZIndex = props.zIndex + 1,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

local function RippleDeckDemo()
	local cards, setCards = React.useState(function()
		return cloneArray(INITIAL_CARDS)
	end)

	local mode, setMode = React.useState("fan")
	local hoveredId, setHoveredId = React.useState(nil)
	local selectedId, setSelectedId = React.useState("aether")
	local draggingId, setDraggingId = React.useState(nil)
	local dragPosition, setDragPosition = React.useState(nil)
	local throwFlashPos, setThrowFlashPos = React.useState(Vector2.new(CENTER_X, CENTER_Y))

	local springsRef = React.useRef({})
	local bindingsRef = React.useRef({})
	local flashSpringRef = React.useRef(nil)
	local flashBindingRef = React.useRef(nil)
	local flashSetBindingRef = React.useRef(nil)

	if flashSpringRef.current == nil then
		flashSpringRef.current = createFlashSpring()
		local binding, setBinding = React.createBinding({
			opacity = 0,
			scale = 0.8,
		})
		flashBindingRef.current = binding
		flashSetBindingRef.current = setBinding
		flashSpringRef.current:onChange(function(value)
			flashSetBindingRef.current(value)
		end)
	end

	local function ensureSpring(cardId)
		if not springsRef.current[cardId] then
			local spring = createCardSpring()
			local binding, setBinding = React.createBinding({
				x = 0,
				y = 0,
				size = 0,
				rotation = 0,
				glow = 0,
				opacity = 1,
			})

			spring:onChange(function(value)
				setBinding(value)
			end)

			springsRef.current[cardId] = spring
			bindingsRef.current[cardId] = binding
		end
	end

	for _, card in ipairs(cards) do
		ensureSpring(card.id)
	end

	local function getCardLayout(index, total, cardId)
		local isHovered = hoveredId == cardId
		local isSelected = selectedId == cardId
		local isDragging = draggingId == cardId

		local base = baseLayoutFor(index, total, mode)
		local x = base.x
		local y = base.y
		local rotation = base.rotation
		local sizeOffset = 0
		local glow = 0

		if isHovered and not isDragging then
			y -= 18
			rotation *= 0.35
			sizeOffset += 10
			glow += 1
		end

		if isSelected and not isDragging then
			y -= 42
			rotation = 0
			sizeOffset += 18
			glow += 1.6
		end

		if isDragging and dragPosition then
			local dx = dragPosition.X - x
			local dy = dragPosition.Y - y

			x = dragPosition.X
			y = dragPosition.Y - DRAG_LIFT
			rotation = math.clamp(dx * 0.05, -18, 18) + math.clamp(dy * -0.015, -6, 6)
			sizeOffset += 24
			glow += 2.2
		end

		return {
			x = x,
			y = y,
			rotation = rotation,
			size = sizeOffset,
			glow = glow,
			opacity = 1,
		}
	end

	React.useEffect(function()
		for index, card in ipairs(cards) do
			local spring = springsRef.current[card.id]
			local isDragging = draggingId == card.id
			local layout = getCardLayout(index, #cards, card.id)

			spring:setGoal({
				x = layout.x,
				y = layout.y,
				size = layout.size,
				rotation = layout.rotation,
				glow = layout.glow,
				opacity = layout.opacity,
			}, {
				tension = if isDragging then 300 elseif selectedId == card.id then 250 elseif hoveredId == card.id then 270 else 220,
				friction = if isDragging then 20 elseif selectedId == card.id then 18 elseif hoveredId == card.id then 16 else 20,
				mass = if isDragging then 0.85 elseif hoveredId == card.id then 0.92 else 1,
			})
		end
	end, { cards, mode, hoveredId, selectedId, draggingId, dragPosition })

	React.useEffect(function()
		local moveConn
		local endConn

		if draggingId then
			moveConn = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					setDragPosition(UserInputService:GetMouseLocation())
				end
			end)

			endConn = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local id = draggingId
					local currentPos = dragPosition or UserInputService:GetMouseLocation()
					local index = findIndex(cards, id)

					setDraggingId(nil)
					setHoveredId(nil)

					if index then
						local base = baseLayoutFor(index, #cards, mode)
						local dx = currentPos.X - base.x

						if dx > THROW_DISTANCE then
							local spring = springsRef.current[id]
							setThrowFlashPos(Vector2.new(currentPos.X, currentPos.Y))

							flashSpringRef.current:setGoal({
								opacity = 0.45,
								scale = 1.8,
							}, {
								tension = 320,
								friction = 14,
								mass = 0.8,
							})

							task.delay(0.06, function()
								flashSpringRef.current:setGoal({
									opacity = 0,
									scale = 2.4,
								}, {
									tension = 250,
									friction = 18,
									mass = 1,
								})
							end)

							spring:setGoal({
								x = currentPos.X + 820,
								y = currentPos.Y - 180,
								size = 34,
								rotation = 42,
								glow = 2.7,
								opacity = 0,
							}, {
								tension = 320,
								friction = 14,
								mass = 0.8,
								impulse = 180,
							})

							task.delay(0.2, function()
								setCards(function(current)
									local updated = removeById(current, id)
									if #updated > 0 then
										local nextIndex = math.clamp(index, 1, #updated)
										setSelectedId(updated[nextIndex].id)
									else
										setSelectedId(nil)
									end
									return updated
								end)
							end)
						else
							setDragPosition(nil)
						end
					end
				end
			end)
		end

		return function()
			if moveConn then
				moveConn:Disconnect()
			end
			if endConn then
				endConn:Disconnect()
			end
		end
	end, { draggingId, dragPosition, cards, mode })

	local function moveSelected(delta)
		local index = findIndex(cards, selectedId)
		if not index then
			return
		end

		local newIndex = index + delta
		if newIndex < 1 or newIndex > #cards then
			return
		end

		setCards(function(current)
			local out = cloneArray(current)
			out[index], out[newIndex] = out[newIndex], out[index]
			return out
		end)
	end

	local function removeSelected()
		local index = findIndex(cards, selectedId)
		if not index then
			return
		end

		local id = selectedId
		local spring = springsRef.current[id]
		local base = baseLayoutFor(index, #cards, mode)

		spring:setGoal({
			x = base.x,
			y = base.y + 180,
			size = -12,
			rotation = 0,
			glow = 0,
			opacity = 0,
		}, {
			tension = 260,
			friction = 18,
			mass = 0.9,
		})

		task.delay(0.18, function()
			setCards(function(current)
				local updated = removeById(current, id)
				if #updated > 0 then
					local nextIndex = math.clamp(index, 1, #updated)
					setSelectedId(updated[nextIndex].id)
				else
					setSelectedId(nil)
				end
				return updated
			end)
		end)
	end

	local function resetDeck()
		springsRef.current = {}
		bindingsRef.current = {}
		setCards(cloneArray(INITIAL_CARDS))
		setHoveredId(nil)
		setSelectedId("aether")
		setDraggingId(nil)
		setDragPosition(nil)
		setMode("fan")
	end

	local function onStartDrag(id)
		setSelectedId(id)
		setDraggingId(id)
		setDragPosition(UserInputService:GetMouseLocation())
	end

	local children = {
		Background = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(7, 9, 15),
		}, {
			Gradient = e("UIGradient", {
				Rotation = 32,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 23, 38)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 16)),
				}),
			}),
		}),

		Title = e("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 24),
			Size = UDim2.fromOffset(520, 38),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Ripple Deck Playground",
			Font = Enum.Font.GothamBold,
			TextSize = 30,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		Subtitle = e("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 60),
			Size = UDim2.fromOffset(760, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Drag cards, tilt them with the cursor, throw to remove, or switch between fan and stack mode.",
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(190, 198, 212),
		}),

		Controls = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 100),
			Size = UDim2.fromOffset(900, 52),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			ToggleMode = e("TextButton", {
				Size = UDim2.fromOffset(130, 42),
				BackgroundColor3 = Color3.fromRGB(32, 42, 70),
				Text = mode == "fan" and "Switch to Stack" or "Switch to Fan",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				AutoButtonColor = false,
				[React.Event.MouseButton1Click] = function()
					setMode(function(current)
						if current == "fan" then
							return "stack"
						end
						return "fan"
					end)
				end,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
			}),

			MoveLeft = e("TextButton", {
				Size = UDim2.fromOffset(105, 42),
				BackgroundColor3 = Color3.fromRGB(24, 26, 38),
				Text = "Move Left",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				AutoButtonColor = false,
				[React.Event.MouseButton1Click] = function()
					moveSelected(-1)
				end,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
			}),

			MoveRight = e("TextButton", {
				Size = UDim2.fromOffset(110, 42),
				BackgroundColor3 = Color3.fromRGB(24, 26, 38),
				Text = "Move Right",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				AutoButtonColor = false,
				[React.Event.MouseButton1Click] = function()
					moveSelected(1)
				end,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
			}),

			Remove = e("TextButton", {
				Size = UDim2.fromOffset(100, 42),
				BackgroundColor3 = Color3.fromRGB(54, 34, 70),
				Text = "Remove",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				AutoButtonColor = false,
				[React.Event.MouseButton1Click] = removeSelected,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
			}),

			Reset = e("TextButton", {
				Size = UDim2.fromOffset(100, 42),
				BackgroundColor3 = Color3.fromRGB(24, 46, 62),
				Text = "Reset",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				AutoButtonColor = false,
				[React.Event.MouseButton1Click] = resetDeck,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 14) }),
			}),
		}),

		Info = e("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(34, 540),
			Size = UDim2.fromOffset(620, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Selected: " .. tostring(selectedId or "none") .. "   |   Mode: " .. mode,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(224, 230, 242),
		}),
	}

	for index, card in ipairs(cards) do
		local binding = bindingsRef.current[card.id]

		local positionBinding = binding:map(function(value)
			return UDim2.fromOffset(value.x, value.y)
		end)

		local sizeBinding = binding:map(function(value)
			return UDim2.fromOffset(CARD_W + value.size, CARD_H + value.size)
		end)

		local rotationBinding = binding:map(function(value)
			return value.rotation
		end)

		local glowSizeBinding = binding:map(function(value)
			return UDim2.fromOffset(
				CARD_W + value.size + 28 + value.glow * 22,
				CARD_H + value.size + 28 + value.glow * 22
			)
		end)

		local glowTransparencyBinding = binding:map(function(value)
			return math.clamp(0.9 - value.glow * 0.12, 0.52, 0.92)
		end)

		local bgTransparencyBinding = binding:map(function(value)
			return math.clamp(0.08 + (1 - value.opacity) * 0.55, 0.02, 0.8)
		end)

		local strokeThicknessBinding = binding:map(function(value)
			return 1.2 + value.glow * 1.3
		end)

		local strokeTransparencyBinding = binding:map(function(value)
			return math.clamp(0.45 - value.glow * 0.18, 0.04, 0.6)
		end)

		local zIndex = 10 + index
		if hoveredId == card.id then
			zIndex += 20
		end
		if selectedId == card.id then
			zIndex += 40
		end
		if draggingId == card.id then
			zIndex += 100
		end

		local isDragging = draggingId == card.id

		if isDragging then
			local base = baseLayoutFor(index, #cards, mode)

			children["Ghost_" .. card.id] = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(base.x, base.y),
				Size = UDim2.fromOffset(CARD_W + 12, CARD_H + 12),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.94,
				ZIndex = 4,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 24),
				}),
				UIStroke = e("UIStroke", {
					Color = card.accent,
					Thickness = 1.5,
					Transparency = 0.6,
				}),
			})
		end

		children["Card_" .. card.id] = e(DeckCard, {
			card = card,
			bindings = {
				position = positionBinding,
				size = sizeBinding,
				rotation = rotationBinding,
				glowSize = glowSizeBinding,
				glowTransparency = glowTransparencyBinding,
				bgTransparency = bgTransparencyBinding,
				strokeThickness = strokeThicknessBinding,
				strokeTransparency = strokeTransparencyBinding,
			},
			zIndex = zIndex,
			isSelected = selectedId == card.id,
			isDragging = isDragging,
			onHover = setHoveredId,
			onSelect = setSelectedId,
			onStartDrag = onStartDrag,
		})
	end

	local flashBinding = flashBindingRef.current
	children.ThrowFlash = e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(throwFlashPos.X, throwFlashPos.Y),
		Size = flashBinding:map(function(value)
			local s = 40 + value.scale * 90
			return UDim2.fromOffset(s, s)
		end),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = flashBinding:map(function(value)
			return math.clamp(1 - value.opacity, 0, 1)
		end),
		ZIndex = 200,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		UIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = flashBinding:map(function(value)
				return math.clamp(1 - value.opacity * 0.8, 0, 1)
			end),
		}),
	})

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, children)
end

return RippleDeckDemo