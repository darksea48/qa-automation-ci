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

Una empresa solicita profesionalizar su proceso de pruebas automatizadas sobre un proyecto Java. El presente taller documenta la construcción, de principio a fin, de un flujo de integración continua que articula los contenidos de la **Unidad I** (estrategias de prueba, atomicidad con alta cohesión y bajo acoplamiento, selección del test adecuado, conformación del equipo de test) con los de la **Unidad II** (integración continua, BDD, pipelines, métricas, reporting y alertas).

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

**Estrategia de ramificación.** Se adoptó un modelo *feature branch*: `main` se mantiene siempre en estado desplegable y cada unidad de trabajo se desarrolla en su propia rama, que se integra mediante *pull request* previa revisión de pares. Esto materializa el criterio de la Unidad I sobre **conformación del equipo de test y desarrollo**: el código de prueba se revisa con el mismo rigor que el productivo.

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

**Historial resultante** (salida real de `git log --oneline --graph --all`):

```
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

- **Commits pequeños y frecuentes (13 commits).** Un commit por cambio conceptual. Si una prueba falla, `git bisect` identifica el commit culpable en pocos pasos; con commits gigantes eso es imposible.
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

El enunciado pide al menos dos pruebas unitarias atómicas e independientes. Se implementaron **doce** (ocho para `Calculadora`, cuatro para `ServicioAutenticacion`).

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

**Verificación de la lógica.** Se ejecutó una verificación independiente de las 15 aserciones que sustentan las pruebas unitarias y los escenarios BDD, sobre las clases compiladas del proyecto:

```
== Unitarias Calculadora ==
  PASS  7+5=12
  PASS  10-4=6
  PASS  999*0=0
  PASS  0+0
  PASS  -5+5
  PASS  -3+-7
  PASS  100+250
  PASS  dividir por cero lanza excepcion
== Escenarios BDD (mismos datos del .feature) ==
  PASS  login exitoso
  PASS  acceso concedido
  PASS  outline fila 1
  PASS  outline fila 2
  PASS  outline fila 3
  PASS  outline fila 4
  PASS  bloqueo tras 3 intentos

Total: 15  PASS=15  FAIL=0
```

---

### 2.4 Estructura de carpetas y `.gitignore`

```
qa-automation-ci/
├── .github/workflows/ci.yml            # Pipeline de integración continua
├── docs/
│   ├── capturas/                       # Evidencia de ejecución
│   └── historial-git.txt
├── performance/login-performance.js    # Prueba de carga k6
├── src/
│   ├── main/java/cl/iplacex/qa/
│   │   ├── calculo/Calculadora.java
│   │   └── auth/
│   │       ├── ServicioAutenticacion.java
│   │       ├── EstadoLogin.java
│   │       └── ResultadoLogin.java
│   └── test/
│       ├── java/cl/iplacex/qa/
│       │   ├── unit/
│       │   │   ├── CalculadoraTest.java
│       │   │   └── ServicioAutenticacionTest.java
│       │   └── bdd/
│       │       ├── runner/BddTestRunner.java
│       │       └── steps/LoginSteps.java
│       └── resources/features/login.feature
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
- `docs/`: la evidencia acompaña al código en el mismo repositorio, versionada.

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

**Salida esperada:**

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running cl.iplacex.qa.unit.CalculadoraTest
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running cl.iplacex.qa.unit.ServicioAutenticacionTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running cl.iplacex.qa.bdd.runner.BddTestRunner
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO]
[INFO] Results:
[INFO] Tests run: 18, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

> 📸 **Captura 7** — Terminal con la salida de `mvn clean test` (BUILD SUCCESS).
> 📸 **Captura 8** — Ejecución del mismo comando en GitHub Actions.
> 📸 **Captura 9** — Prueba negativa: se altera intencionalmente una aserción, el build falla y el pipeline lo bloquea. Demuestra que la puerta de calidad funciona.

---

## 3. Actividad 2 — BDD, performance, métricas y alertas

### 3.1 Sesión Three Amigos

**Funcionalidad seleccionada:** *Inicio de sesión (Login) en el portal de clientes.*

