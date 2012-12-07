module HP
  module Cloud
    class CLI < Thor

      desc "keypairs:private:location <server_name_or_id>", "Find the private key for the given server"
      long_desc <<-DESC
  Find the location of the private key for a given server.

Examples:
  hpcloud keypairs:private:location myserver  # Print the location of the private key for 'myserver'
      DESC
      define_method "keypairs:private:location" do |server_name_or_id|
        cli_command(options) {
          server = Servers.new.get(server_name_or_id)
          if server.is_valid?
            location = KeypairHelper.private_filename("#{server.id}")
            display "The private key for '#{server_name_or_id}' is at '#{location}'."
          else
            error server.error_string, server.error_code
          end
        }
      end
    end
  end
end
