
# RedMew style guide

Not strictly enforced, but we appreciate if you try to remain consistent with our standards.

* Include at least a brief one-line summary in a LuaDoc (a comment with 3 dashes `---`) before each function

* A LuaDoc with extended summary, @params, and @return is encouraged. ([LuaDoc Manual][1])

* Tabs are 4 spaces

* Keep each line of code to a readable length. Under 140 characters when reasonable.

* Never leave trailing whitespace.

* End each file with a newline.

* Newlines are unix `\n`

* Strings should normally be encased in `'` single-quotes. For strings with single quotes inside them, `"` double-quotes can be used.

* Use spaces around operators, after commas, colons, and semicolons.

```lua
sum = 1 + 2
a, b = 1, 2
if 1 < 2 then
    game.print("Hi")
end
```

* No spaces after `(`, `[`, `{` or before `]`, `)`, `}`.

```lua
table = {1, 2, 3}
table[1]
```

* Use empty lines between `functions` and to break up functions into logical paragraphs.

```lua
local function some_function()
    local data = global.data
    local format = global.string_format
    local string = Utils.manipulate(data, format)

    game.print(string)
end

local function say_hello()
    game.print("Hello")
end
```

[1]:[http://keplerproject.github.io/luadoc/manual.htm]
