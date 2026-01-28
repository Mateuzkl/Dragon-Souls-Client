# 🎉 HTML Test Module - Módulo de Teste HTML

Este módulo demonstra o sistema HTML implementado no OTClient Dragon Souls.

## 📋 Funcionalidades

- ✅ Carregamento de arquivos HTML
- ✅ Conversão de elementos HTML para widgets OTClient
- ✅ Suporte a `<div>`, `<label>`, `<select>`, `<option>`
- ✅ Parsing de atributos CSS básicos (width, height)
- ✅ Event handlers para `onchange` em ComboBoxes
- ✅ Integração completa com sistema Lua

## 🎮 Como Usar

1. **Carregar o módulo**: O módulo carrega automaticamente quando o cliente inicia
2. **Abrir painel**: Pressione `Ctrl+U` para abrir/fechar o painel de teste
3. **Testar funcionalidades**: Use os ComboBoxes para testar os event handlers
4. **Ver logs**: Observe o console para mensagens de debug

## 🔧 Estrutura do Módulo

```
game_htmltest/
├── htmltest.otmod     # Definição do módulo
├── htmltest.lua       # Lógica Lua do módulo
├── htmltest.html      # Interface HTML
└── README.md          # Este arquivo
```

## 📝 Exemplo de HTML

```html
<div id="testPanel" style="width: 400px; height: 300px;">
    <label>🎉 OLÁ TESTE HTML! 🎉</label>
    <select id="testComboBox" onchange="onTestComboBoxChange(event)">
        <option value="opcao1">Opção 1 - Vermelho</option>
        <option value="opcao2">Opção 2 - Azul</option>
    </select>
</div>
```

## 🎯 Event Handlers

O sistema suporta event handlers JavaScript-like:

```javascript
// No HTML
<select onchange="onTestComboBoxChange(event)">

// No Lua
function onTestComboBoxChange(event)
    print("Selecionado:", event.text)
end
```

## 🚀 Comandos de Teste

- `Ctrl+U` - Abre/fecha o painel de teste
- Os testes automáticos executam 1 segundo após o carregamento

## 📊 Logs de Debug

O módulo gera logs detalhados:
```
[HTML Test] Inicializando módulo de teste HTML...
[HTML Test] ✓ UI HTML carregada com sucesso!
[HTML Test] ✓ Painel principal encontrado
[HTML Test] ✓ ComboBox de teste encontrado
[HTML Test] Módulo carregado! Pressione Ctrl+U para abrir/fechar o painel
[HTML Test] 🎉 OLÁ TESTE HTML - Sistema funcionando! 🎉
```

## 🎨 Personalização

Você pode modificar:
- `htmltest.html` - Para alterar a interface
- `htmltest.lua` - Para adicionar nova lógica
- Teclas de atalho e posicionamento

## ✨ Recursos Demonstrados

1. **Carregamento HTML**: `g_ui.loadHtml('htmltest.html', parent)`
2. **Acesso por ID**: `htmlTestUI:getChildById('testComboBox')`
3. **Event Binding**: Handlers automáticos para `onchange`
4. **Styling CSS**: Suporte básico a `width` e `height`
5. **Integração Lua**: Comunicação bidirecional HTML ↔ Lua

---

**Desenvolvido para Dragon Souls Client**  
Sistema HTML implementado com sucesso! 🎉