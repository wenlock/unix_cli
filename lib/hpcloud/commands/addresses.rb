require 'hpcloud/commands/addresses/add'
require 'hpcloud/commands/addresses/remove'
require 'hpcloud/commands/addresses/associate'
require 'hpcloud/commands/addresses/disassociate'

module HP
  module Cloud
    class CLI < Thor

      map 'addresses:list' => 'addresses'

      desc "addresses [ip_or_id ...]", "Display list of available addresses."
      long_desc <<-DESC
  List the available addresses for your account. You may filter the addresses listed by specifying one or more ips or ids on the command line.  Optionally, an availability zone can be passed.

Examples:
  hpcloud addresses                            # List addresses
  hpcloud addresses 127.0.0.2                  # List address 127.0.0.2
  hpcloud addresses -z az-2.region-a.geo-1     # Optionally specify an availability zone

Aliases: addresses:list
      DESC
      CLI.add_common_options
      def addresses(*arguments)
        cli_command(options) {
          addresses = Addresses.new
          if addresses.empty?
            display "You currently have no public IP addresses, use `#{selfname} addresses:add` to create one."
          else
            hsh = addresses.get_hash(arguments)
            if hsh.empty?
              display "There are no ip addresses that match the provided arguments"
            else
              Tableizer.new(options, AddressHelper.get_keys(), hsh).print
            end
          end
        }
      end
    end
  end
end
