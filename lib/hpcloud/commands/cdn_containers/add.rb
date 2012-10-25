module HP
  module Cloud
    class CLI < Thor

      desc "cdn:containers:add <name>", "add a container to the CDN"
      long_desc <<-DESC
  Add an existing container from your storage account to the CDN. Container name can be specified with or without the preceding colon: 'my_container' or ':my_container'. Optionally, an availability zone can be passed.

Examples:
  hpcloud cdn:containers:add :my_cdn_container                    # Creates a new container called 'my_cdn_container'
  hpcloud cdn:containers:add :my_cdn_container -z region-a.geo-1  # Optionally specify an availability zone
      DESC
      CLI.add_common_options
      define_method "cdn:containers:add" do |name, *names|
        cli_command(options) {
          names = [name] + names
          names.each { |name|
            name = Container.container_name_for_service(name)
            begin
              if Connection.instance.storage.directories.get(name)
                response = Connection.instance.cdn.put_container(name)
                display "Added container '#{name}' to the CDN."
              else
                error_message "The container '#{name}' does not exist in your storage account. Please create the storage container first and then add it to the CDN.", :incorrect_usage
              end
            rescue Fog::Storage::HP::NotFound
              error_message "The container '#{name}' does not exist in your storage account. Please create the storage container first and then add it to the CDN.", :incorrect_usage
            end
          }
        }
      end
    end
  end
end
