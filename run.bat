@echo off
echo Iniciando Loci Studio...
start "" love .
if %errorlevel% neq 0 (
    echo [ERRO] Nao foi possivel iniciar o Love2D. Certifique-se de que o love.exe esta no PATH ou instalado.
    pause
)
