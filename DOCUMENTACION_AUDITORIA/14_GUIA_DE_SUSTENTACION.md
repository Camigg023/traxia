# GUÍA MAESTRA DE SUSTENTACIÓN ACADÉMICA Y TÉCNICA — PROYECTO TRAXIA

Esta guía ha sido elaborada específicamente para preparar al estudiante o equipo de desarrollo ante un jurado calificador, evaluadores académicos o directores de proyecto. Contiene explicaciones pedagógicas y rigurosas de cada concepto, el análisis del código fuente real, un guion estructurado de sustentación oral (5 a 10 minutos) y las claves para defender cada decisión de diseño tomada.

---

## 1. COMPRENSIÓN CONCEPTUAL Y TÉCNICA DEL PROYECTO

### ¿Qué es TRAXIA?
**En palabras sencillas:** TRAXIA es una plataforma web inteligente que funciona como un punto de encuentro digital entre empresas que necesitan mover mercancías por carretera en Colombia y transportistas de carga pesada que buscan viajes rentables.
**En términos técnicos:** Es un sistema distribuido basado en una arquitectura cliente-servidor desacoplada, con un backend RESTful desarrollado en Java 21 / Spring Boot 3.4 y un frontend web reactivo en Flutter / Dart. Implementa un motor de simulación heurístico ("Gemelo Digital") para calcular costos operativos de referencia y un sistema transaccional de subasta inversa con mitigación de condiciones de carrera.

### ¿Qué problema soluciona?
El sector del transporte de carga en Colombia sufre de tres problemas estructurales:
1. **Intermediación opaca y desleal:** Agencias comisionistas que retienen márgenes excesivos sin agregar valor logístico.
2. **Asimetría de información y viajes en vacío (*Empty Backhaul*):** Conductores que retornan a sus ciudades de origen sin carga, perdiendo tiempo y dinero.
3. **Falta de rigor en la liquidación de fletes:** Desconocimiento de los costos reales de peajes y combustible (ACPM), lo que genera tarifas por debajo del costo operativo o incumplimientos regulatorios del modelo SICE-TAC del Ministerio de Transporte.

### ¿Quiénes son sus usuarios?
1. **Generadores de Carga / Empresas (`SHIPPER`):** Industrias, comercializadoras o distribuidores que publican requerimientos de transporte, simulan fletes sugeridos y seleccionan la mejor oferta económica entre los transportistas.
2. **Transportistas / Conductores (`DRIVER`):** Propietarios o conductores de camiones (desde camionetas ligeras hasta tractomulas de 6 ejes) que consultan la cartelera de cargas, postulan ofertas económicas, aceptan asignaciones y gestionan el estado del viaje hasta la entrega.
3. **Administradores del Sistema (`ADMIN`):** Auditores y supervisores de plataforma que vigilan las operaciones, gestionan la verificación de usuarios y analizan métricas de rendimiento.

### ¿Cómo se conectan empresas y transportistas?
La plataforma opera bajo el modelo de **Mercado Abierto con Asignación Controlada**:
1. La empresa publica una carga tras pasar por un asistente de 5 etapas validado por el gemelo digital.
2. La carga se expone en la cartelera digital.
3. Los conductores interesados postulan sus propuestas económicas y fechas estimadas de recogida.
4. La empresa evalúa las ofertas recibidas y selecciona una.
5. Al aceptar la oferta ganadora, el sistema ejecuta una transacción atómica que:
   - Asigna la carga al conductor elegido.
   - Rechaza automáticamente todas las ofertas competidoras restantes.
   - Crea una orden de viaje (`Trip`) en estado `ASSIGNED`.
   - Cierra la carga para que ningún otro conductor pueda postularse.

---

## 2. EL ECOSISTEMA TECNOLÓGICO EXPLICADO FÁCILMENTE

