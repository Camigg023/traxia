# BANCO DE PREGUNTAS Y RESPUESTAS DEFENSIVAS ANTE EL JURADO — PROYECTO TRAXIA

Este documento recopila treinta y cinco (35) preguntas de alta complejidad técnica y rigor académico que jurados, directores de carrera o evaluadores de software suelen formular durante una sustentación de grado o auditoría de sistemas. Cada respuesta está fundamentada en el código fuente real de TRAXIA, demostrando dominio pleno de la arquitectura, la seguridad, la persistencia y la lógica del negocio.

---

## BLOQUE 1: ARQUITECTURA DE SOFTWARE Y PATRONES DE DISEÑO

### 1. ¿Por qué decidieron separar el sistema en un Frontend con Flutter Web y un Backend con Spring Boot en lugar de un monolito clásico con SSR (como Thymeleaf o JSP)?
**Respuesta:**
"La decisión responde al principio de **desacoplamiento arquitectónico y extensibilidad del producto**:
1. **Omnicanalidad:** Al exponer una API REST pura y sin estado en Spring Boot, el backend queda desacoplado de la tecnología de interfaz. Hoy servimos a Flutter Web, pero mañana podemos compilar el mismo código de Flutter a aplicaciones móviles nativas en Android e iOS, o integrar sistemas de ERP corporativos vía API, sin tener que modificar una sola línea de la lógica de negocio ni de persistencia.
2. **Escalabilidad independiente:** El consumo de cómputo del backend (transacciones de base de datos, cifrado criptográfico y cálculo algorítmico) puede escalarse horizontalmente en contenedores independientes sin verse afectado por el tráfico de entrega de los assets estáticos del frontend web."

---

### 2. ¿Por qué implementaron Clean Architecture y Domain-Driven Design (DDD) en el backend de Spring Boot en lugar del típico modelo plano Controller-Service-Repository?
**Respuesta:**
"El modelo tradicional de tres capas suele degenerar rápidamente en arquitecturas anémicas (*Anemic Domain Model*), donde las entidades son simples contenedores de datos con *getters* y *setters*, y los servicios acumulan miles de líneas de lógica desordenada.
En TRAXIA organizamos el backend en **Contextos Delimitados (*Bounded Contexts*)** independientes (`identity`, `loads`, `simulation`, `bids`, `trips`). Dentro de cada módulo aplicamos la regla de dependencia de Clean Architecture:
- La capa **Domain** (`domain/`) contiene las entidades puras y las invariantes de negocio (por ejemplo, las validaciones de transición de estados de un viaje o las reglas de cálculo de fletes), completamente aisladas de cualquier framework web o base de datos.
- La capa **Application** (`application/`) orquesta los casos de uso específicos del sistema.
- La capa **Infrastructure** (`infrastructure/` y `api/`) implementa los adaptadores concretos: controladores Spring MVC, repositorios Spring Data JPA y filtros de seguridad.
Esto garantiza alta cohesión, bajo acoplamiento y facilidad para realizar pruebas unitarias con dobles de prueba (*mocks*) sin necesidad de levantar el contexto completo de Spring."

---

### 3. ¿Cómo manejan la inversión de dependencias para evitar que el dominio dependa de la base de datos?
**Respuesta:**
"Aplicamos el **Principio de Inversión de Dependencias (DIP)** del estándar SOLID. En la capa de dominio definimos interfaces puras de repositorio (por ejemplo, `UserRepository` o `LoadRepository`). Luego, en la capa de infraestructura, implementamos esas interfaces mediante clases de Spring Data JPA o adaptadores que interactúan con Hibernate. Los servicios de aplicación interactúan exclusivamente con la interfaz del dominio; en ningún momento el dominio conoce las anotaciones de persistencia ni la existencia de MySQL."

---

### 4. En el Frontend, ¿por qué eligieron Riverpod en lugar de soluciones como BLoC, Provider o un simple `setState`?
**Respuesta:**
"Evaluamos tres factores críticos:
1. **Seguridad en tiempo de compilación (*Compile-Time Safety*):** A diferencia de `Provider`, que depende del árbol de widgets (`BuildContext`) y puede provocar excepciones en tiempo de ejecución (`ProviderNotFoundException`), los proveedores de Riverpod son variables globales inmutables declaradas a nivel de archivo y resueltas en compilación.
2. **Desacoplamiento del árbol de UI:** Riverpod permite escuchar estados (`ref.watch`) o ejecutar acciones (`ref.read`) desde cualquier capa de la aplicación, facilitando la inyección de dependencias y la separación limpia entre widgets visuales y la lógica del `StateNotifier`.
3. **Manejo asíncrono con `AsyncValue`:** Riverpod ofrece una estructura funcional nativa para manejar automáticamente los tres estados de una petición HTTP (Cargando, Datos listos y Error), simplificando el renderizado de la interfaz sin requerir *boilerplate* excesivo como en BLoC."

