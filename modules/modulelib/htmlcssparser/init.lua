-- HTML/CSS Parser initialization
-- This module provides advanced HTML parsing with CSS support

-- Load required modules
local ElementNode = dofile('htmlcssparser/ElementNode.lua')
local CssParse = dofile('htmlcssparser/CssParse.lua')

-- Export to global scope for use in other modules
_G.ElementNode = ElementNode
_G.CssParse = CssParse

print("[HTMLCSSParser] Advanced HTML/CSS parsing system loaded")

return {
    ElementNode = ElementNode,
    CssParse = CssParse
}