| Concepto | Explicación Sencilla | Explicación Técnica y Rol en TRAXIA | Archivo Clave en el Código |
|---|---|---|---|
| **Flutter** | Es como el "lienzo" donde se dibuja la aplicación visualmente para que funcione en cualquier pantalla. | Framework UI multiplataforma de Google que compila código Dart a la web usando WebAssembly / CanvasKit, ofreciendo renderizado de 60 FPS. | `web/lib/main.dart` |
| **Dart** | El lenguaje en el que se escribe Flutter; es como el español con el que le damos instrucciones al lienzo. | Lenguaje orientado a objetos fuertemente tipado con recolección de basura (*Garbage Collection*) optimizado para interfaces reactivas. | Toda la carpeta `web/lib/` |
| **Java** | El motor confiable y robusto que procesa todas las operaciones pesadas en el servidor. | Lenguaje empresarial compilado a bytecode ejecutado en la máquina virtual JVM (Java 21 LTS), soportando concurrencia moderna y tipado estricto. | Toda la carpeta `backend/src/` |
| **Spring Boot** | Es un chasis preensamblado para Java que evita tener que reinventar la rueda al crear servidores web. | Framework de desarrollo empresarial que gestiona inversión de control (IoC), inyección de dependencias, seguridad (Spring Security) y persistencia JPA. | `backend/pom.xml` |
| **MySQL** | El cuaderno digital ultra seguro donde se guardan permanentemente los datos sin que se borren si el servidor se apaga. | Sistema de gestión de bases de datos relacional (RDBMS) versión 8.4 LTS con motor transaccional InnoDB que garantiza integridad ACID. | `compose.mysql.yml` |
| **API REST** | El idioma estándar (HTTP / JSON) con el que Flutter y Spring Boot se comunican por internet. | Arquitectura de servicios web sin estado (Stateless) donde los recursos se gestionan mediante verbos HTTP (`GET`, `POST`, `PUT`, `DELETE`). | `backend/.../api/` |
| **JWT** | Un carnet digital de identidad firmado criptográficamente que el usuario lleva en cada petición para demostrar quién es. | Token de seguridad estándar (RFC 7519) firmado con HMAC-SHA256 que viaja en la cabecera `Authorization: Bearer <token>`, con expiración de 15 minutos. | `JwtService.java` |
| **Riverpod** | El cerebro del frontend que recuerda qué usuario inició sesión y actualiza la pantalla automáticamente cuando algo cambia. | Gestor de estado reactivo e inyección de dependencias para Flutter desacoplado del árbol de widgets, garantizando seguridad en compilación. | `web/lib/providers/` |
| **GoRouter** | El policía de tráfico del frontend que decide qué pantalla mostrar según la URL y prohíbe el paso a zonas privadas si no has iniciado sesión. | Enrutador declarativo para Flutter que soporta URLs de navegador web, navegación profunda y guardias de seguridad (`redirect`). | `web/lib/routes/app_router.dart` |
| **Hibernate** | El traductor que convierte automáticamente los objetos de Java en filas y tablas de MySQL. | Proveedor de persistencia Object-Relational Mapping (ORM) que implementa la especificación Jakarta Persistence API (JPA). | `backend/.../infrastructure/` |
| **Flyway** | El sistema de control de versiones de la base de datos (como un Git pero para tablas y columnas). | Herramienta de migración continua que aplica scripts SQL ordenados (`V1` a `V5`) en el arranque, asegurando que todos los entornos tengan el mismo esquema. | `backend/src/main/resources/db/migration/` |

---

## 3. LOS PROCESOS CLAVE DEL SISTEMA EXPLICADOS A FONDO

