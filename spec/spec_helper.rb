$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'scalene'

require 'helpers/connections'
require 'helpers/io'

RSpec.configure do |config|
  
  # export KVS_TEST_HOST=16.49.184.31
  # build/opt-centos5-x86_64/bin/stout-mgr create-account -port 9233 "Unix CLI" "unix.cli@hp.com"
  #
  # http://16.49.184.32:9242/kvs/keygen.html
  KVS_ACCESS_ID = '85449051cf697c675ac3077217f4df39aab00c45'
  KVS_SECRET_KEY = '7cdcc353822b28a61665139de935fae2a869c0f7'
  KVS_ACCOUNT_ID = '807902568678'
  KVS_HOST = '16.49.184.32'
  KVS_PORT = '9242'

  # Generate a unique bucket name
  # def bucket_name(seed=random_string(5))
  #   'fog_' << HOSTNAME << '_' << Time.now.to_i.to_s << '_' << seed.to_s 
  # end

  # Delete any buckets this connection currently has
  def purge_buckets(connection = nil, verbose = false)
    connection ||= storage_connection
    connection.directories.each do |directory|
      purge_bucket(directory.key, :connection => connection, :verbose => verbose)
    end
  end

  # Delete a single bucket, regardless of files present
  def purge_bucket(bucket_name, options={})
    connection = options[:connection] || @kvs
    verbose = options[:verbose] || false
    begin
      puts "Deleting '#{bucket_name}'" if verbose
      connection.delete_bucket(bucket_name)
    rescue Excon::Errors::NotFound # bucket is listed, but does not currently exist
    rescue Excon::Errors::Forbidden
      connection.put_bucket_acl(bucket_name, standard_acl)
      purge_bucket(bucket_name, options)
    rescue Excon::Errors::Conflict # bucket has files in it
      begin
        connection.directories.get(bucket_name).files.each do |file|
          begin
            puts "  - removing file '#{file.key}'" if verbose
            file.destroy
          end
        end
        connection.delete_bucket(bucket_name)
      rescue Excon::Errors::Forbidden
        connection.put_bucket_acl(bucket_name, standard_acl)
        purge_bucket(bucket_name, options)
      end
    end
  end

  def create_bucket_with_files(bucket_name, *files)
    #bucket_name = bucket_name(bucket_seed)
    @kvs.put_bucket(bucket_name)
    files.each do |file_name|
      @kvs.put_object(bucket_name, file_name, read_file(file_name))
    end
    bucket_name
  end

  def read_file(filename)
    read_fixture(:file, filename)
  end
  
  def read_account_file(filename)
    read_fixture(:account, filename)
  end
  
  def read_fixture(type, filename)
    dir_name = type.to_s + "s" # simple pluralize
    File.read(File.dirname(__FILE__) + "/fixtures/#{dir_name}/#{filename}")
  end
  
  def setup_temp_home_directory
    HP::Scalene::Config.home_directory = File.expand_path(File.dirname(__FILE__) + '/tmp/home')
    Dir.mkdir(HP::Scalene::Config.home_directory) unless File.directory?(HP::Scalene::Config.home_directory)
  end


end

