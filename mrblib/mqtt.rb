class MQTT < TCPSocket
  attr_reader :client_id, :message_id

  def initialize(*arg)
    @message_id = 1
    super(*arg)
  end

  def mqttutf(text)
    (text.size >> 8).chr + (text.size & 0xffff).chr + text
  end

  def connect(id)
    @client_id = id
    head_fix = 16.chr

    # variable header
    # version
    head_var = 0.chr + 6.chr
    head_var << 'MQIsdp'
    head_var << 3.chr
    # flags
    head_var << 2.chr
    # keepalive timer MSB => LSB
    head_var << 0.chr
    head_var << 0.chr

    payload = mqttutf @client_id
    # payload << payload
    head_len = (head_var + payload).size.chr

    write(head_fix + head_len + head_var + payload)
  end

  def publish(topic, text, qos = 0)
    if qos > 2
      qos = 2
    elsif qos < 0
      qos = 0
    end

    head_fix = (0b00110000 | (qos << 1)).chr
    head_len = 0.chr

    head_var = self.mqttutf topic

    if qos > 0 then
      head_var << (@message_id >> 8).chr
      head_var << (@message_id & 0xffff).chr
      @message_id += 1
    end

    mes = text

    head_len = (head_var + mes).size.chr

    self.write(head_fix + head_len + head_var + mes)

  end

  def subscrb topic

    qos = 0

    head_fix = 0b10000010.chr
    head_len = 0.chr

    head_var = (@message_id / 256).to_i.chr
    head_var << (@message_id & 0xffff).chr

    #実際ペイロード
    payload = self.mqttutf topic
    payload << qos.chr

    head_len = (head_var + payload).size.chr

    @message_id++

      self.write(head_fix + head_len + head_var + payload)
  end

  def get_packet

    head = self.recv(2)
    return if head == nil

    head.bytes[1].times do
      head << self.recv(1)
    end
    return head
  end

  def get_nonblock
    head = ""
    begin
      head << self.recv_nonblock(2)
      head.bytes[1].times do
        head << self.recv(1)
      end
      return head
    rescue
      return nil
    end
  end


  def get
    if block_given?
      loop do
        # TODO: use queue
        yield self.get_packet
        # TODO: return ack if qos > 0
      end
    else
      self.get_packet
    end
  end

  def self.parse(str)
    fix_head = str.slice!(0, 2)
    type_num = fix_head.bytes[0] >> 4
    under = fix_head.bytes[0] & 0b1111
    hash = { 'msg_type' => type_num,
             'dup' => under >> 3,
             'qos' => (under & 0b111) >> 1,
             'retain' => under & 1,
             'remaining length' => fix_head.bytes[1]
    }
    if type_num == 3
      topic_len = str.bytes[0] * 256 + str.bytes[1]
      hash['topic'] = str.slice(2, topic_len)
      str.slice!(0, 2 + topic_len)
      if hash['qos'] > 0
        # message id (2 bit)
        hash['msg_id'] = str.bytes[0] * 256 + str.bytes[1]
        str.slice!(0, 2)
      end
      hash['mesg'] = str
    else
      hash['remain'] = str
    end
    hash
  end

end
