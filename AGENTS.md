# Special Builder, a CMS plugin — guide for AI agents

This repository is a plugin for the CMS (a Rails engine loaded into a CMS install). It is not an
app on its own: run it from a CMS checkout with the plugin in `plugins/special_builder`.

Read first, in the CMS's repository: `docs/plugins.md` (every extension point) and `STYLE.md`.

## Rules

- Own your tables, prefixed `special_builder_`, pointing at core records by id (`entry_id`: a
  `CollectionEntry`). Never add columns to core tables or write core rows.
- Register everything in the engine's `config.to_prepare`. Controllers `include PluginGated` and
  say `plugin :special_builder`; every action declares `requires_capability`.
- Views use Litewind classes and the core's `ui(...)` recipes, strict locals on partials and
  `<%# herb:key %>` before each loop row; the stylesheet holds only what classes can't say.
  `bin/rspec spec/architecture` checks every class exists.
- Use only gems the CMS bundles: plugins load outside Bundler.

## This plugin

- `SpecialBuilder::Slot` is where a special goes: a weekday of every week (1–7, `Date#cwday`) or
  a date. `Placement` holds the verbs `place`, `remove`, `move` and `import_weekly_lineup`;
  `Day.customise`, `.clear`, `.reset` make a date different, empty, or every week's again.
- `Schedule` reads a run of weeks in three queries (the API and the board); only the collection's
  specials count, and `published_only` for the site's token.
- The page (`boards/show`) holds the list (`boards/_library`, a Turbo Frame its search box fills
  through `CollectionEntry.search_list`, ActiveSearch) and the weeks (`boards/_board`), which a
  Turbo Stream morph replaces after each change, leaving the list and its search alone. The
  Stimulus controller around both (`special-builder--board`) posts a drop to placements with
  `entry_id`, the slot and, for a move, `from[...]`, and submits the search as it's typed.
- Every week's lineup (weekly placements) has no screen of its own: it's each special's `day`,
  imported on first switching on, and fills the days nobody has changed.
- Each change is `Event.record`ed and announces `specials.scheduled` (a deploy event: the site
  rebuilds); the nightly task announces it on Mondays.
