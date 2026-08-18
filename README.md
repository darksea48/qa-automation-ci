# qa-automation-ci

Proyecto Java que implementa un **flujo completo de integración continua para pruebas automatizadas**: gestión de versiones con Git, dependencias con Maven, pruebas unitarias atómicas con JUnit 5, pruebas BDD con Cucumber, pipeline en GitHub Actions con reportes navegables, prueba de performance con k6 y alertas automáticas.

> Taller 1 – Evaluación Unidad II · Automatización de Pruebas (ADP1323) · Douglas Suárez Z.

---

## 1. Objetivos

| # | Objetivo | Dónde se resuelve |
|---|---|---|
| 1 | Versionar el trabajo con ramas y commits frecuentes y descriptivos | Historial Git, `git log --graph` |
| 2 | Gestionar dependencias de prueba de forma declarativa | `pom.xml` |
| 3 | Escribir pruebas unitarias atómicas e independientes | `src/test/java/.../unit/` |
| 4 | Describir el comportamiento en lenguaje de negocio (BDD) | `src/test/resources/features/login.feature` |
| 5 | Ejecutar todo automáticamente en cada push / pull request | `.github/workflows/ci.yml` |
| 6 | Publicar reportes navegables accesibles para el equipo | Artefactos + GitHub Pages |
| 7 | Medir el comportamiento bajo carga | `performance/login-performance.js` |
| 8 | Alertar automáticamente ante fallos o degradaciones | Job `reportes-y-alertas` |

---

## 2. Estructura del proyecto

```
qa-automation-ci/
├── .github/
│   └── workflows/
│       └── ci.yml                      # Pipeline de integración continua
├── docs/
│   ├── capturas/                       # Evidencia de ejecución (local y CI)
│   └── historial-git.txt               # Salida de git log --graph
├── performance/
│   └── login-performance.js            # Prueba de carga k6 sobre el login
├── src/
│   ├── main/java/cl/iplacex/qa/
│   │   ├── calculo/
│   │   │   └── Calculadora.java        # Componente sin estado bajo prueba
│   │   └── auth/
│   │       ├── ServicioAutenticacion.java
│   │       ├── EstadoLogin.java
│   │       └── ResultadoLogin.java     # record inmutable
│   └── test/
│       ├── java/cl/iplacex/qa/
│       │   ├── unit/                   # Pruebas unitarias (JUnit 5)
│       │   │   ├── CalculadoraTest.java
│       │   │   └── ServicioAutenticacionTest.java
│       │   └── bdd/
│       │       ├── runner/BddTestRunner.java
│       │       └── steps/LoginSteps.java
│       └── resources/
│           └── features/login.feature  # Escenarios Gherkin
├── .gitignore
├── pom.xml
└── README.md
```

**Criterio de organización.** El código productivo (`src/main`) y el de prueba (`src/test`) están estrictamente separados según la convención estándar de Maven, de modo que el compilador y el pipeline los tratan distinto sin configuración adicional. Dentro de las pruebas se separan además `unit/` (verificación técnica, rápida) y `bdd/` (verificación de negocio, documento vivo), porque tienen audiencias y frecuencias de ejecución distintas. Los `features` viven en `resources` para que el negocio pueda leerlos sin tocar código Java.

---

## 3. Archivos clave

| Archivo | Función |
|---|---|
| `pom.xml` | Declara dependencias (JUnit 5, Cucumber), fija versiones mediante BOM y configura Surefire como ejecutor de pruebas. |
| `.gitignore` | Excluye `target/`, reportes, archivos de IDE y **secretos**, evitando ruido y filtraciones en el repositorio. |
| `CalculadoraTest.java` | 8 pruebas unitarias atómicas, incluidas parametrizadas y de caso de borde. |
| `login.feature` | 6 escenarios ejecutables en Gherkin (español), con `Esquema del escenario` + `Ejemplos`. |
| `LoginSteps.java` | Step definitions: traducen cada paso Gherkin a una llamada al servicio real. |
| `BddTestRunner.java` | Configura la suite BDD y los tres formatos de reporte (HTML, JSON, JUnit XML). |
| `ci.yml` | Pipeline de 3 jobs encadenados: build+tests → performance → dashboard y alertas. |
| `login-performance.js` | Prueba de carga escalonada con umbrales (SLO) que hacen fallar el build. |

---

## 4. Comandos utilizados

### Gestión de versiones

