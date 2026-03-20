# AGENTS.md

## Scope and baseline
- This repo has no existing agent-policy files beyond `README.md` files; use this document as the working guide.
- Start with `README.md`, then `settings.gradle.kts` to understand the composite build wiring.


## Big picture architecture
- Core transformation logic lives in XSLT under `tools/xslt` (see `tools/Developing.md` and `tools/xslt/binding_setup.xsl`).
- The Gradle plugin in `tools/gradletooling/gradle-plugin` is the main production frontend; Python tooling in `tools/pythontooling` is explicitly less complete - do not use it for orchestrating the XSLT transformations.
- Root build (`settings.gradle.kts`) is an umbrella composite including `runtime/java`, `models/ivoa`, and `tools/gradletooling/sample`.
- `runtime/java` provides the shared runtime dependency for generated Java models (`runtime/java/README.md`).
- `tools/gradletooling/sample` is the integration bench: it exercises code generation, schema generation, docs, and test flows across sample models.

## Data flow and component boundaries
- Inputs: `*.vo-dml.xml` model files + `*vodml-binding.xml` mapping files.
- Plugin tasks (`VodmlGradlePlugin`) map inputs to outputs: docs/site/schema/java/python (`vodmlDoc`, `vodmlSite`, `vodmlSchema`, `vodmlJavaGenerate`, `vodmlPythonGenerate`).
- XSLT execution is centralized in `XSLTTransform.kt` (Saxon + XML resolver + optional catalog).
- Cross-model dependency resolution uses JAR manifest metadata (`VODML-source`, `VODML-binding`) set in `VodmlGradlePlugin.kt` and consumed by `ExternalModelHelper` in `VodmlBaseTask.kt`.

## Critical developer workflows (verified)
- Inspect composite builds: `./gradlew -q projects`.
- Plugin tests: `./gradlew :gradle-plugin:test` (passes in this workspace).
- Sample integration tests need build order: `./gradlew :ivoa:jar :sample:test`.
- Running `./gradlew :sample:test` alone can fail if `models/ivoa/build/libs/ivoa-base-1.0-SNAPSHOT.jar` is missing.
- Discover task surface quickly: `./gradlew :sample:tasks --all`.

## Project-specific conventions
- Gradle Kotlin DSL everywhere (`*.gradle.kts`); Java toolchain is pinned to 17 in plugin/runtime builds.
- Plugin defaults matter: VO-DML files default to `src/main/vo-dml`; binding files auto-detect by `*vodml-binding.xml` in project dir if not explicitly set.
- Generated Java and schema outputs are automatically wired into source/resources and JAR packaging by the plugin.
- Task alias `vodmlGenerateJava` is kept as a deprecated compatibility alias; prefer `vodmlJavaGenerate`.
- `tools/gradletooling/sample/build.gradle.kts` is the canonical example of non-default `vodml { ... }` configuration.
- Java code can use Java 17 features; generated code also can use Java 17 features.
- XSLT code is written in XSLT 3.0; Saxon-HE is the processor, so avoid features that require Saxon-PE/EE.
- Python code to use venv defined by the `ru.vyarus.use-python` plugin in the gradle configuration; generated Python code should be compatible with Python 3.10+. The actual venv location will be in the top level repository directory under `venv` (not checked in) and the plugin will ensure it is created and activated for the relevant tasks.
- Python tests should be run with the via gradle tasks that activate the venv and set the PYTHONPATH to include the generated code; see `tools/gradletooling/sample/build.gradle.kts` for examples of how to do this. 


## Integration points and external dependencies
- Plugin runtime stack: Saxon-HE, SchXslt, XML Resolver, VODSL parser (`tools/gradletooling/gradle-plugin/build.gradle.kts`).
- Generated Java models depend on `org.javastro.ivoa.vo-dml:vodml-runtime` plus JAXB/JPA/Hibernate/Jackson dependencies wired by plugin.
- Documentation/site generation can require external tools (`graphviz`, `mkdocs`, `plantuml`, `yq`) per `doc/guide/Installation.md` and `doc/guide/Documentation.md`.

## VODSL and VO-DML specifics
- VODSL is the source format for the model; VO-DML is generated from it
  - VODSL is a more concise DSL for defining the model, while VO-DML is the verbose XML representation that the tooling operates on.
  - the VODSL syntax is described in [docs/guide/VODSL.md](docs/guide/VODSL.md).
- VO-DML is used as input to the XSLT transformations for Java/schema/docs generation.
- Binding files (`*vodml-binding.xml`) are optional but can be used to customize transformation behavior (e.g., package names, schema namespaces); they are automatically detected by the gradle plugin

## When making changes
- For transformation behavior changes, edit XSLT first; only adjust Kotlin task wiring when task orchestration/IO needs change.
- If you change task names, default directories, or dependency injection, update both `doc/guide/*.md` and `tools/gradletooling/sample/build.gradle.kts` examples.
- For new features (e.g., additional output formats), add new tasks in `VodmlGradlePlugin.kt` and corresponding XSLT templates, then update documentation and sample integration.

  