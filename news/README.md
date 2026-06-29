# News Bar Widget Plugin

Display scrolling news headlines from various sources directly in your bar using NewsAPI.org.

## Features

- 📰 Real-time news from NewsAPI.org (150,000+ sources)
- 🌍 International support with 14+ languages
- 🗺️ 16 countries/regions supported
- 🔄 Auto-refresh at customizable intervals
- 📜 Smooth scrolling text animation
- ⚙️ Highly configurable settings
- 🎨 Matches your system theme

## Installation

1. Clone or download this plugin to your Noctalia plugins directory
2. Register for a free API key at [newsapi.org](https://newsapi.org/register)
3. Add the plugin to your bar configuration
4. Click the widget and right-click to open settings and enter your API key

## Configuration

### API Key
Get your free API key from [NewsAPI.org](https://newsapi.org/register). The free tier allows 100 requests per day.

### Settings

- **Country/Region**: Select region for news (16 options with auto-language detection)
  - *Note: NewsAPI free tier only supports US for true country-specific top headlines. Other regions use language-based filtering.*
- **Language Override**: Manually override language (14 languages available)
- **Category**: Filter by category (General, Business, Technology, Sports, etc.)
- **Refresh Interval**: How often to fetch new headlines (5-1440 minutes)
- **Max Headlines**: Number of headlines to display (1-100)
- **Widget Width**: Width of the widget in pixels (100-1000)
- **Scroll Speed**: Animation speed in milliseconds per pixel (10-200)

## Usage

- The widget displays scrolling news headlines with smooth animation
- **Left-click** the widget to open the news panel with full headlines
- **Right-click** the widget to open settings
- Click the refresh button in the panel header to manually fetch new headlines
- In vertical bars, shows the number of available headlines

## Limitations

- **Free NewsAPI tier limited to 100 requests/day**
- **Country-specific filtering**: Only US is fully supported on free tier for country-specific "top headlines". Other regions use language-based filtering which provides news in that language but not strictly from that country
- News freshness depends on your refresh interval setting
- Requires internet connection
- For true country-specific filtering beyond US, a paid NewsAPI plan is required

## License

MIT License - See LICENSE file for details

## Credits

Based on the Noctalia Shell news widget, reimplemented as a standalone plugin.
