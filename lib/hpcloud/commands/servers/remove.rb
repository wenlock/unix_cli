module HP
  module Cloud
    class CLI < Thor

      map %w(servers:delete servers:del) => 'servers:remove'

      desc "servers:remove <id>", "remove a server by id"
      long_desc <<-DESC
  Remove an existing server by specifying its id.

Examples:
  hpcloud servers:remove i-00000001          # delete 'i-00000001'

Aliases: servers:delete, servers:del
      DESC
      define_method "servers:remove" do |id|
        begin
          # setup connection for compute service
          compute_connection = connection(:compute)
          #server = compute_connection.servers.get(id)
          compute_connection.servers.filters = {'instance-id' => ["#{id}"]}
          server = compute_connection.servers.first
        rescue Excon::Errors::Forbidden => error
          display_error_message(error, :permission_denied)
        end
        if server
          begin
            server.destroy
            display "Removed server '#{id}'."
          rescue Excon::Errors::Conflict, Excon::Errors::Forbidden => error
            display_error_message(error)
          end
        else
          error "You don't have a server with '#{id}'.", :not_found
        end
      end

    end
  end
end