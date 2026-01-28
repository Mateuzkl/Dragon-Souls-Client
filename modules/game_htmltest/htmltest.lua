local htmlTestUI
local isVisible = false

-- Função para toggle da visibilidade
local function toggleHTMLTest()
    if htmlTestUI then
        isVisible = not isVisible
        htmlTestUI:setVisible(isVisible)
        
        if isVisible then
            htmlTestUI:show()
            htmlTestUI:raise()
            htmlTestUI:focus()
            print("[HTML Test] Painel aberto - Pressione Ctrl+U para fechar")
        else
            htmlTestUI:hide()
            print("[HTML Test] Painel fechado - Pressione Ctrl+U para abrir")
        end
    else
        print("[HTML Test] ERRO: htmlTestUI é nil!")
    end
end

function init()
    print("[HTML Test] ===== INICIALIZANDO MÓDULO HTML TEST =====")
    
    -- Carregar a UI HTML personalizada
    htmlTestUI = g_ui.loadHtml('user_test.html', modules.game_interface.getMapPanel())
    
    if htmlTestUI then
        print("[HTML Test] ✅ UI HTML básica carregada com sucesso!")
        
        -- Configurar posição e visibilidade
        htmlTestUI:setMarginTop(200)
        htmlTestUI:setMarginLeft(100)
        htmlTestUI:setVisible(true)
        htmlTestUI:show()
        htmlTestUI:raise()
        
        -- Bind da tecla de atalho Ctrl+U
        g_keyboard.bindKeyDown('Ctrl+U', toggleHTMLTest)
        
        print("[HTML Test] ✅ Módulo carregado! Pressione Ctrl+U para toggle")
        print("[HTML Test] 🎉 SISTEMA HTML FUNCIONANDO! 🎉")
        
    else
        print("[HTML Test] ❌ ERRO: Falha ao carregar UI HTML básica!")
        
        -- Tentar carregar o arquivo simples
        htmlTestUI = g_ui.loadHtml('simple_test.html', modules.game_interface.getMapPanel())
        
        if htmlTestUI then
            print("[HTML Test] ✅ UI HTML simples carregada!")
            htmlTestUI:setMarginTop(200)
            htmlTestUI:setMarginLeft(100)
            htmlTestUI:setVisible(true)
            htmlTestUI:show()
            htmlTestUI:raise()
            g_keyboard.bindKeyDown('Ctrl+U', toggleHTMLTest)
            print("[HTML Test] ✅ Pressione Ctrl+U para toggle")
        else
            print("[HTML Test] ❌ ERRO: Todos os arquivos HTML falharam!")
        end
    end
end

function terminate()
    print("[HTML Test] ===== FINALIZANDO MÓDULO HTML TEST =====")
    
    -- Unbind da tecla
    g_keyboard.unbindKeyDown('Ctrl+U')
    
    -- Destruir UI
    if htmlTestUI then
        htmlTestUI:destroy()
        htmlTestUI = nil
        print("[HTML Test] UI HTML destruída")
    end
    
    print("[HTML Test] Módulo finalizado")
end