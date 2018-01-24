require 'spec_helper'

describe Cuetip::Config do

  it "should have defaults" do
    expect(Cuetip::Config.new.worker_threads).to eq 1
  end

end
