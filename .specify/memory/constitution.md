<!--
Sync Impact Report
==================
Version change: (template, unversioned) → 1.0.0
Modified principles: n/a (initial ratification — all placeholders replaced)
Added sections:
  - Core Principles (I–V): Code Quality First; Test-Driven Development
    (NON-NEGOTIABLE); User Experience Consistency; Performance Requirements;
    Minimal Dependencies, Custom-First
  - Technology Stack & Constraints
  - Development Workflow & Quality Gates
  - Governance
Removed sections: none (template slots SECTION_2/SECTION_3 concretized)
Templates requiring updates:
  - ✅ .specify/templates/tasks-template.md (tests changed from OPTIONAL to
    MANDATORY to honor Principle II)
  - ✅ .specify/templates/plan-template.md (no change needed — Constitution
    Check gate is populated at plan time from this file)
  - ✅ .specify/templates/spec-template.md (no change needed — Success
    Criteria section already carries measurable UX/performance outcomes)
  - ✅ .specify/templates/checklist-template.md (no change needed)
Follow-up TODOs: none
-->

# Cuánto Cobran Constitution

## Core Principles

### I. Code Quality First

All code merged into the repository MUST be clear, maintainable, and self-explanatory.
Specifically:

- Code MUST follow the idiomatic style of its language: official Kotlin coding
  conventions for the Kotlin Multiplatform app, and Swift API Design Guidelines for the
  Vapor backend.
- Public APIs (shared Kotlin modules, backend endpoints, exported Swift types) MUST be
  documented at the declaration site; internal code is documented only where intent
  cannot be expressed in code.
- Functions and types MUST have a single, well-defined responsibility; cyclomatic
  complexity and file size are review concerns, and reviewers MUST request decomposition
  when a unit cannot be understood in isolation.
- Compiler warnings are treated as errors in CI for both stacks; linting and formatting
  checks MUST pass before merge.
- Dead code, commented-out code, and speculative abstractions (YAGNI violations) MUST be
  removed before merge.

Rationale: a public, transparency-focused project is read by outsiders; the code itself
is part of the published artifact and must hold the same standard as the data it serves.

### II. Test-Driven Development (NON-NEGOTIABLE)

TDD is mandatory for all production code in both the app and the backend:

- Tests MUST be written before the implementation. The Red-Green-Refactor cycle is
  strictly enforced: write a failing test, confirm it fails, implement the minimum to
  pass, then refactor.
- Every functional requirement in a spec MUST be traceable to at least one test; every
  bug fix MUST start with a regression test that reproduces the defect.
- The shared Kotlin domain logic MUST be covered by common-source-set unit tests that run
  on all targets. The Vapor backend MUST have unit tests for domain logic and integration
  tests for every public endpoint (request → response contract).
- Contract tests MUST exist for the API boundary between app and backend so either side
  can evolve against a verified contract.
- CI MUST run the full test suite on every pull request; a red suite blocks merge with no
  exceptions.

Rationale: tests written first are the executable form of the spec — they keep the
Spec-Driven workflow honest from specification through implementation.

### III. User Experience Consistency

The app MUST present one coherent experience across Android and iOS:

- All screens, components, and UI state MUST live in the shared Compose Multiplatform
  layer; platform-specific UI code is permitted only for OS integrations that Compose
  cannot express, and each exception MUST be justified in the plan.
- A single design system (typography, spacing, color, component catalog) MUST be defined
  in shared code and reused; ad-hoc styles inside screens are not allowed.
- Every data point displayed MUST show its source and last-updated date, consistently
  formatted across all screens (traceability is a product feature, not an option).
- Loading, empty, and error states MUST be explicitly designed and implemented for every
  screen that performs I/O; no screen may render an indefinite or blank state.
- User-facing text MUST be centralized in shared resources to keep terminology consistent
  and ready for localization.

Rationale: the product's credibility rests on clarity and verifiability; an
inconsistent interface undermines trust in the data it displays.

### IV. Performance Requirements

Performance is a feature with measurable budgets, validated before release:

- Backend read endpoints (listings, search, detail) MUST respond in under 200 ms at p95
  under expected MVP load; data ingestion/normalization jobs MUST NOT degrade query
  latency beyond that budget.