---

### 5. ¿Por qué utilizar GoRouter y cómo garantizan que un usuario no salte rutas privadas simplemente escribiendo la URL en el navegador?
**Respuesta:**
"En Flutter Web, el enrutamiento estándar (`Navigator 1.0`) presenta serias limitaciones al interactuar con el historial del navegador, el botón de retroceso y las URLs directas (*deep linking*). **GoRouter** resuelve esto mediante enrutamiento declarativo.
Para proteger las rutas privadas implementamos un mecanismo de **Guardia (*Redirect Callback*)** en `app_router.dart`:
```dart
redirect: (context, state) {
  final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
  final isAuthRoute = state.uri.path == '/iniciar-sesion' || state.uri.path == '/crear-cuenta';
  if (!isAuthenticated && !isAuthRoute) return '/iniciar-sesion';
  if (isAuthenticated && isAuthRoute) return '/cartelera-cargas';
  return null;
}
```
Si un usuario no autenticado ingresa manualmente `http://localhost:5000/publicar-carga`, GoRouter intercepta la navegación antes de renderizar la pantalla y lo redirige automáticamente a `/iniciar-sesion`. Además, si alguien intentara burlar el router manipulando el código del cliente, el backend rechaza cualquier petición con un código HTTP 401 Unauthorized."

---

### 6. ¿Por qué utilizan objetos DTO (Data Transfer Objects) en lugar de exponer directamente las entidades JPA a través de la API REST?
**Respuesta:**
"Exponer entidades JPA en la capa REST es un antipatrón de seguridad y arquitectura por tres razones:
1. **Vulnerabilidad de Asignación Masiva (*Mass Assignment*):** Un atacante podría enviar campos no autorizados (como `role: "ADMIN"` o `status: "ACTIVE"`) en el cuerpo del JSON y el servidor los persistiría directamente.
2. **Problema de Recursión Infinita y Rendimiento:** Las relaciones bidireccionales de JPA (`@OneToMany` y `@ManyToOne`) provocan bucles cíclicos durante la serialización a JSON o generan excepciones de carga perezosa (`LazyInitializationException`).
3. **Desacoplamiento del Contrato:** El esquema de la base de datos puede evolucionar sin que el contrato público de la API REST sufra cambios disruptivos para el frontend."

---

### 7. ¿Cómo desacoplaron el envío de correos de la lógica principal del registro?
**Respuesta:**
"En `RegistrationService.java`, el servicio orquesta la creación del usuario y la persistencia del token de activación, pero delega el envío físico del mensaje al componente `EmailNotificationService`. Este último está parametrizado para apuntar a un servidor SMTP estándar (Mailpit en desarrollo, Amazon SES o SendGrid en producción). Si el servidor SMTP presentara demoras o fallos, el servicio captura la excepción sin comprometer la consistencia de la base de datos."

---

## BLOQUE 2: CIBERSEGURIDAD, AUTENTICACIÓN Y AUTORIZACIÓN

### 8. ¿Por qué eligieron una arquitectura de Doble Token (Access Token + Refresh Token) en lugar de una sesión tradicional con `JSESSIONID`?
**Respuesta:**
"Las sesiones basadas en `JSESSIONID` requieren que el servidor almacene el estado de cada usuario en memoria RAM o en un almacén compartido como Redis. Esto genera problemas de escalabilidad horizontal y afinidad de servidores (*Sticky Sessions*).
La arquitectura de Doble Token nos brinda lo mejor de ambos mundos:
- El **Access Token** es un JWT sin estado con una vida útil muy corta (15 minutos). El backend puede validar su autenticidad y rol en microsegundos simplemente verificando la firma criptográfica con la clave secreta, sin consultar la base de datos en cada petición.
- El **Refresh Token** (7 días) reside en la base de datos y permite extender la sesión o revocarla de inmediato si detectamos una anomalía de seguridad."

