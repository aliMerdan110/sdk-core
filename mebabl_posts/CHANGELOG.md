# Changelog

## 1.1.0
- Added `MebablPostVisibility` wire values: `Public`, `Followers`, and `Private`.
- Added post visibility to create request serialization and post response parsing.
- Added optional visibility updates to `MebablPostService.updateText`.
- Preserved `Public` as the default when reading older post payloads.
