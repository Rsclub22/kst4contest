--[[
  strip-wiki-links.lua – pandoc Lua filter for KST4Contest documentation
  -----------------------------------------------------------------------
  1. Removes language-switch blockquotes (GitHub Wiki navigation) that
     are not relevant in the printed PDF manual.
  2. Converts internal GitHub-wiki-style links (no http/https prefix) to
     plain text, keeping the display label.
  3. Replaces flag emoji and other symbols that XeLaTeX cannot render with
     plain-text equivalents.
--]]

-- Map of emoji / special Unicode sequences → plain-text replacements.
-- Add more entries here as needed.
local EMOJI_MAP = {
  -- Flag sequences
  ["\xF0\x9F\x87\xAC\xF0\x9F\x87\xA7"] = "[EN]",  -- 🇬🇧
  ["\xF0\x9F\x87\xA9\xF0\x9F\x87\xAA"] = "[DE]",  -- 🇩🇪
  -- Status symbols
  ["\xE2\x9C\x85"] = "[OK]",   -- ✅
  ["\xE2\x9D\x8C"] = "[--]",   -- ❌
  -- Misc symbols used in tables / text
  ["\xF0\x9F\x94\xB4"] = "[red]",    -- 🔴
  ["\xF0\x9F\x9F\xA1"] = "[yellow]", -- 🟡
  ["\xF0\x9F\x9F\xA2"] = "[green]",  -- 🟢
}

--- Replace emoji in a plain string.
local function replace_emoji(text)
  for pattern, replacement in pairs(EMOJI_MAP) do
    text = text:gsub(pattern, replacement)
  end
  return text
end

--- Filter: remove language-switch blockquotes from PDF output.
-- These blockquotes appear in every wiki page for GitHub navigation
-- but are not needed in the printed manual.
function BlockQuote(el)
  local text = pandoc.utils.stringify(el)
  if text:find("Du liest gerade die deutsche Version") or
     text:find("You are reading the English version") then
    return {}
  end
  return el
end

--- Filter: convert internal wiki links to their display text.
function Link(el)
  local target = el.target
  -- Keep external URLs and in-document anchor links unchanged.
  if target:match("^https?://") or target:match("^#") or target:match("^mailto:") then
    return el
  end
  -- Internal wiki link – return the inlines (display label) as-is.
  return el.content
end

--- Filter: replace emoji sequences in plain Str elements.
function Str(el)
  local replaced = replace_emoji(el.text)
  if replaced ~= el.text then
    return pandoc.Str(replaced)
  end
  return el
end