---

### 9. ¿Dónde se almacena cada token y por qué no guardaron el Refresh Token en el `LocalStorage` del navegador?
**Respuesta:**
"Guardar tokens de sesión en el `LocalStorage` o `SessionStorage` del navegador es una mala práctica grave clasificada por OWASP, ya que cualquier script malicioso inyectado mediante una vulnerabilidad de Cross-Site Scripting (XSS) puede leer `window.localStorage` y robar la sesión completa.
Por ello:
- El **Access Token** se mantiene exclusivamente en la memoria volátil de la aplicación en tiempo de ejecución (dentro del estado de Riverpod). Si se recarga la página, el token se pierde de la memoria y se recupera transparentemente pidiendo un refresco.
- El **Refresh Token** se almacena en una **Cookie con la directiva `HttpOnly`**. El motor de JavaScript del navegador tiene terminantemente prohibido acceder a esta cookie, haciéndola completamente inmune a ataques de robo por XSS."

---

### 10. ¿Qué era el BUG-001 que corrigieron durante la auditoría y qué impacto tenía en la seguridad?
**Respuesta:**
"El BUG-001 era una vulnerabilidad crítica clasificada bajo CWE-614 (*Sensitive Cookie in HTTPS Session Without 'Secure' Attribute*).
En `AuthController.java`, la lista blanca de entornos no productivos incluía indebidamente la cadena `"production"`. Como consecuencia, si el sistema se desplegaba en un servidor de producción sin certificados TLS, el backend aceptaba emitir la cookie de refresco sin la directiva `Secure`.
Esto abría la puerta a ataques de tipo *Man-in-the-Middle* (MITM): un atacante posicionado en la misma red de comunicaciones (por ejemplo, una red Wi-Fi pública) podía interceptar el tráfico HTTP plano, sustraer el Refresh Token del usuario y clonar su identidad indefinidamente. Subsanamos el error restringiendo la lista estrictamente a entornos de desarrollo y pruebas locales."

---

### 11. Si Spring Security tiene deshabilitado CSRF para la API REST, ¿cómo protegen el endpoint de refresco contra ataques de Cross-Site Request Forgery?
**Respuesta:**
"Las APIs REST sin estado típicamente deshabilitan la protección CSRF de Spring porque los Access Tokens se envían en la cabecera `Authorization: Bearer`, la cual no es adjuntada automáticamente por el navegador en peticiones cruzadas. Sin embargo, el endpoint `/api/v1/auth/refresh` sí recibe una cookie (`TRAXIA_REFRESH`).
Para blindar este endpoint implementamos una **Defensa en Profundidad en Tres Capas**:
1. **`SameSite=Lax`:** El navegador restringe el envío de la cookie en peticiones `POST` cruzadas iniciadas desde sitios de terceros.
2. **Validación de Encabezado `Origin`:** En `RefreshRequestGuardFilter.java`, el servidor compara el origen de la solicitud contra la lista estricta de dominios autorizados; si una página externa intenta realizar la llamada, es rechazada de inmediato.
3. **Cabecera Personalizada Obligatoria:** Exigimos el envío del encabezado `X-TRAXIA-Refresh-Request: true`. Las políticas de seguridad de los navegadores impiden que un formulario HTML malicioso estándar inyecte cabeceras HTTP personalizadas sin disparar una petición previa de pre-vuelo CORS (*Preflight OPTIONS*), la cual es bloqueada por el servidor."

---

### 12. ¿Qué es la rotación de Refresh Tokens y cómo previene el secuestro de sesiones?
**Respuesta:**
"La rotación de tokens (implementada en `RefreshTokenService.java`) establece que un Refresh Token es de un solo uso. Cuando el cliente envía su token para obtener un nuevo Access Token, el servidor ejecuta una transacción atómica donde marca el token actual como revocado (`revoked = true`) y genera uno completamente nuevo.
Si un atacante lograra interceptar un Refresh Token e intentara utilizarlo después de que el usuario legítimo ya lo utilizó, el backend detecta que se está intentando usar un token ya revocado. Esto dispara una alerta de **Reuso Malicioso de Token**, lo que provoca la revocación automática e inmediata de toda la familia de tokens del usuario, cerrando todas sus sesiones activas de forma preventiva."

---

