module Goliath
  module Plugin
    
    # Sends metrics to a remote statsd-compatible server
    class StatsdSender < EventMachine::Connection
      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 8125
      DEFAULT_FRAC = 1.0
      
      # 
      def initialize options={}
        @name   = options[:name] || 'foo'              # File.basename(Goliath::Application.app_file, '.rb')
        @host   = options[:host] || DEFAULT_HOST
        @port   = options[:port] || DEFAULT_PORT
        @logger = options[:logger] || Logger.new
        @logger.info ['init', @name, @host, @port]
      end

      def name metric=[]
        [@name, metric].flatten.reject{|x| x.to_s.empty? }.join(".")
      end

      def count metric, val=1, sampling_frac=nil
        # p ['count', @name, @host, @port, metric, val, sampling_frac]
        if sampling_frac && (rand < sampling_frac.to_F)
          send_to_statsd "#{name(metric)}:#{val}|c|@#{sampling_frac}"
        else
          send_to_statsd "#{name(metric)}:#{val}|c"
        end
      end

      def timing metric, val
        send_to_statsd "#{name(metric)}:#{val}|ms"
      end

    protected

      def send_to_statsd metric
        # @logger.info metric
        send_datagram metric, @host, @port
      end

      # Called automatically to start the plugin
      def self.open options={}
        EventMachine::open_datagram_socket((options[:host] || DEFAULT_HOST), 0, self, options)
      end
    end
    
    
    # Sends metrics to a remote statsd-compatible server
    #
    # @example
    #  plugin Goliath::Plugin::StatsdLogger
    #
    class StatsdLogger
      attr_reader :agent
      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 8125
      DEFAULT_FRAC = 1.0
      
      # Called by the framework to initialize the plugin
      #
      # @param port [Integer] Unused
      # @param config [Hash] The server configuration data
      # @param status [Hash] A status hash
      # @param logger [Log4R::Logger] The logger
      # @return [Goliath::Plugin::Latency] An instance of the Goliath::Plugin::Latency plugin
      def initialize(port, config, status, logger)
        @status = status
        @config = config
        @config[:statsd_logger] ||= {}
        @logger = logger
        
        @last = Time.now.to_f
      end

      @@recent_latency = 0
      def self.recent_latency
        @@recent_latency
      end

      def agent
        self.class.agent
      end

      def self.agent
        @@agent
      end

      # Called automatically to start the plugin
      def run
        @@agent = StatsdSender.open(@config[:statsd_logger].merge(:logger => @logger))

        EM.add_periodic_timer(1) do
          @@recent_latency = (Time.now.to_f - @last)
          agent.timing 'reactor.latency', @@recent_latency
          agent.count  'reactor.ticks'
          @last = Time.now.to_f
        end
      end
    end
    
  end
end


p __FILE__
