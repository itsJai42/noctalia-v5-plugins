# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-02-20

### Changed
- **BREAKING**: Switched from `/top-headlines` to `/everything` endpoint for better international support
- Country selection now uses language-based filtering (works with free tier)
- Added 16 country/region options with automatic language detection
- Added manual language override setting (14 languages)
- Expanded country list: added Spain, Mexico, Brazil, Netherlands, Sweden, Norway
- Improved category filtering using keyword-based search

### Added
- Language parameter support for better international news
- Country-to-language mapping for automatic language detection
- Search query optimization based on selected category
- Clear documentation about NewsAPI free tier limitations

### Fixed
- International news now works properly on free tier (was limited to US only)
- Better news relevance for non-US countries

### Note
- NewsAPI free tier only supports US for true country-specific top headlines
- Other regions use language-based filtering which provides news in that language
- For true country-specific filtering, a paid NewsAPI plan is required

## [1.1.9] - 2026-02-20

### Fixed
- Fixed Component.onCompleted syntax error (missing colon)

## [1.1.8] - 2026-02-20

### Changed
- Moved refresh button from bar widget to panel header for better UX
- Added refresh signal in Main singleton for communication between components
- Refresh button now appears next to close button in panel

### Removed
- Removed non-functional refresh button from bar widget

## [1.1.7] - 2026-02-20

### Fixed
- Updated README usage instructions to reflect correct click behavior
- Updated CHANGELOG with missing version entries

## [1.1.6] - 2026-02-20

### Fixed
- Fixed refresh button not being clickable due to overlapping MouseAreas
- Moved main MouseArea inside Rectangle for proper event handling
- Added z-index to refresh button to ensure it's above other elements

## [1.1.5] - 2026-02-20

### Fixed
- Fixed Main singleton access via pluginApi.mainInstance instead of direct import
- Added null safety checks for main and main.newsData throughout
- Fixed panel close button to use pluginApi.closePanel() instead of PanelService

## [1.1.4] - 2026-02-20

### Fixed
- Fixed panel not displaying news by moving shared state to Main singleton
- BarWidget now stores data in Main instead of local properties
- Panel reads data from Main singleton for proper synchronization
- Removed defunct syncToPanel() mechanism

## [1.1.3] - 2026-02-15

### Fixed
- Fixed emoji icons rendering as rectangles by adding font family (Noto Color Emoji)
- Fixed panel not showing news data by syncing after panel opens
- Added Qt.callLater to ensure panel instance exists before syncing

## [1.1.2] - 2026-02-15

### Fixed
- Fixed panel not opening on left-click (use pluginApi.openPanel instead of PanelService)
- Replaced NIcon with emojis in Panel.qml for better compatibility
- Added data syncing between BarWidget and Panel
- Removed icon from "Open Article" button (not needed)

## [1.1.1] - 2026-02-15

### Fixed
- Fixed API key not being loaded on startup
- Added onApiKeyChanged handler to fetch news when settings load
- Only start refresh timer when API key is configured
- Use ?? operator instead of || for proper null/undefined handling

## [1.1.0] - 2026-02-15

### Added
- News panel that displays full headlines with descriptions
- Click bar widget to open detailed news panel
- Right-click bar widget to open settings
- Panel shows article source, publish time, and "Open Article" buttons
- Beautiful scrollable list with numbered badges
- Loading, empty, and error states in panel

### Changed
- Changed click behavior: left-click opens panel, right-click opens settings
- Updated tooltip to reflect new interaction

## [1.0.2] - 2026-02-15

### Fixed
- Replaced NIcon with emoji for news icon (📰) to match original implementation
- Replaced NIcon refresh button with emoji (🔄) for better compatibility
- Ensures icons display correctly regardless of icon theme

## [1.0.1] - 2026-02-15

### Fixed
- Fixed Settings.qml component errors (replaced NTextField with NTextInput)
- Replicated original NewsSettings pattern from noctalia-shell for better compatibility
- Fixed NComboBox usage with proper currentKey and onSelected handlers
- Removed unnecessary imports and simplified structure
- Fixed syntax error in Settings.qml

## [1.0.0] - 2026-02-15

### Added
- Initial release of the News Bar widget plugin
- Support for NewsAPI.org integration
- Multiple country and category options
- Configurable refresh intervals
- Smooth scrolling text animation
- Auto-refresh functionality
- Manual refresh button
- Comprehensive settings panel
- Support for horizontal and vertical bars
- Tooltips and hover effects