### 13. ¿Cómo funciona la protección contra ataques de fuerza bruta y por qué utilizan HMAC-SHA256 sobre la dirección IP?
**Respuesta:**
"El servicio `RateLimitingService.java` implementa un algoritmo de ventana deslizante en memoria que rastrea los intentos fallidos de autenticación. Si una dirección IP acumula 5 intentos fallidos en menos de 15 minutos, el sistema bloquea cualquier solicitud posterior devolviendo un código HTTP 429 Too Many Requests.
Para cumplir con los principios de privacidad desde el diseño (*Privacy by Design*) y normativas de protección de datos personales, no almacenamos la dirección IP del cliente en texto plano en la memoria ni en logs. En su lugar, aplicamos una función hash criptográfica con clave secreta (**HMAC-SHA256**), generando un pseudónimo determinístico e irreversible que permite contar intentos sin exponer la IP real del usuario en caso de volcado de memoria."

---

### 14. ¿Por qué utilizan BCrypt para almacenar las contraseñas y qué particularidad tiene con el límite de 72 bytes?
**Respuesta:**
"BCrypt es una función de derivación de claves resistente a ataques por hardware especializado (GPU y ASICs) porque combina una 'sal' aleatoria única por usuario con un factor de trabajo computacional adaptable (*work factor* o costo, configurado en 10 en TRAXIA). Esto hace computacionalmente imposible utilizar tablas precalculadas (*Rainbow Tables*).
Respecto a su límite: la especificación matemática de BCrypt trunca cualquier entrada que exceda los 72 bytes. Si un sistema permitiera contraseñas arbitrariamente largas sin validación, una contraseña de 100 caracteres se evaluaría exactamente igual que una de 72 con los mismos primeros caracteres. En TRAXIA, la clase `Password.java` valida que las contraseñas cumplan con el estándar de longitud (mínimo 8 caracteres) y valida la entrada antes del cálculo de hash."

---

### 15. ¿Cómo garantizan que la autorización de roles se verifique en el servidor y no solo ocultando botones en la interfaz de Flutter?
**Respuesta:**
"Ocultar botones en la interfaz gráfica es una conveniencia de experiencia de usuario (UX), jamás un mecanismo de seguridad.
En el backend, cada endpoint está protegido por directivas de autorización en la capa de Spring Security mediante la anotación `@PreAuthorize` o en la configuración central de `SecurityConfig.java`:
- Por ejemplo, el endpoint `POST /api/v1/loads` exige formalmente la autoridad `ROLE_SHIPPER`.
- El endpoint `POST /api/v1/bids` exige la autoridad `ROLE_DRIVER`.
Si un usuario con rol de conductor o un atacante enviara una petición HTTP manual simulando ser una empresa, el filtro `JwtAuthenticationFilter` extrae el rol contenido en el *claim* firmado del JWT, y el evaluador de acceso deniega la solicitud inmediatamente arrojando un código HTTP 403 Forbidden."

---

## BLOQUE 3: BASE DE DATOS, PERSISTENCIA Y RENDIMIENTO

### 16. ¿Por qué decidieron utilizar identificadores UUID v4 en lugar de llaves primarias numéricas autoincrementables (`BIGINT AUTO_INCREMENT`)?
**Respuesta:**
"El uso de IDs autoincrementables tradicionales introduce dos problemas críticos:
1. **Fuga de Información y Enumeración Insegura (IDOR):** Un competidor o usuario malicioso podría deducir fácilmente cuántas cargas o viajes maneja la empresa simplemente observando el incremento de los IDs en las URLs (`/cargas/101`, `/cargas/102`).
2. **Generación Distribuida y Desacoplada:** Con UUID v4, las entidades pueden generar sus propios identificadores únicos universales en la capa de aplicación o cliente sin necesidad de realizar un viaje de ida y vuelta a la base de datos para esperar que el motor le asigne un número."

---

### 17. Si los UUIDs son cadenas de 36 caracteres con guiones, ¿por qué los almacenan en la base de datos como `BINARY(16)`?
**Respuesta:**
"Almacenar un UUID como texto legible (`VARCHAR(36)`) es sumamente ineficiente: ocupa 36 bytes por fila más la sobrecarga del juego de caracteres UTF-8. En tablas con millones de registros y múltiples llaves foráneas e índices secundarios, esto infla el tamaño de los índices en árbol B+ (*B-Tree*), satura la memoria RAM del búfer de MySQL (*InnoDB Buffer Pool*) y ralentiza drásticamente las operaciones de búsqueda y combinación (`JOIN`).
Al almacenarlo como **`BINARY(16)`**, empaquetamos los 128 bits del UUID en exactamente 16 bytes puros. Esto reduce el consumo de almacenamiento en más de un 55%, duplica la cantidad de índices que caben en la memoria RAM y optimiza el rendimiento de las consultas a nivel de disco."

