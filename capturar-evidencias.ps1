<#
================================================================================
  capturar-evidencias.ps1
  Taller 1 - Evaluación Unidad II - Automatización de Pruebas (ADP1323)
 
  Ejecuta cada prueba del proyecto y guarda su salida en un archivo de texto
  numerado según la captura que le corresponde en el informe. Cada archivo se
  abre en el Bloc de notas para que lo captures con Win+Shift+S y lo pegues
  directamente en el documento Word.
 
  USO:
      cd C:\dev\qa-automation-ci
      powershell -ExecutionPolicy Bypass -File .\capturar-evidencias.ps1
 
  OPCIONES:
      -SinNotepad      Genera los archivos sin abrir el Bloc de notas
      -Solo "07"       Genera únicamente esa captura (ej: "01", "09", "11b")
================================================================================
#>
 
param(
    [switch]$SinNotepad,
    [string]$Solo = ""
)
 
# ------------------------------------------------------------------ preparación
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
 
$raiz    = $PSScriptRoot
$destino = Join-Path $raiz "capturas"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
 
function Toca($id) { return ($script:Solo -eq "" -or $script:Solo -eq $id) }
 
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  GENERADOR DE EVIDENCIAS - Taller 1, Unidad II" -ForegroundColor Cyan
Write-Host "  Destino: $destino" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
 
# -------------------------------------------------------------------- función base
function Grabar {
    param(
        [string]$Id,            # "01", "07", "11b"...
        [string]$Nombre,        # nombre corto para el archivo
        [string]$Titulo,        # descripción que va en el encabezado
        [string]$Comando,       # comando a ejecutar
        [switch]$SeEsperaFallo, # true cuando el build DEBE fallar
        [switch]$EsK6           # k6 devuelve 99 cuando un umbral no se cumple
    )
 
    if (-not (Toca $Id)) { return }
 
    $archivo = Join-Path $destino "captura-$Id-$Nombre.txt"
 
    Write-Host "[$Id] $Titulo" -ForegroundColor Yellow
    Write-Host "     > $Comando" -ForegroundColor DarkGray
 
    # cmd /c fusiona stderr en stdout y evita que PowerShell convierta las líneas
    # de error en objetos ErrorRecord (que saldrían en rojo y desordenados).
    $salida = cmd /c "$Comando 2>&1"
    $codigo = $LASTEXITCODE
 
    $encabezado = @(
        "================================================================================",
        "  CAPTURA $Id - $Titulo",
        "================================================================================",
        "  Comando ejecutado : $Comando",
        "  Fecha y hora      : $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')",
        "  Equipo            : $env:COMPUTERNAME",
        "  Usuario           : $env:USERNAME",
        "  Directorio        : $raiz",
        "  Codigo de salida  : $codigo",
        "================================================================================",
        ""
    )
 
    ($encabezado + $salida) | Out-File -FilePath $archivo -Encoding utf8
 
    if ($SeEsperaFallo) {
        if ($codigo -ne 0) {
            Write-Host "     OK - el build fallo como se esperaba (codigo $codigo)" -ForegroundColor Green
        } else {
            Write-Host "     ATENCION - se esperaba un fallo y el build paso" -ForegroundColor Red
        }
    } elseif ($EsK6 -and $codigo -eq 99) {
        # 99 es el codigo de k6 para "uno o mas umbrales no se cumplieron".
        # La prueba SI se ejecuto: el resultado es un hallazgo, no un error.
        Write-Host "     OK - la prueba corrio. Uno o mas umbrales no se cumplieron (codigo 99)." -ForegroundColor Yellow
        Write-Host "     Eso es un HALLAZGO valido: revisa el DIAGNOSTICO al final del archivo." -ForegroundColor DarkGray
    } elseif ($codigo -eq 0) {
        Write-Host "     OK - guardado en captura-$Id-$Nombre.txt" -ForegroundColor Green
    } else {
        Write-Host "     ATENCION - termino con codigo $codigo. Revisa el archivo." -ForegroundColor Red
    }
    Write-Host ""
 
    if (-not $SinNotepad) { Start-Process notepad.exe $archivo }
}
 
# ============================================================================
#  CAPTURA 01 - Historial de versionado
# ============================================================================
Grabar -Id "01" -Nombre "historial-git" `
       -Titulo "Historial de commits y ramas (gestion de versiones)" `
       -Comando "git log --oneline --graph --all"
 
