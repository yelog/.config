# JDTLS Workspace Compatibility Design

## Goal

Make Spring service debugging survive jdtls and Java Debug upgrades, and launch only the service selected in Overseer.

## Root Cause

The jdtls workspace key currently depends only on the project path. After Mason updated jdtls, the existing Equinox extension registry continued to reference an older plugin set and did not register `org.eclipse.m2e.launchconfig.classpathProvider`, although the current `org.eclipse.m2e.jdt` jar contains that provider. A fresh workspace resolves the same moss-cloud classpath successfully.

The current launch flow also calls `fetch_main_configs()`, which resolves every class containing `main()`. Utility classes such as `ExcelUtil` can fail and prevent the selected `MossAuthApplication` from being returned.

## Design

Include a toolchain fingerprint in the jdtls workspace directory. The fingerprint is computed from the active jdtls m2e plugin and Java Debug bundle filenames, so upgrades automatically create a clean workspace without destructively deleting old caches.

Build one DAP launch configuration from the selected Overseer service metadata (`mainClass`, `projectName`, and `cwd`). nvim-jdtls enriches that configuration with the Java executable and classpath, avoiding full-workspace main-class discovery.

Load only the application debug bundle for now. The installed Java Test bundle requires ASM `[9.9,9.10)`, while the current jdtls ships ASM `9.10.1`; excluding test bundles removes the OSGi resolution errors until compatible versions are available.

## Verification

Test deterministic workspace fingerprints, debug-only bundle filtering, and exact launch configuration construction. Start moss-cloud with the new formal workspace and verify Java Debug can enrich `MossAuthApplication` without resolving unrelated utility main classes.
