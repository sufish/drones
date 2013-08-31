require 'bunny'
require 'active_support/core_ext/class/attribute_accessors'
require 'logger'
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

  class DroneConnectionError < StandardError
  end
  self.logger = ::Logger.new(STDOUT)

  def logger
    self.class.logger
  end
  class << self
    def connect(mq_uri)
      begin
        Drone.instance.connection = Bunny.new(mq_uri, socket_timeout: 0)
        Drone.instance.connection.start
        Drone.instance.channel = Drone.instance.connection.create_channel
        logger.info "connection to #{mq_uri} is established"
      rescue StandardError => e
        raise DroneConnectionError, e.message
      end
    end

    def close
      Drone.instance.connection.close
    end
  end
end