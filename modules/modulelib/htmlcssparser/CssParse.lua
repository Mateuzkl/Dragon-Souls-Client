-- CSS Parser for HTML system
local CssParse = {}
CssParse.mt = { __index = CssParse }

function CssParse:new()
    local instance = {
        objects = {},
        current_selector = "",
        current_declarations = {},
        in_block = false,
        buffer = ""
    }
    return setmetatable(instance, CssParse.mt)
end

function CssParse:parse(css_content)
    self.objects = {}
    self.buffer = css_content:gsub("/%*.--%*/", "") -- Remove comments
    self.buffer = self.buffer:gsub("\n", " "):gsub("\r", " ") -- Normalize whitespace
    
    local i = 1
    local len = #self.buffer
    
    while i <= len do
        local char = self.buffer:sub(i, i)
        
        if char == '{' then
            self:start_block()
        elseif char == '}' then
            self:end_block()
        elseif self.in_block then
            self:parse_declaration(i)
            -- Skip to next declaration or end of block
            local next_semicolon = self.buffer:find(';', i)
            local next_brace = self.buffer:find('}', i)
            if next_semicolon and (not next_brace or next_semicolon < next_brace) then
                i = next_semicolon
            elseif next_brace then
                i = next_brace - 1
            else
                break
            end
        else
            self:parse_selector(i)
            -- Skip to opening brace
            local next_brace = self.buffer:find('{', i)
            if next_brace then
                i = next_brace - 1
            else
                break
            end
        end
        
        i = i + 1
    end
end

function CssParse:start_block()
    self.in_block = true
    self.current_declarations = {}
end

function CssParse:end_block()
    if self.current_selector ~= "" then
        table.insert(self.objects, {
            selector = self.current_selector:trim(),
            declarations = self.current_declarations
        })
    end
    
    self.in_block = false
    self.current_selector = ""
    self.current_declarations = {}
end

function CssParse:parse_selector(start_pos)
    local brace_pos = self.buffer:find('{', start_pos)
    if brace_pos then
        self.current_selector = self.buffer:sub(start_pos, brace_pos - 1):trim()
    end
end

function CssParse:parse_declaration(start_pos)
    local semicolon_pos = self.buffer:find(';', start_pos)
    local brace_pos = self.buffer:find('}', start_pos)
    
    local end_pos = semicolon_pos
    if brace_pos and (not semicolon_pos or brace_pos < semicolon_pos) then
        end_pos = brace_pos
    end
    
    if end_pos then
        local declaration = self.buffer:sub(start_pos, end_pos - 1):trim()
        local colon_pos = declaration:find(':')
        
        if colon_pos then
            local property = declaration:sub(1, colon_pos - 1):trim()
            local value = declaration:sub(colon_pos + 1):trim()
            
            -- Remove quotes from values
            value = value:gsub('^["\']', ''):gsub('["\']$', '')
            
            self.current_declarations[property] = value
        end
    end
end

function CssParse:get_objects()
    return self.objects
end

-- String utility functions
if not string.trim then
    function string:trim()
        return self:match("^%s*(.-)%s*$")
    end
end

if not string.split then
    function string:split(delimiter)
        local result = {}
        local pattern = "(.-)" .. delimiter
        local last_end = 1
        local s, e, cap = self:find(pattern, 1)
        
        while s do
            if s ~= 1 or cap ~= "" then
                table.insert(result, cap)
            end
            last_end = e + 1
            s, e, cap = self:find(pattern, last_end)
        end
        
        if last_end <= #self then
            cap = self:sub(last_end)
            table.insert(result, cap)
        end
        
        return result
    end
end

return CssParse