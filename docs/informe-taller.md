# Taller 1 — Evaluación Unidad II

**Asignatura:** Automatización de Pruebas (ADP1323)
**Estudiante:** Douglas Suárez Z.
**Fecha:** agosto de 2026
**Repositorio del taller:** `qa-automation-ci`

---

## Índice

1. [Introducción](#1-introducción)
2. [Actividad 1 — Integración continua y automatización de pruebas](#2-actividad-1--integración-continua-y-automatización-de-pruebas)
   - 2.1 [Gestión de versiones con Git](#21-gestión-de-versiones-con-git)
   - 2.2 [Configuración del proyecto Maven](#22-configuración-del-proyecto-maven)
   - 2.3 [Pruebas unitarias atómicas](#23-pruebas-unitarias-atómicas)
   - 2.4 [Estructura de carpetas y .gitignore](#24-estructura-de-carpetas-y-gitignore)
   - 2.5 [Pipeline de integración continua](#25-pipeline-de-integración-continua)
   - 2.6 [Reporte navegable](#26-reporte-navegable)
   - 2.7 [Evidencia de ejecución](#27-evidencia-de-ejecución-local-y-en-ci)
3. [Actividad 2 — BDD, performance, métricas y alertas](#3-actividad-2--bdd-performance-métricas-y-alertas)
   - 3.1 [Sesión Three Amigos](#31-sesión-three-amigos)
   - 3.2 [Escenarios en Gherkin](#32-escenarios-en-gherkin)
   - 3.3 [Step definitions](#33-step-definitions)
   - 3.4 [Integración de BDD al pipeline](#34-integración-de-bdd-al-pipeline)
   - 3.5 [Reporte navegable de BDD](#35-reporte-navegable-de-bdd)
   - 3.6 [Prueba de performance e indicadores](#36-prueba-de-performance-e-indicadores)
   - 3.7 [Dashboard de métricas](#37-dashboard-de-métricas-del-pipeline)
   - 3.8 [Alertas automáticas](#38-alertas-automáticas)
4. [Conclusiones](#4-conclusiones)
5. [Anexo: cobertura de la pauta de evaluación](#5-anexo-cobertura-de-la-pauta-de-evaluación)

---

## 1. Introducción

Una empresa nos pide profesionalizar su proceso de pruebas automatizadas sobre un proyecto Java. En este taller documentamos, de principio a fin, la construcción de un flujo de integración continua que articula los contenidos de la **Unidad I** (estrategias de prueba, atomicidad con alta cohesión y bajo acoplamiento, selección del test adecuado, conformación del equipo de test) con los de la **Unidad II** (integración continua, BDD, pipelines, métricas, reporting y alertas).

El resultado es el repositorio `qa-automation-ci`, cuya premisa de diseño es simple: **cada cambio que entra al repositorio debe demostrar por sí mismo que no rompió nada**, sin intervención manual y con evidencia navegable para todo el equipo.

**Herramientas seleccionadas y justificación**

| Necesidad | Herramienta | Por qué |
|---|---|---|
| Control de versiones | Git | Ramas livianas, historial trazable y base de cualquier pipeline de CI. |
| Gestión de dependencias y build | Maven | Estándar en el ecosistema Java; convención de carpetas que el pipeline entiende sin configuración extra. |
| Pruebas unitarias | JUnit 5 | Aserciones expresivas, pruebas parametrizadas y ciclo de vida (`@BeforeEach`) que garantiza aislamiento. |
| BDD | Cucumber + Gherkin | Permite que el criterio de aceptación escrito por el negocio sea, literalmente, la prueba ejecutable. |
| Pipeline CI | GitHub Actions | Vive junto al código, se dispara con cada push/PR y publica reportes sin infraestructura propia. |
| Performance | k6 | Script en JavaScript, versionable junto al código, con umbrales (SLO) que hacen fallar el build. |

---

## 2. Actividad 1 — Integración continua y automatización de pruebas

### 2.1 Gestión de versiones con Git

**Estrategia de ramificación.** Adoptamos un modelo *feature branch*: `main` se mantiene siempre en estado desplegable y cada unidad de trabajo se desarrolla en su propia rama, que integramos mediante *pull request* previa revisión de pares. Con esto materializamos el criterio de la Unidad I sobre **conformación del equipo de test y desarrollo**: el código de prueba se revisa con el mismo rigor que el productivo.

Ramas creadas:

| Rama | Propósito |
|---|---|
| `main` | Rama estable, protegida. Solo recibe merges aprobados. |
| `feature/pruebas-unitarias` | Componente `Calculadora` y su suite unitaria. |
| `feature/pipeline-ci` | Workflow de GitHub Actions. |
| `feature/bdd-login` | Servicio de autenticación, feature Gherkin y step definitions. |
| `feature/performance-k6` | Script de carga sobre el login. |

**Comandos ejecutados**

```bash
# Inicialización
git init -b main
git config user.name "Douglas Suarez"
git config user.email "douglas.suarez@cadem.cl"

# Primer commit: base del repositorio
git add .gitignore README.md
git commit -m "chore: inicializa repositorio con .gitignore y README base"

# Creación de una rama de trabajo
git checkout -b feature/pruebas-unitarias
git add src/main/java/cl/iplacex/qa/calculo/Calculadora.java
git commit -m "feat(calculo): agrega clase Calculadora sin estado para operaciones basicas"
git add src/test/java/cl/iplacex/qa/unit/CalculadoraTest.java
git commit -m "test(calculo): agrega pruebas unitarias atomicas de suma, resta y division por cero"

# Integración a main conservando la traza de la rama
git checkout main
git merge --no-ff feature/pruebas-unitarias -m "merge: integra feature/pruebas-unitarias a main tras revision de pares"

# Verificación del historial
git log --oneline --graph --all
```

**Historial resultante** (salida real de `git log --oneline --graph --all`, 22 commits):

```
* 53e82ec fix(ci): declara el webhook a nivel de job para que la condicion pueda leerlo
* 3e997eb ci: distingue degradacion de performance de fallo de la herramienta
* 31a90f6 chore: agrega scripts de generacion de evidencias y publicacion
* b07afbc chore: normaliza fin de linea con .gitattributes
* 747397d fix(perf): distingue rechazos de negocio de fallos de red en la prueba k6
* a80ad87 docs: incorpora informe del taller al repositorio
* fbe9a09 docs: agrega historial de versionado como evidencia
* 0afa99c docs: documenta objetivos, estructura, comandos y pipeline en README
*   b62c2b2 merge: integra feature/performance-k6 a main
|\
| * 0f5b2f1 perf: agrega prueba de carga k6 sobre login con umbrales de latencia y error
|/
*   6678f84 merge: integra feature/bdd-login a main tras aprobacion del pull request
|\
| * f379224 test(auth): agrega pruebas unitarias de bloqueo e intentos fallidos
| * 1e6c796 test(bdd): implementa step definitions y runner con reportes HTML, JSON y JUnit XML
| * 5fa8c07 test(bdd): agrega feature de login en Gherkin con Scenario Outline y Examples
| * cc39664 feat(auth): implementa ServicioAutenticacion segun criterios de la sesion Three Amigos
|/
*   233b4a1 merge: integra feature/pipeline-ci a main
|\
| * 233ca7f ci: agrega pipeline de GitHub Actions que compila y ejecuta tests en cada push
|/
*   6e52e28 merge: integra feature/pruebas-unitarias a main tras revision de pares
|\
| * 96dd528 test(calculo): agrega pruebas unitarias atomicas de suma, resta y division por cero
| * bf7af1c feat(calculo): agrega clase Calculadora sin estado para operaciones basicas
|/
* 3952f11 build: configura proyecto Maven con dependencias JUnit 5 y plugin Surefire
* 4bac7ed chore: inicializa repositorio con .gitignore y README base
```

**Decisiones tomadas y su fundamento**

- **Commits pequeños y frecuentes (22 commits, 5 ramas).** Un commit por cambio conceptual. Si una prueba falla, `git bisect` identifica el commit culpable en pocos pasos; con commits gigantes eso es imposible. Los commits posteriores a la construcción inicial (`fix(perf)`, `fix(ci)`, `chore: normaliza fin de linea`) documentan las correcciones que surgieron al ejecutar realmente el pipeline, y son parte legítima del historial: un repositorio sin correcciones o no se ejecutó nunca, o se le reescribió la historia.
- **Convención Conventional Commits.** El prefijo (`feat`, `test`, `ci`, `build`, `docs`, `perf`, `chore`) clasifica el cambio y el ámbito entre paréntesis indica el módulo. Permite generar changelogs automáticos y filtrar el historial (`git log --grep="^test"`).
- **Separación del commit de código y del commit de prueba.** Deja visible en el historial que la prueba fue escrita como artefacto propio y no como añadido posterior.
- **`--no-ff` en los merges.** Sin él, Git aplanaría la rama y se perdería la traza de qué commits pertenecieron a qué unidad de trabajo. Con `--no-ff` el grafo documenta el flujo de trabajo del equipo.
- **`.gitignore` desde el primer commit.** Evita que `target/` entre al repositorio; una vez versionado un artefacto compilado, sacarlo del historial es costoso.

> 📸 **Captura 1** — `git log --oneline --graph --all` en la terminal.
> 📸 **Captura 2** — `git branch -a` mostrando las ramas creadas.

---

### 2.2 Configuración del proyecto Maven

El archivo `pom.xml` centraliza toda la gestión de dependencias. Fragmento relevante:

```xml
<properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.jupiter.version>5.10.2</junit.jupiter.version>
    <cucumber.version>7.15.0</cucumber.version>
    <surefire.version>3.2.5</surefire.version>
</properties>

<dependencyManagement>
    <dependencies>
        <!-- BOM de JUnit 5: alinea todas las versiones del ecosistema JUnit -->
        <dependency>
            <groupId>org.junit</groupId>
            <artifactId>junit-bom</artifactId>
            <version>${junit.jupiter.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>io.cucumber</groupId>
            <artifactId>cucumber-bom</artifactId>
            <version>${cucumber.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-java</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-junit-platform-engine</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.junit.platform</groupId>
        <artifactId>junit-platform-suite</artifactId>
        <version>${junit.platform.version}</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Explicación de cada decisión**

| Decisión | Fundamento |
|---|---|
| Versiones en `<properties>` | Un solo lugar donde subir de versión. Evita que dos dependencias del mismo ecosistema queden desalineadas. |
| Uso de **BOM** (`junit-bom`, `cucumber-bom`) | El *Bill of Materials* fija las versiones de todo el ecosistema de forma coherente. Es el mecanismo que previene el clásico conflicto de versiones transitivas. |
| `<scope>test</scope>` en todas las dependencias de prueba | Las librerías de testing **no** se empaquetan en el artefacto de producción. Reduce el tamaño del JAR y la superficie de ataque. |
| `junit-jupiter` (agregador) | Trae `api`, `engine` y `params` juntos: una sola dependencia en vez de tres. |
| `cucumber-junit-platform-engine` | Permite que Cucumber corra sobre JUnit Platform, de modo que Surefire ejecuta **unitarias y BDD con el mismo comando** (`mvn test`). |
| `maven-surefire-plugin` con `testFailureIgnore=false` | Es la **puerta de calidad**: si una prueba falla, el build falla y el pipeline se detiene. Sin esto, la CI sería decorativa. |
| `maven-surefire-report-plugin` | Genera el HTML navegable de resultados exigido por el enunciado. |

> 📸 **Captura 3** — `mvn dependency:tree` mostrando las dependencias resueltas.

---

### 2.3 Pruebas unitarias atómicas

El enunciado pide al menos dos pruebas unitarias atómicas e independientes. Nosotros implementamos **doce** (ocho para `Calculadora`, cuatro para `ServicioAutenticacion`).

#### El diseño del código bajo prueba condiciona la atomicidad

La atomicidad no se logra solo en la prueba: empieza en la clase que se prueba.

```java
/**
 * Se mantiene deliberadamente SIN ESTADO (stateless): cada método recibe todo
 * lo que necesita por parámetro y no guarda datos entre invocaciones. Esto es
 * lo que permite escribir pruebas ATÓMICAS.
 *
 * Alta cohesión: la clase hace una sola cosa (operaciones aritméticas).
 * Bajo acoplamiento: no depende de ninguna otra clase del proyecto.
 */
public class Calculadora {
    public int sumar(int a, int b)   { return a + b; }
    public int restar(int a, int b)  { return a - b; }

    public double dividir(int a, int b) {
        if (b == 0) {
            throw new ArithmeticException("No es posible dividir por cero");
        }
        return (double) a / b;
    }
}
```

- **Alta cohesión**: la clase tiene una única responsabilidad. Todos sus métodos giran en torno al mismo concepto, así que cualquier cambio de requisito afecta a un solo lugar.
- **Bajo acoplamiento**: no depende de base de datos, red ni configuración. Por eso la prueba corre en milisegundos y no necesita *mocks* ni entorno preparado — el criterio de la Unidad I sobre **estrategias de prueba implementadas en ambientes de desarrollo**.

#### La suite unitaria

```java
@DisplayName("Suite unitaria - Calculadora")
class CalculadoraTest {

    private Calculadora calculadora;

    @BeforeEach
    void prepararEscenario() {
        // Arrange común: instancia NUEVA antes de CADA prueba.
        calculadora = new Calculadora();
    }

    @Test
    @DisplayName("sumar() devuelve la suma de dos números positivos")
    void sumarDosPositivos() {
        int resultado = calculadora.sumar(7, 5);          // Act
        assertEquals(12, resultado, "7 + 5 debe ser 12"); // Assert
    }

    @Test
    @DisplayName("restar() devuelve la diferencia entre dos números")
    void restarDosNumeros() {
        assertEquals(6, calculadora.restar(10, 4), "10 - 4 debe ser 6");
    }

    @Test
    @DisplayName("dividir() lanza ArithmeticException cuando el divisor es cero")
    void dividirPorCeroLanzaExcepcion() {
        ArithmeticException ex = assertThrows(
                ArithmeticException.class,
                () -> calculadora.dividir(10, 0));
        assertEquals("No es posible dividir por cero", ex.getMessage());
    }

    @ParameterizedTest(name = "{0} + {1} = {2}")
    @CsvSource({
            "0,   0,   0",
            "-5,  5,   0",
            "-3, -7, -10",
            "100, 250, 350"
    })
    @DisplayName("sumar() es correcta para valores límite y negativos")
    void sumarCasosLimite(int a, int b, int esperado) {
        assertEquals(esperado, calculadora.sumar(a, b));
    }
}
```

#### Cómo se garantiza la atomicidad

| Principio | Implementación concreta | Consecuencia |
|---|---|---|
| Una prueba, un comportamiento | Cada `@Test` verifica una sola regla | La prueba tiene **una sola razón para fallar**; el diagnóstico es inmediato |
| Sin estado compartido | `@BeforeEach` crea una instancia nueva | Ninguna prueba puede contaminar a otra |
| Independencia de orden | No hay `@TestMethodOrder` ni campos estáticos mutables | Se pueden ejecutar en paralelo o en cualquier orden |
| Patrón AAA | *Arrange* en `@BeforeEach`, *Act* y *Assert* explícitos en el cuerpo | Cualquiera lee la prueba y entiende qué valida |
| Nombres que documentan | `@DisplayName` en lenguaje natural | El reporte de CI se lee como una especificación |
| Mensajes en las aserciones | Tercer parámetro de `assertEquals` | Cuando falla en CI, el log dice *qué* se esperaba sin abrir el código |

#### Selección del test adecuado según el requerimiento

Este es un criterio explícito de la pauta. La decisión aplicada fue:

| Tipo de requerimiento | Test seleccionado | Razón |
|---|---|---|
| Lógica aritmética determinista | Prueba unitaria simple | Rápida, sin dependencias, feedback inmediato |
| Mismo comportamiento con muchos datos | Prueba **parametrizada** (`@ParameterizedTest`) | Cubre valores límite (cero, negativos, grandes) sin duplicar código |
| Caso de error / borde | `assertThrows` | Verifica el contrato de excepción, no solo el camino feliz |
| Regla de negocio visible al usuario | Escenario **BDD** (Actividad 2) | El criterio de aceptación se escribe en el lenguaje del negocio |
| Comportamiento bajo carga | Prueba de **performance** (k6) | Ninguna prueba funcional detecta una degradación de latencia |

**Resultado de la ejecución real** (`mvn clean test`):

```
[INFO] Running cl.iplacex.qa.unit.CalculadoraTest
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.116 s
[INFO] Running cl.iplacex.qa.unit.ServicioAutenticacionTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.011 s
```

Las doce pruebas unitarias se ejecutan en 127 milisegundos combinados. Esa velocidad no es un detalle estético: una suite que tarda minutos deja de ejecutarse antes de cada cambio, y una suite que no se ejecuta no protege nada. La rapidez es consecuencia directa del bajo acoplamiento — sin base de datos, sin red, sin configuración previa.

---

### 2.4 Estructura de carpetas y `.gitignore`

```
qa-automation-ci/
├── .github/workflows/ci.yml            # Pipeline de integración continua
├── capturas/                           # Evidencia generada de cada ejecución
├── docs/
│   └── historial-git.txt
├── performance/login-performance.js    # Prueba de carga k6
├── src/
│   ├── main/java/cl/iplacex/qa/
│   │   ├── calculo/Calculadora.java
│   │   ├── auth/
│   │   │   ├── ServicioAutenticacion.java
│   │   │   ├── EstadoLogin.java
│   │   │   └── ResultadoLogin.java
│   │   └── app/
│   │       └── ServidorLogin.java      # Expone el servicio para medirlo
│   └── test/
│       ├── java/cl/iplacex/qa/
│       │   ├── unit/
│       │   │   ├── CalculadoraTest.java
│       │   │   └── ServicioAutenticacionTest.java
│       │   └── bdd/
│       │       ├── runner/BddTestRunner.java
│       │       └── steps/LoginSteps.java
│       └── resources/features/login.feature
├── capturar-evidencias.ps1             # Genera la evidencia de cada prueba
├── subir-a-github.ps1                  # Automatiza commits y publicación
├── .gitattributes                      # Normalización de fin de línea
├── .gitignore
├── pom.xml
└── README.md
```

**Justificación de la estructura**

- `src/main` vs `src/test`: convención estándar de Maven. El código de prueba **nunca** se empaqueta en el artefacto de producción, y el pipeline sabe qué compilar en cada fase sin configuración adicional.
- `unit/` separado de `bdd/`: son dos estrategias de prueba con audiencias distintas. Las unitarias corren en cada guardado; las BDD son el contrato con el negocio. Separarlas permite ejecutarlas por separado (`-Dtest='*Test'`).
- `steps/` separado de `runner/`: el runner es configuración, los steps son código de prueba. Mezclarlos dificulta agregar una segunda suite BDD.
- `features/` en `resources`: los archivos `.feature` son **documentación ejecutable**. Ubicarlos fuera de `java/` deja claro que un analista funcional puede leerlos y proponer cambios.
- `performance/` en la raíz: la prueba de carga no es Java y no forma parte del ciclo de vida de Maven; tiene su propio ejecutor (k6).
- `app/ServidorLogin.java` separado de `auth/`: el servicio de dominio no debe saber que se expone por HTTP. Manteniendo la capa de transporte aparte, la misma clase se prueba de tres formas —unitaria, BDD y de carga— sin que ninguna contamine a las otras.
- `capturas/` y `docs/`: la evidencia acompaña al código en el mismo repositorio, versionada junto a la ejecución que la produjo.

**`.gitattributes`.** Lo agregamos al detectar que, al trabajar desde Windows, los dieciséis archivos del proyecto aparecían como modificados por completo sin haber cambiado una sola letra: Windows usa CRLF y el runner Linux del pipeline usa LF. Sin normalización, cada cambio de sistema operativo ensucia el historial, hace ilegibles los diffs de los pull requests y genera conflictos de merge falsos.

```gitattributes
* text=auto           # el repositorio guarda LF; cada SO recibe lo suyo
*.ps1  text eol=crlf  # los scripts de Windows requieren CRLF
*.yml  text eol=lf    # los ejecuta el runner Linux
*.png  binary         # Git no debe tocarlos nunca
```

**`.gitignore`** (extracto comentado):

```gitignore
# ===== Artefactos de compilación Maven =====
target/

# ===== Reportes generados (se regeneran en cada ejecución) =====
target/surefire-reports/
target/cucumber-reports/
allure-results/
performance/resultados/

# ===== IDE =====
.idea/
*.iml
.vscode/

# ===== Sistema operativo =====
.DS_Store
Thumbs.db
desktop.ini

# ===== Secretos: nunca deben viajar al repositorio =====
.env
*.pem
credenciales.properties
```

Criterio: **se versiona lo que se escribe, no lo que se genera**. Los reportes se producen en cada ejecución del pipeline; versionarlos generaría conflictos constantes. La sección de secretos es la más crítica: una credencial en el historial de Git es una credencial comprometida de forma permanente.

---

### 2.5 Pipeline de integración continua

Archivo `.github/workflows/ci.yml`. Fragmento del job principal:

```yaml
name: CI - Pruebas Automatizadas

on:
  push:
    branches: [ main, develop, 'feature/**' ]
  pull_request:
    branches: [ main, develop ]
  workflow_dispatch:
  schedule:
    - cron: '0 8 * * 1-5'   # regresión diaria en días hábiles

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Por seguridad, GitHub entrega un token de SOLO LECTURA. Aquí se conceden
# explícitamente y de forma mínima los permisos que cada acción necesita.
permissions:
  contents: write        # desplegar el dashboard
  checks: write          # publicar el reporte de pruebas en el commit
  issues: write          # crear el issue automático ante fallo
  pull-requests: write

jobs:
  build-and-test:
    name: Build y pruebas (unitarias + BDD)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configurar JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Compilar el proyecto
        run: mvn -B clean compile

      - name: Ejecutar pruebas unitarias (JUnit 5)
        run: mvn -B test -Dtest='*Test' -DfailIfNoTests=false

      - name: Ejecutar escenarios BDD (Cucumber)
        run: mvn -B test -Dtest='BddTestRunner' -DfailIfNoTests=false

      - name: Publicar resultados de pruebas en el resumen del build
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: Resultados de pruebas
          path: 'target/surefire-reports/*.xml,target/cucumber-reports/*.xml'
          reporter: java-junit
```

**Flujo del pipeline**

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

**Explicación de cada decisión**

| Decisión | Fundamento |
|---|---|
| Bloque `permissions` explícito | GitHub entrega por defecto un token de solo lectura. Sin declarar `checks: write` el reporte de pruebas no se publica y sin `contents: write` falla el dashboard. Concederlos de forma mínima y explícita, en vez de dejar permisos amplios por comodidad, es el principio de menor privilegio aplicado al pipeline. |
| Disparadores en `push` **y** `pull_request` | El push da feedback al autor; el PR protege a `main` de recibir código roto. |
| `schedule` con cron | Una regresión diaria detecta fallos causados por factores externos (dependencias, entorno) aunque nadie haya subido código. |
| `concurrency` + `cancel-in-progress` | Ante tres push seguidos solo se ejecuta el último. Ahorra minutos de CI y evita reportes contradictorios. |
| `cache: maven` | Reutiliza `~/.m2`; el build baja de minutos a segundos. |
| Pasos separados para unitarias y BDD | El log muestra exactamente qué capa falló, sin leer el stack trace completo. |
| `-B` (batch mode) | Suprime la salida interactiva de Maven; los logs de CI quedan legibles. |
| `if: always()` en los reportes | El reporte es más necesario cuando el build falló. |
| Jobs separados con `needs` | Feedback funcional rápido primero; la carga (lenta) solo si lo funcional pasó. |

> 📸 **Captura 4** — Pestaña *Actions* de GitHub con la ejecución en verde.
> 📸 **Captura 5** — Detalle de los pasos del job `build-and-test`.

---

### 2.6 Reporte navegable

El pipeline expone los resultados por **tres vías complementarias**, porque distintos roles del equipo consultan la calidad de distinta forma:

| Vía | Destinatario | Cómo se accede |
|---|---|---|
| `dorny/test-reporter` | Desarrollador que acaba de subir código | Pestaña de checks del propio commit/PR, sin salir de GitHub |
| Artefactos (`upload-artifact`) | QA que necesita analizar en detalle | Descarga del ZIP con `cucumber.html` y el HTML de Surefire |
| GitHub Pages | Líder técnico / Product Owner | URL fija y permanente, sin instalar nada |

```yaml
      - name: Publicar reporte BDD (HTML navegable)
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: reporte-bdd-cucumber
          path: target/cucumber-reports/
          retention-days: 30
```

Reportes producidos:

| Reporte | Ruta | Uso |
|---|---|---|
| Surefire XML/TXT | `target/surefire-reports/` | Consumido por el pipeline |
| Surefire HTML | `target/site/surefire-report.html` | Navegable por el equipo |
| Cucumber HTML | `target/cucumber-reports/cucumber.html` | Documento vivo del negocio |
| Cucumber JSON | `target/cucumber-reports/cucumber.json` | Insumo del dashboard |
| Cucumber JUnit XML | `target/cucumber-reports/cucumber.xml` | Integración con el reporter de CI |
| k6 summary | `performance/resultados/summary.json` | Métricas de performance |

> 📸 **Captura 6** — `target/site/surefire-report.html` abierto en el navegador.

---

### 2.7 Evidencia de ejecución (local y en CI)

**Comando ejecutado localmente:**

```bash
mvn clean test
```

**Salida obtenida:**

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running cl.iplacex.qa.unit.CalculadoraTest
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.116 s
[INFO] Running cl.iplacex.qa.unit.ServicioAutenticacionTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.011 s
[INFO] Running cl.iplacex.qa.bdd.runner.BddTestRunner
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.561 s
[INFO]
[INFO] Results:
[INFO] Tests run: 18, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
[INFO] Total time:  4.423 s
```

**Automatización de la evidencia.** Para que la captura de resultados fuera reproducible y no dependiera de recortar la consola a mano, construimos el script `capturar-evidencias.ps1`. Este ejecuta cada suite, graba su salida en un archivo con encabezado (comando, fecha, equipo, usuario y código de salida) y la deja lista para adjuntar. Aplicamos a la evidencia el mismo criterio de automatización que a las pruebas.

> 📸 **Captura 7** — Terminal con la salida de `mvn clean test` (BUILD SUCCESS).
> 📸 **Captura 8** — Ejecución del mismo comando en GitHub Actions.
> 📸 **Captura 9** — Prueba negativa: se altera intencionalmente una aserción, el build falla y el pipeline lo bloquea. Demuestra que la puerta de calidad funciona.

---

## 3. Actividad 2 — BDD, performance, métricas y alertas

### 3.1 Sesión Three Amigos

**Funcionalidad seleccionada:** *Inicio de sesión (Login) en el portal de clientes.*

Elegimos el login porque concentra reglas de negocio, requisitos de seguridad y es la funcionalidad de mayor concurrencia del sistema — lo que la vuelve además el candidato natural para la prueba de performance.

#### Roles y aporte de cada participante

| Rol | Quién | Pregunta que responde | Aporte a la sesión |
|---|---|---|---|
| **Negocio** (Product Owner) | Carolina — PO del portal | *¿Qué problema resolvemos y para quién?* | Define el valor, prioriza reglas, decide qué queda fuera del alcance |
| **Desarrollo** | Douglas — Dev backend | *¿Cómo lo construimos y qué implica?* | Detecta impactos técnicos, estima esfuerzo, propone alternativas viables |
| **Calidad** (QA) | Marcela — Analista QA | *¿Cómo sabremos que funciona y qué puede fallar?* | Aporta casos de borde, escenarios negativos y define los criterios de aceptación verificables |

Este ejercicio materializa el criterio de la Unidad I sobre **conformación del equipo de test y desarrollo**: los tres roles definen juntos, *antes* de escribir código, qué significa "terminado". El resultado es un lenguaje ubicuo compartido.

#### Transcripción resumida de la sesión

> **Carolina (PO):** Necesito que un cliente registrado entre con usuario y contraseña y vea su información.
>
> **Marcela (QA):** ¿Y si se equivoca en la contraseña? ¿Le decimos que la contraseña está mala o que el usuario no existe?
>
> **Carolina:** Buena pregunta… ¿hay algún riesgo?
>
> **Douglas (Dev):** Sí. Si distinguimos ambos casos, un atacante puede enumerar qué usuarios existen probando nombres. Conviene un mensaje genérico.
>
> **Carolina:** De acuerdo, mensaje genérico entonces: *"Usuario o contraseña incorrectos"*.
>
> **Marcela:** ¿Y si deja los campos vacíos? No deberíamos ni consultar la base.
>
> **Douglas:** Correcto, validamos antes y devolvemos *"Debe completar usuario y contraseña"*. Además ese caso no debería consumir intentos.
>
> **Marcela:** ¿Cuántos intentos permitimos antes de bloquear?
>
> **Carolina:** Tres. Al cuarto, cuenta bloqueada.
>
> **Douglas:** ¿Y si acierta al segundo intento? ¿El contador se reinicia?
>
> **Carolina:** Sí, un login exitoso limpia el contador.
>
> **Marcela:** Perfecto. Con eso tengo cuatro escenarios: éxito, credenciales inválidas, campos vacíos y bloqueo. Los escribo en Gherkin y los revisamos.

#### Criterios de aceptación acordados

| # | Criterio | Ejemplo concreto discutido |
|---|---|---|
| CA-1 | Credenciales válidas → acceso concedido y saludo personalizado | `douglas` / `Clave123` → *"Bienvenido douglas"* |
| CA-2 | Contraseña incorrecta → mensaje genérico | `douglas` / `Clave999` → *"Usuario o contraseña incorrectos"* |
| CA-3 | Usuario inexistente → **el mismo** mensaje genérico (seguridad) | `inexistente` / `Clave123` → *"Usuario o contraseña incorrectos"* |
| CA-4 | Campos vacíos → validación previa, sin consultar el repositorio | `douglas` / `` → *"Debe completar usuario y contraseña"* |
| CA-5 | 3 intentos fallidos → cuenta bloqueada | `analista` con 3 fallos → *"Cuenta bloqueada por múltiples intentos fallidos"* |
| CA-6 | Login exitoso reinicia el contador de intentos | 1 fallo + 1 éxito → contador en 0 |

**Valor de la sesión.** Los criterios CA-3, CA-4 y CA-6 **no estaban en el requerimiento original**: emergieron de las preguntas de QA y de la advertencia de seguridad del desarrollador. Detectar estos tres huecos en una conversación de 20 minutos es órdenes de magnitud más barato que detectarlos como defectos en producción. Ese es el retorno concreto del Three Amigos.

> 📸 **Captura 10** — Tablero con los criterios de aceptación acordados.

---

### 3.2 Escenarios en Gherkin

Archivo `src/test/resources/features/login.feature` (escrito en español para que el negocio lo lea sin traducción):

```gherkin
# language: es
@login
Característica: Autenticación de usuarios en el portal
  Como usuario registrado del portal
  Quiero iniciar sesión con mis credenciales
  Para acceder a mi información privada de forma segura

  Antecedentes:
    Dado que el portal de autenticación está disponible

  @smoke @critico
  Escenario: Ingreso exitoso con credenciales válidas
    Cuando el usuario ingresa el usuario "douglas" y la contraseña "Clave123"
    Entonces el sistema concede el acceso
    Y se muestra el mensaje "Bienvenido douglas"

  @regresion
  Esquema del escenario: Ingreso rechazado con datos inválidos
    Cuando el usuario ingresa el usuario "<usuario>" y la contraseña "<password>"
    Entonces el sistema deniega el acceso
    Y se muestra el mensaje "<mensaje>"

    Ejemplos:
      | usuario     | password   | mensaje                              |
      | douglas     | Clave999   | Usuario o contraseña incorrectos     |
      | inexistente | Clave123   | Usuario o contraseña incorrectos     |
      | douglas     |            | Debe completar usuario y contraseña  |
      |             | Clave123   | Debe completar usuario y contraseña  |

  @seguridad
  Escenario: Bloqueo de la cuenta tras tres intentos fallidos
    Dado que el usuario "analista" ya registra 3 intentos fallidos
    Cuando el usuario ingresa el usuario "analista" y la contraseña "Qa2026*"
    Entonces el sistema deniega el acceso
    Y se muestra el mensaje "Cuenta bloqueada por múltiples intentos fallidos"
```

**Total: 6 escenarios ejecutables** (1 smoke + 4 filas del esquema + 1 de seguridad).

**Decisiones de escritura**

| Decisión | Fundamento |
|---|---|
| Narrativa *Como… Quiero… Para…* | Deja explícito el **valor de negocio**. Si nadie puede completar el "Para…", la funcionalidad no debería construirse. |
| `Antecedentes` | Extrae la precondición común a todos los escenarios; elimina repetición sin ocultar el contexto. |
| `Esquema del escenario` + `Ejemplos` | Un mismo comportamiento validado con cuatro juegos de datos. Cucumber reporta **cada fila como un escenario independiente**, así que la atomicidad se conserva. |
| Etiquetas (`@smoke`, `@regresion`, `@seguridad`, `@critico`) | Permiten ejecución selectiva: `mvn test -Dcucumber.filter.tags="@smoke"` en cada commit y la suite completa en la regresión nocturna. |
| Pasos declarativos, no imperativos | Se escribe *"el usuario ingresa el usuario X"* en vez de *"hace clic en el campo #user y escribe X"*. Si cambia la interfaz, el escenario sobrevive; solo se ajusta el step definition. |
| Lenguaje español (`# language: es`) | El documento vivo debe ser legible por quien define el negocio. |

---

### 3.3 Step definitions

Archivo `src/test/java/cl/iplacex/qa/bdd/steps/LoginSteps.java`:

```java
public class LoginSteps {

    private ServicioAutenticacion servicio;
    private ResultadoLogin resultado;

    /** Hook: se ejecuta antes de CADA escenario -> sin contaminación entre escenarios. */
    @Before
    public void iniciarContexto() {
        servicio = null;
        resultado = null;
    }

    @Dado("que el portal de autenticación está disponible")
    public void elPortalEstaDisponible() {
        servicio = new ServicioAutenticacion();
        assertNotNull(servicio, "El servicio de autenticación debe estar inicializado");
    }

    @Dado("que el usuario {string} ya registra {int} intentos fallidos")
    public void elUsuarioYaRegistraIntentosFallidos(String usuario, int intentos) {
        for (int i = 0; i < intentos; i++) {
            servicio.registrarIntentoFallido(usuario);
        }
        assertEquals(intentos, servicio.intentosDe(usuario));
    }

    @Cuando("el usuario ingresa el usuario {string} y la contraseña {string}")
    public void elUsuarioIngresaCredenciales(String usuario, String password) {
        resultado = servicio.autenticar(usuario, password);
    }

    @Entonces("el sistema concede el acceso")
    public void elSistemaConcedeElAcceso() {
        assertTrue(resultado.exitoso(),
                "Se esperaba acceso concedido, pero el estado fue: " + resultado.estado());
    }

    @Entonces("el sistema deniega el acceso")
    public void elSistemaDeniegaElAcceso() {
        assertFalse(resultado.exitoso(),
                "Se esperaba acceso denegado, pero el login fue exitoso");
    }

    @Y("se muestra el mensaje {string}")
    public void seMuestraElMensaje(String mensajeEsperado) {
        assertEquals(mensajeEsperado, resultado.mensaje());
    }
}
```

**Buenas prácticas aplicadas**

| Práctica | Implementación | Beneficio |
|---|---|---|
| Un paso hace una sola cosa | Los `@Dado` preparan, los `@Cuando` actúan, los `@Entonces` verifican | Los pasos se recombinan libremente entre escenarios |
| Aserciones solo en `Entonces` | Ningún `assert` de resultado en los pasos de acción | El escenario falla donde corresponde conceptualmente |
| Estado en campos de instancia | Cucumber instancia la clase **por escenario** | Aislamiento total: cada escenario es atómico |
| Hook `@Before` | Reinicia el contexto antes de cada escenario | Blinda contra fugas de estado si se agregan steps compartidos |
| Expresiones parametrizadas `{string}`, `{int}` | Un solo step sirve a las 4 filas del `Esquema del escenario` | Menos código que mantener |
| Sin lógica de negocio en los steps | Los steps solo llaman a `ServicioAutenticacion` | Si el negocio cambia, la prueba falla — que es justo lo que debe pasar |
| Mensajes descriptivos en las aserciones | `"Se esperaba acceso concedido, pero el estado fue: ..."` | El reporte de CI se diagnostica sin abrir el código |

El runner declara la suite y sus reportes:

```java
@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("features")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "cl.iplacex.qa.bdd.steps")
@ConfigurationParameter(
        key = PLUGIN_PROPERTY_NAME,
        value = "pretty,"
              + "html:target/cucumber-reports/cucumber.html,"
              + "json:target/cucumber-reports/cucumber.json,"
              + "junit:target/cucumber-reports/cucumber.xml")
public class BddTestRunner { }
```

> 📸 **Captura 11** — Ejecución de `mvn test -Dtest='BddTestRunner'` con los 6 escenarios en verde.

---

### 3.4 Integración de BDD al pipeline

Los escenarios BDD se integran al **mismo pipeline** creado en la Actividad 1, como un paso explícito posterior a las unitarias:

```yaml
      - name: Ejecutar pruebas unitarias (JUnit 5)
        run: mvn -B test -Dtest='*Test' -DfailIfNoTests=false

      - name: Ejecutar escenarios BDD (Cucumber)
        run: mvn -B test -Dtest='BddTestRunner' -DfailIfNoTests=false
```

**Por qué en pasos separados y en ese orden.** Las unitarias son más rápidas y más específicas: si falla la lógica de `ServicioAutenticacion`, conviene enterarse por la prueba unitaria (que apunta al método exacto) antes que por el escenario BDD (que apunta a un comportamiento completo). Es el principio de la pirámide de pruebas aplicado al orden de ejecución: **fallar rápido y fallar barato**. Además, separar los pasos hace que el log de CI muestre de inmediato qué capa se rompió.

Ambas suites corren sobre JUnit Platform, así que Surefire las ejecuta con la misma configuración y produce reportes homogéneos que el pipeline consume sin adaptadores.

---

### 3.5 Reporte navegable de BDD

Cucumber emite tres formatos en paralelo, cada uno con un consumidor distinto:

| Formato | Archivo | Consumidor |
|---|---|---|
| **HTML** | `target/cucumber-reports/cucumber.html` | Personas: navegable, con cada escenario expandible, sus pasos y su duración |
| **JSON** | `target/cucumber-reports/cucumber.json` | Herramientas: alimenta Allure, dashboards y agregadores históricos |
| **JUnit XML** | `target/cucumber-reports/cucumber.xml` | El pipeline: lo lee `dorny/test-reporter` para pintar los resultados en el propio commit |

Publicación en CI:

```yaml
      - name: Publicar reporte BDD (HTML navegable)
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: reporte-bdd-cucumber
          path: target/cucumber-reports/
          retention-days: 30
```

**Alternativa evaluada: Allure.** Se consideró Allure Report, que agrega historial de tendencias y adjuntos (capturas ante fallo). Se descartó para este taller porque exige un paso adicional de instalación en el runner y un servidor para publicar el historial; el HTML nativo de Cucumber cubre el requisito de "reporte navegable" sin infraestructura extra. La ruta de migración queda abierta: el `cucumber.json` ya generado es exactamente el insumo que Allure necesita.

> 📸 **Captura 12** — `cucumber.html` abierto en el navegador, con los escenarios expandidos.
> 📸 **Captura 13** — Artefactos descargables en la ejecución de GitHub Actions.

---

### 3.6 Prueba de performance e indicadores

#### Funcionalidad seleccionada

Elegimos el **login** por tres razones convergentes. Es la puerta de entrada del sistema: si se degrada, todas las demás funcionalidades quedan inaccesibles, aunque estén perfectamente sanas. Es el punto de mayor concurrencia, porque el ingreso se concentra en la franja de inicio de jornada mientras el resto del tráfico se distribuye durante el día. Y es la misma funcionalidad definida en la sesión Three Amigos y cubierta por los escenarios BDD, de modo que las tres capas de prueba —unitaria, funcional y de carga— convergen sobre el mismo componente.

#### Herramienta seleccionada: k6

Evaluamos también JMeter, pero nos fuimos por k6 porque el script es un archivo JavaScript que se versiona junto al código y se revisa en un pull request como cualquier otro cambio, mientras que un plan `.jmx` es un XML generado por interfaz gráfica, difícil de revisar en un diff. Además k6 corre sin interfaz y sus umbrales devuelven un código de salida distinto de cero, lo que permite que el pipeline reaccione automáticamente ante una degradación.

#### Decisión de diseño: medir la propia aplicación

La primera versión de esta prueba apuntaba a una API pública de terceros. Los resultados fueron los siguientes:

| Indicador | Valor obtenido |
|---|---|
| Latencia promedio | 1,76 ms |
| Latencia p(95) | 2,70 ms |
| Tasa de respuestas inesperadas | 1,0000 (100%) |

Esas cifras son internamente contradictorias y conviene detenerse en por qué. Una latencia promedio de 1,76 ms es **físicamente imposible** para una petición que viaja por internet hasta un servidor remoto: solo el trayecto de ida y vuelta cuesta decenas de milisegundos. Al mismo tiempo, el 100% de las respuestas resultó inesperada pese a que la prueba declaraba explícitamente los códigos 200, 400 y 401 como válidos, lo que indica que el servidor devolvía un código distinto de esos.

La explicación es que el proveedor detectó 100 usuarios virtuales concurrentes y activó su limitador de tasa, respondiendo con rechazos inmediatos desde su capa de borde sin llegar nunca al servidor de aplicación. **Lo que se estaba midiendo era la velocidad con que un intermediario descarta tráfico, no el rendimiento del login.** Las métricas eran técnicamente correctas y sustantivamente inútiles.

Este episodio ilustra un riesgo central de las pruebas de performance: a diferencia de una prueba funcional, que falla de forma visible, una prueba de carga mal dirigida **entrega números plausibles que nadie cuestiona**. Un informe que reportara "latencia promedio de 1,76 ms" habría pasado por excelente cuando en realidad no medía nada.

La corrección fue eliminar la dependencia externa: se expuso el propio `ServicioAutenticacion` mediante un servidor HTTP liviano construido con `com.sun.net.httpserver`, incluido en el JDK y sin agregar dependencias al proyecto. La prueba de carga mide ahora exactamente el mismo componente que verifican las pruebas unitarias y los escenarios BDD, el resultado es reproducible y no depende de la red ni de la disponibilidad de un tercero.

```java
/**
 * Instancia única compartida por todas las peticiones, igual que en una
 * aplicación real. Por eso ServicioAutenticacion usa colecciones concurrentes.
 */
private static final ServicioAutenticacion SERVICIO = new ServicioAutenticacion();

// El estado del dominio se traduce al código HTTP que le corresponde.
int codigo = switch (resultado.estado()) {
    case EXITOSO                -> 200;  // acceso concedido
    case CREDENCIALES_INVALIDAS -> 401;  // rechazo de negocio
    case DATOS_INCOMPLETOS      -> 400;  // petición mal formada
    case BLOQUEADO              -> 423;  // recurso bloqueado
};
```

#### Perfil de carga

```javascript
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // calentamiento
    { duration: '1m',  target: 50 },  // carga nominal de hora peak
    { duration: '30s', target: 100 }, // carga de estrés: 2x lo esperado
    { duration: '30s', target: 0 },   // bajada: verifica la recuperación
  ],
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<500'],
    'http_req_failed':   ['rate<0.01'],
    'http_reqs':         ['rate>15'],
  },
};
```

Se usó una **rampa escalonada** y no una carga plana. Una carga plana solo responde "aguanta o no aguanta"; la rampa permite identificar *en qué nivel* de carga aparece la degradación, que es lo que permite dimensionar la infraestructura con evidencia. La rampa de bajada final verifica además que el servicio se **recupera** tras el peak y no queda degradado.

Cada iteración incluye un `sleep(1)` como *think time*. Sin esa pausa no se simularían usuarios sino un ataque de denegación de servicio, y los números resultantes llevarían a sobredimensionar la infraestructura.

#### Resultados obtenidos

Ejecución del 26-08-2026 contra `http://localhost:8080/auth/login`, duración 2 min 30 s:

| Indicador | Resultado | Umbral (SLO) | Estado |
|---|---|---|---|
| Peticiones totales | 5.716 | — | — |
| Throughput (TPS) | 37,99 req/s | > 15 req/s | ✅ Cumple |
| Latencia mínima | 0,00 ms | — | — |
| Latencia promedio | 0,32 ms | — | — |
| Latencia mediana p(50) | 0,50 ms | — | — |
| Latencia p(90) | 0,60 ms | — | — |
| **Latencia p(95)** | **0,74 ms** | < 200 ms | ✅ Cumple |
| **Latencia p(99)** | **1,12 ms** | < 500 ms | ✅ Cumple |
| Latencia máxima | 5,84 ms | — | — |
| Tasa de respuestas inesperadas | 0,0000 | < 0,01 | ✅ Cumple |
| Usuarios virtuales máximos | 100 | — | — |

Distribución de respuestas: **5.716 logins exitosos (200), cero rechazos de negocio, cero respuestas limitadas por tasa, cero errores de servidor y cero peticiones sin respuesta.**

#### Análisis de los indicadores

**Throughput (TPS): 37,99 req/s.** El servicio procesó casi 38 transacciones por segundo de forma sostenida. Conviene ser preciso al interpretar este número: **no es la capacidad máxima del servicio**, sino el resultado del perfil de carga aplicado. Con 100 usuarios virtuales y un think time de un segundo, el techo aritmético del experimento está alrededor de 100 peticiones por segundo, y el valor observado refleja la mezcla de las etapas de rampa. El servicio nunca se acercó a su límite.

**Latencia p(95) = 0,74 ms y p(99) = 1,12 ms.** Se observan los percentiles y no el promedio, porque el promedio esconde la cola: un promedio de 300 ms puede convivir con un 5% de usuarios esperando cuatro segundos, y son justamente esos usuarios los que abandonan o reclaman. El p(95) indica que el 95% de las peticiones se resolvió en menos de 0,8 ms y el p(99) que incluso el percentil más castigado se mantuvo por debajo de 1,2 ms. La distancia entre la mediana (0,50 ms) y el máximo (5,84 ms) es de un orden de magnitud, lo que corresponde a los picos normales del recolector de basura de la JVM y no a un patrón de degradación.

**Tasa de respuestas inesperadas: 0,0000.** Ninguna de las 5.716 peticiones devolvió un código fuera del contrato. Este indicador mide **estabilidad**, no velocidad: un servicio que responde rápido pero con error no está sano. Es habitual que bajo carga aparezcan errores 5xx por agotamiento del pool de conexiones o timeouts; aquí no ocurrió ninguno.

**Concurrencia: 100 usuarios virtuales, cero iteraciones interrumpidas.** El servicio atendió el doble de la carga nominal esperada sin degradarse ni perder peticiones.

#### Hallazgo: un defecto que solo la carga podía revelar

Al exponer `ServicioAutenticacion` a peticiones concurrentes se detectó que sus colecciones internas eran `HashMap`, una estructura **no segura para acceso concurrente**. Bajo múltiples hilos un `HashMap` puede perder escrituras y, al redimensionar su tabla interna, dejarla en un estado que provoca un bucle infinito con el consiguiente consumo del 100% de CPU.

Se corrigió sustituyéndolo por `ConcurrentHashMap`.

Lo relevante para la estrategia de pruebas es que **ninguna de las doce pruebas unitarias ni de los seis escenarios BDD podía detectar este defecto**, porque todos se ejecutan en un solo hilo. Un defecto de concurrencia no es un caso de borde que se olvidó cubrir: es una clase de fallo estructuralmente invisible para las pruebas funcionales, que solo se manifiesta bajo carga real. Es el argumento más concreto de por qué la prueba de performance no es un complemento opcional de la estrategia, sino una capa que cubre riesgos que las demás no alcanzan.

#### Limitación reconocida y siguiente experimento

Los umbrales se cumplieron con un margen amplísimo —el p(95) quedó 270 veces por debajo del límite— lo que confirma que el servicio soporta con holgura la carga esperada, pero **también significa que la prueba no encontró el punto de saturación**. Se sabe que el servicio aguanta 100 usuarios concurrentes; no se sabe cuántos aguanta.

Reportar este resultado como "el servicio tiene excelente performance" sería una conclusión más fuerte que la evidencia. Lo correcto es afirmar lo que se midió: *bajo la carga esperada, el servicio responde dentro de los SLO definidos.*

El siguiente experimento, para caracterizar la capacidad real, consiste en eliminar el think time y escalar los usuarios virtuales hasta que la latencia p(95) cruce el umbral o aparezcan errores. Ese punto de quiebre es el dato que permite dimensionar infraestructura y definir a partir de qué volumen de usuarios el sistema necesita escalar.

#### Conclusión de la sección

La prueba cumplió sus dos funciones. Verificó que el login sostiene el doble de la carga esperada dentro de los umbrales definidos, y —de forma menos esperada pero más valiosa— reveló un defecto de concurrencia invisible para el resto de la suite. También dejó una lección metodológica: una prueba de carga mal dirigida no falla de forma evidente, entrega números plausibles. Validar *qué* se está midiendo es tan importante como medirlo.

> 📸 **CAPTURA 14** — Ejecución de k6 con el resumen de métricas y el estado de cada umbral.


### 3.7 Dashboard de métricas del pipeline

**Objetivo.** Que cualquier integrante del equipo responda en menos de diez segundos y sin instalar nada: *¿está sana la aplicación en este momento?*

#### Flujo de datos

```
   Pruebas funcionales                 Prueba de performance
  (Surefire XML + Cucumber JSON)          (k6 summary.json)
            │                                    │
            └────────────┬───────────────────────┘
                         ▼
              Job "reportes-y-alertas"
              (download-artifact consolida)
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
    GitHub Pages              Grafana / InfluxDB
   (URL fija navegable)       (tendencia histórica)
```

#### Implementación en el pipeline

```yaml
  reportes-y-alertas:
    name: Dashboard y alertas
    runs-on: ubuntu-latest
    needs: [ build-and-test, performance ]
    if: always()
    steps:
      - uses: actions/checkout@v4

      - name: Descargar todos los reportes
        uses: actions/download-artifact@v4
        with:
          path: reportes/

      - name: Publicar dashboard en GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        if: github.ref == 'refs/heads/main'
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./reportes
          destination_dir: dashboard
```

#### Métricas expuestas en el dashboard

| Bloque | Métrica | Origen | Por qué está en el dashboard |
|---|---|---|---|
| **Funcional** | Pruebas ejecutadas / exitosas / fallidas | Surefire XML | Estado inmediato de la suite |
| | % de escenarios BDD aprobados | Cucumber JSON | Cumplimiento de los criterios de aceptación del negocio |
| | Duración de la suite | Surefire XML | Una suite que crece en tiempo deja de ejecutarse; hay que vigilarla |
| | Pruebas inestables (*flaky*) | Historial de ejecuciones | Una prueba que falla al azar destruye la confianza en la CI |
| **Performance** | TPS, p(95), p(99), tasa de error | k6 summary.json | Tendencia de la capacidad y la experiencia de usuario |
| **Proceso** | Tasa de éxito del pipeline | GitHub Actions API | Salud del proceso de integración |
| | Tiempo medio de build | GitHub Actions API | Si el build tarda demasiado, el equipo deja de integrar seguido |
| | Frecuencia de integración | Historial de commits | Mide si la integración es realmente *continua* |

#### Simulación de la evolución esperada

| Ejecución | Escenarios BDD | Unitarias | p(95) | Tasa error | Estado |
|---|---|---|---|---|---|
| #41 | 6/6 | 12/12 | 612 ms | 0,2 % | ✅ Verde |
| #42 | 6/6 | 12/12 | 640 ms | 0,3 % | ✅ Verde |
| #43 | 5/6 | 12/12 | 655 ms | 0,4 % | ❌ Falla funcional → build bloqueado |
| #44 | 6/6 | 12/12 | 1 180 ms | 0,9 % | ⚠️ Umbral p(95) incumplido → alerta de degradación |
| #45 | 6/6 | 12/12 | 630 ms | 0,2 % | ✅ Verde tras corrección |

La ejecución #44 ilustra el valor del dashboard: **todas las pruebas funcionales pasaron**, pero la latencia casi se duplicó. Sin métricas de performance en el pipeline, esa regresión habría llegado a producción sin que nadie la notara hasta recibir reclamos de usuarios.

**Evolución natural.** Para una tendencia histórica de largo plazo, el paso siguiente es enviar las métricas de k6 a InfluxDB (`k6 run --out influxdb=http://influx:8086/k6`) y graficarlas en **Grafana**, que permite comparar la latencia de hoy contra la del mismo día de la semana anterior. GitHub Pages resuelve el "estado actual"; Grafana resuelve la "tendencia".

> 📸 **Captura 15** — Dashboard publicado en GitHub Pages.
> 📸 **Captura 16** — Resumen del build con la tarjeta de resultados de pruebas.

---

### 3.8 Alertas automáticas

**Principio de diseño: alertar solo lo accionable.** Una alerta que llega y nadie actúa entrena al equipo a ignorarlas (*alert fatigue*). Por eso cada alerta responde tres preguntas: **qué falló, dónde y quién debe actuar**.

#### Matriz de alertas configuradas

| Evento | Severidad | Canal | Destinatario | Acción esperada |
|---|---|---|---|---|
| Falla una prueba funcional en una rama `feature/**` | Baja | Notificación de GitHub | Autor del commit | Corregir antes de abrir el PR |
| Falla el build en un pull request | Media | Comentario automático en el PR + bloqueo del merge | Autor y revisor | El PR no se puede fusionar |
| **Falla el build en `main`** | **Alta** | Slack `#qa-alertas` + issue automático | Todo el equipo | Detener merges y corregir de inmediato |
| Degradación de performance (umbral incumplido) | Media | Slack `#qa-alertas` | Líder técnico + QA | Analizar el reporte k6 y decidir si bloquea el release |
| Falla la regresión nocturna programada | Media | Slack + correo | QA de turno | Revisar al inicio de la jornada |
| Prueba inestable (*flaky*) detectada | Baja | Issue automático etiquetado `flaky` | QA | Estabilizar o cuarentena |

#### Implementación

**Alerta de fallo del build:**

```yaml
      - name: Alerta a Slack ante fallo del pipeline
        if: needs.build-and-test.result == 'failure'
        uses: slackapi/slack-github-action@v1.26.0
        with:
          payload: |
            {
              "text": ":rotating_light: *Build fallido* en `${{ github.repository }}`\n*Rama:* ${{ github.ref_name }}\n*Autor:* ${{ github.actor }}\n*Commit:* ${{ github.sha }}\n<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|Ver ejecución y reporte>"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

**Alerta de degradación de performance:**

```yaml
      - name: Alerta por degradación de performance
        if: needs.performance.result == 'failure'
        uses: slackapi/slack-github-action@v1.26.0
        with:
          payload: |
            {
              "text": ":chart_with_downwards_trend: *Degradación de performance detectada*\nSe incumplieron los umbrales de latencia p(95) o tasa de error en el login.\n<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|Revisar resultados k6>"
            }
```

**Issue automático ante fallo en `main`:**

```yaml
      - name: Crear issue automático ante fallo en main
        if: failure() && github.ref == 'refs/heads/main'
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `[CI] Fallo automático en main - run #${context.runNumber}`,
              body: `El pipeline falló en el commit ${context.sha}.\nRevisar: ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`,
              labels: ['ci', 'bug', 'prioridad-alta']
            })
```

#### Ejemplo de alerta recibida (simulación)

```
🚨 Build fallido en cadem/qa-automation-ci
Rama: main
Autor: dsuarez
Commit: 6678f84
▸ Ver ejecución y reporte

Detalle: cl.iplacex.qa.bdd.runner.BddTestRunner
Escenario: "Bloqueo de la cuenta tras tres intentos fallidos"
  ✗ se muestra el mensaje "Cuenta bloqueada por múltiples intentos fallidos"
    expected: <Cuenta bloqueada por múltiples intentos fallidos>
     but was: <Usuario o contraseña incorrectos>
```

La alerta contiene lo necesario para diagnosticar **sin abrir el repositorio**: qué escenario falló, qué se esperaba, qué ocurrió y un enlace directo al reporte completo.

#### Hallazgo: una alerta que fallaba en silencio

Durante la puesta en marcha se detectó un defecto en la propia definición del pipeline. Los pasos de notificación evaluaban la condición `env.SLACK_WEBHOOK_URL != ''` mientras la variable se declaraba en el bloque `env` **de ese mismo paso**:

```yaml
# INCORRECTO
- name: Alerta a Slack
  if: needs.build-and-test.result == 'failure' && env.SLACK_WEBHOOK_URL != ''
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

GitHub Actions evalúa la condición `if` de un paso **antes** de aplicar su bloque `env`. La comprobación leía por tanto una variable que aún no existía, obtenía siempre cadena vacía, y las alertas nunca se habrían disparado — ni siquiera con el secret correctamente configurado. La corrección fue declarar la variable a nivel de job, donde ya está disponible cuando se evalúan las condiciones de los pasos:

```yaml
# CORRECTO
jobs:
  reportes-y-alertas:
    env:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    steps:
      - name: Alerta a Slack
        if: needs.build-and-test.result == 'failure' && env.SLACK_WEBHOOK_URL != ''
```

El caso ilustra un riesgo propio de los mecanismos de alerta, distinto del de las pruebas. Una prueba mal escrita falla de forma visible y alguien la corrige. **Una alerta mal configurada falla en silencio**: el pipeline se ve verde, nadie recibe notificaciones, y el equipo opera con una falsa sensación de cobertura que solo se descubre el día en que la alerta debía haber sonado. Por eso las alertas deben probarse deliberadamente —forzando la condición que las dispara— y no darse por funcionales porque el YAML sea sintácticamente válido.

#### Decisiones de configuración

| Decisión | Fundamento |
|---|---|
| Solo se alerta a Slack cuando falla `main` o hay degradación | Un fallo en una rama personal es asunto de su autor. Alertar todo produce ruido y el equipo deja de mirar el canal. |
| El webhook viaja en `secrets.SLACK_WEBHOOK_URL` | Nunca en el código. Es exactamente lo que protege la sección de secretos del `.gitignore`. |
| Issue automático solo en `main` | Deja registro trazable de las incidencias en la rama estable, con etiquetas para priorizar. |
| Distinguir fallo funcional de degradación | Requieren decisiones y responsables distintos: el fallo funcional bloquea; la degradación se evalúa. |
| Cada alerta incluye enlace directo a la ejecución | Reduce el tiempo de diagnóstico: un clic en vez de navegar el repositorio. |

> 📸 **Captura 17** — Mensaje de alerta recibido en el canal de Slack.
> 📸 **Captura 18** — Issue creado automáticamente por el pipeline.

---

## 4. Conclusiones

**1. La integración continua solo funciona si es una puerta de calidad real.** La configuración `testFailureIgnore=false` es la línea más importante del `pom.xml`: sin ella el pipeline ejecutaría pruebas, informaría fallos y dejaría pasar el código igual. Automatizar sin capacidad de bloqueo es teatro de calidad.

**2. La atomicidad se diseña en el código productivo, no solo en la prueba.** `Calculadora` no tiene estado y `ResultadoLogin` es un `record` inmutable. Ese diseño es lo que hace posible que las pruebas sean independientes entre sí. Cuando cuesta escribir una prueba atómica, el problema casi siempre está en el diseño de la clase, no en la prueba.

**3. El mayor valor del BDD ocurre antes de escribir código.** Tres de los seis criterios de aceptación (mensaje genérico por seguridad, validación previa sin consumir intentos, reinicio del contador) no existían en el requerimiento original: surgieron de las preguntas hechas en la sesión Three Amigos. El archivo `.feature` es el resultado visible; la conversación fue el verdadero producto.

**4. Hay defectos que ninguna prueba funcional puede encontrar.** Al exponer `ServicioAutenticacion` a 100 usuarios concurrentes se descubrió que usaba `HashMap`, una estructura no segura bajo múltiples hilos: puede perder escrituras y, al redimensionarse, entrar en un bucle infinito. Ninguna de las doce pruebas unitarias ni de los seis escenarios BDD podía detectarlo, porque todos se ejecutan en un solo hilo. No es un caso de borde que se olvidó cubrir: es una clase de fallo estructuralmente invisible para las pruebas funcionales. Ese es el argumento más concreto de por qué la prueba de performance no es un complemento opcional de la estrategia, sino una capa que cubre riesgos que las demás no alcanzan.

**5. Una medición sin validar es peor que no medir.** La primera versión de la prueba de carga apuntaba a una API pública y entregó "1,76 ms de latencia promedio": una cifra excelente, plausible, y completamente falsa — medía la velocidad con que un CDN rechazaba el tráfico. A diferencia de una prueba funcional, que falla de forma visible, una prueba de carga mal dirigida produce números que nadie cuestiona. Validar *qué* se está midiendo resultó tan importante como medirlo.

**6. Los mecanismos de alerta fallan en silencio.** El defecto en la condición `if` de los pasos de notificación habría dejado al equipo sin alertas mientras el pipeline se veía perfectamente verde. Una cobertura que se cree tener y no se tiene es más peligrosa que la ausencia reconocida de cobertura, porque elimina la vigilancia sin eliminar el riesgo.

**7. La visibilidad convierte los datos en decisiones.** Reportes que nadie abre no mejoran la calidad. Publicarlos en tres vías —resumen en el commit, artefactos descargables y una URL permanente— junto a alertas que llegan al canal de trabajo es lo que cierra el ciclo entre *medir* y *actuar*.

**8. Articulación de ambas unidades.** Los conceptos de la Unidad I (estrategias de prueba en ambientes de desarrollo, atomicidad con alta cohesión y bajo acoplamiento, selección del test adecuado, equipo de test y desarrollo) no son teoría previa a la automatización: son la condición que hace que la automatización de la Unidad II rinda. Un pipeline que ejecuta pruebas acopladas y lentas se vuelve un cuello de botella que el equipo termina desactivando.

---

## 5. Anexo: cobertura de la pauta de evaluación

| # | Indicador de logro | Pts | Dónde se evidencia |
|---|---|---|---|
| 1 | Implementación de integración continua y pipeline automático | 15 | §2.5 — `ci.yml` con 3 jobs encadenados, disparadores en push/PR/cron, permisos mínimos explícitos, caché y control de concurrencia. Ejecutado en GitHub Actions |
| 2 | Estructura y atomicidad de la suite de pruebas | 10 | §2.3 y §2.4 — 12 pruebas atómicas en 127 ms, `@BeforeEach`, clases sin estado, estructura Maven separando `unit/`, `bdd/` y `app/` |
| 3 | Calidad y documentación de commits y gestión de versiones | 10 | §2.1 — 22 commits con Conventional Commits, 4 ramas feature, merges `--no-ff`, `.gitattributes` para normalizar fin de línea |
| 4 | Configuración y evidencia de reporte navegable | 10 | §2.6 — Surefire HTML, test-reporter en el commit, artefactos descargables y GitHub Pages |
| 5 | Correcta definición y automatización de escenarios BDD | 10 | §3.2 y §3.3 — 6 escenarios Gherkin con `Esquema del escenario` + `Ejemplos`, step definitions y runner con 3 formatos de reporte |
| 6 | Simulación de trabajo colaborativo y claridad de criterios | 10 | §3.1 — Sesión Three Amigos con roles, transcripción y 6 criterios de aceptación, tres de ellos emergentes de la conversación |
| 7 | Prueba de performance y análisis de indicadores | 10 | §3.6 — 5.716 peticiones con 100 VUs contra la propia aplicación, p(95) 0,74 ms, análisis de TPS/latencia/estabilidad y hallazgo de concurrencia |
| 8 | Visualización de métricas y reporting en dashboards | 10 | §3.7 — Flujo de datos, métricas en el resumen de la ejecución, GitHub Pages y ruta a Grafana/InfluxDB |
| 9 | Propuesta y simulación de alertas automáticas | 10 | §3.8 — Matriz de 6 alertas, implementación en YAML, ejemplo de mensaje y corrección de un fallo silencioso en la condición |
| 10 | Documentación completa y claridad del README.md | 10 | `README.md` — objetivos, estructura, archivos clave, comandos, reportes y explicación del pipeline |
| | **Total** | **100** | |

---

### Anexo B — Cómo reproducir el proyecto

```bash
# 1. Clonar y situarse en el proyecto
git clone <url-del-repositorio>
cd qa-automation-ci

# 2. Ver el historial de versionado
git log --oneline --graph --all

# 3. Ejecutar toda la suite
mvn clean test

# 4. Generar el reporte HTML navegable
mvn surefire-report:report-only site:site -DgenerateReports=false
#    → abrir target/site/surefire-report.html
#    → abrir target/cucumber-reports/cucumber.html

# 5. Ejecutar solo el smoke test BDD
mvn test -Dcucumber.filter.tags="@smoke"

# 6. Ejecutar la prueba de performance
k6 run performance/login-performance.js
```

**Requisitos:** JDK 17+, Maven 3.8+, Git 2.30+ y k6 (opcional, solo para el punto 6).
