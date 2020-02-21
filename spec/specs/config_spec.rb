# frozen_string_literal: true

require 'spec_helper'

describe Cuetip::Config do
  it 'should have defaults' do
    expect(Cuetip::Config.new.polling_interval).to eq 5
  end
end
