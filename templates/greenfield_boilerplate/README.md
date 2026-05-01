# Greenfield boilerplate (prompt-driven)

Generic DataHen v3 layout for **non-retail** sources: registries, directories, search portals, etc. Parsers start as placeholders; `/scrape` … `project=greenfield` and the phase workflows replace selectors and output shape from **your prompt** (or `spec=` CSV).

- Retail / grocery scrapers: use `profiles/dmart-dloc.toml` or `profiles/dhero.toml` instead.
- After Phase 3, align `config.yaml` exporter `fields` with the final output hash keys from `field-spec.json`.