# ============================================================================
#  CAPTURA 02 - Ramas del repositorio y detalle de commits
# ============================================================================
# Nota: se usa %x20 (espacio en hexadecimal) en el formato de git para no
# necesitar comillas anidadas dentro del comando.
Grabar -Id "02" -Nombre "ramas-git" `
       -Titulo "Ramas del repositorio y detalle de cada commit" `
       -Comando "git branch -a && echo. && git log --date=short --format=%h%x20%ad%x20%an%x20%s"
 
# ============================================================================
#  CAPTURA 03 - Dependencias resueltas por Maven
# ============================================================================
Grabar -Id "03" -Nombre "dependencias-maven" `
       -Titulo "Arbol de dependencias (JUnit 5 y Cucumber resueltos)" `
       -Comando "mvn -B dependency:tree"
 
# ============================================================================
#  CAPTURA 07 - Ejecución local completa de la suite
# ============================================================================
Grabar -Id "07" -Nombre "ejecucion-local-completa" `
       -Titulo "Ejecucion local de toda la suite (18 pruebas)" `
       -Comando "mvn -B clean test"
 
# ============================================================================
#  CAPTURA 09 - Fallo intencional: la puerta de calidad detiene el build.
#  El script modifica la asercion, ejecuta, y RESTAURA el archivo original.
# ============================================================================
if (Toca "09") {
 
    $testFile = Join-Path $raiz "src\test\java\cl\iplacex\qa\unit\CalculadoraTest.java"
    $respaldo = "$testFile.bak"
 
    if (Test-Path $testFile) {
        Write-Host "[09] Fallo intencional (puerta de calidad)" -ForegroundColor Yellow
        Write-Host "     Se modifica CalculadoraTest.java y se restaura al terminar." -ForegroundColor DarkGray
 
        Copy-Item $testFile $respaldo -Force
        try {
            $contenido  = Get-Content $testFile -Raw -Encoding UTF8
            $modificado = $contenido -replace 'assertEquals\(12, resultado', 'assertEquals(99, resultado'
 
            if ($modificado -eq $contenido) {
                Write-Host "     ATENCION - no se encontro la asercion a modificar. Se omite." -ForegroundColor Red
            } else {
                # UTF-8 SIN BOM: un BOM en un .java puede confundir al compilador
                $utf8SinBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($testFile, $modificado, $utf8SinBom)
                Grabar -Id "09" -Nombre "fallo-intencional-build-failure" `
                       -Titulo "Fallo intencional: el build se detiene (BUILD FAILURE)" `
                       -Comando "mvn -B clean test" -SeEsperaFallo
            }
        }
        finally {
            # Restauracion garantizada aunque algo falle a mitad de camino
            Copy-Item $respaldo $testFile -Force
            Remove-Item $respaldo -Force
            Write-Host "     CalculadoraTest.java restaurado a su estado original." -ForegroundColor Green
            Write-Host ""
        }
    }
}
 
# ============================================================================
#  CAPTURA 11 - Escenarios BDD (Cucumber)
# ============================================================================
Grabar -Id "11" -Nombre "escenarios-bdd" `
       -Titulo "Ejecucion de los 6 escenarios BDD en Gherkin" `
       -Comando "mvn -B test -Dtest=BddTestRunner -DfailIfNoTests=false"
 
# ============================================================================
#  CAPTURA 11b - Ejecución selectiva por etiqueta (complementaria, opcional)
# ============================================================================
Grabar -Id "11b" -Nombre "smoke-test-por-etiqueta" `
       -Titulo "Ejecucion selectiva del smoke test con la etiqueta @smoke" `
       -Comando "mvn -B test -Dtest=BddTestRunner -Dcucumber.filter.tags=@smoke"
 
# ============================================================================
#  CAPTURA 14 - Prueba de performance con k6 (si esta instalado)
# ============================================================================
if (Toca "14") {
    if (Get-Command k6 -ErrorAction SilentlyContinue) {
        New-Item -ItemType Directory -Force -Path (Join-Path $raiz "performance\resultados") | Out-Null
        Grabar -Id "14" -Nombre "performance-k6" `
               -Titulo "Prueba de carga sobre el login (TPS, latencia p95/p99, errores)" `
               -Comando "k6 run performance\login-performance.js" -EsK6
    } else {
        Write-Host "[14] k6 no esta instalado - se omite la prueba de performance." -ForegroundColor DarkYellow
        Write-Host "     Para instalarlo:  winget install k6" -ForegroundColor DarkGray
        Write-Host ""
    }
}
 
