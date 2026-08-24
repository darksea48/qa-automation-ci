package cl.iplacex.qa.auth;

/**
 * Objeto de valor inmutable con el resultado de un login.
 * Al ser inmutable no puede ser mutado por una prueba y filtrar estado a otra.
 */
public record ResultadoLogin(EstadoLogin estado, String mensaje) {

    public boolean exitoso() {
        return estado == EstadoLogin.EXITOSO;
    }
}
