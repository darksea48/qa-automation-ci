/**
 * ===========================================================================
 *  Prueba de performance - Funcionalidad crítica: LOGIN
 *  Herramienta: k6 (https://k6.io)
 *
 *  Requiere que el servidor de la aplicación esté levantado:
 *      mvn compile
 *      java -cp target/classes cl.iplacex.qa.app.ServidorLogin
 *
 *  Ejecución:
 *      k6 run performance/login-performance.js
 *      k6 run --env BASE_URL=http://otro-host:8080 performance/login-performance.js
 * ===========================================================================
 *
 *  ¿POR QUÉ EL LOGIN?
 *  Es la puerta de entrada del sistema: si se degrada, todas las demás
 *  funcionalidades quedan inaccesibles. Es además el punto de mayor
 *  concurrencia en la hora peak.
 *
 *  ¿POR QUÉ CONTRA UN SERVIDOR PROPIO Y NO CONTRA UNA API PÚBLICA?
 *  Una primera versión de esta prueba apuntaba a una API pública de terceros.
 *  El resultado fue inválido: el servicio detectó la carga, activó su
 *  limitador de tasa y devolvió rechazos inmediatos desde su capa de borde.
 *  Las métricas resultantes (1.76 ms de latencia promedio) medían la velocidad
 *  de ese rechazo, no el rendimiento del login. Midiendo la propia aplicación
 *  el resultado es reproducible, no depende de la red y evalúa exactamente el
 *  mismo componente que cubren las pruebas unitarias y los escenarios BDD.
 *
 *  INDICADORES MONITOREADOS
 *  1. TPS / throughput (http_reqs)      -> capacidad del endpoint
 *  2. Latencia p(95) y p(99)            -> experiencia del usuario, no el promedio
 *  3. Tasa de respuestas inesperadas    -> estabilidad bajo carga
 *  4. Usuarios virtuales concurrentes   -> variable independiente del experimento
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ---------------------------------------------------------------------------
// Métricas personalizadas. Separar los tipos de respuesta permite distinguir un
// problema de la aplicación de un problema del entorno, algo que una única
// "tasa de error" agregada esconde.
// ---------------------------------------------------------------------------
const erroresLogin    = new Rate('errores_login');
const latenciaLogin   = new Trend('latencia_login', true);
const loginsExitosos  = new Counter('logins_exitosos');      // 200
const rechazosNegocio = new Counter('rechazos_negocio');     // 400 / 401 / 423
const limitadoPorTasa = new Counter('limitado_por_tasa');    // 429 / 403
const erroresServidor = new Counter('errores_servidor');     // 5xx
const sinRespuesta    = new Counter('sin_respuesta');        // status 0

/**
 * Códigos que representan una respuesta SANA del servicio.
 * Un 401 ante credenciales incorrectas significa que el servidor funcionó y
 * aplicó su regla de negocio; contarlo como error de infraestructura mezclaría
 * dos conceptos distintos. Un 429 o un 5xx, en cambio, sí son fallos.
 */
http.setResponseCallback(http.expectedStatuses(200, 400, 401, 423));

export const options = {
  // --- Perfil de carga escalonado ---
  // Subir por etapas permite identificar EN QUÉ NIVEL de carga se degrada el
  // servicio. Una carga plana solo responde "aguanta o no aguanta".
  stages: [
    { duration: '30s', target: 10 },  // calentamiento
    { duration: '1m',  target: 50 },  // carga nominal de hora peak
    { duration: '30s', target: 100 }, // carga de estrés: 2x lo esperado
    { duration: '30s', target: 0 },   // bajada: verifica la recuperación
  ],

  // Por defecto k6 solo calcula p(90) y p(95). El p(99) hay que pedirlo.
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],

  // --- Umbrales (SLO) ---
  // Calibrados para un servicio local: sin latencia de red, los tiempos
  // aceptables son mucho menores que contra un servicio remoto.
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<500'],
    'http_req_failed':   ['rate<0.01'],
    'errores_login':     ['rate<0.01'],
    'http_reqs':         ['rate>15'],
  },

  thresholdsAbortOnFail: false,
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  // Se usan credenciales VÁLIDAS a propósito. La prueba de carga mide la
  // capacidad del camino exitoso, que es el que ejecuta la gran mayoría del
  // tráfico real y el más costoso de servir. Los caminos de rechazo ya están
  // cubiertos por las pruebas unitarias y los escenarios BDD, donde se
  // verifican por comportamiento y no por volumen.
  const payload = JSON.stringify({
    username: 'douglas',
    password: 'Clave123',
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { funcionalidad: 'login' },
    timeout: '10s',
  };

  const res = http.post(`${BASE_URL}/auth/login`, payload, params);

  // Clasificación de la respuesta por tipo, no solo por éxito/fallo.
  if (res.status === 0)                        sinRespuesta.add(1);
  else if (res.status === 200)                 loginsExitosos.add(1);
  else if (res.status === 429 || res.status === 403) limitadoPorTasa.add(1);
  else if (res.status >= 500)                  erroresServidor.add(1);
  else if (res.status >= 400)                  rechazosNegocio.add(1);

  const ok = check(res, {
    'el servidor respondió':                (r) => r.status !== 0,
    'el login fue exitoso (200)':           (r) => r.status === 200,
    'responde en menos de 200 ms':          (r) => r.timings.duration < 200,
    'el cuerpo trae el estado del login':   (r) => r.body && r.body.includes('estado'),
  });

  erroresLogin.add(!ok);
  latenciaLogin.add(res.timings.duration);

  sleep(1); // think time: sin esta pausa se simula un ataque, no usuarios reales
}

