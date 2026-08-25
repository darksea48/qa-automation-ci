<#
================================================================================
  subir-a-github.ps1
  Taller 1 - Evaluación Unidad II - Automatización de Pruebas (ADP1323)

  1. Limpia archivos de bloqueo y temporales que quedaron en .git
  2. Crea los commits pendientes con mensajes descriptivos
  3. Configura el remoto de GitHub y sube el proyecto

  USO:
      cd C:\dev\qa-automation-ci

      # Solo limpiar y hacer los commits (sin subir todavía):
      powershell -ExecutionPolicy Bypass -File .\subir-a-github.ps1

      # Limpiar, commitear y subir a GitHub:
      powershell -ExecutionPolicy Bypass -File .\subir-a-github.ps1 -Usuario TU-USUARIO-GITHUB
================================================================================
#>

param(
    [string]$Usuario = "",
    [string]$Repositorio = "qa-automation-ci"
)

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $PSScriptRoot

function Paso($texto) {
    Write-Host ""
    Write-Host "== $texto" -ForegroundColor Cyan
}

# ============================================================================
#  1. Limpieza de archivos de bloqueo y temporales
# ============================================================================
Paso "Limpiando archivos de bloqueo de Git"

$bloqueos = @(".git\HEAD.lock", ".git\index.lock", ".git\objects\maintenance.lock")
foreach ($b in $bloqueos) {
    if (Test-Path $b) {
        Remove-Item $b -Force
        Write-Host "   eliminado: $b" -ForegroundColor DarkGray
    }
}

$temporales = Get-ChildItem ".git\objects" -Recurse -Filter "tmp_obj_*" -ErrorAction SilentlyContinue
if ($temporales) {
    $temporales | Remove-Item -Force
    Write-Host "   eliminados $($temporales.Count) objetos temporales" -ForegroundColor DarkGray
}

# Verificación de integridad: confirma que el repositorio quedó sano
$fsck = git fsck --no-progress 2>&1 | Select-String -Pattern "error|fatal"
if ($fsck) {
    Write-Host "   ATENCION - git fsck reporta problemas:" -ForegroundColor Red
    $fsck | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
} else {
    Write-Host "   Repositorio integro." -ForegroundColor Green
}

# ============================================================================
#  2. Commits pendientes
# ============================================================================
Paso "Creando los commits pendientes"

# --- Normalización de fin de línea -----------------------------------------
git add .gitattributes .gitignore 2>&1 | Out-Null
git add --renormalize . 2>&1 | Out-Null

if (git diff --cached --name-only) {
    git commit -q `
        -m "chore: normaliza fin de linea con .gitattributes" `
        -m "Evita que los archivos aparezcan como modificados por completo al alternar entre Windows (CRLF) y el runner Linux del pipeline (LF)."
    Write-Host "   OK - normalizacion de fin de linea" -ForegroundColor Green
} else {
    Write-Host "   (sin cambios de normalizacion pendientes)" -ForegroundColor DarkGray
}

# --- Permisos del pipeline --------------------------------------------------
if (Test-Path ".github\workflows\ci.yml") {
    $ci = Get-Content ".github\workflows\ci.yml" -Raw
    if ($ci -match "(?m)^permissions:") {
        git add ".github\workflows\ci.yml" 2>&1 | Out-Null
        if (git diff --cached --name-only) {
            git commit -q `
                -m "ci: concede permisos minimos explicitos al pipeline" `
                -m "GitHub entrega por defecto un token de solo lectura. Se declaran checks:write para publicar el reporte de pruebas, contents:write para el dashboard e issues:write para el issue automatico. Los pasos accesorios se marcan continue-on-error para que no tumben un build cuyas pruebas pasaron."
            Write-Host "   OK - permisos del pipeline" -ForegroundColor Green
        }
    } else {
        Write-Host "   ATENCION - ci.yml todavia es la version antigua." -ForegroundColor Red
        Write-Host "   Reemplazalo con el archivo que te envie antes de subir." -ForegroundColor Red
    }
}

