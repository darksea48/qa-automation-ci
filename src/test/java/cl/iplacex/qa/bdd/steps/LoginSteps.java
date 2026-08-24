package cl.iplacex.qa.bdd.steps;

import cl.iplacex.qa.auth.ResultadoLogin;
import cl.iplacex.qa.auth.ServicioAutenticacion;
import io.cucumber.java.Before;
import io.cucumber.java.es.Cuando;
import io.cucumber.java.es.Dado;
import io.cucumber.java.es.Entonces;
import io.cucumber.java.es.Y;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Step definitions de la funcionalidad de login.
 *
 * Buenas prácticas aplicadas:
 *  - Un paso hace UNA cosa; las aserciones viven en los pasos "Entonces".
 *  - El estado del escenario es un campo de instancia: Cucumber crea una
 *    instancia nueva por escenario, garantizando aislamiento (atomicidad).
 *  - Los pasos no contienen lógica de negocio: solo orquestan llamadas al
 *    servicio real, de modo que la prueba falla si el negocio cambia.
 *  - Expresiones parametrizadas ({string}) para reutilizar pasos entre
 *    escenarios y alimentar el Scenario Outline.
 */
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
