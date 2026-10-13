# Loci Studio
> **Sandbox Interativo de Sprites, Animações e Habilidades 16x16 da Loci2D**

Esta ferramenta foi criada especialmente para que artistas possam testar, visualizar e ajustar sprites e animações em tempo real sem precisar compilar o código do jogo nem rodar o servidor backend.

---

## Como Executar

### Linux / macOS
Abra o terminal nesta pasta e execute:
```bash
./run.sh
```
*(Ou diretamente com `love .` se você tiver o Love2D instalado).*

### Windows
Execute o arquivo:
```text
run.bat
```

---

## Onde colocar seus Sprites

Salve as imagens em formato `.png` (idealmente 16x16 pixels) dentro das pastas correspondentes:

- `sprites/characters/`: Coloque aqui seus personagens (ex: `arya.png`, `mage.png`, `warrior.png`).
- `sprites/skills/`: Coloque aqui efeitos visuais de habilidades, armas ou projéteis (ex: `blade.png`, `fireball.png`, `slash.png`).

> **Dica:** Não é necessário reiniciar o programa ao adicionar novos sprites. Na tela inicial do Loci Studio, basta clicar no botão **"Recarregar Pastas (F5)"**.

---

## Funcionalidades

### 1. Tela Inicial (Seletor de Sprites)
- Escolha qual personagem carregar da pasta `sprites/characters/`.
- Mapeamento das 4 habilidades da barra de ação:
  - **Slot 1:** Ataque Básico (Slash / Golpe Corpo a Corpo).
  - **Slot 2:** Habilidade Especial 1 (Buff / Defesa / Aura).
  - **Slot 3:** Habilidade Especial 2 (Investida / Dash / Giratório).
  - **Slot 4:** Habilidade Especial 3 (Arremesso à Distância / Projétil).

### 2. Arena Interativa (Playground)
- **Movimentação:** Use `W, A, S, D` ou as `Setas` para andar pelo cenário com o balanço procedural (pêndulo e elevação).
- **Caminhar no Lugar:** Pressione a tecla `P` ou clique no botão para manter o personagem andando no mesmo lugar e avaliar o ciclo sem segurar teclas.
- **Disparo de Habilidades:** Use as teclas `1`, `2`, `3`, `4`, `Espaço` ou o clique do mouse.
- **Painel Lateral de Ajustes em Tempo Real:**
  - **Distâncias das Habilidades:** Configure a distância do avanço do golpe (`lunge`), a distância do dash e o alcance máximo do projétil em pixels.
  - **Caminhada Procedural:** Ajuste o ritmo dos passos (`step_frequency`), inclinação lateral (`max_tilt_deg`), elevação vertical do pé (`bob_pixels`) e efeito squash & stretch.
  - **Visual:** Alterne o zoom (2x, 4x, 6x, 8x), cor de fundo e sombra nos pés.
- **Exportar Configuração:** Clique em **"Exportar Configuração"** para gerar um código Lua pronto com todos os números ajustados para copiar e colar no card do Trello ou enviar aos programadores.
