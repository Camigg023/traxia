# GLOSARIO TÉCNICO Y ARQUITECTÓNICO — PROYECTO TRAXIA

Este glosario define con rigor técnico y conceptual los términos, tecnologías, patrones y estándares de ingeniería implementados en la plataforma de logística y transporte de carga pesada **TRAXIA**.

---

## 1. CIBERSEGURIDAD Y GESTIÓN DE IDENTIDAD

### JWT (JSON Web Token — RFC 7519)
Estándar abierto para la transmisión segura y compacta de información estructurada en formato JSON entre dos partes. En TRAXIA, el **Access Token** es un JWT firmado criptográficamente con el algoritmo simétrico HMAC-SHA256 (`HS256`). Contiene *claims* esenciales como el identificador del usuario (`sub`), su rol operativo (`role`), la fecha de emisión (`iat`) y la fecha de expiración (`exp`), con una vida útil corta (típicamente 15 minutos).

### Refresh Token (Token de Refresco)
Identificador criptográfico aleatorio y opaco con un ciclo de vida más extenso (7 días), almacenado de forma persistente en la base de datos y entregado al navegador exclusivamente mediante una cookie `HttpOnly`. Se utiliza para solicitar nuevos Access Tokens cuando estos expiran sin requerir que el usuario vuelva a ingresar su contraseña.

### Token Rotation (Rotación de Tokens)
Mecanismo de seguridad en el cual cada vez que un Refresh Token es utilizado para renovar una sesión, dicho token es revocado y destruido en la base de datos (`revoked = true`), emitiéndose un nuevo par de Access Token y Refresh Token. Si un atacante roba un Refresh Token antiguo e intenta reutilizarlo, el sistema detecta una anomalía de reutilización y revoca toda la cadena de sesiones asociadas.

### Cookie HttpOnly
Directiva del protocolo HTTP para la cabecera `Set-Cookie` que instruye al navegador a impedir el acceso a la cookie desde scripts de JavaScript (`document.cookie`). En TRAXIA, protege al Refresh Token contra ataques de filtración mediante Cross-Site Scripting (XSS).

### Atributos `Secure` y `SameSite`
- **`Secure`:** Garantiza que la cookie solo viaje a través de canales cifrados HTTPS. Si se transmite por HTTP plano, el navegador la descarta (salvo en orígenes locales permitidos durante desarrollo).
- **`SameSite=Lax`:** Previene el envío involuntario de la cookie en solicitudes cruzadas de terceros originadas en sitios externos, mitigando ataques de Cross-Site Request Forgery (CSRF).

### CORS (Cross-Origin Resource Sharing)
Mecanismo de seguridad de los navegadores que restringe las solicitudes HTTP asíncronas entre orígenes distintos (combinación de protocolo, dominio y puerto). En TRAXIA, Spring Security define una política estricta que solo permite llamadas provenientes del origen frontend autorizado (`http://localhost:5000` o dominio web productivo), habilitando el intercambio de credenciales (`AllowCredentials=true`).

### CSRF (Cross-Site Request Forgery)
Tipo de vulnerabilidad donde un sitio web malicioso fuerza al navegador de una víctima autenticada a ejecutar acciones no deseadas en una aplicación web de destino. TRAXIA mitiga CSRF mediante una defensa en tres capas: directiva `SameSite=Lax`, validación estricta del encabezado `Origin` en el filtro `RefreshRequestGuardFilter`, y exigencia de una cabecera personalizada (`X-TRAXIA-Refresh-Request: true`) que los formularios HTML estándar no pueden inyectar.

### Rate Limiting y HMAC-SHA256
Estrategia de defensa contra ataques de fuerza bruta y denegación de servicio (DoS). TRAXIA implementa una ventana deslizante en memoria que rastrea el número de intentos de inicio de sesión fallidos. Para proteger la privacidad de los usuarios y cumplir normativas de protección de datos personales (GDPR/Habeas Data), la dirección IP del cliente no se almacena en texto plano, sino que se seudonimiza aplicando una función hash criptográfica con clave secreta (**HMAC-SHA256**).

### BCrypt (Función Hash con Sal)
Algoritmo de derivación de claves para contraseñas basado en el cifrador Blowfish. Incorpora un valor de "sal" (*salt*) criptográfico aleatorio para mitigar ataques basados en tablas precalculadas (*Rainbow Tables*) y un factor de costo computacional ajustable (en TRAXIA `cost = 10`), garantizando que los intentos de fuerza bruta sobre hashes filtrados sean computacionalmente inviables.

