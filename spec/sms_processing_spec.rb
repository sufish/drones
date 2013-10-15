require 'spec_helper'

describe 'SMS Processing' do
  it 'should process sms' do
    received_sms = OpenStruct.new
    CONN.consume_sms do |sms|
      received_sms = sms
      true
    end

    CONN.send_sms('123', '456', 50)
    sleep 0.5
    received_sms.mobile.should == '123'
    received_sms.content.should == '456'
    received_sms.priority.should == 50
  end
end