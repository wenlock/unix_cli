module HP
  module Cloud
    class CLI < Thor

      map 'cdn:containers:loc' => 'cdn:containers:location'

      desc "cdn:containers:location <name>", "Get the location of a container on the CDN."
      long_desc <<-DESC
  Get the location of an existing container on the CDN. Optionally, an availability zone can be passed.

Examples:
  hpcloud cdn:containers:location :my_cdn_container                     # gets the location of the container 'my_cdn_container'
  hpcloud cdn:containers:location :my_cdn_container -z region-a.geo-1   # Optionally specify an availability zone

Aliases: cdn:containers:loc
      DESC
      method_option :ssl, :default => false,
                    :type => :boolean, :aliases => '-s',
                    :desc => 'Print the ssl version of the url.'
      CLI.add_common_options
      define_method "cdn:containers:location" do |name, *names|
        cli_command(options) {
          names = [name] + names
          names.each { |name|
            resource = Resource.create_remote(Connection.instance.storage, name)
            if resource.read_header
              if options.ssl
                display resource.cdn_public_ssl_url
              else
                display resource.cdn_public_url
              end
            else
              error_message resource.error_string, resource.error_code
            end
          }
        }
      end
    end
  end
end