# ============================================================================
#  CAPTURAS 06 y 12 - Reportes HTML navegables: se generan y se abren
# ============================================================================
if ($Solo -eq "") {
    Write-Host "[06/12] Generando reportes HTML navegables..." -ForegroundColor Yellow
    cmd /c "mvn -B surefire-report:report-only site:site -DgenerateReports=false 2>&1" | Out-Null
 
    $reporteUnit = Join-Path $raiz "target\site\surefire-report.html"
    $reporteBdd  = Join-Path $raiz "target\cucumber-reports\cucumber.html"
 
    if (Test-Path $reporteBdd) {
        Write-Host "     CAPTURA 12 - abriendo reporte BDD de Cucumber" -ForegroundColor Green
        Write-Host "     Recuerda expandir un escenario antes de capturar." -ForegroundColor DarkGray
        Start-Process $reporteBdd
    } else {
        Write-Host "     No se encontro cucumber.html. Ejecuta antes 'mvn clean test'." -ForegroundColor Red
    }
 
    if (Test-Path $reporteUnit) {
        Write-Host "     CAPTURA 06 - abriendo reporte de pruebas unitarias" -ForegroundColor Green
        Start-Process $reporteUnit
    } else {
        Write-Host "     No se encontro surefire-report.html." -ForegroundColor Red
    }
    Write-Host ""
}
 
# ============================================================================
#  Indice de evidencias
# ============================================================================
if ($Solo -eq "") {
    $indice = Join-Path $destino "_INDICE.txt"
    @(
        "================================================================================",
        "  INDICE DE EVIDENCIAS - Taller 1, Unidad II",
        "  Generado el $(Get-Date -Format 'dd-MM-yyyy HH:mm')",
        "================================================================================",
        "",
        "ARCHIVOS .TXT GENERADOS POR ESTE SCRIPT (captura desde el Bloc de notas)",
        "--------------------------------------------------------------------------------",
        "  01   historial-git                 Historial de commits y ramas",
        "  02   ramas-git                     Ramas del repositorio y detalle de commits",
        "  03   dependencias-maven            Arbol de dependencias resueltas",
        "  07   ejecucion-local-completa      mvn clean test - 18 pruebas en verde",
        "  09   fallo-intencional             BUILD FAILURE - la puerta de calidad bloquea",
        "  11   escenarios-bdd                Los 6 escenarios Gherkin ejecutados",
        "  11b  smoke-test-por-etiqueta       Ejecucion selectiva con @smoke (opcional)",
        "  14   performance-k6                TPS, latencia p95/p99 y tasa de error",
        "",
        "SE ABREN EN EL NAVEGADOR (captura con Win+Shift+S)",
        "--------------------------------------------------------------------------------",
        "  06   surefire-report.html          Reporte HTML de pruebas unitarias",
        "  12   cucumber.html                 Reporte BDD navegable (expande un escenario)",
        "",
        "REQUIEREN SUBIR EL PROYECTO A GITHUB (ver Paso 7 de la guia)",
        "--------------------------------------------------------------------------------",
        "  04   Pestana Actions con la ejecucion en verde",
        "  05   Detalle de los pasos del job build-and-test",
        "  08   Pruebas ejecutandose dentro de GitHub Actions",
        "  13   Artefactos descargables de la ejecucion",
        "  15   Dashboard publicado / resumen de la ejecucion",
        "  16   Tarjeta de resultados de pruebas en el resumen del build",
        "",
        "SE SIMULAN O SE ARMAN A MANO (ver Paso 9 de la guia)",
        "--------------------------------------------------------------------------------",
        "  10   Tablero con los criterios de la sesion Three Amigos",
        "  17   Mensaje de alerta en Slack",
        "  18   Issue creado automaticamente por el pipeline",
        "",
        "================================================================================"
    ) | Out-File -FilePath $indice -Encoding utf8
 
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  LISTO" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Get-ChildItem $destino -Filter "*.txt" | Sort-Object Name | ForEach-Object {
        Write-Host ("   {0,-48} {1,7:N0} bytes" -f $_.Name, $_.Length)
    }
    Write-Host ""
    Write-Host "  Carpeta: $destino" -ForegroundColor Green
    Write-Host "  Indice : _INDICE.txt" -ForegroundColor Green
    Write-Host ""
    Start-Process explorer.exe $destino
}
 