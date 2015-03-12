assert("MQTT#open") do
  mq = MQTT.open("iot.eclipse.org", 1883)
  assert(mq)
end
