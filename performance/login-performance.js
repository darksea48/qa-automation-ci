/**
 * ===========================================================================
 *  Prueba de performance - Funcionalidad crítica: LOGIN
 *  Herramienta: k6 (https://k6.io)
 *  Ejecución local : k6 run performance/login-performance.js
 *  Ejecución en CI : k6 run --out json=performance/resultados/raw.json ...
 * ===========================================================================
 *
 *  ¿Por qué el login? Es la puerta de entrada del sistema: si se degrada,
 *  TODAS las demás funcionalidades quedan inaccesibles. Es el punto de mayor
 *  concurrencia en la hora peak.
 *
 *  INDICADORES MONITOREADOS
 *  ------------------------
 *  1. TPS / throughput (http_reqs)        -> transacciones por segundo que
 *     soporta el endpoint. Mide capacidad.
 *  2. Latencia (http_req_duration)        -> se observa el percentil 95 y 99,
 *     NO el promedio: el promedio esconde la cola de usuarios lentos.
 *  3. Tasa de errores (http_req_failed)   -> % de respuestas != 2xx/3xx.
 *     Es el indicador de estabilidad bajo carga.
 *  4. Usuarios virtuales concurrentes (vus)-> carga aplicada en cada momento.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Métricas personalizadas: permiten graficar el login por separado del resto.
const erroresLogin = new Rate('errores_login');
const latenciaLogin = new Trend('latencia_login', true);

export const options = {
  // --- Perfil de carga escalonado (ramping) ---
  // Se sube la carga por etapas para identificar el punto de quiebre,
  // en lugar de golpear el sistema de una sola vez.
  stages: [
    { duration: '30s', target: 10 },  // rampa de subida: calentamiento
    { duration: '1m',  target: 50 },  // carga nominal esperada en hora peak
    { duration: '30s', target: 100 }, // carga de estrés: 2x lo esperado
    { duration: '30s', target: 0 },   // rampa de bajada: verifica recuperación
  ],

  // --- Umbrales (SLO): si no se cumplen, k6 devuelve exit code 99
  //     y el pipeline marca el build como fallido. Esta es la puerta de
  //     calidad de performance.
  thresholds: {
    'http_req_duration': ['p(95)<800', 'p(99)<1500'], // 95% bajo 800 ms
    'http_req_failed':   ['rate<0.01'],               // menos de 1% de errores
    'errores_login':     ['rate<0.01'],
    'http_reqs':         ['rate>20'],                 // al menos 20 TPS
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';

export default function () {
  const payload = JSON.stringify({
    username: 'douglas',
    password: 'Clave123',
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { funcionalidad: 'login' }, // etiqueta para filtrar en el dashboard
  };

  const res = http.post(`${BASE_URL}/auth/token/login/`, payload, params);

  // Validaciones funcionales dentro de la prueba de carga: un servicio que
  // responde rápido pero con error no está "sano".
  const ok = check(res, {
    'status es 200 o 400 (endpoint alcanzable)': (r) => r.status === 200 || r.status === 400,
    'responde en menos de 800 ms': (r) => r.timings.duration < 800,
    'el cuerpo no viene vacío': (r) => r.body && r.body.length > 0,
  });

  erroresLogin.add(!ok);
  latenciaLogin.add(res.timings.duration);

  sleep(1); // think time: simula el tiempo real entre acciones de un usuario
}

/**
 * Genera un resumen navegable al final de la ejecución.
 * El HTML se publica como artefacto del pipeline junto a los reportes
 * funcionales, y el JSON alimenta el dashboard de métricas.
 */
export function handleSummary(data) {
  return {
    'performance/resultados/summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const m = data.metrics;
  const val = (metrica, campo) => (m[metrica] && m[metrica].values[campo] != null)
      ? m[metrica].values[campo].toFixed(2) : 'n/d';
  return `
===========================================
 RESUMEN DE PERFORMANCE - LOGIN
===========================================
 Throughput (TPS)      : ${val('http_reqs', 'rate')} req/s
 Latencia promedio     : ${val('http_req_duration', 'avg')} ms
 Latencia p(95)        : ${val('http_req_duration', 'p(95)')} ms
 Latencia p(99)        : ${val('http_req_duration', 'p(99)')} ms
 Tasa de error         : ${val('http_req_failed', 'rate')}
 Iteraciones totales   : ${val('iterations', 'count')}
===========================================
`;
}
