# Door Sensor (Berry) – ESP32 ULP + Deep Sleep for Tasmota

## Description
Berry script for ESP32/Tasmota:
- **Normal mode**: initializes the ULP (Ultra Low Power) program to monitor a GPIO (door sensor), then enters **deep sleep** quickly.
- **Config mode**: if Wi-Fi is not configured or the BOOT button (GPIO0) is pressed, the device stays awake to allow configuration and (optionally) shows door state via a **lightweight Web UI**.

## Installation

### Prerequisites:
   - ESP32 with Tasmota installed
   - Berry activated

### Module installation:

#### Manual installation 
   - Download the `door_sensor.be` and `door_sensor_config.be`  files
   - Copy it to your ESP32 via Tasmota web interface (Console -> Manage File System)
   - Enable it:
   ```
   br load('door_sensor.be')
   ```

#### Automatic installation 
   - Paste this code in your ESP32 via Tasmota web interface (Console -> Berry Scripting Console)
   ```
import path

var base_url = "https://raw.githubusercontent.com/Flobul/Tasmota-DoorSensor_ULP_DeepSleep/main/"
var files = {
  'sensor': "door_sensor.be",
  'sensor_config': "door_sensor_config.be"
}

def download_file(filename)
  var cl = webclient()
  cl.begin(base_url + filename)
  if cl.GET() != 200 return false end
  cl.write_file(filename)
  cl.close()
  return true
end

def start_door_sensor_setup()
  var success = true

  for name: files.keys()
    print(format("Downloading %s...", files[name]))
    if !download_file(files[name])
      print(format("Error downloading %s", files[name]))
      success = false
      break
    end
  end

  if success
    print("All files downloaded successfully")
    load('door_sensor.be')
    return true
  end
  return false
end

start_door_sensor_setup()
   ```
### Load on boot

If you would like a fully berry solution to loading eWeLinkRemote, add the following line to autoexec.be

   ```
    tasmota.add_rule('System#Boot', / -> load('door_sensor.be'))
   ```

Otherwise, you can simply make a rule:

   ```
    Rule1 ON System#Boot DO br load('door_sensor.be') ENDON 
   ```
Enable the rule:
   ```
    Rule1 1
   ```

## Files
- `door_sensor.be`: main script
- `door_sensor_config.be`: optional config override file

## Settings
In `door_sensor_config.be`:

- `DOOR_GPIO` (int): door sensor GPIO (e.g. 33)
- `CONFIG_GPIO` (int): config button GPIO (often `0` on ESP32 = BOOT)
- `SLEEP_DELAY_S` (int/float): delay before deep sleep, in seconds
- `WEBUI_IN_CONFIG` (bool): enable the mini Web UI only in config mode

## Config mode (AP / button)
The script enters config mode if:
- Wi-Fi is not configured, **or**
- `CONFIG_GPIO` is low (button pressed on pull-up input)

In config mode:
- **no deep sleep**
- Web UI is available if `WEBUI_IN_CONFIG=true`

## Technical notes
- The ULP program is embedded as base64 and uses `ULP.set_mem(55, ...)` and `ULP.set_mem(56, ...)` exactly like the original version.  
  If you change the ULP program, these offsets may need to change.
- Check your sensor wiring (pull-up/pull-down) and expected logic level (OPEN/CLOSED).