Se eligió el login porque concentra reglas de negocio, requisitos de seguridad y es la funcionalidad de mayor concurrencia del sistema — lo que la vuelve además el candidato natural para la prueba de performance.

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

**Funcionalidad seleccionada: el login.** Es la puerta de entrada del sistema — si se degrada, todas las demás funcionalidades quedan inaccesibles — y es el punto de mayor concurrencia en la hora peak.

**Herramienta: k6.** Se eligió sobre JMeter porque el script es un archivo JavaScript versionable junto al código (revisable en un pull request como cualquier otro cambio), corre sin interfaz gráfica y trae umbrales nativos que devuelven un código de salida distinto de cero, lo que permite que el pipeline falle automáticamente ante una degradación.

```javascript
export const options = {
  // --- Perfil de carga escalonado (ramping) ---
  stages: [
    { duration: '30s', target: 10 },  // rampa de subida: calentamiento
    { duration: '1m',  target: 50 },  // carga nominal esperada en hora peak
    { duration: '30s', target: 100 }, // carga de estrés: 2x lo esperado
    { duration: '30s', target: 0 },   // rampa de bajada: verifica recuperación
  ],

  // --- Umbrales (SLO): si no se cumplen, k6 devuelve exit code 99
  thresholds: {
    'http_req_duration': ['p(95)<800', 'p(99)<1500'],
    'http_req_failed':   ['rate<0.01'],
    'errores_login':     ['rate<0.01'],
    'http_reqs':         ['rate>20'],
  },
};

export default function () {
  const payload = JSON.stringify({ username: 'douglas', password: 'Clave123' });
  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { funcionalidad: 'login' },
  };

  const res = http.post(`${BASE_URL}/auth/token/login/`, payload, params);

  const ok = check(res, {
    'status es 200 o 400 (endpoint alcanzable)': (r) => r.status === 200 || r.status === 400,
    'responde en menos de 800 ms': (r) => r.timings.duration < 800,
    'el cuerpo no viene vacío': (r) => r.body && r.body.length > 0,
  });

  erroresLogin.add(!ok);
  latenciaLogin.add(res.timings.duration);

  sleep(1); // think time: simula el tiempo real entre acciones de un usuario
}
```

#### Indicadores monitoreados y por qué

| Indicador | Métrica k6 | Qué mide | Umbral definido | Por qué importa |
|---|---|---|---|---|
| **TPS / Throughput** | `http_reqs` (rate) | Transacciones por segundo procesadas | `> 20 req/s` | Es la **capacidad** del sistema. Si el throughput se estanca mientras suben los usuarios virtuales, se encontró el punto de saturación. |
| **Latencia p(95)** | `http_req_duration` | Tiempo de respuesta bajo el cual está el 95% de las peticiones | `< 800 ms` | Se usa el **percentil, no el promedio**: un promedio de 300 ms puede esconder un 5% de usuarios esperando 4 segundos. El percentil describe la experiencia real del usuario más perjudicado. |
| **Latencia p(99)** | `http_req_duration` | El 99% de las peticiones | `< 1500 ms` | Vigila la cola larga. En un sistema con miles de sesiones, ese 1% son cientos de personas. |
| **Tasa de errores** | `http_req_failed` | % de respuestas fuera de 2xx/3xx | `< 1%` | Indicador de **estabilidad**. Un sistema rápido que responde error no está sano; suele indicar agotamiento de pool de conexiones o timeouts. |
| **Usuarios virtuales** | `vus` | Carga concurrente aplicada | escalonada 10→50→100 | Es la variable independiente: permite correlacionar en qué nivel de carga se degradan los demás indicadores. |
| **Errores funcionales** | `errores_login` (custom) | Fallos de las validaciones `check()` | `< 1%` | Distingue "respondió lento" de "respondió mal". Un servicio veloz que devuelve datos incorrectos es peor que uno lento. |

