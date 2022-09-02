#! /system/bin/sh

buttonlight(){
    echo 1 > /sys/class/leds/button-backlight/brightness
    sleep 5
    while true
    do
# If you want to turn on backlight only when touch input is provided, Uncomment these and comment l>
#      if dumpsys input | grep "Last Raw Touch: pointerCount=1"; then
#        echo 1 > /sys/class/leds/button-backlight/brightness && sleep 5
      if [ $(cat "/sys/class/leds/lcd-backlight/brightness") != "0" ]; then
        echo 1 > /sys/class/leds/button-backlight/brightness && sleep 1
      else
        echo 0 > /sys/class/leds/button-backlight/brightness
      fi
    done
}

buttonlight
