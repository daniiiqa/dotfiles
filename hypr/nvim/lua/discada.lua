-- discada: el colorscheme que sigue al look, como rola y vato. Los colores
-- salen del theme de kitty que tenga puesto el look (wallust o la paleta fija)
-- y el estilo de ~/.config/rola/look.json: bordes de las ventanas flotantes,
-- cómo se marca lo elegido, tinte (color, phosphor, ink) y transparencia.
-- Al cambiar de look o de wallpaper se recarga solo.
--
--   :colorscheme discada   (LazyVim ya lo pone: lua/plugins/discada.lua)

local M = {}

local uv = vim.uv or vim.loop
local cfg = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"))

local function read(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local t = f:read("*a")
  f:close()
  return t
end

-- el último `include` de kitty.conf que trae colores (igual que vato)
local function kitty_theme()
  local dir = cfg .. "/kitty"
  local conf = dir .. "/kitty.conf"
  local text = read(conf) or ""
  local found
  for line in text:gmatch("[^\n]+") do
    local p = line:match("^%s*include%s+(.-)%s*$")
    if p then
      p = p:gsub("^~/", os.getenv("HOME") .. "/")
      if p:sub(1, 1) ~= "/" then p = dir .. "/" .. p end
      local t = read(p)
      if t and (t:find("^background") or t:find("\nbackground")) then found = p end
    end
  end
  return found or conf
end

local function look_file()
  local own = cfg .. "/vato/look.json"
  return uv.fs_stat(own) and own or (cfg .. "/rola/look.json")
end

local function rgb(h) return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16) end

-- a sobre b con la proporción t (1 = a)
local function mix(a, b, t)
  local r1, g1, b1 = rgb(a)
  local r2, g2, b2 = rgb(b)
  local m = function(x, y) return math.floor(x * t + y * (1 - t) + 0.5) end
  return string.format("#%02x%02x%02x", m(r1, r2), m(g1, g2), m(b1, b2))
end

local function palette()
  local c = {}
  for k, v in (read(kitty_theme()) or ""):gmatch("([%w_]+)%s+(#%x%x%x%x%x%x)") do c[k] = v end
  if not (c.background and c.foreground) then return nil end
  return c
end

local function look()
  local ok, v = pcall(vim.json.decode, read(look_file()) or "{}")
  return ok and type(v) == "table" and v or {}
end

local BORDERS = {
  rounded = "rounded", plain = "single", double = "double", thick = "bold", none = "none",
  dashed = { "┌", "┄", "┐", "┆", "┘", "┄", "└", "┆" },
}

function M.border()
  local b = look().borders or "auto"
  if b == "auto" then
    local r = vim.fn.system({ "hyprctl", "getoption", "decoration:rounding", "-j" })
    local ok, v = pcall(vim.json.decode, r)
    return (ok and type(v) == "table" and (v.int or 0) > 0) and "rounded" or "single"
  end
  return BORDERS[b] or "rounded"
end

