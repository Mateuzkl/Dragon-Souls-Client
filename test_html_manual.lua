-- Manual HTML Test
-- Execute this in the terminal to test HTML system

print("=== TESTE MANUAL HTML ===")

-- Test basic HTML loading
local testWidget = g_ui.loadHtml('modules/game_htmltest/basic_test.html', g_ui.getRootWidget())

if testWidget then
    print("✅ HTML carregado com sucesso!")
    testWidget:setMarginTop(50)
    testWidget:setMarginLeft(50)
    testWidget:show()
    testWidget:raise()
    
    print("✅ Widget HTML visível na tela!")
    print("ID:", testWidget:getId())
    print("Classe:", testWidget:getClassName())
    
    -- Test keyboard binding
    g_keyboard.bindKeyDown('Ctrl+T', function()
        if testWidget:isVisible() then
            testWidget:hide()
            print("HTML Test: Escondido")
        else
            testWidget:show()
            testWidget:raise()
            print("HTML Test: Mostrado")
        end
    end)
    
    print("✅ Pressione Ctrl+T para toggle do painel HTML!")
    
else
    print("❌ ERRO: Falha ao carregar HTML!")
end

print("=== FIM DO TESTE ===")