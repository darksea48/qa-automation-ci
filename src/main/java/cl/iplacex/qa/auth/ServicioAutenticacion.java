package cl.iplacex.qa.auth;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Servicio de autenticación simulado (funcionalidad "Login" definida en la
 * sesión Three Amigos documentada en el informe).
 *
 * Reglas de negocio acordadas con el equipo:
 *  - Credenciales correctas  -> acceso concedido.
 *  - Password incorrecta     -> mensaje genérico, sin revelar si el usuario existe.
 *  - Usuario inexistente     -> mismo mensaje genérico (criterio de seguridad).
 *  - Campos vacíos           -> validación previa, no se consulta el repositorio.
 *  - 3 intentos fallidos     -> cuenta bloqueada.
 */
public class ServicioAutenticacion {

    private static final int MAX_INTENTOS = 3;

    /**
     * Repositorio de usuarios en memoria: mantiene la prueba rápida y sin
     * dependencias externas.
     *
     * Se usan colecciones CONCURRENTES porque la prueba de carga expone este
     * mismo servicio a 100 hilos simultáneos. Un HashMap corriente no es seguro
     * bajo concurrencia: puede perder escrituras o, al redimensionarse, dejar
     * su tabla interna en un estado que provoca un bucle infinito. Es
     * exactamente el tipo de defecto que las pruebas unitarias (de un solo
     * hilo) nunca detectan y que solo aparece bajo carga.
     */
    private final Map<String, String> usuarios = new ConcurrentHashMap<>();
    private final Map<String, Integer> intentosFallidos = new ConcurrentHashMap<>();

    public ServicioAutenticacion() {
        usuarios.put("douglas", "Clave123");
        usuarios.put("analista", "Qa2026*");
    }

    /**
     * Intenta autenticar a un usuario.
     *
     * @return ResultadoLogin con el estado y el mensaje que vería el usuario final.
     */
    public ResultadoLogin autenticar(String usuario, String password) {
        // 1) Validación de entrada: evita consultas innecesarias al repositorio.
        if (usuario == null || usuario.isBlank() || password == null || password.isBlank()) {
            return new ResultadoLogin(EstadoLogin.DATOS_INCOMPLETOS,
                    "Debe completar usuario y contraseña");
        }

        // 2) Cuenta bloqueada por exceso de intentos.
        if (intentosFallidos.getOrDefault(usuario, 0) >= MAX_INTENTOS) {
            return new ResultadoLogin(EstadoLogin.BLOQUEADO,
                    "Cuenta bloqueada por múltiples intentos fallidos");
        }

        // 3) Verificación de credenciales.
        String passwordAlmacenada = usuarios.get(usuario);
        if (passwordAlmacenada != null && passwordAlmacenada.equals(password)) {
            intentosFallidos.remove(usuario); // login exitoso reinicia el contador
            return new ResultadoLogin(EstadoLogin.EXITOSO, "Bienvenido " + usuario);
        }

        // 4) Fallo: se registra el intento y se responde con un mensaje genérico.
        intentosFallidos.merge(usuario, 1, Integer::sum);
        return new ResultadoLogin(EstadoLogin.CREDENCIALES_INVALIDAS,
                "Usuario o contraseña incorrectos");
    }

    /** Expuesto solo para preparar escenarios de prueba (cuenta ya bloqueada). */
    public void registrarIntentoFallido(String usuario) {
        intentosFallidos.merge(usuario, 1, Integer::sum);
    }

    public int intentosDe(String usuario) {
        return intentosFallidos.getOrDefault(usuario, 0);
    }
}