function M.load()
  local c = palette()
  if not c then
    vim.cmd("colorscheme habamax")
    return
  end
  local L = look()
  local tint = L.tint or "color"
  local clear = L.transparent ~= false

  local bg, fg = c.background, c.foreground
  local primary = c.color12 or fg
  local accent = c.color11 or primary
  if tint == "phosphor" then fg = primary end
  if tint == "ink" then primary = fg end

  local s = {
    bg = bg, fg = fg, primary = primary, accent = accent,
    muted = mix(fg, bg, 0.55), border = mix(fg, bg, 0.22), hl = mix(primary, bg, 0.35),
    line = mix(fg, bg, 0.07), float = mix(fg, bg, 0.04),
    red = c.color9 or c.color1 or "#e0452b", green = c.color10 or c.color2 or "#8fa86a",
    yellow = c.color11 or c.color3 or accent, cyan = c.color14 or c.color6 or primary,
    magenta = c.color13 or c.color5 or primary, blue = c.color12 or c.color4 or primary,
  }
  -- sintaxis: con "color" cada cosa su color de la paleta; phosphor es todo un
  -- solo fósforo en tonos; ink es tinta: negritas y cursivas, casi sin color
  local syn
  if tint == "phosphor" then
    syn = { kw = primary, fn = mix(primary, bg, 0.9), str = mix(primary, bg, 0.75), type = primary,
            const = mix(primary, bg, 0.85), op = mix(primary, bg, 0.7), prop = mix(primary, bg, 0.8) }
  elseif tint == "ink" then
    syn = { kw = fg, fn = fg, str = mix(fg, bg, 0.7), type = fg, const = fg, op = mix(fg, bg, 0.75), prop = fg }
  else
    syn = { kw = s.magenta, fn = s.blue, str = s.green, type = s.yellow, const = s.red,
            op = s.cyan, prop = c.color6 or s.cyan }
  end
  local ink = tint == "ink"

  local sel = L.select or "fill"
  local visual = { bg = s.hl }
  local pmsel = sel == "inverse" and { bg = primary, fg = bg, bold = true }
    or sel == "bar" and { bg = s.line, fg = primary, bold = true }
    or { bg = s.hl, fg = fg, bold = true }

  local none = clear and "NONE" or bg
  local floatbg = clear and "NONE" or s.float

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
  local r, g, b = rgb(bg)
  vim.o.background = (0.299 * r + 0.587 * g + 0.114 * b) > 140 and "light" or "dark"
  vim.g.colors_name = "discada"

  local H = {
    -- interfaz
    Normal = { fg = fg, bg = none }, NormalNC = { fg = fg, bg = none },
    NormalFloat = { fg = fg, bg = floatbg }, FloatBorder = { fg = s.border, bg = floatbg },
    FloatTitle = { fg = primary, bg = floatbg, bold = true }, FloatFooter = { fg = s.muted, bg = floatbg },
    WinSeparator = { fg = s.border }, VertSplit = { link = "WinSeparator" },
    SignColumn = { bg = none }, FoldColumn = { fg = s.border, bg = none }, Folded = { fg = s.muted, bg = s.line },
    LineNr = { fg = s.border }, CursorLineNr = { fg = primary, bold = true },
    CursorLine = { bg = s.line }, CursorColumn = { bg = s.line }, ColorColumn = { bg = s.line },
    Cursor = { fg = bg, bg = fg }, TermCursor = { fg = bg, bg = fg },
    Visual = visual, VisualNOS = visual,
    Search = { fg = bg, bg = accent }, IncSearch = { fg = bg, bg = primary, bold = true }, CurSearch = { link = "IncSearch" },
    Substitute = { fg = bg, bg = s.red },
    MatchParen = { fg = accent, bold = true, underline = true },
    Pmenu = { fg = fg, bg = floatbg }, PmenuSel = pmsel, PmenuSbar = { bg = s.line }, PmenuThumb = { bg = s.border },
    PmenuKind = { fg = primary, bg = floatbg }, PmenuExtra = { fg = s.muted, bg = floatbg },
    StatusLine = { fg = fg, bg = clear and "NONE" or s.line }, StatusLineNC = { fg = s.muted, bg = clear and "NONE" or s.line },
    TabLine = { fg = s.muted, bg = none }, TabLineFill = { bg = none }, TabLineSel = { fg = primary, bold = true },
    WinBar = { fg = s.muted, bg = none }, WinBarNC = { fg = s.border, bg = none },
    Title = { fg = primary, bold = true }, Directory = { fg = primary },
    NonText = { fg = s.border }, Whitespace = { fg = s.border }, EndOfBuffer = { fg = bg },
    SpecialKey = { fg = s.border }, Conceal = { fg = s.muted },
    ModeMsg = { fg = primary, bold = true }, MoreMsg = { fg = primary }, Question = { fg = primary },
    ErrorMsg = { fg = s.red, bold = true }, WarningMsg = { fg = s.yellow },
    QuickFixLine = { bg = s.hl }, WildMenu = pmsel,
    SpellBad = { sp = s.red, undercurl = true }, SpellCap = { sp = s.yellow, undercurl = true },
    SpellRare = { sp = s.magenta, undercurl = true }, SpellLocal = { sp = s.cyan, undercurl = true },
    DiffAdd = { bg = mix(s.green, bg, 0.2) }, DiffChange = { bg = mix(s.blue, bg, 0.15) },
    DiffDelete = { fg = s.red, bg = mix(s.red, bg, 0.15) }, DiffText = { bg = mix(s.blue, bg, 0.35) },
    Added = { fg = s.green }, Changed = { fg = s.blue }, Removed = { fg = s.red },

    -- sintaxis
    Comment = { fg = s.muted, italic = true },
    Constant = { fg = syn.const }, String = { fg = syn.str, italic = ink }, Character = { fg = syn.str },
    Number = { fg = syn.const }, Boolean = { fg = syn.const, bold = ink }, Float = { link = "Number" },
    Identifier = { fg = fg }, Function = { fg = syn.fn, bold = ink },
    Statement = { fg = syn.kw, bold = ink }, Keyword = { fg = syn.kw, bold = ink },
    Conditional = { link = "Keyword" }, Repeat = { link = "Keyword" }, Label = { fg = syn.kw },
    Exception = { link = "Keyword" }, Operator = { fg = syn.op },
    PreProc = { fg = syn.kw }, Include = { link = "Keyword" }, Define = { link = "PreProc" }, Macro = { fg = syn.const },
    Type = { fg = syn.type, bold = ink }, StorageClass = { link = "Keyword" }, Structure = { link = "Type" },
    Typedef = { link = "Type" }, Special = { fg = syn.op }, SpecialChar = { fg = syn.op },
    Delimiter = { fg = s.muted }, Tag = { fg = syn.kw }, Debug = { fg = s.red },
    Underlined = { underline = true }, Bold = { bold = true }, Italic = { italic = true },
    Error = { fg = s.red }, Todo = { fg = bg, bg = accent, bold = true },

    -- treesitter
    ["@variable"] = { fg = fg }, ["@variable.builtin"] = { fg = syn.const, italic = true },
    ["@variable.parameter"] = { fg = fg, italic = true }, ["@variable.member"] = { fg = syn.prop },
    ["@property"] = { fg = syn.prop }, ["@field"] = { fg = syn.prop },
    ["@constant"] = { link = "Constant" }, ["@constant.builtin"] = { fg = syn.const, bold = true },
    ["@module"] = { fg = syn.type }, ["@namespace"] = { fg = syn.type },
    ["@string"] = { link = "String" }, ["@string.escape"] = { fg = syn.op }, ["@string.regexp"] = { fg = syn.op },
    ["@string.special.url"] = { fg = primary, underline = true },
    ["@function"] = { link = "Function" }, ["@function.builtin"] = { fg = syn.fn, italic = true },
    ["@function.call"] = { link = "Function" }, ["@function.method"] = { link = "Function" },
    ["@constructor"] = { fg = syn.type }, ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { fg = syn.kw, italic = true }, ["@keyword.return"] = { fg = syn.kw, bold = true },
    ["@type"] = { link = "Type" }, ["@type.builtin"] = { fg = syn.type, italic = true },
    ["@attribute"] = { fg = syn.op }, ["@punctuation"] = { fg = s.muted }, ["@punctuation.bracket"] = { fg = s.muted },
    ["@punctuation.delimiter"] = { fg = s.muted }, ["@operator"] = { link = "Operator" },
    ["@tag"] = { fg = syn.kw }, ["@tag.attribute"] = { fg = syn.prop }, ["@tag.delimiter"] = { fg = s.muted },
    ["@comment"] = { link = "Comment" },
    ["@comment.todo"] = { link = "Todo" }, ["@comment.error"] = { fg = bg, bg = s.red, bold = true },
    ["@comment.warning"] = { fg = bg, bg = s.yellow, bold = true }, ["@comment.note"] = { fg = bg, bg = primary, bold = true },
    ["@markup.heading"] = { fg = primary, bold = true }, ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true }, ["@markup.link"] = { fg = primary, underline = true },
    ["@markup.link.url"] = { fg = primary, underline = true }, ["@markup.raw"] = { fg = syn.str },
    ["@markup.list"] = { fg = accent }, ["@markup.quote"] = { fg = s.muted, italic = true },
    ["@diff.plus"] = { fg = s.green }, ["@diff.minus"] = { fg = s.red }, ["@diff.delta"] = { fg = s.blue },
    ["@lsp.type.comment"] = {},

    -- diagnósticos y LSP
    DiagnosticError = { fg = s.red }, DiagnosticWarn = { fg = s.yellow },
    DiagnosticInfo = { fg = primary }, DiagnosticHint = { fg = s.cyan }, DiagnosticOk = { fg = s.green },
    DiagnosticUnderlineError = { sp = s.red, undercurl = true }, DiagnosticUnderlineWarn = { sp = s.yellow, undercurl = true },
    DiagnosticUnderlineInfo = { sp = primary, undercurl = true }, DiagnosticUnderlineHint = { sp = s.cyan, undercurl = true },
    DiagnosticVirtualTextError = { fg = s.red, bg = mix(s.red, bg, 0.1) },
    DiagnosticVirtualTextWarn = { fg = s.yellow, bg = mix(s.yellow, bg, 0.1) },
    DiagnosticVirtualTextInfo = { fg = primary, bg = mix(primary, bg, 0.1) },
    DiagnosticVirtualTextHint = { fg = s.cyan, bg = mix(s.cyan, bg, 0.1) },
    DiagnosticUnnecessary = { fg = s.muted },
    LspReferenceText = { bg = s.line }, LspReferenceRead = { bg = s.line }, LspReferenceWrite = { bg = s.line, underline = true },
    LspInlayHint = { fg = s.border, italic = true }, LspSignatureActiveParameter = { fg = accent, bold = true },
    LspInfoBorder = { link = "FloatBorder" },

    -- git
    GitSignsAdd = { fg = s.green }, GitSignsChange = { fg = s.blue }, GitSignsDelete = { fg = s.red },
    MiniDiffSignAdd = { fg = s.green }, MiniDiffSignChange = { fg = s.blue }, MiniDiffSignDelete = { fg = s.red },

    -- lo que trae LazyVim
    SnacksPicker = { link = "NormalFloat" }, SnacksPickerBorder = { link = "FloatBorder" },
    SnacksPickerTitle = { link = "FloatTitle" }, SnacksPickerMatch = { fg = accent, bold = true },
    SnacksPickerDir = { fg = s.muted }, SnacksPickerPrompt = { fg = primary },
    SnacksPickerListCursorLine = pmsel, SnacksPickerSelected = { fg = accent },
    SnacksDashboardHeader = { fg = primary }, SnacksDashboardIcon = { fg = primary },
    SnacksDashboardKey = { fg = accent, bold = true }, SnacksDashboardDesc = { fg = fg },
    SnacksDashboardFooter = { fg = s.muted }, SnacksDashboardSpecial = { fg = accent },
    SnacksIndent = { fg = s.line }, SnacksIndentScope = { fg = s.border },
    SnacksNotifierInfo = { fg = primary }, SnacksNotifierBorderInfo = { fg = s.border },
    WhichKey = { fg = accent }, WhichKeyGroup = { fg = primary }, WhichKeyDesc = { fg = fg },
    WhichKeySeparator = { fg = s.muted }, WhichKeyNormal = { link = "NormalFloat" }, WhichKeyBorder = { link = "FloatBorder" },
    BlinkCmpMenu = { link = "Pmenu" }, BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpMenuSelection = pmsel, BlinkCmpLabelMatch = { fg = accent, bold = true },
    BlinkCmpKind = { fg = primary }, BlinkCmpDoc = { link = "NormalFloat" }, BlinkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpGhostText = { fg = s.border, italic = true },
    FlashLabel = { fg = bg, bg = accent, bold = true }, FlashMatch = { fg = primary }, FlashCurrent = { fg = accent },
    FlashBackdrop = { fg = s.muted },
    NoiceCmdlinePopupBorder = { link = "FloatBorder" }, NoiceCmdlineIcon = { fg = primary },
    NoiceCmdlinePopupTitle = { link = "FloatTitle" },
    BufferLineFill = { bg = none }, BufferLineBufferSelected = { fg = primary, bold = true },
    BufferLineIndicatorSelected = { fg = primary },
    TroubleNormal = { link = "Normal" }, TodoBgTODO = { link = "Todo" },
    MiniIconsAzure = { fg = s.blue }, MiniIconsBlue = { fg = s.blue }, MiniIconsCyan = { fg = s.cyan },
    MiniIconsGreen = { fg = s.green }, MiniIconsGrey = { fg = s.muted }, MiniIconsOrange = { fg = accent },
    MiniIconsPurple = { fg = s.magenta }, MiniIconsRed = { fg = s.red }, MiniIconsYellow = { fg = s.yellow },
    TelescopeBorder = { link = "FloatBorder" }, TelescopeSelection = pmsel, TelescopeMatching = { fg = accent, bold = true },
    NeoTreeNormal = { link = "Normal" }, NeoTreeNormalNC = { link = "Normal" },
    LazyNormal = { link = "NormalFloat" }, MasonNormal = { link = "NormalFloat" },
  }
  for name, spec in pairs(H) do vim.api.nvim_set_hl(0, name, spec) end

  -- la terminal de nvim con la misma paleta que kitty
  for i = 0, 15 do
    if c["color" .. i] then vim.g["terminal_color_" .. i] = c["color" .. i] end
  end

  -- bordes de las ventanas flotantes según el look
  if vim.fn.has("nvim-0.11") == 1 then
    local bd = M.border()
    pcall(function() vim.o.winborder = type(bd) == "table" and table.concat(bd, ",") or bd end)
  end
end

-- volver a cargar cuando cambia el look: kitty.conf (otro include), el theme
-- (wallust lo reescribe con cada wallpaper) o look.json
local watching
function M.watch()
  if watching then return end
  watching = uv.new_timer()
  local stamp
  local function now()
    local t = {}
    for _, p in ipairs({ cfg .. "/kitty/kitty.conf", kitty_theme(), look_file() }) do
      local st = uv.fs_stat(p)
      t[#t + 1] = p .. ":" .. (st and st.mtime.sec .. "." .. st.mtime.nsec or "-")
    end
    return table.concat(t, "|")
  end
  stamp = now()
  watching:start(1500, 1500, vim.schedule_wrap(function()
    local n = now()
    if n ~= stamp then
      stamp = n
      if vim.g.colors_name == "discada" then
        M.load()
        vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "discada" })
      end
    end
  end))
end

return M