### RFC 7807 (Problem Details for HTTP APIs)
Estándar internacional que especifica un formato JSON estandarizado para reportar errores en APIs RESTful. Contiene atributos canónicos como `type`, `title`, `status`, `detail`, `instance` y `timestamp`, facilitando que el frontend Flutter interprete y muestre mensajes de error claros al usuario.

---

## 2. ARQUITECTURA DEL BACKEND Y PATRONES DE DISEÑO

### Spring Boot 3.4.x
Framework líder en el ecosistema Java para el desarrollo de microservicios y aplicaciones empresariales de producción. Automatiza la configuración (*Opinionated Auto-configuration*), incluye un servidor web embebido de alto rendimiento (Apache Tomcat), e integra herramientas de observabilidad como Spring Boot Actuator.

### Spring Security 6.x
Módulo de seguridad para aplicaciones basadas en Spring. Controla la autenticación y autorización mediante una cadena de filtros de servlet (**`SecurityFilterChain`**). En TRAXIA, opera en modo completamente sin estado (**Stateless Session Creation Policy**), delegando la validación de identidad a filtros personalizados como `JwtAuthenticationFilter`.

### Domain-Driven Design (DDD — Diseño Guiado por el Dominio)
Enfoque de desarrollo de software que estructura el sistema modelando fielmente las reglas, el lenguaje y las entidades del negocio del transporte de carga. TRAXIA organiza su código en módulos o contextos delimitados (*Bounded Contexts*): `identity`, `loads`, `simulation`, `bids` y `trips`.

### Clean Architecture (Arquitectura Limpia) / Arquitectura Hexagonal
Patrón arquitectónico que aísla las reglas de negocio del dominio de los detalles tecnológicos externos (bases de datos, frameworks web, protocolos de comunicación). En TRAXIA, cada módulo divide su estructura en tres capas desacopladas:
1. **Domain:** Entidades puras, objetos de valor (*Value Objects*), excepciones de negocio y repositorios como interfaces.
2. **Application:** Servicios de orquestación y casos de uso del sistema.
3. **Infrastructure / API:** Controladores REST, adaptadores de persistencia JPA y clientes externos.

### Spring Data JPA e Hibernate
- **JPA (Jakarta Persistence API):** Especificación estándar de Java para la persistencia de datos en bases de datos relacionales mediante mapeo objeto-relacional (ORM).
- **Hibernate:** El motor de implementación subyacente que traduce automáticamente las operaciones sobre objetos Java en sentencias SQL optimizadas.

### HikariCP
Pool de conexiones JDBC de alto rendimiento y ultraligero que gestiona eficientemente la apertura, reutilización y cierre de conexiones TCP hacia la base de datos MySQL, reduciendo drásticamente la latencia en entornos concurrentes.

### Flyway
Herramienta de versionamiento y migración continua de bases de datos. Garantiza que el esquema de la base de datos evolucione de manera determinística, auditable y sincronizada en todos los entornos de desarrollo, prueba y producción mediante scripts versionados (`V1__...sql` a `V5__...sql`).

---

## 3. BASE DE DATOS Y PERSISTENCIA

### MySQL 8.4 LTS
Sistema de Gestión de Bases de Datos Relacional (RDBMS) de código abierto y estándar de la industria. Ofrece soporte nativo para transacciones conformes a los principios ACID (Atomicidad, Consistencia, Aislamiento y Durabilidad) mediante su motor de almacenamiento transaccional **InnoDB**.

### Identificadores UUID y Representación `BINARY(16)`
Un UUID (Universally Unique Identifier) versión 4 es un identificador aleatorio de 128 bits. En lugar de almacenarlo como texto legible de 36 caracteres (`VARCHAR(36)`), TRAXIA lo almacena en formato binario compacto de 16 bytes (**`BINARY(16)`**). Esto ahorra más del 55% del espacio en disco, reduce la memoria ocupada por los índices de árbol B+ (*B-Tree*) y optimiza significativamente la velocidad de las consultas de unión (`JOIN`).

