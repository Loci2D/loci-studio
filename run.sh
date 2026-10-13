#!/usr/bin/env bash
cd "$(dirname "$0")"

if ! command -v love &> /dev/null; then
    echo "[ERRO] Love2D não encontrado no PATH."
    echo "Instale o Love2D: https://love2d.org ou no Ubuntu/Debian: sudo apt install love"
    exit 1
fi

echo "Iniciando Loci Studio..."
love .
