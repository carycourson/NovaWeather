# **NovaWeather**

**NovaWeather** is a sleek, transparent, and information-dense weather widget (Plasmoid) for the KDE Plasma 6 desktop.

Designed for users who want "at-a-glance" deep data, it features a custom vertically-stacked forecast layout, real-time pressure trends, moon phases, and "vibrant" weather icon mapping to ensure your desktop looks alive regardless of the forecast.

## 🌟 Features

* Deep Data Dashboard: Displays Current Temp, Feels Like, Wind Speed/Direction, Humidity, UV Index, and Pressure.

* Live Trends:

  * Pressure: Indicates rising (▲) or falling (▼) pressure based on 3-hour forecast trends.

  * Wind: Shows precise wind direction and speed using dynamic arrows.

* Astro Data: Sunrise and Sunset times with a real-time graphical Moon Phase indicator.

* Smart Layout:

  * Stacked Forecast: Vertical stacking of Wind and Rain data to maximize readability in a narrow form factor.

  * Vibrant Icons: Custom mapping logic that prioritizes Sun/Moon visibility even during rain/cloud events for a colorful UI.

* Click-to-Refresh: Instant update by clicking the location header.

* Custom Design: Semi-transparent dark background (0.70 opacity) that blends perfectly with modern dark themes.

## 🛠️ Prerequisites

* KDE Plasma 6 (Recommended) or Plasma 5 (Requires modifying installation commands to use kpackagetool5).

* QtQuick 2.15+

* OpenWeatherMap API Key (Free tier is sufficient).

## 📦 Installation

**Option 1: Manual Install (Development)**

1. Clone or download this repository.

2. Open a terminal inside the parent directory (one level up from NovaWeather).

3. Run the standard KPackage tool:

```
# For Plasma 6
kpackagetool6 --type Plasma/Applet --install NovaWeather

# For Plasma 5
kpackagetool5 --type Plasma/Applet --install NovaWeather
```

**Option 2: Updating**

If you have modified the code and need to push changes to your desktop:

```
kpackagetool6 --type Plasma/Applet --upgrade NovaWeather
```

**Troubleshooting: "Ghost Package"**

If you receive an error stating the package exists but cannot be upgraded:

```
# Manually remove the existing folder
rm -rf ~/.local/share/plasma/plasmoids/com.scott.novaweather

# Reinstall
kpackagetool6 --type Plasma/Applet --install NovaWeather
```

## ⚙️ Configuration

**Important:** This widget uses hardcoded values for the Location and API Key. You must configure these manually for the widget to function.

1. Open contents/ui/main.qml in your text editor.

2. Locate the Configuration block near the top (approx. lines 20-30):

```
    readonly property string apiKey: "YOUR_OPENWEATHER_API_KEY_HERE"
    readonly property string lat: "31.063635"   // Your Latitude
    readonly property string lon: "-97.897753"  // Your Longitude
```

3. Replace the values with your own.

4. Save the file and reinstall/reload the widget.

## 📂 File Structure
```
NovaWeather/
├── metadata.json           # KDE Plugin Registration info
├── README.md               # This file
└── contents/
    └── ui/
        ├── main.qml        # Core logic and UI layout
        └── Icons/          # Weather and Moon Phase PNGs
            ├── 01d.png
            ├── moon-full.png
            ├── wind-arrow.png
            └── ...
```

## 🎨 Icon Credits

**Weather Icons:** Based on the "VClouds" standard mapping style.

**Moon Phases:** Uses standard semi-realistic moon phase imagery.

## 📄 License

This project is licensed under the **GPL-2.0+** License. Feel free to fork, modify, and share!
