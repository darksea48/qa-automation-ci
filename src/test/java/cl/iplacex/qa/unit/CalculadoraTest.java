package cl.iplacex.qa.unit;

import cl.iplacex.qa.calculo.Calculadora;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Pruebas unitarias ATÓMICAS de la Calculadora.
 *
 * Principios aplicados (Unidad I - atomicidad, alta cohesión / bajo acoplamiento):
 *  1. Una prueba = un comportamiento verificable, con una sola razón para fallar.
 *  2. @BeforeEach crea una instancia NUEVA por prueba -> sin estado compartido.
 *  3. No hay dependencias entre pruebas: se pueden ejecutar en cualquier orden
 *     o en paralelo sin cambiar el resultado.
 *  4. Nombres descriptivos (@DisplayName) que documentan el comportamiento
 *     esperado, no la implementación.
 */
@DisplayName("Suite unitaria - Calculadora")
class CalculadoraTest {

    private Calculadora calculadora;

    @BeforeEach
    void prepararEscenario() {
        // Arrange común: instancia limpia antes de CADA prueba.
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
        int resultado = calculadora.restar(10, 4);
        assertEquals(6, resultado, "10 - 4 debe ser 6");
    }

    @Test
    @DisplayName("multiplicar() devuelve cero cuando un operando es cero")
    void multiplicarPorCero() {
        assertEquals(0, calculadora.multiplicar(999, 0));
    }

    @Test
    @DisplayName("dividir() lanza ArithmeticException cuando el divisor es cero")
    void dividirPorCeroLanzaExcepcion() {
        // Verificación del caso de borde: se prueba tanto el tipo de excepción
        // como el mensaje, porque el mensaje es parte del contrato del método.
        ArithmeticException ex = assertThrows(
                ArithmeticException.class,
                () -> calculadora.dividir(10, 0));
        assertEquals("No es posible dividir por cero", ex.getMessage());
    }

    /**
     * Prueba parametrizada: un mismo comportamiento validado con varios juegos
     * de datos. Reduce duplicación sin sacrificar atomicidad, ya que JUnit
     * reporta cada fila como una ejecución independiente.
     */
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
