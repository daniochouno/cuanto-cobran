# Cuánto Cobran

> App multiplataforma para consultar y visualizar sueldos de cargos públicos en España a partir de datos públicos y fuentes de transparencia.

![Status](https://img.shields.io/badge/status-en%20desarrollo-blue)
![KMP](https://img.shields.io/badge/Kotlin-Multiplatform-7F52FF)
![Compose](https://img.shields.io/badge/UI-Compose%20Multiplatform-4285F4)
![Backend](https://img.shields.io/badge/backend-Vapor%20%2B%20Swift-F05138)
![Method](https://img.shields.io/badge/method-Spec--Driven%20Development-black)

Cuánto Cobran se construirá con Kotlin Multiplatform para compartir lógica y UI entre plataformas, usando Compose Multiplatform basado en Jetpack Compose para Android e iOS, un backend en Vapor con Swift para exponer APIs y procesos de ingestión, y un flujo de desarrollo público basado en Spec-Driven Development con Spec Kit de GitHub.

## Tabla de contenidos

- [Propósito](#propósito)
- [Objetivos del MVP](#objetivos-del-mvp)
- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura](#arquitectura)
- [Funcionalidades iniciales](#funcionalidades-iniciales)
- [UI compartida con Compose](#ui-compartida-con-compose)
- [Backend en Vapor](#backend-en-vapor)
- [Desarrollo público](#desarrollo-público)
- [Flujo Spec-Driven](#flujo-spec-driven)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Principios](#principios)
- [Roadmap](#roadmap)
- [Visión](#visión)

## Propósito

El objetivo del proyecto es construir un MVP sencillo, útil y verificable que permita buscar, filtrar y entender retribuciones públicas sin fricción. La propuesta parte de que ya existe información pública sobre retribuciones en portales institucionales y en herramientas periodísticas que demuestran interés real por este tipo de consulta ciudadana.

## Objetivos del MVP

- Consultar sueldos de cargos públicos en España desde una app móvil simple y rápida.
- Unificar en una experiencia clara datos que hoy suelen estar dispersos entre portales de transparencia y publicaciones públicas.
- Validar una arquitectura full-stack con cliente móvil multiplataforma y backend en Swift.
- Documentar el desarrollo en abierto para que las decisiones y los cambios sean trazables desde la especificación hasta la implementación.

## Stack tecnológico

| Capa | Tecnología | Uso principal |
|---|---|---|
| App móvil | Kotlin Multiplatform | Compartir lógica de dominio, red, modelos y casos de uso entre iOS y Android. |
| UI compartida | Compose Multiplatform basado en Jetpack Compose | Construir una única capa de interfaz para Android e iOS con APIs compartidas de Compose. |
| Backend | Vapor + Swift | Exponer la API, normalizar datos y soportar procesos de agregación. |
| Método de trabajo | GitHub Spec Kit | Seguir el flujo Spec → Plan → Tasks → Implement. |

## Arquitectura

La solución se divide en dos bloques: una app móvil orientada a consulta y exploración de datos, y un backend que centraliza la obtención, normalización y publicación de información pública. Kotlin Multiplatform permite compartir la base funcional entre iOS y Android, y Compose Multiplatform permite compartir también la interfaz usando el mismo paradigma declarativo de Jetpack Compose.

La capa compartida incluirá dominio, casos de uso, networking, estado de pantalla y componentes de interfaz reutilizables. Cada plataforma mantendrá sus puntos de entrada y cualquier integración nativa necesaria, pero la mayor parte del MVP vivirá en código Compose compartido.

### Dominio inicial

La primera versión girará alrededor de entidades como cargo público, organismo, retribución, fuente y fecha de vigencia. Este modelo facilita la trazabilidad del dato y prepara el terreno para futuras extensiones como histórico salarial, comparativas o alertas de cambios.

## Funcionalidades iniciales

- Listado de cargos públicos con nombre, institución y retribución visible.
- Búsqueda por nombre del cargo, organismo o ámbito administrativo.
- Ficha de detalle con desglose básico y referencia a la fuente pública original.
- Filtros simples, por ejemplo por institución o tipo de cargo.
- Indicador de fecha de actualización del dato y trazabilidad de origen.

## UI compartida con Compose

La interfaz se desarrollará con Compose Multiplatform, que comparte gran parte de la API de Jetpack Compose y permite utilizar el mismo enfoque declarativo en Android e iOS. Esto permite construir pantallas, componentes y estado de UI una sola vez, manteniendo una base coherente entre ambas plataformas.

Para el MVP, este enfoque reduce duplicidad y acelera la iteración de producto. La arquitectura seguirá dejando espacio para integrar código nativo o ajustes específicos de plataforma cuando el producto lo necesite.

## Backend en Vapor

El backend tendrá como responsabilidad exponer una API estable para el cliente móvil y preparar los datos para consulta eficiente. Vapor está orientado a construir APIs, servidores backend y servicios HTTP en Swift, por lo que encaja bien con este objetivo.

### Responsabilidades iniciales

- Ingesta de fuentes públicas.
- Normalización y validación de registros.
- API de consulta para listados y detalle.
- Capa de mapeo de fuentes para conservar trazabilidad.
- Posible cacheado o almacenamiento intermedio para mejorar rendimiento.

## Desarrollo público

El desarrollo será público desde el inicio, con repositorio abierto, documentación viva y evolución visible de cada decisión relevante. Esto encaja especialmente bien con un proyecto centrado en transparencia y datos públicos, porque el producto y su proceso comparten la misma lógica de apertura y verificabilidad.

La documentación del proyecto debe explicar no sólo qué se construye, sino también por qué se toma cada decisión técnica o de producto. Esa trazabilidad se refuerza al adoptar Spec-Driven Development como columna vertebral del trabajo.

## Flujo Spec-Driven

GitHub Spec Kit plantea Spec-Driven Development como un proceso en el que la especificación guía el trabajo antes de pasar a la implementación, con un flujo estructurado de especificación, planificación, tareas e implementación.

Este proyecto seguirá el siguiente ciclo:

1. **Spec**: definir el problema, el alcance del incremento y el valor para usuario o sistema.
2. **Plan**: decidir stack, arquitectura, restricciones y estrategia técnica para ese incremento.
3. **Tasks**: desglosar el trabajo en unidades pequeñas, revisables y ejecutables.
4. **Implement**: desarrollar cada tarea con validación continua y feedback sobre la propia especificación.

Este enfoque resulta especialmente útil en un proyecto público porque hace visible la intención antes del código y convierte la documentación en una pieza operativa del desarrollo.

## Estructura del repositorio

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

## Principios

- Claridad antes que complejidad.
- Datos con fuente verificable antes que amplitud sin trazabilidad.
- MVP pequeño, pero bien estructurado para evolucionar.
- Lógica y UI compartidas entre plataformas cuando aceleren el aprendizaje y reduzcan duplicidad.
- Documentación y especificación como parte del producto, no como anexos.

## Roadmap

### Fase 1

Definición del alcance del MVP, diseño del dominio, estructura inicial del monorepo y primera spec funcional para la consulta de sueldos.

### Fase 2

Construcción del backend en Vapor con un primer conjunto de endpoints y una fuente pública integrada de forma controlada.

### Fase 3

Desarrollo de la app móvil con Kotlin Multiplatform y Compose Multiplatform, incluyendo listado inicial, detalle y conexión con la API.

### Fase 4

Refinamiento de UX, mejora de la calidad del dato, publicación del progreso y apertura a contribuciones o feedback público.

## Visión

Cuánto Cobran busca demostrar que una app cívica puede ser simple en su uso, rigurosa con la trazabilidad del dato y transparente también en su forma de construirse. El MVP no pretende cubrir todo el mapa institucional desde el primer día, sino validar una base técnica y de producto creíble sobre la que crecer.
