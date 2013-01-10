module HP
  module Cloud
    class CLI < Thor

      desc 'migrate <source_account> <source> [source ...] <destination>', "Migrate files from a provider described by the source account."
      long_desc <<-DESC
  This command works similarly to the copy command except the first argument is the source account.  The source objects may be containers or objects or regular expressions.

Examples:
  hpcloud migrate aws :aws_tainer :hp_tainer # Migrate ojbects from the AWS :aws_tainer container to the :hp_tainer container
  hpcloud migrate rackspace :rackspace1 :rackspace2 :hp_tainer # Migrate ojbects from the two containers in the rackspace account to the :hp_tainer container

      DESC
      method_option :mime,
                    :type => :string, :aliases => '-m',
                    :desc => 'Set the MIME type of the remote object.'
      CLI.add_common_options
      def migrate(source_account, source, *destination)
        cli_command(options) {
          last = destination.pop
          source = [source] + destination
          destination = last
          to = ResourceFactory.create_any(Connection.instance.storage, destination)
          if source.length > 1 && to.isDirectory() == false
            @log.fatal("The destination '#{destination}' for multiple files must be a directory or container")
          end
          source.each { |name|
            from = ResourceFactory.create_any(Connection.instance.storage(source_account), name)
            from.set_mime_type(options[:mime])
            if to.copy(from)
              @log.display "Migrated #{from.fname} => #{to.fname}"
            else
              @log.fatal to.cstatus
            end
          }
        }
      end
    end
  end
end