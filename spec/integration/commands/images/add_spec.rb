require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe "images:add command" do
  def cli
    @cli ||= HP::Cloud::CLI.new
  end

  before(:all) do
    @hp_svc = compute_connection
    @flavor_id = OS_COMPUTE_BASE_FLAVOR_ID
    @image_id = OS_COMPUTE_BASE_IMAGE_ID
    @server_name = resource_name("iadd")
    @image_name = resource_name("add")
    @server = @hp_svc.servers.create(:flavor_id => @flavor_id, :image_id => @image_id, :name => @server_name )
    @server.wait_for { ready? }
  end

  context "when creating image with name, server and defaults" do
    before(:all) do
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
    end
  end

  after(:all) do
    @server.destroy
  end
end