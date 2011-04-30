require 'eventmachine'
require 'gorillib/logger/log'

class StatsdRequestLogger < EventMachine::Connection
  DEFAULT_HOST = '127.0.0.1'
  DEFAULT_PORT = 8125
  DEFAULT_FRAC = 1.0

  def initialize options={}
    @host = options[:host] || DEFAULT_HOST
    @port = options[:port] || DEFAULT_PORT
    @frac = options[:frac] || DEFAULT_FRAC
  end

  # def post_init
  # end

  def count name, val=1
    send_to_statsd "#{name}:#{val}|c"
  end

  def send_timing
  end

  def send_to_statsd metric
    send_datagram metric, @host, @port
  end

  def self.open
    EventMachine::open_datagram_socket(DEFAULT_HOST, 0, self) do |c|
      EM.add_periodic_timer(0.001) do
        c.count('foo.counted')
      end
    end
  end
end

EventMachine::run do

  EM.add_timer(2){ EM.stop }

  StatsdRequestLogger.open
end
