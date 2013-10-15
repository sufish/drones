require 'bunny'
require 'active_support/core_ext/class/attribute_accessors'
require 'logger'
require 'oj'
require 'ostruct'
require_relative 'connection_level_exception'
class Drone
  cattr_accessor :logger
  attr_accessor :connection, :channel
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

  def initialize(mq_uri)
    connect(mq_uri)
  end

  def connect(mq_uri)
    @mq_uri = mq_uri
    begin
      @connection = Bunny.new(@mq_uri, socket_timeout: 0)
      @connection.start
      @channel = @connection.create_channel
      logger.info "connection to #{@mq_uri} is established"
    rescue Bunny::Exception => e
      raise Drones::ConnectionLevelException, e.message
    end
  end

  def close
    @connection.close
  end

  def reconnect
    begin
      connect(@mq_uri)
    rescue Exception => e
      logger.error "reconnection failed ; #{e.message}"
    end
  end

  def send_sms(mobile, content, priority = 100)
    begin
      exchange = @channel.direct(MESSAGING_EXCHANGE, durable: true)
      sms_json = Oj.dump({mobile: mobile, content: content, priority: priority})
      exchange.publish(sms_json, persistent: true, routing_key: SMS_ROUTING_KEY)
    rescue Bunny::Exception => e
      raise Drones::ConnectionLevelException, e.message
    end
  end

  def consume_sms(blocking = false)
    exchange = @channel.direct(MESSAGING_EXCHANGE, durable: true)
    queue = @channel.queue(SMS_QUEUE_NAME, :durable => true, :auto_delete => false)
    queue.bind(exchange, routing_key: SMS_ROUTING_KEY)

    queue.subscribe(ack: true, block: blocking) do |delivery_info, _, payload|
      send_success = true
      begin
        sms = OpenStruct.new(Oj.load(payload))
        send_success= yield sms if block_given?
        if send_success
          @channel.acknowledge(delivery_info.delivery_tag, false)
        else
          @channel.reject(delivery_info.delivery_tag, true)
        end
      rescue Bunny::Exception => e
        raise ConnectionLevelException, e.message
      rescue StandardError => e
        logger.error "message is discarded due to #{e.message}"
        @channel.reject(delivery_info.delivery_tag, false)
      end
    end
  end
end