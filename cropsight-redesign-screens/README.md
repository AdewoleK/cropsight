# CropSight screens

Captured from the real app on an iPhone 16 Pro simulator (iOS 26.2) by
`tool/capture_screenshots.sh`. Rerun that script to regenerate them after a UI
change.

Fields, reminders and the past field checks are demo data, seeded for the
capture. Every match, guide entry and screen shown is real app output. Leaf
photos come from Wikimedia Commons (credits in `tool/screenshot_photos/`).

## Photo diagnosis
| File | Screen |
|---|---|
| `01-setup.png` | First launch: one-time offline setup |
| `02-diagnose-home.png` | Diagnose: aim at one leaf |
| `03-photo-check-warning.png` | Photo check: warns that the photo is blurry before diagnosing |
| `04-photo-ready.png` | Photo confirmed, ready to diagnose |
| `05-diagnosing.png` | Look → Match → Write progress |

**Not included yet: photo-diagnosis result screens.** The photo model's image
step doesn't run on iOS with the current MediaPipe engine, so there's no real
result to capture here. Capture these on an Android phone (6GB+ RAM). Don't
use mock-ups.

## Lite mode (low-memory phones, no photo model)
| File | Screen |
|---|---|
| `23-lite-setup.png` | Lite setup: photo AI skipped on this phone |
| `24-lite-home.png` | "What do you see?": pick the crop |
| `25-lite-describe.png` | Tap where on the plant and what it looks like |
| `26-lite-matches.png` | Possible matches from the 116-entry field guide |
| `27-lite-chosen.png` | Chosen match: what to do, plus safety |
| `28-lite-actions.png` | Listen · Save · Remind · Share |
| `29-save-to-field.png` | Save the check to a field |

## Fields, reminders, log
| File | Screen |
|---|---|
| `12-fields.png` | Fields: to-dos and tracked plots |
| `13-field-detail.png` | One field's to-dos and checks |
| `14-set-reminder.png` | Set an offline reminder |
| `15-field-history.png` | Field after a new reminder |
| `20-log.png` | Field log with sync status |

## Library and settings
| File | Screen |
|---|---|
| `16-library.png` | Browsable field guide, searchable and filterable |
| `17-library-pests.png` | Filtered to pests |
| `18-card-detail.png` | Full guide entry: what you see, what to do |
| `19-card-detail-safety.png` | Safety notes for any spray |
| `21-settings.png` | Theme, diagnosis mode (shows the phone's memory) |
| `22-settings-languages.png` | 10 answer languages, voice test, privacy |

## Dark mode
`31-dark-diagnose-home.png`, `32-dark-fields.png`, `33-dark-library.png`,
`34-dark-field-detail.png`
