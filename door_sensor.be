import ULP
import gpio

# ------------------------------------------------------------
# Door Sensor (Berry) for Tasmota / ESP32 ULP wake + deep sleep
# ------------------------------------------------------------
#
# USER SETTINGS (edit these)
# ------------------------------------------------------------
var DOOR_GPIO       = 33    # Door sensor GPIO
var CONFIG_GPIO     = 0     # Config button GPIO (BOOT)
var SLEEP_DELAY_S   = 5     # Delay before deep sleep (seconds)
var WEBUI_IN_CONFIG = true  # Show Web UI only in config mode
#
# ------------------------------------------------------------
# End of user settings
# ------------------------------------------------------------

# -------------------------
# Detect Wi-Fi configuration
# -------------------------
var wifi = tasmota.wifi()
var wifi_configured = wifi.contains("mac") && wifi["mac"] != ""

# -------------------------
# Config mode detection
# -------------------------
gpio.pin_mode(CONFIG_GPIO, gpio.INPUT_PULLUP)
var button_pressed = (gpio.digital_read(CONFIG_GPIO) == 0)
var config_mode = button_pressed || !wifi_configured

if config_mode
    if !wifi_configured
        print("Wi-Fi not configured -> AP config mode active")
        print("Connect to the device Wi-Fi to configure")
    else
        print("CONFIG MODE (button)")
    end
else
    print("NORMAL MODE")
end

# ------------------------------------------------------------
# ULP setup (normal mode only)
# ------------------------------------------------------------
if !config_mode
    ULP.wake_period(0, 20000)

    var program = bytes().fromb64(
        "dWxwAAwAzAAAABgAgwOAcg8AANA8AIBwEAAJggkBuC4wAMBwKAAAgAkB+C8PASByMADAcBAAQHIzA4ByDwAA0DMAAHAfAEByVABAgFMDgHJCA4ByDwAA0AsAAGgAAACwQwOAcg4AANAKAABycABAgBoAIHIOAABoAAAAsFMDgHJCA4ByDwAA0AsAAGgzA4ByDgAA0BoAAHIaAEByDgAAaGMDgHIOAADQGgAAcg4AAGhzA4ByDwAA0C8AIHC4AECAAAAAsDAAzCkQAEByuABAgAEAAJAAAACw"
    )

    ULP.load(program)
    program = nil

    var rtc = ULP.gpio_init(DOOR_GPIO, 0)
    ULP.set_mem(55, 3)
    ULP.set_mem(56, rtc)
    ULP.run()

    print("Sleeping in", SLEEP_DELAY_S, "s")
    tasmota.set_timer(SLEEP_DELAY_S * 1000, /-> ULP.sleep())
end

# ------------------------------------------------------------
# Optional lightweight Web UI (config mode only)
# ------------------------------------------------------------
class DoorStatusDriver : Driver
    var g
    def init(gp) self.g = gp end

    def web_sensor()
        import webserver
        var s = gpio.digital_read(self.g)
        var state_txt = s ? "OPEN" : "CLOSED"
        var color = s ? "#931f1f" : "#4caf50"
        webserver.content_send('{s}Door{m}<b style="color:' + color + '">' + state_txt + '</b>{e}')
    end
end

if config_mode && WEBUI_IN_CONFIG
    tasmota.add_driver(DoorStatusDriver(DOOR_GPIO))
end

print("OK")
