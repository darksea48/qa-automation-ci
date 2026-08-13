package cl.iplacex.qa.auth;

/** Estados posibles de un intento de autenticación. */
public enum EstadoLogin {
    EXITOSO,
    CREDENCIALES_INVALIDAS,
    DATOS_INCOMPLETOS,
    BLOQUEADO
}
