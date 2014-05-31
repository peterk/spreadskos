require 'spec_helper'

describe Spreadskos do

  ROOT = "#{File.dirname(__FILE__)}"

  it "should instantiate" do
    s = Spreadskos::Converter.new(ROOT + "/pizza.xlsx")
    s.should_not be_nil
  end


end

