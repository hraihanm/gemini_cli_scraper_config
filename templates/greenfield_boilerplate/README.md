# Greenfield boilerplate (prompt-driven)

Generic DataHen v3 layout for **non-retail** sources: registries, directories, search portals, etc. Parsers start as placeholders; `/greenfield-scrape` (or `/scrape` … `project=greenfield`) fills selectors and output shape from **your message** (no default spec file). Optional `spec=` on the slash line if you use a file.

- Retail / grocery scrapers: use `profiles/dmart-dloc.toml` or `profiles/dhero.toml` instead.
- After Phase 3, align `config.yaml` exporter `fields` with the final output hash keys from `field-spec.json`.