- The app MUST render scrolling lists at a sustained 60 fps on mid-range reference
  devices and reach an interactive first screen in under 2 seconds on a warm start.
- Search-as-you-type interactions MUST show results in under 500 ms perceived latency,
  using local caching where the data set allows.
- Payload sizes MUST be kept minimal: list endpoints return only fields the list UI
  renders; detail data is fetched on demand.
- Every spec MUST state its performance criteria in Success Criteria, and plans MUST
  identify how each budget will be measured (test, profiler, or load script) before
  implementation begins.

Rationale: the MVP's promise is consulting public salaries "without friction"; latency
and jank are friction.

### V. Minimal Dependencies, Custom-First

Third-party dependencies are a liability to be justified, not a default:

- Custom implementations MUST be preferred over external libraries whenever the
  functionality can be built and tested with reasonable effort within the project.
- Platform and first-party frameworks (Kotlin stdlib, kotlinx libraries, Compose
  Multiplatform, Swift standard library, Vapor and its SwiftNIO foundation) are not
  considered third-party for this purpose.
- Any proposed third-party dependency MUST be recorded in the feature plan's Complexity
  Tracking with: the problem it solves, why a custom implementation is unreasonable, and
  its maintenance/license risk. Unjustified dependencies MUST be rejected in review.
- Dependencies MUST be wrapped behind project-owned interfaces so they can be replaced
  without touching domain code.

Rationale: a small, auditable dependency surface keeps the open-source project
trustworthy, buildable long-term, and free of supply-chain surprises.

## Technology Stack & Constraints

The project consists of two distinct parts, and all plans MUST respect this split:

- **Mobile app**: Kotlin Multiplatform targeting Android and iOS, with UI built in
  Jetpack Compose Multiplatform. Domain logic, use cases, networking, screen state, and
  UI components live in shared source sets; per-platform code is limited to entry points
  and native integrations.
- **Backend**: Swift with Vapor, responsible for ingestion of public sources,
  normalization and validation, and the query API. Swift strict concurrency MUST be
  enabled (complete concurrency checking); all shared mutable state MUST be protected via
  actors or `Sendable`-conforming types, and concurrency warnings are build errors.
- **API boundary**: the app communicates with the backend only through the versioned
  public API; no shared database access or other side channels.
- Repository layout follows the structure documented in `README.md` (`app/` for the KMP
  client, `backend/` for the Vapor server, `specs/` for Spec Kit artifacts).

## Development Workflow & Quality Gates

All work follows the Spec-Driven Development cycle: Spec → Plan → Tasks → Implement.

- No implementation work begins without an approved spec and plan for the increment;
  plans MUST pass the Constitution Check gate against this document before Phase 0
  research and again after design.
- Task lists MUST order test tasks before their corresponding implementation tasks
  within every user story (Principle II).
- Every pull request MUST: pass CI (build, lint, full test suite, strict concurrency
  checks), keep performance budgets intact, and link to the spec/tasks it implements.
- Development is public: decisions with lasting impact MUST be captured in the repo
  (specs, plans, or `docs/decisions/`) so intent is traceable from specification to code.
- Violations of any principle discovered during planning or review MUST be either fixed
  or explicitly justified in the plan's Complexity Tracking table before work proceeds.

## Governance

This constitution supersedes all other development practices in this repository. Where
guidance conflicts, the constitution wins.

- **Amendments**: changes are proposed via pull request that updates this file, states
  the rationale, and includes a migration note for any in-flight specs or plans affected.
  The amendment merges only after the Sync Impact Report is updated and dependent
  templates are reconciled.
- **Versioning**: the constitution follows semantic versioning. MAJOR for removals or
  incompatible redefinitions of principles, MINOR for new principles or materially
  expanded guidance, PATCH for clarifications and wording fixes.
- **Compliance review**: every plan MUST re-run the Constitution Check gate; every code
  review MUST verify the principles touched by the change (tests-first evidence, UX
  consistency, performance budgets, dependency justification). Recurring violations are
  grounds for amending either the practice or the constitution — never for silently
  ignoring it.

**Version**: 1.0.0 | **Ratified**: 2026-06-10 | **Last Amended**: 2026-06-10
