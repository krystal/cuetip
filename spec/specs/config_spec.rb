require 'spec_helper'

describe Cuetip::Config do

  it "should have defaults" do
    expect(Cuetip::Config.new.polling_interval).to eq 10
  end

  context "#on" do
    it "should register callbacks" do
      config = Cuetip::Config.new
      block = Proc.new {}
      config.on(:before_job, &block)
      expect(config._cuetip_events[:before_job]).to include block
    end
  end

end
