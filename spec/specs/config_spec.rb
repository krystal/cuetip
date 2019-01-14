require 'spec_helper'

describe Cuetip::Config do

  it "should have defaults" do
    expect(Cuetip::Config.new.workers).to eq 1
  end

  it "should disconnect ActiveRecord before fork" do
    allow(ActiveRecord::Base).to receive(:clear_all_connections!)
    Cuetip::Config.new.before_fork&.call
    expect(ActiveRecord::Base).to have_received(:clear_all_connections!)
  end

end