---

### 18. ¿Cómo previene el sistema condiciones de carrera (*Race Conditions*) cuando dos conductores intentan postularse o cuando la empresa acepta una oferta?
**Respuesta:**
"La prevención se apoya en dos pilares del motor transaccional de MySQL e Hibernate:
1. **Atomicidad Transaccional (`@Transactional`):** El método `acceptBid` en `BidService.java` ejecuta una transacción atómica. Cuando la empresa acepta la oferta seleccionada, el servicio ejecuta de forma inmediata una actualización masiva que marca esa oferta como `ACCEPTED` y todas las demás ofertas asociadas a esa carga como `REJECTED`.
2. **Verificación Estricta del Estado de la Carga:** Antes de proceder, el sistema valida que la carga continúe en estado `PUBLISHED`. Si una transacción concurrente ya la adjudicó cambiándola a `ASSIGNED`, cualquier intento posterior es abortado al instante lanzando una excepción de negocio que revierte la transacción (*Rollback*), imposibilitando que dos conductores ganen la misma carga."

---

### 19. ¿Por qué utilizar Flyway para el esquema de la base de datos y no dejar que Hibernate genere las tablas automáticamente con `ddl-auto=update`?
**Respuesta:**
"Utilizar `hibernate.ddl-auto=update` en proyectos serios es considerado un antipatrón peligroso porque:
- No versiona los cambios ni ofrece trazabilidad de quién modificó el esquema ni cuándo.
- No puede realizar renombrado de columnas ni migraciones complejas de datos sin riesgo de pérdida de información.
- En despliegues concurrentes puede generar bloqueos catastróficos en el catálogo de base de datos.
Con **Flyway**, cada cambio estructural se escribe en un script SQL versionado, inmutable y auditable (`V1__...`, `V2__...`, etc.). En el arranque, Flyway consulta la tabla de control `flyway_schema_history` y ejecuta únicamente los scripts pendientes dentro de una transacción. Si un desarrollador intentara modificar el contenido de un script ya aplicado, Flyway calcula la suma de verificación (*checksum*) criptográfica, detecta la discrepancia y detiene el arranque del servidor para proteger la integridad de los datos."

---

### 20. ¿Qué es HikariCP y qué parámetros de conexión configuraron para TRAXIA?
**Respuesta:**
"HikariCP es el pool de conexiones JDBC de mayor rendimiento en el mundo Java. Evita la sobrecarga de tiempo de latencia asociada a negociar el saludo TCP y la autenticación con MySQL en cada consulta HTTP, manteniendo un conjunto de conexiones abiertas y listas para ser reutilizadas.
En `application.properties`, configuramos un pool optimizado para el perfil local y de pruebas, gestionando un límite máximo de conexiones activas, tiempos máximos de espera para evitar hilos bloqueados y validación de vida de conexión con `keepalive`."

---

### 21. ¿Cómo manejan las transacciones en Spring y qué sucede si ocurre un error inesperado a mitad de una operación?
**Respuesta:**
"Utilizamos la anotación `@Transactional(rollbackFor = Exception.class)` en los métodos de servicio de aplicación. Spring envuelve la ejecución del método en un proxy transaccional:
- Si el método finaliza con éxito, emite la instrucción `COMMIT` a MySQL y los cambios se vuelven permanentes.
- Si se dispara cualquier excepción no controlada (`RuntimeException` o excepción verificada declarada), el proxy intercepta el fallo e invoca inmediatamente la instrucción `ROLLBACK` de la base de datos, garantizando que no queden datos huérfanos ni estados intermedios inconsistentes."

---