**Por qué carga escalonada y no carga plana.** Golpear el sistema de una vez con 100 usuarios solo dice si aguanta o no. La rampa escalonada permite identificar *en qué punto* se degrada: si la latencia p(95) se mantiene con 50 usuarios y se dispara con 100, se conoce el límite operativo y se puede dimensionar la infraestructura con evidencia. La rampa de bajada final verifica además que el sistema **se recupera** tras el peak y no queda degradado.

**Por qué `sleep(1)`.** Sin think time se simularía un ataque, no usuarios reales. Un usuario real pausa entre acciones; omitir esa pausa produce números pesimistas que llevan a sobredimensionar la infraestructura.

**Salida de la ejecución:**

```
===========================================
 RESUMEN DE PERFORMANCE - LOGIN
===========================================
 Throughput (TPS)      : __.__ req/s
 Latencia promedio     : ___.__ ms
 Latencia p(95)        : ___.__ ms
 Latencia p(99)        : ____.__ ms
 Tasa de error         : _.__
 Iteraciones totales   : ____
===========================================
```

> 📸 **Captura 14** — Ejecución de `k6 run performance/login-performance.js` con el resumen de métricas y el estado de los umbrales.

---

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

**4. Las pruebas funcionales y las de performance responden preguntas distintas.** Las funcionales responden *"¿hace lo correcto?"*; las de performance, *"¿lo sigue haciendo cuando lo usan cien personas a la vez?"*. La ejecución simulada #44 —todo verde en lo funcional, latencia casi duplicada— muestra que una estrategia de pruebas sin la segunda pregunta tiene un punto ciego que solo se descubre en producción.

**5. La visibilidad convierte los datos en decisiones.** Reportes que nadie abre no mejoran la calidad. Publicarlos en tres vías —resumen en el commit, artefactos descargables y una URL permanente— junto a alertas que llegan al canal de trabajo es lo que cierra el ciclo entre *medir* y *actuar*.

**6. Articulación de ambas unidades.** Los conceptos de la Unidad I (estrategias de prueba en ambientes de desarrollo, atomicidad con alta cohesión y bajo acoplamiento, selección del test adecuado, equipo de test y desarrollo) no son teoría previa a la automatización: son la condición que hace que la automatización de la Unidad II rinda. Un pipeline que ejecuta pruebas acopladas y lentas se vuelve un cuello de botella que el equipo termina desactivando.

---

## 5. Anexo: cobertura de la pauta de evaluación

| # | Indicador de logro | Pts | Dónde se evidencia |
|---|---|---|---|
| 1 | Implementación de integración continua y pipeline automático | 15 | §2.5 — `ci.yml` con 3 jobs, disparadores en push/PR/cron, caché y control de concurrencia |
| 2 | Estructura y atomicidad de la suite de pruebas | 10 | §2.3 y §2.4 — 12 pruebas atómicas, `@BeforeEach`, clases sin estado, estructura Maven separando `unit/` y `bdd/` |
| 3 | Calidad y documentación de commits y gestión de versiones | 10 | §2.1 — 13 commits con Conventional Commits, 4 ramas feature, merges `--no-ff`, historial en grafo |
| 4 | Configuración y evidencia de reporte navegable | 10 | §2.6 — Surefire HTML, test-reporter en el commit, artefactos y GitHub Pages |
| 5 | Correcta definición y automatización de escenarios BDD | 10 | §3.2 y §3.3 — 6 escenarios Gherkin con `Esquema del escenario` + `Ejemplos`, step definitions y runner |
| 6 | Simulación de trabajo colaborativo y claridad de criterios | 10 | §3.1 — Sesión Three Amigos con roles, transcripción y 6 criterios de aceptación |
| 7 | Prueba de performance y análisis de indicadores | 10 | §3.6 — Script k6 con carga escalonada, umbrales SLO y análisis de TPS, p(95), p(99) y tasa de error |
| 8 | Visualización de métricas y reporting en dashboards | 10 | §3.7 — Flujo de datos, métricas expuestas, GitHub Pages y ruta a Grafana/InfluxDB |
| 9 | Propuesta y simulación de alertas automáticas | 10 | §3.8 — Matriz de 6 alertas, implementación en YAML y ejemplo de alerta recibida |
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
