require 'spec_helper'

describe 'Transaction Processing' do
  it 'should process transaction' do
    received_params = OpenStruct.new
    received_trans_id = nil
    Drone::Consumer.consume_transaction_confirm do |trans_id, params|
      received_trans_id = trans_id
      received_params = params
      true
    end

    Drone::Producer.send_transaction_confirmation('1', {:param1 => '1', :param2 => '2'})
    sleep 0.5
    received_trans_id.should == '1'
    received_params.param1.should == '1'
    received_params.param2.should == '2'
  end
end