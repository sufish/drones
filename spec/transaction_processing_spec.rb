require 'spec_helper'

describe 'Transaction Processing' do
  it 'should process transaction' do
    received_trans_id = nil
    Drone::Consumer.consume_transaction_confirm do |trans_id|
      received_trans_id = trans_id
      true
    end

    Drone::Producer.send_transaction_confirmation('1')
    sleep 0.5
    received_trans_id.should == '1'
  end
end