### 22. ¿Por qué eligieron una base de datos relacional como MySQL 8.4 en lugar de una base de datos NoSQL como MongoDB?
**Respuesta:**
"El modelo de negocio del transporte de carga pesada exige consistencia estricta, integridad referencial y transacciones ACID. Manejamos entidades fuertemente vinculadas: un usuario tiene ofertas, una oferta pertenece a una carga, una carga adjudicada genera un viaje y un viaje genera registros de auditoría y novedades.
En MongoDB, modelar estas relaciones implicaría o bien anidar documentos masivos (creando problemas de concurrencia al actualizar ofertas simultáneas) o manejar referencias manuales sin integridad referencial garantizada por el motor, trasladando el riesgo de inconsistencia al código de la aplicación. MySQL 8.4 con motor InnoDB nos ofrece restricciones de llave foránea nativas, aislamiento de transacciones y confiabilidad comprobada."

---

## BLOQUE 4: MODELO LOGÍSTICO Y GEMELO DIGITAL

### 23. ¿Por qué llaman a su simulador "Gemelo Digital" si no está conectado a dispositivos satelitales GPS en tiempo real?
**Respuesta:**
"En la literatura académica de ingeniería de sistemas y operaciones (según estándares como ISO/IEC 30149), un Gemelo Digital se define como un modelo computacional que emula el comportamiento de un sistema físico del mundo real para propósitos de predicción, optimización o diagnóstico. Existen gemelos digitales telemáticos (basados en sensores en vivo) y gemelos digitales paramétricos de simulación previa (*Pre-operational Digital Twins*).
El Gemelo Digital de TRAXIA modela la física y la economía del viaje antes de que el vehículo salga del patio de carga: simula la resistencia del trayecto en kilómetros, la demanda energética en combustible de acuerdo con el tonelaje y tipo de motor, el costo regulado de los peajes nacionales y los costos fijos de operación del transportista. Por lo tanto, cumple rigurosamente con la definición de modelo de simulación de gemelo digital para despacho logístico."

---

### 24. ¿Cómo calcula exactamente el sistema el flete sugerido en el servicio de simulación?
**Respuesta:**
"El cálculo implementado en `SimulationService.java` se fundamenta en la siguiente ecuación paramétrica:
$$\text{Costo Directo} = (\text{Galones ACPM} \times \text{Precio Galón}) + (\text{Número de Peajes} \times \text{Tarifa Promedio Peaje})$$
Donde:
1. $\text{Galones ACPM} = \frac{\text{Distancia (km)}}{\text{Rendimiento Tipología (km/gal)}}$.
   - Camioneta: $30\text{ km/gal}$.
   - Turbo: $18\text{ km/gal}$.
   - Sencillo: $12\text{ km/gal}$.
   - Doble Troque: $8\text{ km/gal}$.
   - Tractomula: $5.5\text{ km/gal}$.
   - Precio de referencia de ACPM: $\$10,500\text{ COP/galón}$.
2. $\text{Número de Peajes} = \max\left(1, \left\lfloor \frac{\text{Distancia}}{75} \right\rfloor \right)$ con un costo promedio de $\$14,500\text{ COP}$ por caseta.
3. Finalmente, el **Flete Sugerido** incorpora un margen operativo y de contingencia del 45%:
$$\text{Flete Sugerido} = \text{Costo Directo} \times (1 + 0.45)$$
Por ejemplo, en la ruta Bogotá – Medellín (420 km) para un camión Sencillo:
- ACPM: $420 / 12 = 35\text{ galones} \times \$10,500 = \$367,500\text{ COP}$.
- Peajes: $420 / 75 = 5\text{ peajes} \times \$14,500 = \$72,500\text{ COP}$.
- Costo Directo: $\$440,000\text{ COP}$.
- Flete Sugerido con margen: $\$440,000 \times 1.45 = \$638,000\text{ COP}$."

---

### 25. ¿Cómo se alinea este cálculo con la regulación colombiana del SICE-TAC?
**Respuesta:**
"El SICE-TAC (Sistema de Información de Costos Eficientes para el Transporte Automotor de Carga del Ministerio de Transporte) estructura los costos del transporte en dos categorías: Costos Variables (combustible, peajes, llantas, lubricantes y mantenimiento) y Costos Fijos (seguros, salario de conductor y depreciación vehicular).
El algoritmo de TRAXIA captura con precisión los dos rubros de mayor peso dentro de los costos variables (combustible y peajes, que representan más del 60% del costo directo de un viaje) y cubre los costos fijos e imprevistos a través del margen operativo del 45%, asegurando que las tarifas sugeridas protejan al transportista contra el cobro de fletes que no cubran los costos mínimos operativos."

---

