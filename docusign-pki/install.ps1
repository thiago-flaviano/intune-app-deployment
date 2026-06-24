# =============================================================================
# install.ps1 — Wrapper de Deploy: DocuSign PKI
# =============================================================================
# Autor      : Thiago Flaviano
# Data       : Junho/2026
# Repositorio: github.com/thiago-flaviano/intune-app-deployment
# -----------------------------------------------------------------------------
# Contexto de execucao : User (Per-User app — instala em %LocalAppData%)
# Comando no Intune    : powershell.exe -ExecutionPolicy Bypass -File install.ps1
# -----------------------------------------------------------------------------
# Por que este wrapper existe?
#
# O DocuSign PKI e um app Per-User — instala no perfil do usuario, nao no
# sistema. Em tentativas anteriores de deploy direto via Intune, o processo
# de instalacao ficava em loop infinito ("Instalando..." sem progresso).
#
# Causa raiz diagnosticada:
#   1. Processos "fantasmas" de tentativas anteriores travados na memoria
#      impediam novas instalacoes de iniciar corretamente.
#   2. O parametro silencioso estava errado (/silent em vez de /S).
#      O instalador NSIS e case-sensitive — so aceita /S com S maiusculo.
#
# Este wrapper resolve os dois problemas antes de chamar o instalador.
# =============================================================================

# -----------------------------------------------------------------------------
# ETAPA 1 — Encerrar processos em execucao
# -----------------------------------------------------------------------------
# Se houver uma instancia do DocuSign rodando (ou travada de tentativa
# anterior), o instalador nao consegue sobrescrever os arquivos em uso.
# Encerramos forcadamente antes de prosseguir.
#
# -ErrorAction SilentlyContinue: nao gera erro se o processo nao existir.
# Isso garante que o script funcione tanto em maquinas com quanto sem
# o DocuSign instalado.
# -----------------------------------------------------------------------------

Write-Host "[1/3] Encerrando processos DocuSign em execucao..."

Stop-Process -Name "DocuSignPKI" -Force -ErrorAction SilentlyContinue

Write-Host "      Processos encerrados (ou nenhum encontrado)."

# -----------------------------------------------------------------------------
# ETAPA 2 — Aguardar liberacao dos arquivos
# -----------------------------------------------------------------------------
# Apos encerrar o processo, o sistema operacional precisa de um breve momento
# para liberar os handles de arquivo. Sem essa pausa, o instalador pode
# encontrar arquivos ainda "em uso" logo apos o Stop-Process.
# -----------------------------------------------------------------------------

Write-Host "[2/3] Aguardando liberacao de recursos..."

Start-Sleep -Seconds 3

# -----------------------------------------------------------------------------
# ETAPA 3 — Executar o instalador em modo silencioso
# -----------------------------------------------------------------------------
# Parametros importantes:
#
#   -FilePath ".\\DocuSignPKI.exe"
#     Caminho relativo ao .intunewin — o Intune extrai tudo na mesma pasta.
#
#   -ArgumentList "/S"
#     Modo silencioso do NSIS. ATENCAO: /S com S MAIUSCULO.
#     O NSIS e case-sensitive — /silent ou /s (minusculo) sao ignorados
#     e o instalador abre a interface grafica, travando o deploy.
#
#   -Wait
#     O script aguarda o instalador terminar antes de continuar.
#     Sem -Wait, o Intune pode reportar sucesso antes da instalacao
#     terminar, gerando falsos positivos na detection rule.
#
#   -NoNewWindow
#     Nao abre janela adicional — instalacao totalmente silenciosa.
# -----------------------------------------------------------------------------

Write-Host "[3/3] Iniciando instalacao silenciosa do DocuSign PKI..."

Start-Process `
    -FilePath ".\DocuSignPKI.exe" `
    -ArgumentList "/S" `
    -Wait `
    -NoNewWindow

Write-Host "      Instalacao concluida."

# -----------------------------------------------------------------------------
# RESULTADO ESPERADO
# -----------------------------------------------------------------------------
# Apos a execucao bem-sucedida, o DocuSign PKI estara instalado em:
#   %LocalAppData%\DocuSignPKI\
#
# A Detection Rule no Intune valida:
#   Tipo   : File
#   Caminho: %LocalAppData%\DocuSignPKI
#   Arquivo: DocuSignPKI.exe
#   Metodo : File or folder exists
#
# Usando %LocalAppData% (variavel de ambiente) em vez de caminho fixo
# (ex: C:\Users\Thiago\AppData\Local\...) garante que a regra funcione
# para qualquer usuario na maquina — principio de identidade dinamica.
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "Deploy concluido. Verifique em %LocalAppData%\DocuSignPKI\"
