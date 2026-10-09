# Special Builder

A builder for daily specials in the CMS. Drag a special onto a day: under **Every week** it runs that
day each week; on a day of one week it runs that week only, and the site shows today's.

A CMS plugin (`docs/plugins.md` in the CMS): a Rails engine that owns its `special_builder_*`
tables, reaches the specials by id, and extends the core only through `Cms::Plugins`. Needs CMS
1.2 or newer.

## Install

Settings › Plugins › Add a plugin, with `Martin-Business-Consultants/plugin-special-builder`, or
from the shell:

    bin/rails "plugins:install[https://github.com/Martin-Business-Consultants/plugin-special-builder]"

Then switch it on in Settings › Plugins. Switching it on the first time takes each special's own
`day` (and `active`, if it has one) as the every-week lineup, so the site keeps showing what it
did.

## What it does

- **The specials** are the entries of a collection: `specials`, unless Settings › Special Builder
  names another. A special is whatever the collection holds (a title, a description, a price, an
  image); the builder lists them all, drafts marked, with **Add new** for another.
- **Every week**: Monday to Sunday. A special dropped on a day runs it every week.
- **Week by week**: four weeks at a time (Earlier, This week, Later), today marked. A date runs
  every week's lineup for its day (shown faded) until something is dropped on it, taken off it or
  it's cleared: then it's **Changed** and runs its own specials, starting from every week's, so a
  drop adds to the day rather than replacing it. **Reset** puts it back to every week's; **Clear**
  leaves it with no special.
- **Moving**: drag a special from one day to another; × takes it off a day.
- **The site** reads the schedule from the API and is rebuilt when it changes (the
  `specials.scheduled` event, which a webhook can hear too) and each Monday, so the weeks it was
  given move on. Every change is in the audit log.

## The API

`GET /api/special_builder/schedule` (needs `special_builder:read`; the Production site role has
it). `?from=` is any date (the schedule starts on its week's Monday; this week by default) and
`?weeks=` how many (Settings › Special Builder's number, 8 unless changed). A token that can't
write entries — the site's own — gets only published specials.

```json
{"data": {
  "collection": "specials", "time_zone": "America/New_York",
  "from": "2026-10-05", "to": "2026-11-29",
  "every_week": {"monday": [{"id": 3, "slug": "meatloaf-monday", "title": "Meatloaf Monday",
                  "status": "published", "frontmatter": {"price": "$13.99", "description": "…"}}], "tuesday": […], …},
  "days": [{"date": "2026-10-08", "weekday": "Thursday", "customised": false, "specials": […]}, …]
}}
```

A site renders every day it was given and, in the browser, opens today's (in the site's time
zone), as a static site must: the build's "today" is stale by tomorrow.

## Permissions

`special_builder:read` sees the builder and reads the API (Editor, Author, Production site and
Agent start with it); `special_builder:write` builds the schedule (Editor). Settings › Special
Builder takes `settings:read` / `settings:write`.

## Developing

Link it into a CMS checkout and run its specs there:

    ln -s ../../path/to/special_builder plugins/special_builder
    bundle install && bin/rails db:migrate
    bin/rspec plugins/special_builder/spec

`bin/rubocop plugins/special_builder`, `bundle exec herb lint plugins/special_builder/app/views`
and `bin/rspec spec/architecture` should all be clean.

## Releasing

Bump `lib/special_builder/version.rb`, commit, and push a matching `vX.Y.Z` tag: the release
workflow publishes it, and installs see it as an update in Settings › Plugins.
