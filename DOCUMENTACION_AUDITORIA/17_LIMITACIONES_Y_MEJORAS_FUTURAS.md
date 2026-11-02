# LIMITACIONES TÉCNICAS IDENTIFICADAS Y HOJA DE RUTA DE MEJORAS FUTURAS

La honestidad técnica y la capacidad de introspección arquitectónica son sellos distintivos de un equipo de ingeniería de software senior y de un proyecto de grado con madurez académica. Este documento expone con rigor los límites operativos actuales de la plataforma **TRAXIA** (Fase 2) y define la hoja de ruta evolutiva para su escalamiento comercial en la Fase 3.

---

## 1. MATRIZ DE LÍMITES OPERATIVOS ACTUALES (FASE 2)

| Componente | Estado Actual en Fase 2 | Justificación de Diseño | Riesgo Operativo |
|---|---|---|---|
| **Gemelo Digital** | Modelo matemático heurístico y determinístico en `SimulationService.java`. | No incurre en costos de APIs comerciales ni depende de conectividad satelital en zonas sin señal. | No refleja trancones imprevistos, derrumbes viales ni desvíos temporales en vivo. |
| **Validación de Identidad** | Validación sintáctica de cédulas, NIT, licencias y placas por expresiones regulares (Regex). | Autonomía durante el desarrollo y pruebas locales sin requerir credenciales gubernamentales. | No valida en tiempo real si una licencia de conducción está suspendida ante el RUNT. |
| **Notificaciones de Ofertas** | Consulta bajo demanda (*Polling*) y refresco reactivo mediante Riverpod. | Resiliencia ante desconexiones de red intermitentes en teléfonos celulares de transportistas. | Los usuarios deben actualizar la vista o interactuar con la pantalla para ver contraofertas inmediatas. |
| **Recuperación de Contraseña** | Lógica de generación de tokens implementada en backend; interfaz pendiente en Flutter. | Se priorizó el flujo crítico de registro, activación de correo y login empresarial seguro. | Un usuario que olvide su contraseña debe solicitar restablecimiento manual al administrador. |
| **Pasarela de Pagos** | Registro y liquidación contable del flete en pesos colombianos (COP); pago fuera de banda. | La custodia de dinero exige cumplimiento estricto con la Superintendencia Financiera. | El desembolso físico del dinero depende de acuerdos directos entre empresa y conductor. |
| **Almacenamiento de Rate Limiting** | Memoria volátil de la Máquina Virtual de Java (`ConcurrentHashMap`). | Cero dependencias externas para despliegue ligero en entornos de evaluación. | Si el backend se reinicia, el contador de intentos fallidos de autenticación vuelve a cero. |

---

## 2. ANÁLISIS DETALLADO DE LIMITACIONES

---

### A. Simulación Heurística vs. Telemática Satelital en Tiempo Real
- **Situación Actual:** El módulo de simulación calcula distancias utilizando una matriz interdepartamental precisa entre las principales ciudades de Colombia (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga, etc.) y computa los peajes promedio mediante una tasa geométrica ($\max(1, \text{distancia} / 75\text{ km})$).
- **Límite:** Aunque el cálculo es riguroso para la cotización inicial del flete, no cuenta con sensores telemáticos IoT instalados en los vehículos para monitorear el consumo real de combustible por sensor de tanque, la velocidad instantánea ni la ubicación satelital continua durante el viaje.
- **Defensa Académica:** Esta decisión aísla el núcleo transaccional de dependencias costosas de hardware externo, cumpliendo el rol de un gemelo digital paramétrico de despacho logístico.

---

### B. Validación de Documentación Vehicular y Conectores de Gobierno
- **Situación Actual:** El sistema valida que las placas de los camiones cumplan con la nomenclatura colombiana (tres letras y tres números o dos números y una letra para remolques) y que el NIT empresarial cuente con dígito de verificación.
- **Límite:** No existe un conector SOAP/REST directo hacia las bases de datos del **RUNT** (Registro Único Nacional de Tránsito), el Ministerio de Transporte o la **DIAN** para verificar automáticamente si el SOAT o la revisión técnico-mecánica están vigentes al momento de la postulación.
- **Defensa Académica:** Las APIs del RUNT están restringidas a entidades autorizadas y exigen convenios interinstitucionales que escapan al alcance de un entorno de pruebas académicas.

