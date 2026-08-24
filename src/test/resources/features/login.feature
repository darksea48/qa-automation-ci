# language: es
# ============================================================================
# Funcionalidad definida en la sesión "Three Amigos" (ver informe, Actividad 2)
# Participantes: Product Owner (negocio) - Desarrollador - QA
# Este archivo es el "documento vivo": lo lee el negocio y lo ejecuta la máquina.
# ============================================================================

@login
Característica: Autenticación de usuarios en el portal
  Como usuario registrado del portal
  Quiero iniciar sesión con mis credenciales
  Para acceder a mi información privada de forma segura

  Antecedentes:
    Dado que el portal de autenticación está disponible

  @smoke @critico
  Escenario: Ingreso exitoso con credenciales válidas
    Cuando el usuario ingresa el usuario "douglas" y la contraseña "Clave123"
    Entonces el sistema concede el acceso
    Y se muestra el mensaje "Bienvenido douglas"

  @regresion
  Esquema del escenario: Ingreso rechazado con datos inválidos
    Cuando el usuario ingresa el usuario "<usuario>" y la contraseña "<password>"
    Entonces el sistema deniega el acceso
    Y se muestra el mensaje "<mensaje>"

    Ejemplos:
      | usuario     | password   | mensaje                              |
      | douglas     | Clave999   | Usuario o contraseña incorrectos     |
      | inexistente | Clave123   | Usuario o contraseña incorrectos     |
      | douglas     |            | Debe completar usuario y contraseña  |
      |             | Clave123   | Debe completar usuario y contraseña  |

  @seguridad
  Escenario: Bloqueo de la cuenta tras tres intentos fallidos
    Dado que el usuario "analista" ya registra 3 intentos fallidos
    Cuando el usuario ingresa el usuario "analista" y la contraseña "Qa2026*"
    Entonces el sistema deniega el acceso
    Y se muestra el mensaje "Cuenta bloqueada por múltiples intentos fallidos"
