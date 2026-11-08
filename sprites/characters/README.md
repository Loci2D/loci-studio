# Pasta de Personagens (`sprites/characters/`)

O Loci Studio suporta dois formatos de personagens:

### 1. Novo Padrão de Produção: PixelLab (32px, 8 Direções)
Coloque a pasta exportada diretamente pelo PixelLab contendo o arquivo `metadata.json` e as subpastas de estados e animações.

Exemplo:
```text
sprites/characters/
└── arya/
    ├── metadata.json
    ├── Rotacao/rotations/
    ├── andando/rotations/
    ├── correndo/rotations/
    ├── ataque/rotations/
    ├── ataque_furia/
    │   ├── rotations/
    │   └── animations/ataque_furia/ (17 frames por direção)
    ├── espada_voa/rotations/
    └── morte/rotations/
```

- **Resolução & Canvas:** Personagens escala 32px (canvas com padding de 44x40 ou 48x48 dependendo do rastro da arma).
- **8 Direções:** `south`, `south-east`, `east`, `north-east`, `north`, `north-west`, `west`, `south-west`.
- **Animações Frame-a-Frame:** O Loci Studio reproduzirá as sequências completas de frames (ex: 17 quadros do `ataque_furia`) e usará as rotações estáticas em repouso.

---

### 2. Formato Legado: Sprite Único (16x16)
Arquivos `.png` avulsos colocados diretamente nesta pasta continuam funcionando no modo procedural legado (com flip horizontal esquerda/direita).

Exemplo:
- `arya_legada_16x16.png`
- `warrior.png`
