local function FixSelection(selector)
    local lastPos = nil
    while true do
        local pos = selector:find('%[', lastPos)
        if not pos then
            break
        end
        lastPos = selector:find(']', lastPos)
        local res = nil
        local cmd = selector:sub(pos + 1, lastPos - 1)
        local values = cmd:split('=')
        if #values > 1 then
            res = '[' .. values[1] .. '="' .. values[2] .. '"]'
        end
        if res then
            selector = table.concat { selector:sub(1, pos - 1), res, selector:sub(lastPos + 2) }
        end
    end
    return selector
end

local function parseStyleElement(content, cssList, checkExist)
    local css = CssParse.new()
    css:parse(content)
    local data = css:get_objects()
    for _, o in ipairs(data) do
        table.insert(cssList, {
            selector = FixSelection(o.selector:trim()),
            attrs = o.declarations,
            checkExist = checkExist
        })
    end
end

local function processDisplayStyle(el)
    -- Simplified display processing without hasAnchoredLayout
    if not el.style then
        return
    end
    
    if el.style.display == 'none' then
        el.widget:setVisible(false)
    end
end

local function processFloatStyle(el)
    -- Simplified float processing without hasAnchoredLayout
    if not el.style or not el.style.float then
        return
    end
    
    -- Basic float implementation using margins
    if el.style.float == 'right' then
        el.widget:setMarginRight(0)
    elseif el.style.float == 'left' then
        el.widget:setMarginLeft(0)
    end
end

return parseStyleElement, processDisplayStyle, processFloatStyle