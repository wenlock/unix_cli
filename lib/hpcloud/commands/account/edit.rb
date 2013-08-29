require 'hpcloud/accounts'

module HP
  module Cloud
    class CLI < Thor

      map %w(account:add account:setup account:update) => 'account:edit'

      desc 'account:edit <account_name> [name_value_pair ...]', "Create or edit your account credentials."
      long_desc <<-DESC
  Create or edit your account credentials. If you do not specify an account name on the command line, the default account is updated.  If you do not specify name value pairs, you are prompted to input the account values.

  You  need your Access Key Id, Secret Key and Project (aka Tenant) Id from the HP Cloud web site to set up your account. Optionally, you can specify your own endpoint to authorize your identity, but in most cases we recommend you use the default.
  
  Availability zones typically have the format 'az-1.region-a.geo-1' or 'region-a.geo-1', depending on the service.  See your account API keys page to see your list of activated availability zones: https://console.hpcloud.com/account/api_keys or use the `account:catalog` command to print out your service catalog.
  
  You can re-run this command at any time to modify your settings.

  The interactive mode prompts you for the following values:
  
  * Access Key Id
  * Secret Key 
  * Project (aka Tenant) Id
  * Identify (Auth) Uri
  * Various zones and regions you have activated

  The command line mode allows you to set the following values:
#{Accounts.get_known}
  
Examples:
  hpcloud account:setup # Create or edit the default account interactively
  hpcloud account:edit  # Edit the default account settings interactively
  hpcloud account:edit pro auth_uri='https://127.0.0.1/' block_availability_zone='az-2.region-a.geo-1' # Set the account credential authorization URI to `https://127.0.0.1\` and the block availability zone to `az-2.region-a.geo-1`
  hpcloud account:setup rackspace -p rackspace # Create a Rackspace account for migration

Aliases: account:add, account:setup, account:update
      DESC
      method_option 'userpass', :type => :boolean,
                    :desc => "Use username/password authentication instead of authentication keys"
      method_option 'no-validate', :type => :boolean, :aliases => '-n',
                    :default => false,
                    :desc => "Don't verify account settings during edit"
      method_option 'provider', :type => :string, :aliases => '-p',
                    :desc => "Cloud provider for migration: AWS, Rackspace, or Google"
      define_method "account:edit" do |*args|
        cli_command(options) {
          if args.empty?
            config = Config.new(true)
            name = config.get(:default_account)
          else
            name = args.shift
          end
          accounts = HP::Cloud::Accounts.new()
          if args.empty?
            begin
              acct = accounts.read(name)
            rescue Exception => e
              acct = accounts.create(name)
            end
            acct[:provider] ||= 'hp'
            unless options[:provider].nil?
              provider = options[:provider].downcase
              if provider != acct[:provider]
                acct[:provider] = provider
                acct[:options] = {}
                acct[:credentials] = {}
                acct[:regions] = {}
              end
            end
            cred = acct[:credentials]

            # ask for credentials
            case acct[:provider]
            when "hp"
              service_name = "HP Cloud Services"
              @log.display "****** Setup your #{service_name} #{name} account ******"
              unless options[:userpass].nil?
                if options[:userpass] == true
                  cred[:userpass] = options[:userpass]
                else
                  cred[:userpass] = nil
                end
              end
              if cred[:userpass] == true
                cred[:account_id] = ask_with_default 'User name:', "#{cred[:account_id]}"
                cred[:secret_key] = ask_with_default 'Password:', "#{cred[:secret_key]}"
              else
                cred[:account_id] = ask_with_default 'Access Key Id:', "#{cred[:account_id]}"
                cred[:secret_key] = ask_with_default 'Secret Key:', "#{cred[:secret_key]}"
              end
              cred[:tenant_id] = ask_with_default 'Project (aka Tenant) Id:', "#{cred[:tenant_id]}"
              cred[:auth_uri] = ask_with_default 'Identity (Auth) Uri:', "#{cred[:auth_uri]}"
            when "aws"
              service_name = "AWS"
              @log.display "****** Setup your #{service_name} #{name} account ******"
              cred[:aws_access_key_id] = ask_with_default 'Access Key ID:', "#{cred[:aws_access_key_id]}"
              cred[:aws_secret_access_key] = ask_with_default 'Secret Access Key:', "#{cred[:aws_secret_access_key]}"
              acct[:options] = {}
              acct[:regions] = {}
            when "rackspace"
              service_name = "Rackspace"
              @log.display "****** Setup your #{service_name} #{name} account ******"
              cred[:rackspace_username] = ask_with_default 'Username:', "#{cred[:rackspace_username]}"
              cred[:rackspace_api_key] = ask_with_default 'API Key:', "#{cred[:rackspace_api_key]}"
              acct[:options] = {}
              acct[:regions] = {}
            when "google"
              service_name = "Google"
              @log.display "****** Setup your #{service_name} #{name} account ******"
              cred[:google_storage_access_key_id] = ask_with_default 'Storage access key id:', "#{cred[:google_storage_access_key_id]}"
              cred[:google_storage_secret_access_key] = ask_with_default 'Storage secret access key:', "#{cred[:google_storage_secret_access_key]}"
              acct[:options] = {}
              acct[:regions] = {}
            else
              @log.error "Provider '#{acct[:provider]}' not recognized.  Supported providers include hp, aws and rackspace."
              @log.fatal "If your provider is not supported, you may manually create an account configuration file in the ~/.hpcloud/accounts directory."
            end

            # update credentials and stash in config directory
            accounts.set_cred(name, cred)
            accounts.write(name)

            unless options['no-validate']
              @log.display "Verifying your #{service_name} account..."
              if cred[:auth_uri].nil?
                identifier = cred.to_s
              else
                identifier = cred[:auth_uri]
              end

              begin
                cata = Connection.instance.catalog(name, [])
                regions = acct[:regions]
                if acct[:provider] == "hp"
                  services = []
                  cata.keys.each { |x| services << x.to_s }
                  services.sort!
                  services.each { |service|
                    zone = "#{service.downcase}".to_sym
                    regs = []
                    cata[service.to_sym].keys.each { |x| regs << x.to_s }
                    regs.sort!
                    default_region = regions[zone] || regs.first.to_s
                    az = regs.join(',')
                    unless service == "Image Management" || service == "Identity"
                      regions[zone] = ask_with_default "#{service} region (#{az}):", "#{default_region}"
                    end
                  }
                end
                acct[:regions] = regions
                accounts.set_regions(name, regions)
                accounts.write(name)
              rescue Exception => e
                e = ErrorResponse.new(e).to_s
                @log.error "Account verification failed. Error connecting to the service endpoint at: '#{identifier}'. Please verify your account credentials. \n Exception: #{e}"
              end
            end

            @log.display "Account credentials for #{service_name} have been saved."
            unless acct[:provider] == "hp"
              @log.display "Accounts for providers other than HP are only supported for migration"
            end
          else
            acct = accounts.read(name, true)
            updated = ""
            args.each { |nvp|
              sub_command {
                k, v = Config.split(nvp)
                accounts.set(name, k, v)
                updated += " " if updated.empty? == false
                updated += nvp
              }
            }
            if updated.empty? == false
              accounts.write(name)
              @log.display "Account '#{name}' set " + updated
            end
          end
        }
      end
    end
  end
end