# --- Script generador de evidencias ----------------------------------------
git add capturar-evidencias.ps1 subir-a-github.ps1 2>&1 | Out-Null
if (git diff --cached --name-only) {
    git commit -q -m "chore: agrega scripts de generacion de evidencias y publicacion"
    Write-Host "   OK - scripts de apoyo" -ForegroundColor Green
}

# --- Evidencias de la ejecución local ---------------------------------------
if (Test-Path "capturas") {
    git add capturas 2>&1 | Out-Null
    if (git diff --cached --name-only) {
        git commit -q `
            -m "docs: incorpora evidencias de la ejecucion local de las pruebas" `
            -m "Salida de las suites unitaria y BDD, arbol de dependencias, historial de versionado, fallo intencional y prueba de performance."
        Write-Host "   OK - evidencias de ejecucion" -ForegroundColor Green
    }
}

# --- Cualquier cosa que haya quedado suelta ---------------------------------
$sueltos = git status --porcelain
if ($sueltos) {
    Write-Host ""
    Write-Host "   Quedaron archivos sin commitear:" -ForegroundColor Yellow
    git status --short
    Write-Host "   Revisalos y agregalos manualmente si corresponde." -ForegroundColor DarkGray
}

# ============================================================================
#  3. Historial resultante
# ============================================================================
Paso "Historial del repositorio"
git log --oneline --graph --all | Select-Object -First 25

# ============================================================================
#  4. Publicación en GitHub
# ============================================================================
if ($Usuario -eq "") {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  COMMITS LISTOS. Para subir a GitHub:" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Crea el repositorio en https://github.com/new" -ForegroundColor White
    Write-Host "     Nombre: $Repositorio   |   Visibilidad: Public" -ForegroundColor White
    Write-Host "     NO marques 'Add a README file'" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Vuelve aqui y ejecuta:" -ForegroundColor White
    Write-Host "     .\subir-a-github.ps1 -Usuario TU-USUARIO-GITHUB" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Paso "Publicando en GitHub"

$url = "https://github.com/$Usuario/$Repositorio.git"

$remotoActual = git remote get-url origin 2>$null
if ($remotoActual) {
    Write-Host "   El remoto 'origin' ya existe: $remotoActual" -ForegroundColor DarkGray
    if ($remotoActual -ne $url) {
        git remote set-url origin $url
        Write-Host "   Actualizado a: $url" -ForegroundColor Yellow
    }
} else {
    git remote add origin $url
    Write-Host "   Remoto agregado: $url" -ForegroundColor Green
}

Write-Host ""
Write-Host "   Subiendo... (si pide credenciales, se abrira el navegador)" -ForegroundColor DarkGray
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  PROYECTO SUBIDO" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Repositorio : https://github.com/$Usuario/$Repositorio" -ForegroundColor White
    Write-Host "  Pipeline    : https://github.com/$Usuario/$Repositorio/actions" -ForegroundColor White
    Write-Host ""
    Write-Host "  El workflow arranca solo. Espera 1-3 minutos y saca las capturas" -ForegroundColor White
    Write-Host "  04, 05, 08, 13, 15 y 16 desde la pestana Actions." -ForegroundColor White
    Write-Host ""
    Start-Process "https://github.com/$Usuario/$Repositorio/actions"
} else {
    Write-Host ""
    Write-Host "   El push no se completo (codigo $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "   Causas frecuentes:" -ForegroundColor DarkGray
    Write-Host "     - El repositorio aun no existe en GitHub: crealo en https://github.com/new" -ForegroundColor DarkGray
    Write-Host "     - El nombre de usuario esta mal escrito" -ForegroundColor DarkGray
    Write-Host "     - Falta autenticacion: instala Git Credential Manager o usa un token" -ForegroundColor DarkGray
}
