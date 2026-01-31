<div align="center">

# 🐉 Dragon Souls Client

### Custom OTClientV8 for Protocol 11.00

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=flat-square)](https://github.com/Mateuzkl/Dragon-Souls-Client)
[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)](https://github.com/Mateuzkl/Dragon-Souls-Client/releases)
[![Protocol](https://img.shields.io/badge/protocol-11.00-orange?style=flat-square)](https://github.com/Mateuzkl/Dragon-Souls-Client)
[![License](https://img.shields.io/badge/license-MIT-red?style=flat-square)](LICENSE)

*Cliente oficial do Dragon Souls RPG, otimizado para a melhor experiência na Terra Média.*

</div>

---

## 📖 Sobre

O **Dragon Souls Client** é uma modificação robusta do **OTClientV8**, adaptada especificamente para suportar as funcionalidades únicas do protocolo 11.00 e o ambiente imersivo de *O Senhor dos Anéis* do servidor Dragon Souls.

---

## 🌟 Funcionalidades (Features)

Este cliente inclui diversas melhorias e adaptações para garantir estabilidade e performance:

*   ✅ **Protocolo 11.00 Nativo:** Suporte completo para assets e mecânicas da versão 11.00.
*   ✅ **Extended Viewport:** Renderização de mapa expandida para monitores modernos/ultrawide (requer suporte do servidor).
*   ✅ **Otimização de Renderização:** Melhorias no uso de GPU para taxas de quadros mais estáveis.

*   ✅ **Smart Walking:** Sistema de movimentação preditiva para menor latência percebida.

---

## 🛠️ Compilação e Instalação

### Windows (Recomendado)

Utilize o **vcpkg** para gerenciar as dependências de forma fácil e consistente.

> [!WARNING]
> **Atenção:** Versões recentes do vcpkg podem causar incompatibilidade. Utilize a versão homologada abaixo.

1.  **Download do vcpkg homologado (aprox. 5GB):**
    [Baixar vcpkg.rar](https://www.mediafire.com/file/ipd4qzohe9jwji3/vcpkg.rar/file)

2.  **Instalação:**
    Extraia o conteúdo diretamente em `C:\vcpkg`.

3.  **Bootstrap e Integração:**
    Abra o PowerShell como Administrador e execute:
    ```powershell
    cd C:\vcpkg
    .\bootstrap-vcpkg.bat
    .\vcpkg.exe integrate install
    ```

2.  **Compile com Visual Studio 2022:**
    *   Abra a pasta do projeto no VS 2022.
    *   Selecione o Backend (DirectX ou OpenGL).
    *   Selecione a Plataforma (`x64` recomendado).
    *   Clique em **Build**. O VS irá baixar e instalar todas as libs automaticamente via vcpkg.

### Linux (Ubuntu 22.04)

```bash
sudo apt update
sudo apt install git curl build-essential cmake gcc g++ pkg-config autoconf libtool libglew-dev -y
cd ~
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh && cd ..
git clone https://github.com/Mateuzkl/Dragon-Souls-Client.git
cd Dragon-Souls-Client && mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake .. && make -j$(nproc)
```

---

## 🤝 Como Contribuir

Quer ajudar a melhorar o cliente? Toda ajuda é bem-vinda!

### 🔧 Enviando Pull Requests (PR)

Se você implementou uma melhoria ou corrigiu um bug:

1.  Faça um **Fork** deste repositório.
2.  Crie uma nova branch para sua feature (`git checkout -b feature/minha-melhoria`).
3.  **Importante:** Se for uma nova funcionalidade, torne-a opcional!
    *   Use `g_game.enableFeature` para ativar/desativar.
    *   Isso garante compatibilidade e evita rejeição do PR.
4.  Commit suas alterações (`git commit -m 'Adiciona: Nova funcionalidade de UI'`).
5.  Push para a sua branch (`git push origin feature/minha-melhoria`).
6.  Abra um **Pull Request** descrevendo suas mudanças.

### 🐛 Reportando Bugs

Encontrou um problema? Ajude-nos a corrigir!

1.  Vá para a aba **Issues** no GitHub.
2.  Crie uma **New Issue**.
3.  Seja detalhista:
    *   Descreva o bug.
    *   Passos para reproduzir ("Como fazer ele acontecer?").
    *   Anexe screenshots ou logs (terminal/console) se possível.
    *   Informe a versão do seu Windows/Linux.

---

## 📞 Suporte

Para dúvidas técnicas ou suporte direto:

*   **Discord:** `g.joker`
*   **Issues:** Use para bugs confirmados.

---

<div align="center">

**Dragon Souls RPG Team**

</div>
