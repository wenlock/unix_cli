# encoding: utf-8
#
# © Copyright 2013 Hewlett-Packard Development Company, L.P.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Rules getter" do
  def mock_rule(rulo)
    RuleTestHelper.mock(rulo)
  end

  before(:each) do
    @groupo = "groupo"
    @rules = [ mock_rule("rulo1"), mock_rule("rulo2"), mock_rule("rulo3"), mock_rule("rulo3") ]

    @security_group = double("security_group")
    @security_group.stub(:id).and_return(1047)
    @security_group.stub(:name).and_return(@groupo)
    @security_group.stub(:description).and_return("description")
    @security_group.stub(:tenant_id).and_return("2222")
    @security_group.stub(:security_group_rules).and_return(@rules)
    @network = double("network")
    @network.stub(:security_groups).and_return([@security_group])
    @connection = double("connection")
    @connection.stub(:network).and_return(@network)
    Connection.stub(:instance).and_return(@connection)
  end

  context "when we get with no arguments" do
    it "should return them all" do
      rules = Rules.new(@groupo).get()

      rules[0].name.should eql("rulo1")
      rules[1].name.should eql("rulo2")
      rules[2].name.should eql("rulo3")
      rules[3].name.should eql("rulo3")
      rules.length.should eql(4)
    end
  end

  context "when we specify name" do
    it "should return them all" do
      rules = Rules.new(@groupo).get(["rulo2"])

      rules[0].name.should eql("rulo2")
      rules.length.should eql(1)
    end
  end

  context "when we specify a couple" do
    it "should return them all" do
      rules = Rules.new(@groupo).get(["rulo1", "rulo2"])

      rules[0].name.should eql("rulo1")
      rules[1].name.should eql("rulo2")
      rules.length.should eql(2)
    end
  end

  context "when we match multiple" do
    it "should return both" do
      rules = Rules.new(@groupo).get(["rulo3"])

      rules[0].name.should eql("rulo3")
      rules[1].name.should eql("rulo3")
      rules.length.should eql(2)
    end
  end

  context "when we match multiple" do
    it "should return error" do
      rules = Rules.new(@groupo).get(["rulo3"], false)

      rules[0].is_valid?.should be_false
      rules[0].cstatus.error_code.should eq(:general_error)
      rules[0].cstatus.message.should eq("More than one rule matches 'rulo3', use the id instead of name.")
      rules.length.should eql(1)
    end
  end

  context "when we fail to match" do
    it "should return error" do
      rules = Rules.new(@groupo).get(["bogus"])

      rules[0].is_valid?.should be_false
      rules[0].cstatus.error_code.should eq(:not_found)
      rules[0].cstatus.message.should eq("Cannot find a rule matching 'bogus'.")
      rules.length.should eql(1)
    end
  end

  context "when check empty" do
    it "should return false" do
      Rules.new(@groupo).empty?.should be_false
    end
  end
end