### A. El Gemelo Digital: Desmitificando el Concepto
> **Pregunta típica del jurado:** *"¿Ustedes dicen que tienen un Gemelo Digital, pero dónde está el satélite o el GPS en tiempo real?"*
>
> **Respuesta contundente:**
> "Un Gemelo Digital no se limita exclusivamente a telemetría IoT en tiempo real; en ingeniería de operaciones y ciencias de la computación, un gemelo digital es una réplica computacional de un proceso físico del mundo real.
>
> En TRAXIA, nuestro Gemelo Digital (`SimulationService.java`) es un **modelo matemático determinístico y paramétrico** que replica la física y la economía de una ruta carretera colombiana:
> 1. Utiliza una matriz de distancias oficiales entre capitales (ej. Bogotá – Medellín = 420 km).
> 2. Modela la infraestructura física mediante una tasa de peajes estimada ($\max(1, \text{distancia} / 75\text{ km})$) a un valor de $14,500 COP por caseta.
> 3. Modela el consumo energético según la tipología física del camión: una camioneta rinde 30 km/galón, mientras que una tractomula de 6 ejes consume 5.5 km/galón de ACPM a $10,500 COP por galón.
> 4. Incorpora un margen operativo y de contingencia del 45% sobre los costos directos, alineándose con las directrices de costo eficiente de SICE-TAC.
>
> Por ende, nuestro gemelo digital simula el costo operacional antes de que el camión encienda el motor, permitiendo negociar fletes financieramente viables."

---

### B. El Asistente de Publicación de Cargas (5 Etapas)
Ubicado en `web/lib/screens/create_load_screen.dart` y procesado por `LoadService.java`:
1. **Etapa 1 (Origen):** Departamento, municipio y dirección exacta de cargue.
2. **Etapa 2 (Destino):** Departamento, municipio y dirección de entrega.
3. **Etapa 3 (Características Físicas):** Peso en kilogramos, volumen en metros cúbicos, tipo de mercancía y requerimientos de empaque.
4. **Etapa 4 (Vehículo Requerido):** Tipología mínima requerida (Camioneta, Turbo, Sencillo, Doble Troque, Tractomula) y tipo de carrocería (Furgón, Estacas, Refrigerado, Planchón).
5. **Etapa 5 (Esquema Económico y Gemelo Digital):** Se invoca la simulación automática de costos, se presenta el flete sugerido y la empresa establece su presupuesto ofertado.

---

### C. Prevención de Condiciones de Carrera en la Subasta
> **Pregunta típica del jurado:** *"¿Qué pasa si dos transportistas aceptan una carga al mismo milisegundo o la empresa hace clic dos veces seguidas en aceptar ofertas distintas?"*
>
> **Respuesta contundente:**
> "El sistema implementa dos barreras de protección de concurrencia:
> 1. **Transaccionalidad Atómica ACID (`@Transactional`):** El método `acceptBid` en `BidService.java` se ejecuta dentro de una transacción con nivel de aislamiento relacional en MySQL. Cuando se acepta la oferta elegida, el servicio ejecuta de forma inmediata una sentencia SQL de actualización masiva que marca a todas las demás ofertas de esa carga en estado `REJECTED`.
> 2. **Validación de Estado Finito:** Antes de procesar la aceptación, el servicio verifica que la carga se encuentre en estado `PUBLISHED`. Si una solicitud concurrente ya modificó la carga a `ASSIGNED`, la segunda petición es abortada instantáneamente con una excepción de negocio `IllegalStateException` y un código HTTP 400/409, garantizando que jamás existan dos conductores asignados al mismo viaje."

---

### D. Ciclo de Vida de los Viajes y Trazabilidad Forense
El módulo `trips` modela una máquina de estados finitos estricta:
```
           [Oferta Aceptada]
                   │
                   ▼
               ASSIGNED
                   │
           (iniciarViaje por Conductor)
                   │
                   ▼
              IN_TRANSIT
                   │
         (registrarEntrega con Observaciones)
                   │
                   ▼
               DELIVERED
```
- **Validaciones de Rol y Pertenencia:** Un conductor no puede iniciar un viaje que pertenece a otro conductor; una empresa no puede marcar un viaje como `IN_TRANSIT` (solo el transportista físico tiene esa potestad).
- **Inmutabilidad y Auditoría:** Cada cambio de estado genera un registro en la tabla `audit_events`, asociando el ID del usuario ejecutor, su dirección IP, la fecha/hora UTC y el resultado de la acción.

