# Cuánto Cobran

Cuánto Cobran es una app multiplataforma para iOS y Android centrada en consultar y visualizar sueldos de cargos públicos en España a partir de datos públicos y fuentes de transparencia.[cite:17][cite:21]

El proyecto se construirá con Kotlin Multiplatform para compartir lógica y UI entre plataformas, usando Compose Multiplatform basado en Jetpack Compose para Android e iOS, un backend en Vapor con Swift para exponer APIs y procesos de ingestión, y un flujo de desarrollo público basado en Spec-Driven Development con Spec Kit de GitHub.[cite:41][cite:30][cite:29][cite:28][cite:31]

## Propósito

El objetivo del proyecto es crear un MVP sencillo, útil y verificable que permita buscar, filtrar y entender retribuciones públicas sin fricción. La propuesta se apoya en la existencia de información pública sobre retribuciones en portales institucionales y en herramientas periodísticas que ya demuestran interés real en este tipo de consulta ciudadana.[cite:11][cite:17][cite:21]

## Objetivos del MVP

- Consultar sueldos de cargos públicos en España desde una app móvil simple y rápida.[cite:11][cite:17]
- Unificar en una experiencia clara datos que hoy suelen estar dispersos entre portales de transparencia y publicaciones públicas.[cite:11][cite:21]
- Validar una arquitectura full-stack compuesta por cliente móvil multiplataforma con UI compartida y backend en Swift.[cite:41][cite:29]
- Documentar el desarrollo en abierto para que el proceso, las decisiones y los cambios sean trazables desde la especificación hasta la implementación.[cite:25][cite:28][cite:31]

## Stack

| Capa | Tecnología | Papel en el proyecto |
|---|---|---|
| App móvil | Kotlin Multiplatform | Compartir lógica de dominio, red, modelos y casos de uso entre iOS y Android.[cite:27][cite:30] |
| UI compartida | Compose Multiplatform basado en Jetpack Compose | Construir una única capa de interfaz para Android e iOS con APIs compartidas de Compose.[cite:41][cite:42][cite:44] |
| Backend | Vapor + Swift | API, normalización de datos, procesos de agregación y servicios de soporte.[cite:29][cite:38] |
| Método de desarrollo | GitHub Spec Kit | Flujo Spec → Plan → Tasks → Implement como base del proyecto.[cite:28][cite:31] |

## Arquitectura inicial

La arquitectura se plantea en dos bloques principales: una app móvil multiplataforma orientada a consumo y exploración de datos, y un backend que centraliza la obtención, normalización y publicación de la información pública. Kotlin Multiplatform encaja bien para compartir lógica entre iOS y Android, y Compose Multiplatform permite además compartir la UI con el mismo paradigma declarativo basado en Jetpack Compose.[cite:41][cite:42][cite:48]

En esta propuesta, la capa compartida incluirá dominio, casos de uso, networking, estado de pantalla y componentes de interfaz reutilizables. Cada plataforma mantendrá sus entry points y cualquier integración nativa que sea necesaria, pero la mayor parte de la experiencia visible del MVP vivirá en código Compose compartido.[cite:41][cite:48][cite:53]

A nivel de dominio, la primera versión puede girar alrededor de entidades como cargo público, organismo, retribución, fuente y fecha de vigencia. Esta separación facilita tanto la trazabilidad del dato como futuras ampliaciones, por ejemplo histórico salarial, comparativas o alertas de cambios.[cite:11][cite:17][cite:21]

## Funcionalidades iniciales

- Listado de cargos públicos con nombre, institución y retribución visible.[cite:11][cite:17]
- Búsqueda por nombre del cargo, organismo o ámbito administrativo.
- Ficha de detalle con desglose básico y referencia a la fuente pública original.[cite:17][cite:21]
- Filtros simples, por ejemplo por institución o tipo de cargo.
- Indicador de fecha de actualización del dato y trazabilidad de origen.[cite:21]

## UI con Jetpack Compose

La interfaz del proyecto se desarrollará con Compose Multiplatform, que comparte gran parte de la API de Jetpack Compose y permite utilizar el mismo enfoque declarativo para Android e iOS.[cite:41][cite:44] Esto hace posible construir pantallas, componentes y estado de UI una sola vez, manteniendo una base coherente entre ambas plataformas.[cite:42][cite:51]

