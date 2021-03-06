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

describe "Metadata class" do

  before(:each) do
    superfly = double("superfly")
    superfly.stub(:key).and_return("superfly")
    superfly.stub(:value).and_return("xc")
    rumblefish = double("rumblefish")
    rumblefish.stub(:key).and_return("rumblefish")
    rumblefish.stub(:value).and_return("am")
    @fog_metadata = [superfly,rumblefish]
  end

  context "when we get_keys" do
    it "it returns some keys" do
      keys = HP::Cloud::Metadata.get_keys()

      keys[0].should eql("key")
      keys[1].should eql("value")
      keys.length.should eql(2)
    end
  end

  context "when we to_array" do
    it "it returns some expected hash" do
      hsh = HP::Cloud::Metadata.new(@fog_metadata).to_array()

      hsh[0]["key"].should eql("rumblefish")
      hsh[0]["value"].should eql("am")
      hsh[1]["key"].should eql("superfly")
      hsh[1]["value"].should eql("xc")
      hsh.length.should eql(2)
    end
  end

  context "when we construct" do
    it "it parses the fog metadata" do
      mta = HP::Cloud::Metadata.new(@fog_metadata)

      mta.to_s.should eq('rumblefish=am,superfly=xc')
      mta.hsh['superfly'].should eq('xc')
      mta.hsh['rumblefish'].should eq('am')
      mta.hsh.to_a.length.should eq(2)
    end
  end

  context "when we call set_metadata with three items" do
    it "it changes the metadata and returns true" do
      mta = HP::Cloud::Metadata.new()

      mta.set_metadata('one=1,two=2,three=3').should be_true

      mta.to_s.should eq('one=1,three=3,two=2')
      mta.hsh['one'].should eq('1')
      mta.hsh['two'].should eq('2')
      mta.hsh['three'].should eq('3')
      mta.hsh.to_a.length.should eq(3)
    end
  end

  context "when we call set_metadata" do
    it "it changes the metadata and returns true" do
      mta = HP::Cloud::Metadata.new()

      mta.set_metadata('one=1').should be_true

      mta.to_s.should eq('one=1')
      mta.hsh['one'].should eq('1')
      mta.hsh.to_a.length.should eq(1)
    end
  end

  context "when we call set_metadata with quotes" do
    it "it changes the security_groups and returns false" do
      mta = HP::Cloud::Metadata.new()
      mta.set_metadata('garbage').should be_false
      mta.cstatus.message.should eq("Invalid metadata 'garbage' should be in the form 'k1=v1,k2=v2,...'")
      mta.cstatus.error_code.should eq(:incorrect_usage)
    end
  end

  context "when we call set_metadata with quotes" do
    it "it changes the security_groups and returns false" do
      mta = HP::Cloud::Metadata.new()
      mta.set_metadata('asdf==ddd').should be_false
      mta.cstatus.message.should eq("Invalid metadata 'asdf==ddd' should be in the form 'k1=v1,k2=v2,...'")
      mta.cstatus.error_code.should eq(:incorrect_usage)
    end
  end

  context "when we call set_metadata with empty string" do
    it "it changes the meta to nothing and returns true" do
      mta = HP::Cloud::Metadata.new()
      mta.set_metadata('something=else').should be_true

      mta.set_metadata('').should be_true

      mta.to_s.should eq('')
      mta.hsh.length.should eq(0)
    end
  end

  context "when we call set_metadata with nil" do
    it "it doesn't change the metadata" do
      mta = HP::Cloud::Metadata.new()
      mta.set_metadata('something=else').should be_true

      mta.set_metadata(nil).should be_true

      mta.to_s.should eq('something=else')
      ray = mta.hsh.to_a
      ray[0][0].should eq('something')
      ray[0][1].should eq('else')
      ray[0].length.should eq(2)
      ray.length.should eq(1)
    end
  end

  context "when we call remove_metadata with nil @fog_metadata" do
    it "it should return error" do
      mta = HP::Cloud::Metadata.new()

      mta.remove_metadata('something').should be_false

      mta.cstatus.message.should eq("Metadata key 'something' not found")
      mta.cstatus.error_code.should eq(:not_found)
    end
  end

  context "when we call remove_metadata with unknown key" do
    it "it doesn't change the metadata" do
      fogger = double("fogger")
      fogger.stub(:map).and_return([].each)
      fogger.stub(:get).and_return(nil)
      mta = HP::Cloud::Metadata.new(fogger)

      mta.remove_metadata('something').should be_false

      mta.cstatus.message.should eq("Metadata key 'something' not found")
      mta.cstatus.error_code.should eq(:not_found)
      mta.to_s.should eq('')
      mta.hsh.to_a.length.should eq(0)
    end
  end

  context "when we call remove_metadata with unknown key" do
    it "it doesn't change the metadata" do
      pair = double("pair")
      pair.should_receive(:destroy)
      fogger = double("fogger")
      fogger.stub(:map).and_return([].each)
      fogger.stub(:get).and_return(pair)
      mta = HP::Cloud::Metadata.new(fogger)

      mta.remove_metadata('something').should be_true

    end
  end
end
