require_relative 'drone'
require 'ostruct'

class Drone
  class Consumer
    class << self
      def logger
        Drone.logger
      end

      def consume_sms
        exchange = Drone.instance.channel.direct(MESSAGING_EXCHANGE, durable: true)
        queue = Drone.instance.channel.queue(SMS_QUEUE_NAME, :durable => true, :auto_delete => false)
        queue.bind(exchange, routing_key: SMS_ROUTING_KEY)

        queue.subscribe ack: true do |delivery_info, properties, payload|
          send_success = true
          begin
            sms = OpenStruct.new(Oj.load(payload))
            send_success= yield sms if block_given?
            if send_success
              Drone.instance.channel.acknowledge(delivery_info.delivery_tag, false)
            else
              Drone.instance.channel.reject(delivery_info.delivery_tag, true)
            end
          rescue StandardError => e
            logger.error "message is discarded due to #{e.message}"
            Drone.instance.channel.reject(delivery_info.delivery_tag, false)
          end
        end
      end

      def consume_transaction_confirm
        exchange = Drone.instance.channel.direct(TRANSACTION_EXCHANGE, durable: true)
        queue =  Drone.instance.channel.queue(TRANSACTION_QUEUE_NAME, :durable => true, :auto_delete => false)
        queue.bind(exchange, routing_key: TRANSACTION_ROUTING_KEY)
        queue.subscribe ack: true do |delivery_info, properties, payload|
          confirm_success = true
          begin
            transaction = OpenStruct.new(Oj.load(payload))
            params = OpenStruct.new(transaction.params)
            trans_id = transaction.trans_id
            confirm_success = yield trans_id, params if block_given?
            if confirm_success
              Drone.instance.channel.acknowledge(delivery_info.delivery_tag, false)
            else
              Drone.instance.channel.reject(delivery_info.delivery_tag, true)
            end
          rescue StandardError => e
            logger.error "transaction is discarded due to #{e.message}"
            Drone.instance.channel.reject(delivery_info.delivery_tag, false)
          end
        end
      end
    end
  end
end