Para el MVP, este enfoque encaja especialmente bien porque reduce duplicidad en una primera versión y acelera la iteración de producto. Aun así, la arquitectura debe dejar espacio para incorporar integraciones nativas o ajustes específicos de plataforma cuando el producto lo requiera.[cite:48][cite:53]

## Backend en Vapor

El backend tendrá como responsabilidad exponer una API estable para el cliente móvil y preparar los datos para consulta eficiente. Vapor está orientado a construir APIs, servidores backend y servicios HTTP en Swift, por lo que encaja bien con este objetivo.[cite:29][cite:38]

En una primera fase, el backend puede incluir estos módulos:

- Ingesta de fuentes públicas.
- Normalización y validación de registros.
- API de consulta para listados y detalle.
- Capa de mapeo de fuentes para conservar trazabilidad.
- Posible cacheado o almacenamiento intermedio para mejorar rendimiento.

## Desarrollo público

El desarrollo será público desde el inicio, con repositorio abierto, documentación viva y evolución visible de cada decisión relevante. Esto encaja especialmente bien con un proyecto centrado en transparencia y datos públicos, porque el producto y su proceso comparten la misma lógica de apertura y verificabilidad.[cite:17][cite:21]

La documentación del proyecto debe reflejar no sólo qué se construye, sino también por qué se toma cada decisión técnica o de producto. Esa trazabilidad se refuerza al adoptar Spec-Driven Development como columna vertebral del trabajo.[cite:25][cite:28][cite:31]

## Método Spec-Driven

GitHub Spec Kit define Spec-Driven Development como un proceso en el que la especificación guía el trabajo antes de pasar a la implementación, con un flujo estructurado de especificación, planificación, tareas e implementación.[cite:25][cite:28][cite:31]

En este proyecto, el ciclo de trabajo seguirá esta estructura:

1. **Spec**: definir el problema, el alcance del incremento y el valor para usuario o sistema.[cite:28][cite:31]
2. **Plan**: decidir stack, arquitectura, restricciones y estrategia técnica para ese incremento.[cite:31]
3. **Tasks**: desglosar el trabajo en unidades pequeñas, revisables y ejecutables.[cite:25][cite:31]
4. **Implement**: desarrollar cada tarea con validación continua y feedback sobre la propia especificación.[cite:28][cite:31]

Este enfoque es especialmente útil para un proyecto público porque hace visible la intención antes del código y convierte la documentación en una pieza operativa del desarrollo, no en un artefacto secundario.[cite:25][cite:28]

## Estructura sugerida del repositorio

```text
cuanto-cobran/
├── README.md
├── docs/
│   ├── vision.md
│   ├── architecture.md
│   └── decisions/
├── specs/
│   └── 001-mvp-consulta-sueldos/
│       ├── spec.md
│       ├── plan.md
│       └── tasks.md
├── app/
│   ├── composeApp/
│   └── shared/
├── backend/
│   └── vapor-server/
└── scripts/
```

## Principios del proyecto

- Claridad antes que complejidad.
- Datos con fuente verificable antes que amplitud sin trazabilidad.[cite:17][cite:21]
- MVP pequeño, pero bien estructurado para evolucionar.
- Lógica y UI compartidas entre plataformas cuando aceleren el aprendizaje y reduzcan duplicidad.[cite:41][cite:42][cite:48]
- Documentación y especificación como parte del producto, no como anexos.[cite:25][cite:28][cite:31]

## Roadmap inicial

### Fase 1

Definición del alcance del MVP, diseño del dominio, estructura inicial del monorepo y primera spec funcional para la consulta de sueldos.[cite:28][cite:31]

### Fase 2

Construcción del backend en Vapor con un primer conjunto de endpoints y una fuente pública integrada de forma controlada.[cite:29][cite:17]

### Fase 3

Desarrollo de la app móvil con Kotlin Multiplatform y Compose Multiplatform, incluyendo listado inicial, detalle y conexión con la API.[cite:41][cite:30][cite:48]

### Fase 4

Refinamiento de UX, mejora de la calidad del dato, publicación del progreso y apertura a contribuciones o feedback público.

## Visión

Cuánto Cobran busca demostrar que una app cívica puede ser simple en su uso, rigurosa con la trazabilidad del dato y transparente también en su forma de construirse. El MVP no pretende cubrir todo el mapa institucional desde el primer día, sino validar una base técnica y de producto creíble sobre la que crecer.[cite:11][cite:17][cite:21]
