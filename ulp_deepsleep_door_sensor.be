import ULP
import string
import gpio

# Config
var DOOR_GPIO = 33
var CONFIG_GPIO = 0
var SLEEP_DELAY = 5  # Réduit à 5s pour publier plus vite

# Vérifier si WiFi configuré
var wifi_cfg = tasmota.wifi().contains('mac') && tasmota.wifi()['mac'] != ""

# Mode config (bouton BOOT OU WiFi non configuré)
gpio.pin_mode(CONFIG_GPIO, gpio.INPUT_PULLUP)
var cfg = gpio.digital_read(CONFIG_GPIO) == 0 || !wifi_cfg

if cfg
    if !wifi_cfg
        print("⚠️ WiFi non configuré - Mode AP actif")
        print("Connectez-vous au WiFi du module pour configurer")
    else
        print("⚙️ CONFIG MODE (bouton)")
    end
    return  # Pas de deep sleep
end

print("🚀 NORMAL MODE")

# Lire et publier
# var st = gpio.digital_read(DOOR_GPIO)
# print("Door:", st ? "OPEN" : "CLOSED")

# ULP
ULP.wake_period(0, 20000)
var c = bytes().fromb64("dWxwAAwAzAAAABgAgwOAcg8AANA8AIBwEAAJggkBuC4wAMBwKAAAgAkB+C8PASByMADAcBAAQHIzA4ByDwAA0DMAAHAfAEByVABAgFMDgHJCA4ByDwAA0AsAAGgAAACwQwOAcg4AANAKAABycABAgBoAIHIOAABoAAAAsFMDgHJCA4ByDwAA0AsAAGgzA4ByDgAA0BoAAHIaAEByDgAAaGMDgHIOAADQGgAAcg4AAGhzA4ByDwAA0C8AIHC4AECAAAAAsDAAzCkQAEByuABAgAEAAJAAAACw")
ULP.load(c)
c = nil
var rtc = ULP.gpio_init(DOOR_GPIO, 0)
ULP.set_mem(55, 3)
ULP.set_mem(56, rtc)
ULP.run()

# Sleep rapide
print("Sleep in", SLEEP_DELAY, "s")
tasmota.set_timer(SLEEP_DELAY * 1000, /-> ULP.sleep())

# Web UI léger (seulement en mode config)
class DS : Driver
    var g
    def init(gp) self.g = gp end
    def web_sensor()
        import webserver
        var s = gpio.digital_read(self.g)
        var t = s ? "OPEN" : "CLOSED"
        var c = s ? "#931f1f" : "#4caf50"
        webserver.content_send('{s}Door{m}<b style="color:' + c + '">' + t + '</b>{e}')
    end
end

if cfg
    tasmota.add_driver(DS(DOOR_GPIO))
end

print("OK!")
