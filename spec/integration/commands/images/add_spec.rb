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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe "images:add command" do
  before(:all) do
    @hp_svc = Connection.instance.compute
  end

  context "when creating image with name, server and defaults" do
    it "should show success message" do
      @image_name1 = resource_name("add")
      @server = ServerTestHelper.create('cli_test_srv3')

      rsp = cptr("images:add #{@image_name1} #{@server.name} -m e=mc2,pv=nRT")

      rsp.stderr.should eq("")
      rsp.stdout.should include("Created image '#{@image_name1}'")
      rsp.exit_status.should be_exit(:success)
      new_image_id = rsp.stdout.scan(/'([^']+)/)[2][0]

      image = HP::Cloud::Images.new.get(@image_name1)
      image.id.should eq(new_image_id)
      hshstr = image.meta.to_s
      hshstr.should include('e=mc2')
      hshstr.should include('pv=nRT')
    end

    after(:each) do
      cptr("images:remove #{@image_name1}")
    end
  end

  context "images:add with valid avl" do
    it "should report success" do
      @image_name2 = resource_name("add2")
      @server = ServerTestHelper.create('cli_test_srv2')

      rsp = cptr("images:add #{@image_name2} #{@server.name} -z #{REGION}")

      rsp.stderr.should eq("")
      rsp.stdout.should include("Created image '#{@image_name2}'")
      rsp.exit_status.should be_exit(:success)
    end

    after(:each) do
      cptr("images:remove #{@image_name2}")
    end
  end

  context "images:add with invalid avl" do
    it "should report error" do
      rsp = cptr("images:add image server -z blah")

      rsp.stderr.should include("Please check your HP Cloud Services account to make sure the 'Compute' service is activated for the appropriate availability zone.\n")
      rsp.stdout.should eq("")
      rsp.exit_status.should be_exit(:general_error)
    end
    after(:all) { Connection.instance.clear_options() }
  end

  context "verify the -a option is activated" do
    it "should report error" do
      @server = ServerTestHelper.create('cli_test_srv1')
      AccountsHelper.use_tmp()

      rsp = cptr("images:add -a bogus image_name #{@server.name}")

      tmpdir = AccountsHelper.tmp_dir()
      rsp.stderr.should eq("Could not find account file: #{tmpdir}/.hpcloud/accounts/bogus\n")
      rsp.stdout.should eq("")
      rsp.exit_status.should be_exit(:general_error)
    end
    after(:all) {reset_all()}
  end
end
