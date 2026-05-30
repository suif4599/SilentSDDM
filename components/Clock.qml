import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: clockContainer
    signal loginRequested

    // Size based on content
    width: clockContent.implicitWidth + 96
    height: clockContent.implicitHeight + 72

    // Glass background container
    // Rectangle {
    //     id: backgroundRect
    //     anchors.fill: parent
    //     radius: 20
    //     color: Qt.rgba(0.15, 0.15, 0.15, 0.6)
    //     border.width: 0

    //     gradient: Gradient {
    //         orientation: Gradient.Horizontal
    //         GradientStop { position: 0.0; color: Qt.rgba(0.25, 0.25, 0.25, 0) }
    //         GradientStop { position: 0.15; color: Qt.rgba(0.25, 0.25, 0.25, 0) }
    //         GradientStop { position: 0.25; color: Qt.rgba(0.25, 0.25, 0.25, 0.4) }
    //         GradientStop { position: 0.5; color: Qt.rgba(0.25, 0.25, 0.25, 0.4) }
    //         GradientStop { position: 0.75; color: Qt.rgba(0.25, 0.25, 0.25, 0.4) }
    //         GradientStop { position: 0.85; color: Qt.rgba(0.25, 0.25, 0.25, 0) }
    //         GradientStop { position: 1.0; color: Qt.rgba(0.25, 0.25, 0.25, 0) }
    //     }
    // }

    Canvas {
        id: radialFadeRect
        anchors.fill: parent

        // Enable layer for blur effect
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 8
            transparentBorder: true
        }

        // 当 Canvas 尺寸变化时重绘
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;
            if (w === 0 || h === 0) return;

            var centerX = w / 2;
            var centerY = h / 2;
            // var radius = Math.sqrt(w * w + h * h) / 2;
            var radius = Math.min(w, h) / 2;

            var gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, radius);

            gradient.addColorStop(0, Qt.rgba(0.25, 0.25, 0.25, 0.4));
            gradient.addColorStop(0.5, Qt.rgba(0.25, 0.25, 0.25, 0.2));
            gradient.addColorStop(1, Qt.rgba(0.25, 0.25, 0.25, 0));

            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, w, h);
        }
    }

    // Clock content
    Column {
        id: clockContent
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter

            function updateTime() {
                text = new Date().toLocaleTimeString(
                    Qt.locale(Config.dateLocale),
                    Config.clockFormat !== "" ? Config.clockFormat : Locale.ShortFormat
                )
            }

            font.pixelSize: Math.max(48, Math.round(root.height / 16))
            font.weight: Font.DemiBold
            font.family: "Noto Sans"
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter

            function updateTime() {
                var date = new Date();
                var days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                var dayName = days[date.getDay()];
                var year = date.getFullYear();
                var month = String(date.getMonth() + 1).padStart(2, '0');
                var day = String(date.getDate()).padStart(2, '0');
                text = dayName + '. ' + year + '-' + month + '-' + day;
            }

            font.pixelSize: Math.max(14, Math.round(root.height / 48))
            font.family: "Noto Sans"
            color: Qt.rgba(1, 1, 1, 0.85)
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Update timer
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            timeLabel.updateTime()
            dateLabel.updateTime()
        }
    }

    // Keyboard input
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_CapsLock) {
            root.capsLockOn = !root.capsLockOn;
        }
        if (event.key === Qt.Key_Escape) {
            event.accepted = false;
            return;
        } else {
            loginRequested();
        }
        event.accepted = true;
    }

    Component.onCompleted: {
        timeLabel.updateTime()
        dateLabel.updateTime()
    }
}
