# Loci Studio
> **Sandbox Interativo de Sprites 32px (8 Direções) & Animações da Loci2D**

Esta ferramenta foi criada especialmente para que artistas possam testar, visualizar e ajustar sprites e animações em tempo real sem precisar compilar o código do jogo nem rodar o servidor backend.

O Loci Studio suporta o novo padrão de produção do **PixelLab (32px com 8 direções nativas e sequências quadro a quadro com `metadata.json`)**, mantendo total retrocompatibilidade com o modelo procedural legado de 16x16.

A ferramenta é totalmente agnóstica e modular: qualquer personagem pode ter suas habilidades e parâmetros de movimento configurados livremente.

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

### 1. Personagens (`sprites/characters/`)
- **Padrão PixelLab (32px, 8 Direções):**
  Coloque a pasta descompactada exportada do PixelLab contendo o arquivo `metadata.json` (ex: `sprites/characters/arya/`).
  O Loci Studio detecta automaticamente as 8 direções (`south`, `south-west`, `west`, `north-west`, `north`, `north-east`, `east`, `south-east`) e animações frame-a-frame (como os 17 quadros do `ataque_furia`).
- **Formato Legado (16x16):**
  Coloque arquivos `.png` avulsos diretamente na pasta (ex: `warrior.png`, `arya_legada_16x16.png`).

### 2. Habilidades e Efeitos (`sprites/skills/`)
Coloque aqui imagens de projéteis, arcos de corte ou efeitos visuais (ex: `fireball.png`, `blade_throw.png`, `slash_arc.png`, `frost_nova.png`).

> **Dica:** Não é necessário reiniciar o programa ao adicionar novos sprites ou pastas. Na tela inicial, basta pressionar **F5** ou clicar em **"Recarregar Pastas"**.

---

## Funcionalidades

### 1. Tela Inicial: Seletor de Assets e Arquétipos
- **Seleção de Personagens:** Lista automática com identificação de formato (`[PixelLab 8-Dir]` vs `[16x16]`).
- **Inspeção 360° no Preview:** Gire o personagem nas 8 direções com as teclas **Q** / **E** ou os botões de rotação.
- **Configuração Modular dos 4 Slots de Habilidades:**
  Cada slot pode ser configurado com um dos 4 arquétipos:
  - **Melee (Golpe):** Dispara avanço (*lunge*) e corte — se o personagem tiver animação dedicada (ex: `ataque_furia` da Arya), os 17 quadros reais são reproduzidos na direção correta.
  - **Projétil (Disparo):** Disparo à distância que arremessa o projétil em linha reta.
  - **Dash (Investida):** Deslocamento rápido com rastro translúcido do personagem.
  - **Área / Aura (AoE):** Anel de impacto e partículas expansivas no chão.
- **Botão [▶ Play] no Preview:** Teste visual instantâneo de cada habilidade dentro da caixa de preview antes de entrar na arena.

### 2. Arena Interativa (Playground)
- **Movimentação em 8 Direções:** Use `W, A, S, D` ou as `Setas` para andar pelo cenário com orientação visual nas 8 direções.
- **Caminhar no Lugar:** Pressione a tecla `P` ou clique no botão para avaliar o ciclo de caminhada continuamente.
- **Disparo de Habilidades:** Teclas `1`, `2`, `3`, `4`, `Espaço` ou clique no HUD para disparar os slots configurados.
- **Painel Lateral de Ajustes em Tempo Real:**
  - **Velocidade de Movimento:** Slider dinâmico (`speed` em px/s).
  - **FPS de Animação PixelLab:** Slider de taxa de quadros (8 a 30 FPS) para avaliar a fluidez dos frames reais.
  - **Caminhada e Balanço:** Ajuste de ritmo dos passos (`step_frequency`), inclinação lateral (`max_tilt_deg`), elevação do passo (`bob_pixels`) e compressão (`squash_amount`).
  - **Distâncias das Habilidades:** Sliders adaptativos para alcance, lunge, distância de dash e raio de área.
  - **Câmera & Visual:** Zoom calibrado para 32px (`2x`, `3x`, `4x`, `6x`) e estilos de fundo de arena.
- **Exportação de Configuração:** Clique em **"Exportar Configuração"** para gerar um código Lua pronto (`config_export.lua`) com a ficha técnica completa do personagem para o jogo e Trello.

---

## Licença

Este projeto está licenciado sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para obter mais detalhes.
