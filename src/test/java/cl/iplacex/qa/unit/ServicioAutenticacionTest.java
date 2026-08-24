package cl.iplacex.qa.unit;

import cl.iplacex.qa.auth.EstadoLogin;
import cl.iplacex.qa.auth.ResultadoLogin;
import cl.iplacex.qa.auth.ServicioAutenticacion;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Pruebas unitarias del servicio de autenticación.
 *
 * Complementan a los escenarios BDD: aquí se verifican las reglas internas
 * (contador de intentos, validaciones), mientras que en Gherkin se describe
 * el comportamiento observable por el negocio.
 */
@DisplayName("Suite unitaria - ServicioAutenticacion")
class ServicioAutenticacionTest {

    private ServicioAutenticacion servicio;

    @BeforeEach
    void prepararEscenario() {
        servicio = new ServicioAutenticacion(); // estado limpio en cada prueba
    }

    @Test
    @DisplayName("Credenciales válidas devuelven estado EXITOSO")
    void loginConCredencialesValidas() {
        ResultadoLogin r = servicio.autenticar("douglas", "Clave123");
        assertTrue(r.exitoso());
        assertEquals(EstadoLogin.EXITOSO, r.estado());
    }

    @Test
    @DisplayName("Password incorrecta incrementa el contador de intentos fallidos")
    void passwordIncorrectaIncrementaIntentos() {
        servicio.autenticar("douglas", "mala");
        assertEquals(1, servicio.intentosDe("douglas"));
    }

    @Test
    @DisplayName("Campos vacíos devuelven DATOS_INCOMPLETOS sin consumir intentos")
    void camposVacios() {
        ResultadoLogin r = servicio.autenticar("", "");
        assertEquals(EstadoLogin.DATOS_INCOMPLETOS, r.estado());
        assertEquals(0, servicio.intentosDe(""));
    }

    @Test
    @DisplayName("Un login exitoso reinicia el contador de intentos fallidos")
    void loginExitosoReiniciaContador() {
        servicio.autenticar("douglas", "mala");
        servicio.autenticar("douglas", "Clave123");
        assertEquals(0, servicio.intentosDe("douglas"));
    }
}
