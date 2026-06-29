# Zen Note

Cozy, theme-aware Noctalia v5 desktop note backed by the [ZenQuotes API](https://zenquotes.io/).

## Features

- Rotates quotes on a configurable 15-minute to 24-hour schedule.
- Fetches a batch and cycles locally, limiting API traffic to at most one background refresh per hour.
- Lets the refresh button move to the next cached quote without another API call.
- Keeps the last quote cache at `$XDG_STATE_HOME/noctalia/zen-note.json` for offline use.
- Uses Noctalia theme roles and per-widget size/font settings.
- Includes the attribution link required by ZenQuotes' free API.

## Enable

```bash
noctalia msg plugins update local-v5
noctalia msg plugins enable noctalia/zen-note
noctalia msg desktop-widgets-edit
```

Add **Zen Note** from the desktop widget editor. Change schedule under **Settings → Plugins → Zen Note**; change card size and quote font in the widget's settings.

ZenQuotes' free API is rate-limited. Zen Note caches the batch, keeps the last good quote on failures, and only refreshes the API cache hourly.
