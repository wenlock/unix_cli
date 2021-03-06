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

module HP
  module Cloud
    class CLI < Thor

      map %w(addresses:allocate) => 'addresses:add'

      desc "addresses:add", "Allocate a new public IP address."
      long_desc <<-DESC
  Add or allocate a new public IP address from the pool of available IP addresses.  If a network is not specified, the first external network found will be used.

Examples:
  hpcloud addresses:add # Add a new public IP address to external network
  hpcloud addresses:add -n netty # Add a new IP address to `netty`

Aliases: addresses:allocate
      DESC
      method_option :network,
                    :type => :string, :aliases => '-n',
                    :desc => 'Name or id of the network associated with this IP.'
      method_option :port,
                    :type => :string, :aliases => '-p',
                    :desc => 'Name or id of the port associated with this IP.'
      method_option :fixed_ip,
                    :type => :string,
                    :desc => 'Fixed IP address to associate with this IP.'
      method_option :floating_ip,
                    :type => :string,
                    :desc => 'Floating IP to assign.'
      CLI.add_common_options
      define_method "addresses:add" do
        cli_command(options) {
          address = FloatingIpHelper.new(Connection.instance)
          address.set_network(options[:network])
          address.port = options[:port]
          address.fixed_ip = options[:fixed_ip]
          address.floating_ip = options[:floating_ip]
          if address.save
            @log.display "Created a public IP address '#{address.ip}'."
          else
            @log.fatal address.cstatus
          end
        }
      end
    end
  end
end
