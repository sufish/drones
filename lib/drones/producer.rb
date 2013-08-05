require_relative 'drone'
require 'oj'
class Drone
  class Producer
    class << self
      def logger
        Drone.logger
      end

      def send_sms(mobile, content, priority = 100)
        begin
          exchange = Drone.instance.channel.direct(MESSAGING_EXCHANGE, durable: true)
          sms_json = Oj.dump({mobile: mobile, content: content, priority: priority})
          exchange.publish(sms_json, persistent: true, routing_key: SMS_ROUTING_KEY)
        rescue Exception => e
          raise DroneConnectionError, e.message
        end
      end

      def send_transaction_confirmation(trans_id, params)
        begin
          exchange = Drone.instance.channel.direct(TRANSACTION_EXCHANGE, durable: true)
          transaction_json = Oj.dump({trans_id: trans_id, params: params})
          exchange.publish(transaction_json, persistent: true, routing_key: TRANSACTION_ROUTING_KEY)
          true
        rescue Exception => e
          logger.fatal("failed to send transaction confirmation, due to: #{e.message}")
          false
        end
      end
    end
  end
end