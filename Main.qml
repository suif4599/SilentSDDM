import "."
import QtQuick
import SddmComponents
import QtQuick.Effects
import QtMultimedia
import "components"

Item {
    id: root
    state: Config.lockScreenDisplay ? "lockState" : "loginState"

    // TODO: Add own translations: https://github.com/sddm/sddm/wiki/Localization
    TextConstants {
        id: textConstants
    }

    property bool capsLockOn: false
    Component.onCompleted: {
        if (keyboard)
            capsLockOn = keyboard.capsLock;
    }
    onCapsLockOnChanged: {
        loginScreen.updateCapsLock();
    }

    states: [
        State {
            name: "lockState"
            PropertyChanges {
                target: lockScreen
                opacity: 1.0
            }
            PropertyChanges {
                target: loginScreen
                opacity: 0.0
            }
            PropertyChanges {
                target: loginScreen.loginContainer
                scale: 0.5
            }
            PropertyChanges {
                target: backgroundEffect
                blurMax: 0
                brightness: 0
                saturation: 0
            }
        },
        State {
            name: "loginState"
            PropertyChanges {
                target: lockScreen
                opacity: 0.0
            }
            PropertyChanges {
                target: loginScreen
                opacity: 1.0
            }
            PropertyChanges {
                target: loginScreen.loginContainer
                scale: 1.0
            }
            PropertyChanges {
                target: backgroundEffect
                blurMax: Config.loginScreenBlur
                brightness: Config.loginScreenBrightness
                saturation: Config.loginScreenSaturation
            }
        }
    ]
    transitions: Transition {
        enabled: Config.enableAnimations
        PropertyAnimation {
            duration: 150
            properties: "opacity"
        }
        PropertyAnimation {
            duration: 400
            properties: "blurMax"
        }
        PropertyAnimation {
            duration: 400
            properties: "brightness"
        }
        PropertyAnimation {
            duration: 400
            properties: "saturation"
        }
    }

    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        // Simple background - only default.jpg
        Image {
            id: backgroundImage
            anchors.fill: parent
            source: "backgrounds/default.jpg"
            cache: true
            mipmap: true
            fillMode: Image.PreserveAspectCrop
        }

        MultiEffect {
            // Background effects
            id: backgroundEffect
            source: backgroundImage
            anchors.fill: parent
            blurEnabled: blurMax > 0
            blur: blurMax > 0 ? 1.0 : 0.0
            autoPaddingEnabled: false
        }

        Item {
            id: screenContainer
            anchors.fill: parent
            anchors.top: parent.top

            MouseArea {
                anchors.fill: parent
                enabled: root.state === "lockState"
                onClicked: {
                    root.state = "loginState";
                    loginScreen.resetFocus();
                }
            }

            // Keyboard handler for clock screen
            Item {
                anchors.fill: parent
                enabled: root.state === "lockState"
                focus: root.state === "lockState"

                Keys.onPressed: function (event) {
                    // Whitelist of keys that trigger login
                    var isLetter = event.key >= Qt.Key_A && event.key <= Qt.Key_Z;
                    var isNumber = event.key >= Qt.Key_0 && event.key <= Qt.Key_9;
                    var isEnter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
                    var isSpace = event.key === Qt.Key_Space;
                    var isArrow = event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                                   event.key === Qt.Key_Up || event.key === Qt.Key_Down;
                    var isSymbol = (event.key >= Qt.Key_Exclam && event.key <= Qt.Key_AsciiTilde);

                    if (isLetter || isNumber || isEnter || isSpace || isArrow || isSymbol) {
                        root.state = "loginState";
                        loginScreen.resetFocus();
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }

            Clock {
                id: lockScreen
                z: root.state === "lockState" ? 2 : 1 // Fix tooltips from the login screen showing up on top of the lock screen.
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                focus: root.state === "lockState"
                enabled: root.state === "lockState"
                state: root.state === "lockState" ? "visible" : "hidden"
            }
            LoginScreen {
                id: loginScreen
                z: root.state === "loginState" ? 2 : 1
                anchors.fill: parent
                enabled: root.state === "loginState"
                opacity: 0.0
                onClose: {
                    root.state = "lockState";
                }
            }
        }
    }
}
