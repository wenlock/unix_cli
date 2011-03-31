require "bundler/setup"
require 'thor'
require 'thor/group'
require 'fog'

require 'hpcloud/version'
require 'hpcloud/config'
require 'hpcloud/resource'
require 'hpcloud/bucket'

module HPCloud
  class CLI < Thor
    
    private
    
    def connection
      return @connection if @connection
      credentials = Config.current_credentials
      if credentials
        @connection ||= Fog::HP::Storage.new( :hp_access_id =>  credentials[:access_id],
                                              :hp_secret_key => credentials[:secret_key],
                                              :hp_account_id => credentials[:email],
                                              :host => credentials[:host],
                                              :port => credentials[:port] )
      else
        error "Please run `hpcloud account:setup` to set up your account."
      end
    end
    
    def display_error_message(error)
      puts parse_error(error.response)
    end
    
    def parse_error(response)
      response.body =~ /<Message>(.*)<\/Message>/
      return $1 if $1
      response.body
    end
    
    ### Thor extensions
    
    def ask_with_default(statement, default, color = nil)
      response = ask("#{statement} [#{default}]")
      return response.empty? ? default : response
    end
    
    def error(message, exit_status=nil)
      puts message
      exit exit_status || 1
    end
    
  end
  
end

require 'hpcloud/commands/info'
require 'hpcloud/commands/account'
require 'hpcloud/commands/buckets'
require 'hpcloud/commands/list'
require 'hpcloud/commands/touch'
require 'hpcloud/commands/copy'
require 'hpcloud/commands/move'
require 'hpcloud/commands/remove'
require 'hpcloud/commands/acl'
require 'hpcloud/commands/location'
require 'hpcloud/commands/versioning'