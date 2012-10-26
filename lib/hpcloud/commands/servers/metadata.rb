require 'hpcloud/servers'
require 'hpcloud/metadata'

module HP
  module Cloud
    class CLI < Thor

      map 'servers:metadata:list' => 'servers:metadata'

      desc "servers:metadata <name_or_id>", "List the metadata for a server."
      long_desc <<-DESC
  List the metadata for a server in your compute account. You may specify either the name or the id of the server.  Optionally, an availability zone can be passed.

Examples:
  hpcloud servers:metadata Skynet                        # List server metadata
  hpcloud servers:metadata -z az-2.region-a.geo-1 565394 # List server metadata for an availability zone

Aliases: servers:metadata:list
      DESC
      CLI.add_common_options
      define_method "servers:metadata" do |name_or_id|
        cli_command(options) {
          server = Servers.new.get(name_or_id)
          if server.is_valid?
            hsh = server.meta.to_hash()
            Tableizer.new(options, Metadata.get_keys(), hsh).print
          else
            error server.error_string, server.error_code
          end
        }
      end
    end
  end
end