```bash
git init -b main
git checkout -b feature/pruebas-unitarias        # una rama por unidad de trabajo
git add .
git commit -m "test(calculo): agrega pruebas unitarias atomicas de suma y resta"
git checkout main
git merge --no-ff feature/pruebas-unitarias      # --no-ff conserva la traza de la rama
git log --oneline --graph --all
```

Se usa la convención **Conventional Commits** (`feat:`, `test:`, `ci:`, `build:`, `chore:`, `perf:`): el prefijo indica el tipo de cambio y el ámbito entre paréntesis indica el módulo afectado. Esto permite generar changelogs automáticos y facilita la revisión de pares.

### Ejecución de pruebas

```bash
mvn clean compile                       # solo compila
mvn test                                # ejecuta TODAS las pruebas (unitarias + BDD)
mvn test -Dtest='*Test'                 # solo pruebas unitarias
mvn test -Dtest='BddTestRunner'         # solo escenarios BDD
mvn test -Dcucumber.filter.tags="@smoke"          # solo el smoke test
mvn surefire-report:report-only site:site -DgenerateReports=false   # reporte HTML
```

### Prueba de performance

```bash
k6 run performance/login-performance.js
k6 run --vus 50 --duration 2m performance/login-performance.js
```

---

## 5. Reportes generados

| Reporte | Ruta | Formato |
|---|---|---|
| Resultados unitarios | `target/surefire-reports/` | TXT + XML |
| Reporte navegable Surefire | `target/site/surefire-report.html` | HTML |
| Reporte BDD | `target/cucumber-reports/cucumber.html` | HTML navegable |
| BDD para dashboards | `target/cucumber-reports/cucumber.json` | JSON |
| BDD para el pipeline | `target/cucumber-reports/cucumber.xml` | JUnit XML |
| Performance | `performance/resultados/summary.json` | JSON |

En CI, todos se publican como **artefactos descargables** y, en la rama `main`, se despliegan en **GitHub Pages** bajo una URL fija, de modo que cualquier integrante del equipo revisa el estado de calidad sin instalar nada.

---

## 6. Cómo funciona el pipeline

```
push / pull request / cron 08:00 días hábiles
            │
            ▼
┌───────────────────────────────┐
│ JOB 1: build-and-test         │
│  · checkout                   │
│  · setup JDK 17 + caché Maven │
│  · mvn clean compile          │
│  · pruebas unitarias (JUnit)  │
│  · escenarios BDD (Cucumber)  │
│  · reporte HTML Surefire      │
│  · publica artefactos         │
└──────────────┬────────────────┘
               │ needs
               ▼
┌───────────────────────────────┐
│ JOB 2: performance (k6)       │
│  · carga escalonada al login  │
│  · valida umbrales p95/error  │
│  · publica resultados         │
└──────────────┬────────────────┘
               │ needs (if: always)
               ▼
┌───────────────────────────────┐
│ JOB 3: reportes-y-alertas     │
│  · consolida reportes         │
│  · publica GitHub Pages       │
│  · alerta Slack si falla      │
│  · crea issue si falla main   │
└───────────────────────────────┘
```

**Decisiones de diseño del pipeline**

- **Jobs separados en lugar de uno solo**: las pruebas funcionales son rápidas y deben dar feedback en minutos; la de performance es lenta. Separarlas evita que el desarrollador espere la carga para saber si rompió algo.
- **`needs: build-and-test`**: no tiene sentido medir la performance de un código que ni siquiera pasa las pruebas funcionales.
- **`if: always()` en los pasos de reporte**: el reporte es más valioso justamente cuando algo falló.
- **`continue-on-error` en performance**: una degradación se alerta pero no bloquea el merge; un fallo funcional sí lo bloquea. La puerta de calidad es más estricta donde el riesgo es mayor.
- **`concurrency` con `cancel-in-progress`**: si se hacen tres push seguidos, solo se ejecuta el último. Ahorra minutos de CI.
- **Caché de Maven**: reduce el tiempo de build de minutos a segundos en ejecuciones sucesivas.

---

## 7. Requisitos

- JDK 17 o superior
- Apache Maven 3.8+
- Git 2.30+
- k6 (opcional, solo para la prueba de performance): `winget install k6` / `brew install k6`

---

## 8. Evidencia

Las capturas de la ejecución local y en CI están en `docs/capturas/`. El historial completo de versionado está en `docs/historial-git.txt`.
