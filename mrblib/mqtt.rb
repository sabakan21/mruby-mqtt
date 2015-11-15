class MQTT < TCPSocket
  @messageID
  @client_id
  @keep_alive
  @read_queue
  @read_packet
  attr_reader :client_id

  def initialize(sockaddr, family=Socket::PF_UNSPEC, socktype=0, protocol=0)
    @messageID = 1
    @client_id = "mruby" + sprintf("%04d",Random.rand(9999))
    @read_queue = Array.new
    @read_packet = Array.new
    super
  end

  def mqttutf text
    (text.size >> 8).chr + (text.size & 0xffff).chr + text
  end


  def connect
    #fixed header
    head_fix = 16.chr

    #header length
    head_len = 0.chr

    #variable header
    #length MSB => LSB
    head_var = 0.chr + 6.chr
    #protocol name and version
    head_var << "MQIsdp"
    head_var << 3.chr
    #flags
    head_var << 2.chr
    #keepalive timer MSB => LSB
    head_var << 0.chr
    head_var << 0.chr

    @keep_alive = 10

    payload = self.mqttutf @client_id
    #payload << payload
    head_len = (head_var + payload).size.chr

    #p head_fix
    #p head_len
    #p head_var
    #p payload
    self.write(head_fix + head_len + head_var + payload)
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
      head_var << (@messageID >> 8).chr
      head_var << (@messageID & 0xffff).chr
      @messageID += 1
    end

    mes = text

    head_len = (head_var + mes).size.chr

    self.write(head_fix + head_len + head_var + mes)

  end

  def subscrb topic

    qos = 0

    head_fix = 0b10000010.chr
    head_len = 0.chr

    head_var = (@messageID >> 8).chr
    head_var << (@messageID & 0xffff).chr

    #実際ペイロード
    payload = self.mqttutf topic
    payload << qos.chr

    head_len = (head_var + payload).size.chr

    @messageID++

      self.write(head_fix + head_len + head_var + payload)
  end

  def get_packet
    head = ""
    head << self.recv(1)
    head << self.recv(1)
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
	

end
