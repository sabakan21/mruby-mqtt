class MQTT < TCPSocket
		@messageID
		@client_id
		@time
		@keep_alive
		attr_reader :client_id
		def initialize(sockaddr, family=Socket::PF_UNSPEC, socktype=0, protocol=0)
				@messageID = 1
        @client_id = "mruby" + sprintf("%04d",rand(9999))
				@time = Time.now
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
				head_var << 60.chr
				
				@keep_alive = 10
				
				payload = self.mqttutf @client_id
				#payload << payload
				head_len = (head_var + payload).size.chr
				
				p head_fix
        p head_len
        p head_var
        p payload
				self.write(head_fix + head_len + head_var + payload)
		end
		
		def publish(topic, text, qos = 1)
				if qos > 2
						qos = 2
				elsif qos < 0
						qos = 0
				end
				
				head_fix = (0b00110000 | (qos << 1)).chr
				head_len = 0.chr
				
				head_var = self.mqttutf topic
				head_var << (@messageID >> 8).chr
				head_var << (@messageID & 0xffff).chr
				
				mes = text
				
				head_len = (head_var + mes).size.chr
				
				p head_fix
				p head_len
				p head_var
				p "=========="
				p head_fix + head_len + head_var + mes
				self.write(head_fix + head_len + head_var + mes)
				
				@messageID += 1
		end
		
		def subscrb topic
				
				qos =1
				
				head_fix = 0b10000010.chr
				head_len = 0.chr
				
				head_var = (@messageID >> 8).chr
				head_var << (@messageID & 0xffff).chr
				
				#実際ペイロード
				payload = self.mqttutf topic
				payload << qos.chr
				
				head_len = (head_var + payload).size.chr
				
				
				p head_fix
				p head_len
				p head_var
				p "=========="
				p head_fix + head_len + head_var + payload
				
				@messageID++
				
				self.write(head_fix + head_len + head_var + payload)
		end

		def get
				head =self.recv 2
				p " received header =" + head
				while head.empty? do
						head =self.recv 2
				end
				r = self.recv head[1].bytes[0]
				return head + r
		end
		
		
end
