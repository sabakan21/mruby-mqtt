# MQTT Class
class MQTT < TCPSocket
  attr_reader :client_id, :message_id

  def initialize(*arg)
    @message_id = 1
    super(*arg)
  end

  # Packet class
  class Packet
    attr_reader :packet
    def initialize(type, str, dup = 0, qos = 0, retain = 0)
      @type = type.to_i
      @dup = dup.to_i
      @qos = qos.to_i
      @retain = retain.to_i
      head = @retain + (@qos << 1) + (@dup << 3) + (@type * 16)
      @packet = head.chr + msg_len(str) + str
    end

    def msg_len(str)
      str.size.chr
    end

    def self.mqttutf(id)
      str = (id / 256).to_i.chr
      str << (id & 0xffff).chr
    end

    def self.parse(str)
      fix_head = str.slice!(0, 2)
      type_num = fix_head.bytes[0] >> 4
      under = fix_head.bytes[0] & 0b1111
      hash = { 'msg_type' => type_num,
               'dup' => under >> 3,
               'qos' => (under & 0b111) >> 1,
               'retain' => under & 1,
               'len' => fix_head.bytes[1]
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

  def self.parse(str)
    MQTT::Packet.parse(str)
  end

  def connect(id)
    @client_id = id
    # variable header
    # version
    head_var = "\000\006MQIsdp\003"
    # flags
    head_var << 2.chr
    # keepalive timer MSB => LSB
    head_var << "\000\000"

    payload = Packet.mqttutf @client_id.size
    payload << @client_id
    # payload << payload
    packet = Packet.new(1, head_var + payload)

    write(packet.packet)
  end

  def publish(topic, text, qos = 0)
    # if qos > 2
    #   qos = 2
    # elsif qos < 0
    #   qos = 0
    # end

    head_var = Packet.mqttutf topic.size
    head_var << topic
    if qos > 0
      head_var << Packet.id_case(@message_id)
      @message_id += 1
    end
    packet = Packet.new(3, head_var + text, 0, qos)
    write(packet.packet)
  end

  def subscrb(topic, qos = 0)
    head_var = Packet.mqttutf @message_id
    # topic
    payload = Packet.mqttutf topic.size
    payload << topic
    payload << qos.chr
    @message_id += 1
    packet = Packet.new(8, head_var + payload, 0, 1)

    write(packet.packet)
  end

  def disconnect
    packet = Packet.new(14, '')
    write(packet.packet)
    close
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
        packet = get_packet
        yield packet.nil? ? next : packet
        # TODO: return ack if qos > 0
      end
    else
      self.get_packet
    end
  end

end