### 26. ¿Qué sucede si un usuario intenta cotizar una ruta entre dos municipios que no están registrados en la matriz de distancias?
**Respuesta:**
"La clase `SimulationService.java` implementa un algoritmo de resolución jerárquica con respaldo defensivo (*Fallback*):
1. Primero busca el par exacto municipio origen - municipio destino en la matriz de rutas troncales.
2. Si no existe, busca la distancia entre las capitales departamentales correspondientes.
3. Si tampoco existen, aplica un estimador de contingencia basado en la distancia promedio intermunicipal por defecto, registrando una advertencia en la respuesta para indicar que se trata de un valor aproximado."

---

### 27. ¿Por qué no utilizaron la API comercial de Google Maps o Mapbox para obtener la distancia satelital exacta?
**Respuesta:**
"La decisión de ingeniería obedeció a dos razones técnicas y operativas:
1. **Autonomía y Resiliencia del Sistema:** Depender de una API de terceros para el núcleo del cálculo de fletes expone al sistema a fallos por caídas de servicio externo, latencias de red y cuotas de consumo por facturación.
2. **Realidad Operativa del Transporte Pesado:** Las APIs estándar de navegación para automóviles (como Google Maps convencional) calculan rutas para vehículos particulares, sugiriendo a menudo atajos urbanos, vías con restricciones de gálibo (altura de puentes) o pendientes no transitables por tractomulas cargadas con 35 toneladas. Nuestra matriz modela las troncales de carga pesada autorizadas por el Instituto Nacional de Vías (INVIAS)."

---

## BLOQUE 5: PRUEBAS, CALIDAD, DEVOPS Y RESILIENCIA

### 28. Durante la auditoría inicial de Maven se reportaban 5 fallos en pruebas unitarias. ¿Cuáles fueron y cómo se resolvieron?
**Respuesta:**
"Las 5 pruebas que fallaban estaban localizadas en `AuthControllerTest` y `RegistrationServiceTest`:
- En `AuthControllerTest`, fallaba la prueba que verifica el rechazo de cookies inseguras fuera de entornos de desarrollo, debido a que se había agregado `"production"` a la lista de entornos no seguros (BUG-001). Se corrigió eliminando `"production"`.
- En `RegistrationServiceTest`, fallaban cuatro pruebas debido a que se había introducido un valor `"production"` en `ALLOWED_ENVIRONMENTS` (BUG-002), se había forzado la activación automática en el registro (BUG-003) y se había eliminado la llamada `authMethod.verify(now)` en la verificación de correo.
Revertimos las alteraciones inapropiadas, agregamos validaciones contra valores nulos y parametrizamos el comportamiento mediante flags limpios de configuración. Como resultado, las 30 pruebas unitarias y de integración de Maven pasan hoy con 0 fallos y 0 errores."

---

### 29. En el reporte de Maven aparecen 5 pruebas en estado "Skipped". ¿A qué se debe y por qué no representa un defecto?
**Respuesta:**
"Las 5 pruebas omitidas pertenecen a suites de pruebas de integración con contenedores Docker (**Testcontainers**). Estas pruebas están configuradas con la directiva `@EnabledIfDocker` o evaluadores condicionales que inspeccionan si el socket del daemon de Docker (`dockerd`) está disponible en el entorno de ejecución.
Al ejecutar la auditoría de forma nativa en Windows con MySQL y Mailpit instalados localmente sin Docker Desktop activo en segundo plano, el framework de pruebas de Spring detecta la ausencia del socket y omite las pruebas de contenedores temporales de forma segura (*Skipped*), en lugar de romper la construcción del proyecto. La funcionalidad completa fue probada y verificada contra el servidor MySQL real en ejecución."

---

### 30. ¿Qué estándar utilizaron para reportar los errores en la API REST y cómo los procesa el frontend?
**Respuesta:**
"Implementamos el estándar internacional **RFC 7807 (Problem Details for HTTP APIs)** mediante una clase global de captura de excepciones marcada con `@RestControllerAdvice` (`GlobalExceptionHandler.java`).
Cuando ocurre un error (por ejemplo, validación de contraseña inválida o token expirado), el servidor no responde con un mensaje de texto plano ni con la traza interna del servidor (*stacktrace*), sino con un objeto JSON estandarizado:
```json
{
  "type": "https://traxia.com/errors/invalid-credentials",
  "title": "Credenciales inválidas",
  "status": 401,
  "detail": "El correo o la contraseña son incorrectos",
  "timestamp": "2026-11-02T20:30:00Z"
}
```
En el frontend Flutter, el cliente Dio captura la respuesta estructurada y Riverpod extrae el atributo `detail` para mostrar notificaciones de error comprensibles al usuario final."

