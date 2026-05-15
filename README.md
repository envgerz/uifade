# ui_fade

A small Luau utility for fading Roblox UI.

`ui_fade` lets you fade a `GuiBase2d` and its descendants without manually tweening every transparency property yourself. It keeps track of the original transparency values it finds, so fading back in restores the UI to the state it started in.

## Installation

Install with `pesde`:

```sh
pesde add envger/ui_fade
```

Then require it in your project:

```luau
local fadeUtil = require(path.to.ui_fade)
```

## Example

```luau
local fadeUtil = require(path.to.ui_fade)

local fade = fadeUtil.new(screenGui.MainFrame)({
	tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	modifiers = {
		[screenGui.MainFrame.Title] = { "TextTransparency", "TextStrokeTransparency" },
	},
})

fade:out()
task.wait(0.25)
fade:inFade()
```

## API

```luau
local fade = fadeUtil.new(rootObject)(config?)
```

Config:

- `ignore`: instances to skip
- `modifiers`: extra transparency properties per instance
- `tweenInfo`: tween settings
- `watchDescendants`: automatically track new descendants

Methods:

- `fade:out()`
- `fade:inFade()`
- `fade:force(transparency)`
- `fade:custom(transparency, tweenInfo?)`
- `fade:refresh()`
- `fade:destroy()`

## Defaults

The module includes built-in support for:

- `Frame`
- `ScrollingFrame`
- `ImageLabel`
- `ImageButton`
- `ViewportFrame`
- `TextLabel`
- `TextButton`
- `TextBox`
- `CanvasGroup`
- `UIStroke`