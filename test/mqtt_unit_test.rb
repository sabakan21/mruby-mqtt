# Test for mqtt
class Test4MQTT < MTest::Unit::TestCase
  def mqttconnection
    mq = MQTT.open('iot.eclipse.org', 1883)
    mq.connect('mruby_test')
    mq.recv 255
    mq
  end

  def test_assert_open
    assert('mqtt#open') do
      MQTT.open('iot.eclipse.org', 1883)
    end
  end

  def test_assert_parse
    conack = MQTT.parse " \002\000\000"
    assert_equal(conack['msg_type'], 2)
    suback = MQTT.parse "\220\003\000\001\000"
    assert_equal(suback['msg_type'], 9)
    pub = MQTT.parse "0\020\000\nmruby/testtest"
    assert_equal(pub['msg_type'], 3)
  end

  def test_assert_parse_pub
    res = MQTT.parse "0\020\000\nmruby/testtest"
    pub = { 'msg_type' => 3,
            'dup' => 0,
            'qos' => 0,
            'retain' => 0,
            'remaining length' => 16,
            'topic' => 'mruby/test',
            'mesg' => 'test'
    }
    assert_equal(pub, res)
  end

  def test_assert_connect
    mq = MQTT.open('iot.eclipse.org', 1883)
    mq.connect('mruby_test')
    res = mq.recv 255
    assert_equal(" \002\000\000", res)
  end

  def test_assert_subscribe
    mq = mqttconnection
    mq.subscrb('mruby/test')
    res = mq.recv 255
    assert_equal res, "\220\003\000\001\000"
  end
end

MTest::Unit.new.run