---

## 4. DISCURSO DE SUSTENTACIÓN PASO A PASO (GUION ORAL DE 5 A 10 MINUTOS)

> [!TIP]
> Practique este guion con un temporizador. Mantenga un tono sereno, profesional, técnico y seguro.

---

### [Minuto 0:00 – 1:30] Introducción y Contexto del Negocio
*"Buenos días, señores miembros del jurado y profesor evaluador.
Hoy tenemos el honor de presentarles **TRAXIA**, una plataforma integral de ingeniería de software diseñada para transformar la logística del transporte de carga pesada en Colombia.

En nuestro país, más del 80% de la carga se mueve por carretera, pero el sector enfrenta graves ineficiencias: intermediación comisionista no regulada, falta de herramientas para estimar costos reales de fletes y miles de camiones retornando vacíos por falta de canales confiables de contratación.

TRAXIA soluciona esta brecha conectando directamente a empresas generadoras de carga con transportistas certificados, proporcionando tres pilares fundamentales: un motor de simulación heurístico para fletes basados en costos de combustible y peajes, una cartelera de negociación en tiempo real con adjudicación atómica, y una arquitectura de ciberseguridad empresarial con trazabilidad total."*

---

### [Minuto 1:30 – 3:30] Arquitectura Tecnológica y Desacoplamiento
*"Desde el punto de vista arquitectónico, concebimos a TRAXIA bajo los principios de **Clean Architecture** y **Domain-Driven Design (DDD)**.

En el **Backend**, implementamos **Java 21 con Spring Boot 3.4**. Diseñamos una arquitectura modular dividida en contextos de dominio independientes: Identidad, Cargas, Simulación, Ofertas y Viajes. En la capa de persistencia utilizamos **Spring Data JPA** con **Hibernate** sobre **MySQL 8.4 LTS**. Para garantizar la evolución controlada del esquema de datos, utilizamos **Flyway**, permitiendo que las migraciones se apliquen de forma determinística y versionada. Además, optimizamos el almacenamiento guardando los UUIDs en formato binario compacto de 16 bytes (`BINARY(16)`), lo que reduce el tamaño de los índices de árbol B+ y agiliza las consultas en más de un 50%.

En el **Frontend**, desarrollamos una aplicación web moderna en **Flutter y Dart**, gestionada con **Riverpod** para la arquitectura de estado reactivo y **GoRouter** para el enrutamiento declarativo con guardias de seguridad que protegen los módulos privados contra accesos no autenticados."*

---

### [Minuto 3:30 – 5:30] El Gemelo Digital y Modelo de Costos
*"Uno de los mayores diferenciadores de TRAXIA es su **Gemelo Digital de Simulación de Costos**.

A diferencia de modelos teóricos o dependencias ciegas a APIs externas, implementamos un motor algorítmico determinístico en el servicio `SimulationService`. Cuando una empresa ingresa un origen y destino —por ejemplo, Bogotá a Medellín—, el simulador procesa la matriz de distancias (420 km), calcula el consumo de combustible ACPM en función de la tipología del camión seleccionado (desde 30 km/galón en camionetas hasta 5.5 km/galón en tractomulas), proyecta el número de estaciones de peaje promedio y agrega un margen operativo de contingencia del 45%, inspirado en los lineamientos del SICE-TAC del Ministerio de Transporte.

Esto garantiza que antes de publicar una carga, tanto la empresa como el transportista cuenten con un flete de referencia transparente, evitando tarifas predatorias o fletes financieramente inviables."*

---

### [Minuto 5:30 – 7:30] Ciberseguridad y Auditoría Forense
*"Durante la fase de aseguramiento de calidad y auditoría forense que realizamos sobre la plataforma, aplicamos los estándares internacionales de **OWASP**.

