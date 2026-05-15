--!strict

local tweenService = game:GetService "TweenService"

-- stylua: ignore
local keys: { [string]: string } = {
	Frame          = "BackgroundTransparency",
	ImageLabel     = "ImageTransparency",
	ImageButton    = "ImageTransparency",
	TextLabel      = "TextTransparency",
	TextButton     = "TextTransparency",
	TextBox        = "TextTransparency",
	ScrollingFrame = "BackgroundTransparency",
	ViewportFrame  = "ImageTransparency",
	CanvasGroup    = "GroupTransparency",
	UIStroke       = "Transparency",
}

local defaultTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type modifiers = { [Instance]: string | { string } }

export type fadeConfig = {
	ignore: { Instance }?,
	modifiers: modifiers?,
	tweenInfo: TweenInfo?,
	watchDescendants: boolean?,
}

type instanceData = {
	props: { string },
	originals: { number },
	tweens: { Tween },
	destroyConn: RBXScriptConnection,
}

export type fade = {
	object: Instance,
	data: { [Instance]: instanceData },
	ignore: { [Instance]: true },
	modifiers: modifiers?,
	tweenInfo: TweenInfo,
	watchDescendants: boolean,
	descendantConn: RBXScriptConnection?,

	fadeOut: (self: fade) -> (),
	fadeIn: (self: fade) -> (),
	force: (self: fade, transparency: number) -> (),
	custom: (self: fade, transparency: number, tweenInfo: TweenInfo?) -> (),
	refresh: (self: fade) -> (),
	destroy: (self: fade) -> (),
}

local function cancelInstanceTweens(entry: instanceData)
	local tweens = entry.tweens
	for i = 1, #tweens do
		tweens[i]:Cancel()
	end
	table.clear(tweens)
end

local function unregisterInstance(self: fade, instance: Instance)
	local entry = self.data[instance]
	if not entry then
		return
	end

	cancelInstanceTweens(entry)
	entry.destroyConn:Disconnect()
	self.data[instance] = nil
end

local function registerInstance(self: fade, instance: Instance)
	if self.ignore[instance] then
		return
	end

	local props: { string } = {}
	local originals: { number } = {}
	local count = 0

	local defaultKey = keys[instance.ClassName]
	if defaultKey then
		count += 1
		props[count] = defaultKey
		originals[count] = (instance :: any)[defaultKey]
	end

	local modifier = self.modifiers and self.modifiers[instance]
	if modifier then
		if typeof(modifier) == "string" then
			if modifier ~= defaultKey then
				count += 1
				props[count] = modifier
				originals[count] = (instance :: any)[modifier]
			end
		else
			for i = 1, #modifier do
				local prop = modifier[i]
				if prop ~= defaultKey then
					count += 1
					props[count] = prop
					originals[count] = (instance :: any)[prop]
				end
			end
		end
	end

	if count == 0 then
		return
	end

	local entry: instanceData = {
		props = props,
		originals = originals,
		tweens = {},
		destroyConn = nil :: any,
	}

	entry.destroyConn = instance.Destroying:Connect(function()
		cancelInstanceTweens(entry)
		entry.destroyConn:Disconnect()
		self.data[instance] = nil
	end)

	self.data[instance] = entry
end

local function buildData(self: fade)
	for _, instance in self.object:QueryDescendants "GuiObject, UIStroke" do
		registerInstance(self, instance)
	end
end

local function tweenTo(self: fade, alpha: number, tweenInfo: TweenInfo?)
	local info = tweenInfo or self.tweenInfo

	for instance, entry in self.data do
		cancelInstanceTweens(entry)

		local props = entry.props
		local originals = entry.originals
		local goals: { [string]: number } = {}

		for i = 1, #props do
			local original = originals[i]
			goals[props[i]] = original + (1 - original) * alpha
		end

		local tween = tweenService:Create(instance :: any, info, goals)
		entry.tweens[1] = tween
		tween:Play()
	end
end

local function fadeOut(self: fade)
	tweenTo(self, 1)
end

local function fadeIn(self: fade)
	tweenTo(self, 0)
end

local function fadeForce(self: fade, transparency: number)
	for instance, entry in self.data do
		cancelInstanceTweens(entry)

		local props = entry.props
		local originals = entry.originals

		for i = 1, #props do
			local original = originals[i];
			(instance :: any)[props[i]] = original + (1 - original) * transparency
		end
	end
end

local function fadeCustom(self: fade, transparency: number, tweenInfo: TweenInfo?)
	tweenTo(self, transparency, tweenInfo)
end

local function fadeRefresh(self: fade)
	for instance in self.data do
		unregisterInstance(self, instance)
	end

	buildData(self)
end

local function fadeDestroy(self: fade)
	for instance, entry in self.data do
		cancelInstanceTweens(entry)
		entry.destroyConn:Disconnect()

		local props = entry.props
		local originals = entry.originals

		for i = 1, #props do
			(instance :: any)[props[i]] = originals[i]
		end
	end

	if self.descendantConn then
		self.descendantConn:Disconnect()
		self.descendantConn = nil
	end

	table.clear(self.data)
end

local function new(object: GuiBase2d): (config: fadeConfig?) -> fade
	return function(config: fadeConfig?): fade
		local ignoreSet: { [Instance]: true } = {}
		if config and config.ignore then
			for _, inst in config.ignore do
				ignoreSet[inst] = true
			end
		end

		local self: fade = {
			object = object,
			data = {},
			ignore = ignoreSet,
			modifiers = if config then config.modifiers else nil,
			tweenInfo = if config and config.tweenInfo then config.tweenInfo else defaultTweenInfo,
			watchDescendants = if config and config.watchDescendants then config.watchDescendants else false,
			descendantConn = nil,

			fadeOut = fadeOut,
			fadeIn = fadeIn,
			force = fadeForce,
			custom = fadeCustom,
			refresh = fadeRefresh,
			destroy = fadeDestroy,
		}

		buildData(self)

		if self.watchDescendants then
			self.descendantConn = object.DescendantAdded:Connect(function(descendant)
				registerInstance(self, descendant)
			end)
		end

		return self
	end
end

return {
	new = new,
}
