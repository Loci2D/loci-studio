# Loci Studio
> **Sandbox Interativo de Sprites, Animações e Habilidades 16x16 da Loci2D**

Esta ferramenta foi criada especialmente para que artistas possam testar, visualizar e ajustar sprites e animações em tempo real sem precisar compilar o código do jogo nem rodar o servidor backend.

A ferramenta é totalmente agnóstica e modular: qualquer personagem (seja guerreiro corpo a corpo, mago à distância, arqueiro ou suporte) pode ter suas habilidades configuradas livremente.

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
- `sprites/skills/`: Coloque aqui efeitos visuais de habilidades, armas ou projéteis (ex: `fireball.png`, `blade_throw.png`, `slash_arc.png`, `frost_nova.png`).

> **Dica:** Não é necessário reiniciar o programa ao adicionar novos sprites. Na tela inicial do Loci Studio, basta clicar no botão **"Recarregar Pastas (F5)"**.

---

## Funcionalidades

### 1. Tela Inicial: Seletor de Assets e Arquétipos
- **Escolha do Personagem:** Selecione qualquer sprite presente na pasta `sprites/characters/`.
- **Configuração Modular dos 4 Slots de Habilidades:**
  Cada um dos 4 botões de habilidade pode ser configurado de forma independente com um dos 4 arquétipos de ação:
  - **Melee (Golpe):** Golpe físico corpo a corpo com recuo, avanço (*lunge*) e corte/impacto.
  - **Projétil (Disparo):** Disparo à distância que arremessa o sprite selecionado em linha reta até o limite.
  - **Dash (Investida):** Deslocamento rápido do próprio personagem com rastro e efeito visual.
  - **Área / Aura (AoE):** Anel de choque e partículas expansivas ao redor do personagem.
- **Vínculo de Sprite:** Cada slot pode utilizar um sprite da pasta `sprites/skills/` ou o efeito procedural padrão.

### 2. Arena Interativa (Playground)
- **Movimentação:** Use `W, A, S, D` ou as `Setas` para andar pelo cenário com o balanço procedural (pêndulo e elevação).
- **Caminhar no Lugar:** Pressione a tecla `P` ou clique no botão para manter o personagem andando no mesmo lugar e avaliar o ciclo sem segurar teclas.
- **Disparo de Habilidades:** Use as teclas `1`, `2`, `3`, `4`, `Espaço` ou o clique do mouse para testar os 4 slots configurados.
- **Painel Lateral de Ajustes em Tempo Real:**
  - **Distâncias das Habilidades:** Sliders dinâmicos que se adaptam aos tipos escolhidos nos slots (avanço do golpe para Melee, distância para Dash, alcance máximo para Projétil, raio para Área).
  - **Caminhada Procedural:** Ajuste o ritmo dos passos (`step_frequency`), inclinação lateral (`max_tilt_deg`), elevação vertical do pé (`bob_pixels`) e compressão (`squash_amount`).
  - **Visual & Câmera:** Alterne o zoom (2x, 4x, 6x, 8x), estilos de fundo e sombra nos pés.
- **Exportação de Configuração:** Clique em **"Exportar Configuração"** para gerar um código Lua pronto (`config_export.lua`) com a definição completa de cada slot para colar direto no card do Trello ou repassar aos desenvolvedores.
