import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmoidItem {
    id: root
    readonly property string apiKey: "YourApiKeyHere"
    readonly property string lat: "31.063635"
    readonly property string lon: "-97.897753"
    readonly property int updateInterval: 10 // in minutes

    // --- CONFIGURATION ---
    Plasmoid.backgroundHints: "NoBackground"
    preferredRepresentation: fullRepresentation

    // --- STATE ---
    property string currentTemp: "--"
    property string feelsLike: "--"
    property string cityName: "Loading..."
    property string countryCode: ""
    property string conditionText: "..."
    property string iconPath: ""

    property string windString: "--"
    property int windDeg: 0

    property string humidity: "--"
    property string uvIndex: "--"
    property string pressure: "--"
    property string pressTrendChar: ""
    property string pressTrendColor: "white"

    property string sunriseTime: "--:--"
    property string sunsetTime: "--:--"
    property string moonIconPath: ""

    property string currentTime: "--:--"
    property string tzAbbrev: ""
    property int timezoneOffset: 0

    ListModel { id: forecastModel }

    // --- LOGIC ---
    function fetchWeather() {
        var xhr = new XMLHttpRequest();
        var url = "https://api.openweathermap.org/data/3.0/onecall?lat=" + lat + "&lon=" + lon + "&appid=" + apiKey + "&units=imperial&exclude=minutely,alerts";
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var json = JSON.parse(xhr.responseText);
                
                // --- TIMEZONE ---
                root.timezoneOffset = json.timezone_offset;
                root.tzAbbrev = getTimezoneAbbrev(json.timezone, json.timezone_offset);
                root.currentTime = formatTimeWithOffset(Math.floor(Date.now() / 1000), json.timezone_offset);
                
                // --- CURRENT ---
                root.currentTemp = Math.floor(json.current.temp) + "°";
                root.feelsLike = Math.floor(json.current.feels_like) + "°";
                root.conditionText = json.current.weather[0].main;
                root.iconPath = getIconPath(json.current.weather[0].icon);
                
                root.windDeg = json.current.wind_deg || 0;
                var wDir = getWindDir(root.windDeg);
                var wSpd = Math.floor(json.current.wind_speed);
                root.windString = wDir + " " + wSpd + " mph";

                var pNow = json.current.pressure;
                var pFuture = (json.hourly && json.hourly[2]) ? json.hourly[2].pressure : pNow;
                var pDiff = pFuture - pNow;
                
                root.pressure = (pNow * 0.02953).toFixed(2) + " in";
                root.pressTrendChar = (pDiff >= 0) ? "▲" : "▼";
                root.pressTrendColor = (pDiff >= 0) ? "#FF9F00" : "#34C9F6";

                root.humidity = json.current.humidity + " %";
                root.uvIndex = Math.floor(json.current.uvi) + " / 11";
                
                // Use timezone-aware time formatting for sunrise/sunset
                root.sunriseTime = formatTimeWithOffset(json.current.sunrise, json.timezone_offset);
                root.sunsetTime = formatTimeWithOffset(json.current.sunset, json.timezone_offset);

                // Moon Phase Logic
                if (json.daily && json.daily[0]) {
                    root.moonIconPath = getMoonIcon(json.daily[0].moon_phase);
                }

                // --- FORECAST ---
                forecastModel.clear();
                for (var i = 0; i < 8; i++) {
                    var day = json.daily[i];
                    forecastModel.append({
                        "dayName": i === 0 ? "Today" : formatDay(day.dt),
                        "high": Math.floor(day.temp.max) + "°",
                        "low": Math.floor(day.temp.min) + "°",
                        "highColor": getTempColor(day.temp.max),
                        "lowColor": getTempColor(day.temp.min),
                        "pop": Math.round(day.pop * 100) + "%",
                        "condition": day.weather[0].main,
                        "icon": getIconPath(day.weather[0].icon),
                        "windSpd": Math.round(day.wind_speed),
                        "windRot": (day.wind_deg || 0) + 180
                    });
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }
    // --- HELPERS ---
    function fetchLocation() {
        var xhr = new XMLHttpRequest();
        var url = "https://api.openweathermap.org/geo/1.0/reverse?lat=" + lat + "&lon=" + lon + "&limit=1&appid=" + apiKey;
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var json = JSON.parse(xhr.responseText);
                if (json.length > 0) {
                    root.cityName = json[0].name;
                    root.countryCode = json[0].country;
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    function getTimezoneAbbrev(timezoneStr, offsetSeconds) {
        // Map of common timezone strings to their abbreviations
        var tzMap = {
            "America/New_York": { standard: "EST", daylight: "EDT", stdOffset: -18000 },
            "America/Chicago": { standard: "CST", daylight: "CDT", stdOffset: -21600 },
            "America/Denver": { standard: "MST", daylight: "MDT", stdOffset: -25200 },
            "America/Phoenix": { standard: "MST", daylight: "MST", stdOffset: -25200 },
            "America/Los_Angeles": { standard: "PST", daylight: "PDT", stdOffset: -28800 },
            "America/Anchorage": { standard: "AKST", daylight: "AKDT", stdOffset: -32400 },
            "Pacific/Honolulu": { standard: "HST", daylight: "HST", stdOffset: -36000 },
        };
        
        if (tzMap[timezoneStr]) {
            var tz = tzMap[timezoneStr];
            // If current offset differs from standard offset, we're in daylight time
            var isDaylight = (offsetSeconds !== tz.stdOffset);
            return isDaylight ? tz.daylight : tz.standard;
        }
        
        // Fallback: generate UTC offset string
        var hours = Math.floor(Math.abs(offsetSeconds) / 3600);
        var sign = offsetSeconds >= 0 ? "+" : "-";
        return "UTC" + sign + hours;
    }

    function formatTimeWithOffset(unix, offsetSeconds) {
        // Create date adjusted for timezone offset
        var utcMs = unix * 1000;
        var localMs = utcMs + (offsetSeconds * 1000);
        var d = new Date(localMs);
        
        // Use UTC methods since we've already applied the offset
        var h = d.getUTCHours();
        var m = d.getUTCMinutes();
        var ampm = h >= 12 ? 'pm' : 'am';
        h = h % 12;
        h = h ? h : 12;
        m = m < 10 ? '0' + m : m;
        return h + ':' + m + ' ' + ampm;
    }

    function getMoonIcon(val) {
        // Use a small buffer (0.02) for the exact phases
        if (val <= 0.02 || val >= 0.98) return "Icons/moon-new.png";
        if (val > 0.02 && val < 0.23)   return "Icons/moon-waxing-crescent.png";
        if (val >= 0.23 && val <= 0.27) return "Icons/moon-first-quarter.png";
        if (val > 0.27 && val < 0.48)   return "Icons/moon-waxing-gibbous.png";
        if (val >= 0.48 && val <= 0.52) return "Icons/moon-full.png";
        if (val > 0.52 && val < 0.73)   return "Icons/moon-waning-gibbous.png";
        if (val >= 0.73 && val <= 0.77) return "Icons/moon-last-quarter.png";
        if (val > 0.77 && val < 0.98)   return "Icons/moon-waning-crescent.png";
        
        return "Icons/moon-full.png"; // Fallback
    }

    function getWindDir(deg) {
        var dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW","N"];
        return dirs[Math.floor((deg / 22.5) + 0.5) % 16];
    }

    function getTempColor(t) {
        if (t < 32) return "#0FFFEF";
        if (t < 50) return "#3FFFBF";
        if (t < 68) return "#CFFF2F";
        if (t < 86) return "#FFCF00";
        return "#FF0E00";
    }

    function getIconPath(code) {
        var map = {
            "01d": "32", "01n": "31", "02d": "34", "02n": "33", "03d": "30", "03n": "29", 
            "04d": "28", "04n": "27", "09d": "12", "09n": "12", "10d": "39", "10n": "45", 
            "11d": "4",  "11n": "4",  "13d": "16", "13n": "16", "50d": "20", "50n": "20" 
        };
        return "Icons/" + (map[code] || "na") + ".png";
    }

    function formatTime(unix) {
        var d = new Date(unix * 1000);
        var h = d.getHours(); var m = d.getMinutes();
        var ampm = h >= 12 ? 'pm' : 'am';
        h = h % 12; h = h ? h : 12; 
        m = m < 10 ? '0'+m : m;
        return h + ':' + m + ' ' + ampm;
    }

    function formatDay(unix) {
        var d = new Date(unix * 1000);
        var days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
        var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return days[d.getDay()] + " " + months[d.getMonth()] + " " + d.getDate();
    }

    Component.onCompleted: {
        fetchLocation();
        fetchWeather();
    }    
    Timer { interval: updateInterval * 60 * 1000; running: true; repeat: true; onTriggered: fetchWeather() }

    // --- UI ---
    
    compactRepresentation: PlasmaComponents.Label {
        text: root.currentTemp
        font.pixelSize: 24
        Layout.minimumWidth: 50
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 240
        Layout.preferredHeight: bg.height

        Rectangle {
            id: bg
            width: parent.width
            height: content.height + 30
            color: "#000000"
            opacity: 0.70
            radius: 5

            Column {
                id: content
                width: parent.width
                spacing: 0
                y: 15
                anchors.horizontalCenter: parent.horizontalCenter

                // --- HEADER ---
                ColumnLayout {
                    width: 220
                    spacing: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: locationCol.implicitHeight
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.cityName = "Refreshing..."
                            fetchWeather()
                            fetchLocation()
                        }

                        ColumnLayout {
                            id: locationCol
                            spacing: 0
                            width: parent.width
                            
                            PlasmaComponents.Label { 
                                text: root.cityName + (root.countryCode ? " " + root.countryCode : "")
                                color: "white"; font.pixelSize: 14; font.family: "DejaVu Sans"
                                Layout.fillWidth: true; wrapMode: Text.NoWrap; elide: Text.ElideRight
                            }
                            PlasmaComponents.Label { 
                                text: root.currentTime + " " + root.tzAbbrev
                                color: "#AAAAAA"; font.pixelSize: 12; font.family: "DejaVu Sans"
                            }
                        }
                    }

                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: mouseAreaContent.implicitHeight
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Toggle between daily and hourly views (not implemented yet)
                            root.cityName = "Refreshing..."
                            fetchWeather()
                            fetchLocation()
                        }

                        ColumnLayout {
                            id: mouseAreaContent
                            anchors.fill: parent
                            spacing: 0

                            RowLayout {
                                spacing: 5
                                PlasmaComponents.Label {
                                    text: root.currentTemp
                                    color: getTempColor(parseInt(root.currentTemp))
                                    font.pixelSize: 52
                                    font.family: "DejaVu Sans"
                                }
                                Item { Layout.fillWidth: true }
                                Image {
                                    source: root.iconPath
                                    sourceSize.width: 58
                                    sourceSize.height: 58
                                }
                            }
                            
                            PlasmaComponents.Label {
                                text: root.conditionText
                                color: "white"
                                font.pixelSize: 15
                                Layout.alignment: Qt.AlignRight
                                font.family: "DejaVu Sans"
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.topMargin: 12
                        Repeater {
                            model: [
                                {l: "Feels Like:", v: root.feelsLike, c: "#58CCED"},
                                {l: "Wind:", v: root.windString, c: "white", icon: "Icons/wind-arrow.png", rot: root.windDeg + 180},
                                {l: "Pressure:", v: root.pressure, c: "white", trend: root.pressTrendChar, trendC: root.pressTrendColor},
                                {l: "Humidity:", v: root.humidity, c: "white"},
                                {l: "UV Index:", v: root.uvIndex, c: root.uvIndex.startsWith("0") ? "green" : "orange"}
                            ]
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                PlasmaComponents.Label { text: modelData.l; color: "#AAAAAA"; font.pixelSize: 12; font.family: "DejaVu Sans" }
                                Item { Layout.fillWidth: true }
                                
                                Image {
                                    visible: modelData.icon !== undefined
                                    source: modelData.icon || ""
                                    sourceSize.width: 12; sourceSize.height: 12
                                    rotation: modelData.rot || 0
                                    transformOrigin: Item.Center
                                }
                                PlasmaComponents.Label {
                                    visible: modelData.trend !== undefined
                                    text: modelData.trend || ""
                                    color: modelData.trendC || "white"
                                    font.pixelSize: 12
                                    font.family: "DejaVu Sans"
                                }

                                PlasmaComponents.Label { text: modelData.v; color: modelData.c; font.pixelSize: 12; font.family: "DejaVu Sans" }
                            }
                        }
                    }
                    
                    // --- ASTRO ROW ---
                    RowLayout {
                        Layout.topMargin: 18
                        Layout.bottomMargin: 18
                        Layout.fillWidth: true
                        
                        RowLayout {
                            spacing: 5
                            Image { source: "Icons/Sunrise.png"; sourceSize.width: 18; sourceSize.height: 18 }
                            PlasmaComponents.Label { text: root.sunriseTime; color: "#FF9F00"; font.pixelSize: 12; font.family: "DejaVu Sans" }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Image {
                            source: root.moonIconPath
                            sourceSize.width: 32  // 32px as requested
                            sourceSize.height: 32
                        }
                        
                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 5
                            Image { source: "Icons/Sunset.png"; sourceSize.width: 18; sourceSize.height: 18 }
                            PlasmaComponents.Label { text: root.sunsetTime; color: "#FF9F00"; font.pixelSize: 12; font.family: "DejaVu Sans" }
                        }
                    }
                }

                // --- FORECAST ---
                ColumnLayout {
                    width: 220
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Repeater {
                        model: forecastModel
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            // 1. DATE & TEMP
                            ColumnLayout {
                                spacing: 0
                                Layout.preferredWidth: 95
                                PlasmaComponents.Label { 
                                    text: model.dayName; color: "white"; font.pixelSize: 13; font.family: "DejaVu Sans"
                                }
                                RowLayout {
                                    spacing: 4
                                    PlasmaComponents.Label { text: model.high; color: model.highColor; font.bold: true; font.pixelSize: 13; font.family: "DejaVu Sans" }
                                    PlasmaComponents.Label { text: "/ " + model.low; color: model.lowColor; font.pixelSize: 13; font.family: "DejaVu Sans" }
                                }
                                PlasmaComponents.Label { 
                                    text: model.condition; color: "#888888"; font.pixelSize: 12; font.family: "DejaVu Sans" 
                                }
                            }

                            // 2. WIND (Top) / RAIN (Bottom)
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4
                                
                                RowLayout {
                                    spacing: 4
                                    Image { 
                                        source: "Icons/wind-arrow.png"; 
                                        sourceSize.width: 12; sourceSize.height: 12
                                        rotation: model.windRot
                                        transformOrigin: Item.Center
                                    }
                                    PlasmaComponents.Label { 
                                        text: model.windSpd + " mph"; color: "white"; font.pixelSize: 11; font.family: "DejaVu Sans"
                                    }
                                }

                                RowLayout {
                                    spacing: 4
                                    Image { source: "Icons/Drop.png"; sourceSize.width: 12; sourceSize.height: 12 }
                                    PlasmaComponents.Label { 
                                        text: model.pop; color: "#58CCED"; font.pixelSize: 11; font.family: "DejaVu Sans"
                                    }
                                }
                            }

                            // 3. SPACER
                            Item { Layout.fillWidth: true }

                            // 4. ICON
                            Image {
                                source: model.icon
                                sourceSize.width: 50; sourceSize.height: 50
                                Layout.preferredWidth: 50; Layout.preferredHeight: 50
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
