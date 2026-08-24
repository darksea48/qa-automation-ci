package cl.iplacex.qa.calculo;

/**
 * Componente de dominio bajo prueba.
 *
 * Se mantiene deliberadamente SIN ESTADO (stateless): cada método recibe todo
 * lo que necesita por parámetro y no guarda datos entre invocaciones. Esto es
 * lo que permite escribir pruebas ATÓMICAS: ninguna prueba puede contaminar a
 * otra, y el orden de ejecución es irrelevante.
 *
 * Alta cohesión: la clase hace una sola cosa (operaciones aritméticas).
 * Bajo acoplamiento: no depende de ninguna otra clase del proyecto.
 */
public class Calculadora {

    /** Suma dos enteros. */
    public int sumar(int a, int b) {
        return a + b;
    }

    /** Resta el segundo entero al primero. */
    public int restar(int a, int b) {
        return a - b;
    }

    /** Multiplica dos enteros. */
    public int multiplicar(int a, int b) {
        return a * b;
    }

    /**
     * Divide dos enteros.
     *
     * @throws ArithmeticException si el divisor es cero. Se valida de forma
     *         explícita para que el caso de borde sea verificable por una prueba.
     */
    public double dividir(int a, int b) {
        if (b == 0) {
            throw new ArithmeticException("No es posible dividir por cero");
        }
        return (double) a / b;
    }
}