export function handleSummary(data) {
  return {
    'performance/resultados/summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const m = data.metrics;

  const val = (metrica, campo, dec = 2) =>
    (m[metrica] && m[metrica].values && m[metrica].values[campo] != null)
      ? m[metrica].values[campo].toFixed(dec)
      : 'n/d';

  const cuenta = (metrica) =>
    (m[metrica] && m[metrica].values && m[metrica].values.count != null)
      ? m[metrica].values.count
      : 0;

  const total      = cuenta('http_reqs');
  const exitosos   = cuenta('logins_exitosos');
  const rechazos   = cuenta('rechazos_negocio');
  const limitados  = cuenta('limitado_por_tasa');
  const erroresSrv = cuenta('errores_servidor');
  const sinResp    = cuenta('sin_respuesta');

  const p95 = m['http_req_duration'] ? m['http_req_duration'].values['p(95)'] : null;
  const p99 = m['http_req_duration'] ? m['http_req_duration'].values['p(99)'] : null;

  // ---- Diagnóstico automático -------------------------------------------
  // Mira la DISTRIBUCIÓN de códigos, no solo el conteo agregado: es lo que
  // permite distinguir una degradación real de un problema de entorno.
  let diagnostico;
  if (total === 0) {
    diagnostico =
      ' El servidor no recibió ninguna petición. Verifica que ServidorLogin\n' +
      ' esté levantado en ' + BASE_URL + ' antes de ejecutar k6.';
  } else if (sinResp >= total * 0.5) {
    diagnostico =
      ' El ' + Math.round((sinResp / total) * 100) + '% de las peticiones no obtuvo respuesta.\n' +
      ' El servidor no está escuchando, se cayó durante la prueba, o un firewall\n' +
      ' bloquea el puerto. La medición NO es válida.';
  } else if (limitados >= total * 0.1) {
    diagnostico =
      ' El ' + Math.round((limitados / total) * 100) + '% de las peticiones fue limitada por tasa (429/403).\n' +
      ' Un intermediario está rechazando el tráfico antes de que llegue a la\n' +
      ' aplicación. Lo medido es la velocidad de ese rechazo, no el rendimiento\n' +
      ' del login. La medición NO es válida.';
  } else if (erroresSrv > 0) {
    diagnostico =
      ' Se registraron ' + erroresSrv + ' errores 5xx: la aplicación falló bajo carga.\n' +
      ' Es un hallazgo de estabilidad y debe investigarse antes que la latencia.';
  } else if (exitosos >= total * 0.95) {
    const veredicto = (p95 != null && p95 < 200)
      ? ' Los umbrales de latencia se cumplieron: el servicio soportó la carga.'
      : ' La latencia p(95) supero el umbral de 200 ms: se identifico el punto de\n' +
        ' saturacion del servicio bajo la carga aplicada. Es un HALLAZGO valido.';
    diagnostico =
      ' El ' + Math.round((exitosos / total) * 100) + '% de los logins fue exitoso contra la aplicación real.\n' +
      ' Las métricas de latencia y throughput son válidas.\n' + veredicto;
  } else {
    diagnostico =
      ' Distribución mixta de respuestas: ' + exitosos + ' exitosas, ' + rechazos + ' rechazos de\n' +
      ' negocio, ' + limitados + ' limitadas. Revisa la configuración de la prueba.';
  }

  return `
================================================================================
 RESUMEN DE PERFORMANCE - FUNCIONALIDAD LOGIN
 Objetivo medido: ${BASE_URL}/auth/login
================================================================================
 Peticiones totales        : ${total}
 Throughput (TPS)          : ${val('http_reqs', 'rate')} req/s
 Usuarios virtuales máx.   : ${val('vus_max', 'value', 0)}
 Iteraciones completadas   : ${cuenta('iterations')}
--------------------------------------------------------------------------------
 LATENCIA
   Mínima                  : ${val('http_req_duration', 'min')} ms
   Promedio                : ${val('http_req_duration', 'avg')} ms
   Mediana p(50)           : ${val('http_req_duration', 'med')} ms
   p(90)                   : ${val('http_req_duration', 'p(90)')} ms
   p(95)                   : ${val('http_req_duration', 'p(95)')} ms   [umbral: < 200 ms]
   p(99)                   : ${val('http_req_duration', 'p(99)')} ms   [umbral: < 500 ms]
   Máxima                  : ${val('http_req_duration', 'max')} ms
--------------------------------------------------------------------------------
 DISTRIBUCION DE RESPUESTAS
   Logins exitosos (200)   : ${exitosos}
   Rechazos de negocio     : ${rechazos}   (4xx: respuesta correcta del servidor)
   Limitadas por tasa      : ${limitados}   (429/403: rechazo de un intermediario)
   Errores del servidor    : ${erroresSrv}   (5xx: fallo de la aplicacion)
   Sin respuesta           : ${sinResp}   (status 0: red, puerto o caida)
--------------------------------------------------------------------------------
 Tasa de respuestas
   inesperadas             : ${val('http_req_failed', 'rate', 4)}   [umbral: < 0.01]
================================================================================
 DIAGNOSTICO
${diagnostico}
================================================================================
 NOTA: un umbral incumplido hace que k6 termine con codigo 99. Eso NO es un
 error de ejecucion: es el resultado de la prueba, y como tal se analiza en el
 informe (¿en que nivel de carga se degrado? ¿latencia o estabilidad?).
================================================================================
`;
}
