-- Module Library for HTML Extensions
-- Provides advanced CSS parsing and event handling for HTML system

function init()
    print("[ModuleLib] Loading simplified HTML parsing extensions...")
    
    -- Load basic parsing extensions only
    dofile('ext/parse.lua')
    dofile('ext/parseevent.lua')
    dofile('ext/translator.lua')
    
    print("[ModuleLib] ✅ Simplified HTML system ready!")
    print("[ModuleLib] Features loaded:")
    print("[ModuleLib] - Basic CSS parsing")
    print("[ModuleLib] - Event handling system")
    print("[ModuleLib] - HTML element translation")
end

function terminate()
    print("[ModuleLib] Module library terminated")
end