La autenticación está construida bajo una estrategia de **Doble Token con Rotación**:
1. El cliente recibe un **Access Token JWT** de vida corta (15 minutos) que viaja en memoria.
2. La sesión prolongada se mantiene mediante un **Refresh Token** opaco con rotación obligatoria, almacenado en una **Cookie HttpOnly**. Esto significa que es completamente invisible para JavaScript, protegiendo a los usuarios contra ataques de robo de sesión por Cross-Site Scripting (XSS).
3. Implementamos una protección estricta contra CSRF combinando `SameSite=Lax`, verificación de encabezado `Origin` y una cabecera personalizada `X-TRAXIA-Refresh-Request`.
4. Protegemos los endpoints de inicio de sesión contra ataques de fuerza bruta mediante un algoritmo de **Rate Limiting** que bloquea las solicitudes excesivas tras 5 intentos fallidos, seudonimizando la dirección IP mediante hashes criptográficos **HMAC-SHA256** para preservar la privacidad de los usuarios.

Asimismo, durante la auditoría identificamos y subsanamos 5 anomalías críticas en el código fuente, garantizando el 100% de éxito en la suite de 30 pruebas unitarias y de integración de Maven y 4 pruebas en Flutter."*

---

### [Minuto 7:30 – 9:00] Demostración del Flujo Operativo en Vivo
*(El presentador puede mostrar el navegador web en `http://localhost:5000` o describir con seguridad el flujo validado)*:
*"Podemos observar en pantalla la ejecución real del sistema:
1. Una empresa publica un requerimiento de carga de Bogotá a Medellín para un camión tipo Sencillo. El gemelo digital calcula los 420 km, 5 peajes y 35 galones de combustible.
2. Desde la cartelera de cargas, un transportista registrado consulta el requerimiento y postula una oferta por 2,600,000 COP.
3. Un segundo conductor intenta competir enviando una contraoferta.
4. La empresa evalúa las propuestas y acepta la del primer transportista: de manera inmediata, en una transacción atómica protegida contra condiciones de carrera, la carga queda adjudicada, la segunda oferta es rechazada y se crea la orden de viaje en estado `ASSIGNED`.
5. El transportista toma el control del viaje, lo marca en estado `IN_TRANSIT` y finalmente registra la entrega exitosa (`DELIVERED`) con observaciones de recibo a conformidad, quedando cada paso registrado en la tabla de auditoría forense de MySQL."*

---

### [Minuto 9:00 – 10:00] Conclusión y Cierre
*"En conclusión, señores del jurado, TRAXIA no es un prototipo visual estático; es una plataforma de software robusta, probada con datos reales, auditada en seguridad y construida sobre estándares de nivel de producción. Resuelve un problema real de la economía colombiana mediante una combinación efectiva de arquitectura limpia, modelos de simulación determinísticos y ciberseguridad avanzada.

Quedamos a su entera disposición para responder cualquier pregunta técnica o funcional. Muchas gracias."*

---

## 5. CÓMO DEFENDERSE ANTE PREGUNTAS INCÓMODAS DEL JURADO

1. **Mantenga la calma y hable con el código:** No invente funciones que no existen. Si le preguntan por algo que no está implementado (como pagos con pasarelas bancarias o geolocalización satelital en vivo), responda con seguridad:
   *"Esa funcionalidad fue identificada en la matriz de limitaciones como parte de la Fase 3 del producto, priorizando en esta fase la solidez del motor transaccional, el modelo de costos y la ciberseguridad del sistema."*
2. **Defienda el uso de `BINARY(16)` para UUIDs:** Explique que los UUIDs como texto (`VARCHAR(36)`) ocupan 36 bytes y degradan los índices relacionales. Convertirlos a binario puro (`BINARY(16)`) es la mejor práctica de ingeniería recomendada por MySQL para optimizar memoria RAM y lectura en disco.
3. **Defienda el desacoplamiento de Flutter y Spring Boot:** Explique que al no usar tecnologías acopladas (como JSP o Thymeleaf), el backend de TRAXIA es una API pura que en el futuro puede alimentar no solo la aplicación web, sino también aplicaciones móviles nativas en Android e iOS sin cambiar una sola línea de lógica de negocio.
