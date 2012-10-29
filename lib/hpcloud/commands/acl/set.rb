module HP
  module Cloud
    class CLI < Thor
    
      desc 'acl:set <resource> <acl>', "Set a given resource to a canned ACL."
      long_desc <<-DESC
  Set the Access Control List (ACL) values for the specified containers. The supported ACL settings are private or public-read. Optionally, you can select a specific availability zone.

Examples:
  hpcloud acl:set :my_container public-read    # Set the 'my_container' ACL value to public-read.
  hpcloud acl:set :my_container private        # Set the 'my_container' ACL value to private.
  hpcloud acl:set :my_container public-read -z region-a.geo-1  # Set 'my_container' ACL to public-read for an availability zone.

      DESC
      CLI.add_common_options
      define_method 'acl:set' do |resource, acl|
        cli_command(options) {
          acl = acl.downcase
          unless CANNED_ACLS.include?(acl)
            error "Your ACL '#{acl}' is invalid.\nValid options are: #{CANNED_ACLS.join(', ')}."
          end
          type = Resource.detect_type(resource)
          container, key = Container.parse_resource(resource)

          dir = Connection.instance.storage.directories.get(container)
          if type == :object
            if dir
              file = dir.files.get(key)
              if file
                # since setting acl at object level is not supported, so just making parent directory public
                dir.acl = acl
                dir.save
                display "ACL for #{resource} updated to #{acl}."
              else
                error "No object exists at '#{container}/#{key}'.", :not_found
              end
            else
              error "No object exists at '#{container}/#{key}'.", :not_found
            end
          elsif type == :container
            if dir
              dir.acl = acl
              dir.save
              display "ACL for #{resource} updated to #{acl}."
            else
              error "No container named '#{container}' exists.", :not_found
            end
          else
            error 'Setting ACLs is only supported for containers and objects.', :not_supported
          end
        }
      end
    end
  end
end
