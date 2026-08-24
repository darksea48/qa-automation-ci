package cl.iplacex.qa.bdd.runner;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.*;

/**
 * Runner de la suite BDD sobre JUnit Platform.
 *
 * Publica tres formatos de reporte:
 *  - HTML  (target/cucumber-reports/cucumber.html)  -> reporte navegable para el equipo
 *  - JSON  (target/cucumber-reports/cucumber.json)  -> insumo para dashboards / Allure
 *  - JUnit XML (target/cucumber-reports/cucumber.xml) -> lo consume el pipeline de CI
 */
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
@ConfigurationParameter(key = PLUGIN_PUBLISH_QUIET_PROPERTY_NAME, value = "true")
public class BddTestRunner {
    // Clase vacía a propósito: solo transporta configuración.
}