### Condición de Carrera (Race Condition)
Anomalía de concurrencia donde dos o más transacciones simultáneas intentan modificar el mismo recurso de forma no coordinada, produciendo un estado inconsistente. En el módulo de ofertas (`bids`), TRAXIA previene condiciones de carrera mediante transacciones atómicas a nivel de base de datos (`@Transactional`), asegurando que cuando una oferta es aceptada, las demás sean rechazadas inmediatamente y ninguna otra pueda adjudicarse al mismo tiempo.

---

## 4. FRONTEND Y DESARROLLO MÓVIL/WEB

### Flutter Web
Framework de desarrollo multiplataforma impulsado por Google que permite compilar código fuente en lenguaje Dart directamente a aplicaciones web de alto rendimiento, renderizando la interfaz mediante CanvasKit / HTML.

### Dart
Lenguaje de programación orientado a objetos, fuertemente tipado y compilado por delante en el tiempo (AOT) o justo a tiempo (JIT), optimizado para la construcción de interfaces de usuario reactivas y fluidas.

### Riverpod
Framework avanzado de gestión de estado reactivo para Flutter. A diferencia de `Provider`, Riverpod ofrece seguridad en tiempo de compilación (evita errores `ProviderNotFoundException`), no depende del árbol de widgets para instanciar estados y facilita la inyección de dependencias y pruebas unitarias aisladas mediante `ProviderScope`.

### GoRouter
Enrutador declarativo para Flutter que traduce URLs de navegadores web en rutas y pantallas de la aplicación. Soporta navegación anidada, redirección condicional (**Guards**) basada en el estado de autenticación del usuario y manejo dinámico de parámetros de ruta y consulta.

### Dio
Cliente HTTP robusto para Dart que soporta interceptores de red, configuración global de cabeceras, serialización JSON y gestión de cookies entre dominios (`withCredentials = true`).

---

## 5. MODELO LOGÍSTICO Y OPERATIVO DE TRAXIA

### Gemelo Digital (Digital Twin / Modelo de Simulación Heurístico)
En el contexto de TRAXIA, el gemelo digital es un motor de simulación matemática determinística que proyecta los costos operativos directos de una ruta de transporte de carga antes de su publicación. A diferencia de un sistema telemático IoT de seguimiento en tiempo real, el simulador de TRAXIA calcula distancias por matriz interdepartamental, consumo de combustible según la tipología vehicular y cantidad estimada de peajes viales.

### SICE-TAC
*Sistema de Información de Costos Eficientes para el Transporte Automotor de Carga*, establecido por el Ministerio de Transporte de Colombia para fijar parámetros de referencia en los costos operativos de fletes y evitar la competencia desleal o la explotación tarifaria. TRAXIA utiliza las fórmulas de costo directo de combustible y peajes del modelo SICE-TAC para calcular fletes sugeridos con márgenes operativos justos (45%).

### ACPM (Aceite Combustible Para Motores)
Denominación técnica oficial del combustible diésel en Colombia, utilizado por más del 95% del parque automotor de carga pesada en el país. En el modelo matemático de TRAXIA, se toma como valor de referencia $10,500 COP por galón.

### Tipologías Vehiculares de Carga en Colombia
- **Camioneta:** Vehículo liviano de distribución urbana o intermunicipal corta (rendimiento: 30 km/gal).
- **Turbo:** Camión de dos ejes liviano (capacidad ~4.5 a 5 toneladas, rendimiento: 18 km/gal).
- **Sencillo:** Camión rígido de dos ejes para carga mediana (capacidad ~8.5 a 10 toneladas, rendimiento: 12 km/gal).
- **Doble Troque:** Camión rígido de tres ejes para carga pesada y granel (rendimiento: 8 km/gal).
- **Tractomula (Tractocamión):** Vehículo articulado de 4 a 6 ejes para carga de larga distancia y contenedores (rendimiento: 5.5 km/gal).

### Cartelera de Cargas (Marketplace de Fletes)
Tablero digital dinámico donde las empresas publican requerimientos de transporte disponibles y los transportistas consultan, filtran por origen/destino y postulan ofertas económicas competitivas.

### Novedad de Entrega y Prueba de Entrega (POD - Proof of Delivery)
Registro digital emitido por el transportista al completar la entrega física de la mercancía. En TRAXIA, el cierre de un viaje (`DELIVERED`) exige ingresar un informe de entrega u observaciones de novedades, las cuales son registradas con sello temporal inmutable en la tabla de auditoría.