---

### C. Canal de Notificaciones y Comunicación Instantánea
- **Situación Actual:** Cuando un conductor postula una oferta sobre una carga, la empresa generadora visualiza la propuesta al consultar la carga o al navegar en el panel de control.
- **Límite:** No se cuenta con un canal bidireccional permanente vía WebSockets ni notificaciones emergentes de tipo *Push Notification* en el dispositivo móvil del conductor cuando su oferta es aceptada.
- **Defensa Académica:** El protocolo HTTP/2 y las peticiones REST garantizan menor consumo de batería y datos móviles en zonas rurales con cobertura de red inestable (2G/3G/4G intermitente).

---

## 3. HOJA DE RUTA TECNOLÓGICA (FASE 3 — ESCALAMIENTO INDUSTRIAL)

Para llevar la plataforma TRAXIA al mercado productivo nacional, se establece la siguiente hoja de ruta organizada en tres horizontes de evolución tecnológica:

```
[ HORIZONTE 1: CORTO PLAZO ]
├── Completar Pantalla de Recuperación de Contraseña en Flutter Web.
├── Integración de WebSockets (STOMP sobre SockJS) para Cartelera en Vivo.
└── Centralización de Rate Limiting y Revocación de Tokens en Clúster de Redis.

[ HORIZONTE 2: MEDIANO PLAZO ]
├── Integración con Pasarela de Pagos en Custodia (Escrow vía Wompi / PayU).
├── API Connector con RUNT y Ministerio de Transporte (Validación SOAT y Tecnomecánica).
├── Compilación de la App Móvil Nativa de Flutter para Conducción en Android e iOS.
└── Módulo de Carga de Fotografías y Firma Digital para Pruebas de Entrega (POD).

[ HORIZONTE 3: LARGO PLAZO ]
├── Integración Telemática IoT con Dispositivos GPS y Sensores de Combustible CAN-Bus.
├── Algoritmo de Inteligencia Artificial para Ruteo Dinámico y Predicción de Tráfico.
└── Despliegue en Alta Disponibilidad sobre Kubernetes (EKS/GKE) con Réplicas de Lectura en MySQL.
```

---

## 4. PROPUESTA DE ARQUITECTURA DISTRIBUIDA PARA FASE 3

En la siguiente etapa de crecimiento masivo, la arquitectura evolucionará de un servidor monolítico modular a una infraestructura de contenedores altamente disponible:

```
                                  [ INTERNET ]
                                       │
                                       ▼
                       [ Cloudflare / AWS CloudFront ]
                       (Protección DDoS y Caché CDN)
                                       │
                                       ▼
                          [ Ingress Controller NGINX ]
                                       │
                   ┌───────────────────┴───────────────────┐
                   ▼                                       ▼
        [ Flutter Web Pods ]                    [ Spring Boot API Pods ]
     (Servidores Nginx Livianos)            (Horizontal Pod Autoscaler - HPA)
                                                           │
                                        ┌──────────────────┴──────────────────┐
                                        ▼                                     ▼
                                [ Clúster de Redis ]                 [ Clúster MySQL 8.4 ]
                            (Sesiones, Rate Limiting)             (Nodo Primario: Escrituras)
                                                                              │
                                                                   [ Réplica de Lectura ]
                                                                   (Cartelera y Consultas)
```

**Conclusión:** Las limitaciones identificadas no representan fallas de calidad, sino **fronteras conscientes de alcance de ingeniería**. La plataforma cuenta con una base arquitectónica sólida, limpia y extensible que permite implementar cualquiera de las mejoras de la Fase 3 sin necesidad de reconstruir ni modificar el diseño actual.
