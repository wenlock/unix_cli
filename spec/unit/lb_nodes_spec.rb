require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "LbNodes" do
  before(:each) do
    @items = [ "1", "2", "3" ]
    @service = double("service")
    @connection = double("connection")
    @service.stub(:nodes).and_return(@items)
    @connection.stub(:lb).and_return(@service)
    Connection.stub(:instance).and_return(@connection)
  end

  context "name" do
    it "should return name" do
      LbNodes.new("lbid").name.should eq("load balancer node")
    end
  end

  context "items" do
    it "should return them all" do
      sot = LbNodes.new("lbid")

      sot.items.should eq(@items)
    end
  end

  context "matches" do
    it "should return name" do
      item = double("item")
      item.stub(:address).and_return("127.0.0.1")
      item.stub(:port).and_return("999")
      item.stub(:id).and_return("ido")
      sot = LbNodes.new("lbid")

      sot.matches("127.0.0.1:999", item).should be_true
      sot.matches("ido", item).should be_true
      sot.matches("bogus", item).should be_false
    end
  end
end