---

### 31. ¿Cómo probaron el flujo de registro y activación por correo si no tenían un dominio ni servidor SMTP público configurado?
**Respuesta:**
"Utilizamos **Mailpit**, una herramienta moderna de captura e inspección de correos para entornos de desarrollo y control de calidad.
Configuramos Spring Boot para enviar los correos al servidor SMTP local de Mailpit en el puerto 1025. Mailpit intercepta los mensajes en memoria y expone una API REST y una interfaz gráfica en el puerto 8025. Durante las pruebas automatizadas, pudimos consultar la API de Mailpit (`GET /api/v1/messages`), extraer el token criptográfico de activación directamente del cuerpo del correo y enviarlo al endpoint `/api/v1/auth/verify-email`, comprobando la activación real del usuario sin emitir tráfico fuera de la red local."

---

### 32. Si la plataforma creciera repentinamente a 100.000 usuarios concurrentes, ¿cuáles serían los principales cuellos de botella y cómo los resolverían?
**Respuesta:**
"En un escenario de alta concurrencia, identificaríamos tres puntos de saturación:
1. **Base de Datos MySQL (Concurrencia de Escritura):**
   - *Solución:* Implementar un esquema de réplicas de lectura (*Read Replicas*). Las consultas de cartelera de cargas y simulación se dirigirían a réplicas, reservando el nodo primario para transacciones de escritura (publicación, ofertas y viajes).
2. **Rate Limiting en Memoria:**
   - *Solución:* Actualmente el Rate Limiting reside en la memoria de la JVM. En un clúster distribuido con múltiples instancias del backend, migraríamos el almacenamiento de intentos a un clúster de **Redis** con llaves expirables.
3. **Persistencia de Sesiones y Refresh Tokens:**
   - *Solución:* Indexación optimizada sobre la columna `token_hash` en la tabla `refresh_tokens` y purga asíncrona periódica mediante un trabajo programado (*Spring Scheduled Task*) de tokens expirados o revocados."

---

### 33. ¿Por qué el proyecto no utiliza WebSockets para actualizar las ofertas en la cartelera en tiempo real?
**Respuesta:**
"La arquitectura de Fase 2 priorizó la resiliencia en conexiones móviles intermitentes (conductores en carretera con cobertura celular 3G/4G inestable), donde las conexiones persistentes TCP de WebSockets sufren caídas continuas y obligan a reconexiones costosas. El frontend Flutter implementa patrones de consulta bajo demanda y refresco automático al interactuar con la pantalla, reservando WebSockets o Server-Sent Events (SSE) para la fase de seguimiento telemático en vivo."

---

### 34. Si un atacante interceptara un enlace de activación de correo ya utilizado e intentara reenviarlo, ¿cómo reacciona el sistema?
**Respuesta:**
"El sistema rechaza la solicitud de forma contundente arrojando un código **HTTP 400 Bad Request** con la excepción `InvalidEmailVerificationTokenException`.
Cuando un token es utilizado por primera vez, el servicio `RegistrationService` marca el registro del token en la base de datos con `used_at = NOW()`. En la consulta de validación (`findUserByValidToken`), la cláusula SQL exige explícitamente que `used_at IS NULL` y que `expires_at > NOW()`. Por lo tanto, un token de un solo uso jamás puede ser reutilizado (*Replay Attack Prevention*)."

---

### 35. ¿Cuál es el mayor aporte o lección de ingeniería de software que les dejó este proyecto de grado / auditoría?
**Respuesta:**
"La lección fundamental es que la calidad de un software no se mide por lo vistosa que sea su interfaz gráfica, sino por la **solidez de sus invariantes de negocio, su cobertura de pruebas y su postura de ciberseguridad**.
Aprendimos que relajar una directiva de seguridad para facilitar un despliegue rápido —como ocurrió con la inclusión de `"production"` en las listas de desarrollo— puede abrir brechas de seguridad críticas como cookies inseguras o fallos de compilación. Haber llevado a cabo una auditoría forense con pruebas reales, subsanando errores en código Java y Dart, y validando la persistencia real en MySQL nos demostró la importancia de la ingeniería rigurosa frente a la simple programación."
