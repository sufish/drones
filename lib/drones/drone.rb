require 'bunny'
require 'active_support/core_ext/class/attribute_accessors'
require 'logger'
require_relative 'connection_level_exception'
require 'singleton'
class Drone
  include Singleton
  cattr_accessor :logger
  attr_accessor :connection, :channel
  include Singleton
  MESSAGING_EXCHANGE = 'messaging-exchange'
  SMS_ROUTING_KEY = 'raw-sms'
  SMS_QUEUE_NAME = 'raw-sms'
  TRANSACTION_EXCHANGE = 'transaction-exchange'
  TRANSACTION_ROUTING_KEY = 'transaction'
  TRANSACTION_QUEUE_NAME = 'transaction'

  self.logger = ::Logger.new(STDOUT)

  def logger
    self.class.logger
  end
  class << self
    def connect(mq_uri)
      @mq_uri = mq_uri
      begin
        Drone.instance.connection = Bunny.new(@mq_uri, socket_timeout: 0)
        Drone.instance.connection.start
        Drone.instance.channel = Drone.instance.connection.create_channel
        logger.info "connection to #{@mq_uri} is established"
      rescue Bunny::Exception => e
        raise Drones::ConnectionLevelException, e.message
      end
    end

    def close
      Drone.instance.connection.close
    end

    def reconnect
       begin
         connect(@mq_uri)
       rescue Exception => e
         logger.error "reconnection failed ; #{e.message}"
       end
    end
  end
end