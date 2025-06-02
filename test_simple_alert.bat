@echo off
echo Testing MQTT Alert Command...

echo.
echo Sending test alert to center position...
mosquitto_pub -h localhost -t "kingkiosk/command" -m "{\"command\": \"alert\", \"title\": \"Test Alert\", \"message\": \"This is a test alert positioned in the center\", \"position\": \"center\"}"

echo.
echo Done! Check the KingKiosk application for the alert.
pause
