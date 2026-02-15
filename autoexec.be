def system_boot()
  load('door_sensor.be')
end
tasmota.add_rule('System#Boot', system_boot)
