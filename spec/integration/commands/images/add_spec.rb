require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe "images:add command" do
  def cli
    @cli ||= HP::Cloud::CLI.new
  end

  before(:all) do
    @hp_svc = compute_connection
    @flavor_id = OS_COMPUTE_BASE_FLAVOR_ID
    @image_id = OS_COMPUTE_BASE_IMAGE_ID
  end

  context "when creating image with name, server and defaults" do
    before(:all) do
      @server_name = resource_name("iadd")
      @image_name = resource_name("add")
      @server = @hp_svc.servers.create(:flavor_id => @flavor_id, :image_id => @image_id, :name => @server_name )
      @server.wait_for { ready? }

      @response, @exit = run_command("images:add #{@image_name} #{@server_name}").stdout_and_exit_status
      @new_image_id = @response.scan(/'([^']+)/)[2][0]
    end

    it "should show success message" do
      @response.should include("Created image '#{@image_name}'")
    end
    its_exit_status_should_be(:success)

    it "should list id in images" do
      images = @hp_svc.images.map {|i| i.id}
      images.should include(@new_image_id)
    end
    it "should list name in images" do
      images = @hp_svc.images.map {|i| i.name}
      images.should include(@image_name)
    end

    after(:all) do
      @hp_svc.images.get(@new_image_id).destroy
      @server.destroy
    end
  end

  context "with avl settings passed in" do
    before(:all) do
      @image_name2 = resource_name("add2")
      @server_name2 = resource_name("iadd2")
    end
    context "images:add with valid avl" do
      before(:all) do
        @server2 = @hp_svc.servers.create(:flavor_id => @flavor_id, :image_id => @image_id, :name => @server_name2 )
        @server2.wait_for { ready? }
      end
      it "should report success" do
        response, exit_status = run_command("images:add #{@image_name2} #{@server_name2} -z az-1.region-a.geo-1").stdout_and_exit_status
        @image_id2 = response.scan(/'([^']+)/)[2][0]
        response.should include("Created image '#{@image_name2}'")
        exit_status.should be_exit(:success)

      end
      after(:all) do
        @hp_svc.images.get(@image_id2).destroy
        @server2.destroy
      end
    end
    context "images:add with invalid avl" do
      it "should report error" do
        response, exit_status = run_command("images:add #{@image_name2} #{@server_name2} -z blah").stderr_and_exit_status
        response.should include("Please check your HP Cloud Services account to make sure the 'Compute' service is activated for the appropriate availability zone.\n")
        exit_status.should be_exit(:general_error)
      end
    end
  end

end