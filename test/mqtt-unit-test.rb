class Test4MQTT < MTest::Unit::TestCase
  def mqttconnection
    mq = MQTT.open("iot.eclipse.org", 1883)
    mq.connect("mruby_test")
    mq.recv 255
    mq
  end

  def test_assert_open
    assert("mqtt#open") do
      mq = MQTT.open("iot.eclipse.org", 1883)
    end
  end

  def test_assert_connect
    mq = MQTT.open("iot.eclipse.org", 1883)
    mq.connect("mruby_test")
    res = mq.recv 255
    assert_equal(" \002\000\000", res)
  end

  def test_assert_subscribe
    mq = mqttconnection
    mq.subscrb ("mruby/test")
    res = mq.recv 255
    assert_equal 
  end
end

MTest::Unit.new.run

