package cl.iplacex.qa.app;

import cl.iplacex.qa.auth.EstadoLogin;
import cl.iplacex.qa.auth.ResultadoLogin;
import cl.iplacex.qa.auth.ServicioAutenticacion;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Servidor HTTP mínimo que expone el ServicioAutenticacion sobre la red.
 *
 * ¿POR QUÉ EXISTE ESTA CLASE?
 * ---------------------------
 * La prueba de carga necesita un endpoint HTTP contra el cual medir. Apuntar a
 * una API pública de terceros parecía más simple, pero produjo mediciones
 * inválidas: el servicio externo activó su limitador de tasa al detectar 100
 * usuarios virtuales y devolvió rechazos inmediatos desde su capa de borde. Lo
 * que se medía entonces era la velocidad de ese rechazo, no el rendimiento de
 * la aplicación.
 *
 * Al levantar la propia aplicación se elimina esa dependencia externa: la
 * prueba de carga mide EL MISMO componente que verifican las pruebas unitarias
 * y los escenarios BDD, el resultado es reproducible y no depende de la red.
 *
 * Se usa com.sun.net.httpserver (incluido en el JDK) para no agregar
 * dependencias: el objetivo es medir, no construir un framework web.
 */
public class ServidorLogin {

    /**
     * Instancia única compartida por todas las peticiones, igual que en una
     * aplicación real. Por eso ServicioAutenticacion usa colecciones
     * concurrentes: bajo 100 hilos simultáneos un HashMap corriente podría
     * corromperse o entrar en bucle infinito.
     */
    private static final ServicioAutenticacion SERVICIO = new ServicioAutenticacion();

    private static final Pattern CAMPO_USUARIO  = Pattern.compile("\"username\"\\s*:\\s*\"([^\"]*)\"");
    private static final Pattern CAMPO_PASSWORD = Pattern.compile("\"password\"\\s*:\\s*\"([^\"]*)\"");

    public static void main(String[] args) throws IOException {
        int puerto = Integer.parseInt(System.getenv().getOrDefault("PUERTO", "8080"));

        HttpServer servidor = HttpServer.create(new InetSocketAddress(puerto), 0);
        servidor.createContext("/auth/login", ServidorLogin::manejarLogin);
        servidor.createContext("/salud", ServidorLogin::manejarSalud);

        // Pool fijo de hilos: permite atender peticiones concurrentes y, al ser
        // acotado, hace que la saturación sea observable en la prueba de carga.
        servidor.setExecutor(Executors.newFixedThreadPool(16));
        servidor.start();

        System.out.println("Servidor de login escuchando en http://localhost:" + puerto);
        System.out.println("  POST /auth/login   -> autenticacion");
        System.out.println("  GET  /salud        -> verificacion de disponibilidad");
    }

    /** Endpoint de salud: lo consulta el pipeline para saber cuándo el servidor está listo. */
    private static void manejarSalud(HttpExchange intercambio) throws IOException {
        responder(intercambio, 200, "{\"estado\":\"arriba\"}");
    }

    /** Endpoint de autenticación. */
    private static void manejarLogin(HttpExchange intercambio) throws IOException {
        if (!"POST".equalsIgnoreCase(intercambio.getRequestMethod())) {
            responder(intercambio, 405, "{\"error\":\"Metodo no permitido\"}");
            return;
        }

        String cuerpo = leerCuerpo(intercambio.getRequestBody());
        String usuario  = extraer(CAMPO_USUARIO, cuerpo);
        String password = extraer(CAMPO_PASSWORD, cuerpo);

        ResultadoLogin resultado = SERVICIO.autenticar(usuario, password);

        // El estado del dominio se traduce al código HTTP que le corresponde.
        // Esta correspondencia es parte del contrato de la API y por eso la
        // prueba de carga puede declarar qué códigos son una respuesta sana.
        int codigo = switch (resultado.estado()) {
            case EXITOSO                -> 200;  // acceso concedido
            case CREDENCIALES_INVALIDAS -> 401;  // rechazo de negocio
            case DATOS_INCOMPLETOS      -> 400;  // petición mal formada
            case BLOQUEADO              -> 423;  // recurso bloqueado
        };

        responder(intercambio, codigo, String.format(
                "{\"estado\":\"%s\",\"mensaje\":\"%s\"}",
                resultado.estado(), escapar(resultado.mensaje())));
    }

    // ------------------------------------------------------------------ apoyo

    private static String leerCuerpo(InputStream entrada) throws IOException {
        return new String(entrada.readAllBytes(), StandardCharsets.UTF_8);
    }

    /**
     * Extracción de campos por expresión regular.
     * Deliberadamente simple: el objetivo de esta clase es exponer el servicio
     * para medirlo, no implementar un analizador de JSON completo. Agregar una
     * librería solo para esto introduciría una dependencia sin valor de prueba.
     */
    private static String extraer(Pattern patron, String json) {
        Matcher m = patron.matcher(json);
        return m.find() ? m.group(1) : "";
    }

    private static String escapar(String texto) {
        return texto == null ? "" : texto.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static void responder(HttpExchange intercambio, int codigo, String cuerpo) throws IOException {
        byte[] bytes = cuerpo.getBytes(StandardCharsets.UTF_8);
        intercambio.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        intercambio.sendResponseHeaders(codigo, bytes.length);
        try (OutputStream salida = intercambio.getResponseBody()) {
            salida.write(bytes);
        }
    }
}
