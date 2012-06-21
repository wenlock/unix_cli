require 'hpcloud/connection.rb'
require 'progressbar'
include HP::Cloud

module HP
  module Cloud
    class Resource
      attr_reader :fname, :ftype, :container, :path
      attr_reader :destination, :error_string, :error_code
    
      REMOTE_TYPES = [:container, :container_directory, :object]
      LOCAL_TYPES = [:directory, :file]
    
      def self.create(fname)
        if LOCAL_TYPES.include?(detect_type(fname))
          return LocalResource.new(fname)
        end
        return RemoteResource.new(fname)
      end

      def initialize(fname)
        @error_string = nil
        @error_code = nil
        @fname = fname
        @ftype = Resource.detect_type(@fname)
        parse()
      end

      class << self
        protected :new
      end

      def isLocal()
        return Resource::LOCAL_TYPES.include?(@ftype)
      end

      def isRemote()
        return Resource::REMOTE_TYPES.include?(@ftype)
      end

      def isDirectory()
        return @ftype == :directory
      end

      def isFile()
        return @ftype == :file
      end

      def isObject()
        return @ftype == :object
      end

      def self.detect_type(resource)
        if resource[0,1] == ':'
          if resource[-1,1] == '/'
            :container_directory
          elsif resource.index('/')
            :object
          else
            :container
          end
        elsif resource[-1,1] == '/'
          :directory
        else
          if File.directory?(resource)
            :directory
          else
            :file
          end
        end
      end
    
      def parse()
        @container = nil
        @path = nil
        if @fname.empty?
          return
        end
        if @fname[0,1] == ':'
          @container, *rest = @fname.split('/')
          @container = @container[1..-1] if @container[0,1] == ':'
          @path = rest.empty? ? '' : rest.join('/')
        else
          rest = @fname.split('/')
          @path = rest.empty? ? '' : rest.join('/')
        end
      end

      def get_mime_type()
        # this probably needs some security lovin'
        full_mime = `file --mime -b #{@fname}`
        full_mime.split(';')[0].chomp
      end

      def get_size()
        return File.size(@fname)
      end

      def valid_source()
        return true
      end

      def valid_destination()
        return true
      end

      def set_destination(from)
        return true
      end

      def open(output=false, siz=0)
        return false
      end

      def read()
        return nil
      end

      def write(data)
        return false
      end

      def close()
        return false
      end

      def copy(from)
        return false
      end

      def foreach(&block)
        return
      end
    end

    class LocalResource < Resource

      def valid_source()
        if !File.exists?(@fname)
          @error_string = "File not found at '#{@fname}'."
          @error_code = :not_found
          return false
        end
        return true
      end

      def set_destination(from)
        @destination = @path
        if isDirectory()
          @destination = "#{@destination}/#{File.basename(from.path)}"
        end
        dir_path = File.expand_path(File.dirname(@destination))
        if !File.directory?(dir_path)
          dname = File.dirname(@destination)
          @error_string = "No directory exists at '#{dname}'."
          @error_code = :not_found
          return false
        end
        return true
      end

      def open(output=false, siz=0)
        close()
        @lastread = 0
        begin
          if (output == true)
            @pbar = ProgressBar.new(File.basename(@destination), siz)
            @file = File.open(@destination, 'w')
          else
            @pbar = ProgressBar.new(File.basename(@fname), get_size())
            @file = File.open(@fname, 'r')
          end
        rescue Exception => e
          @error_string = e.to_s
          @error_code = :permission_denied
          return false
        end
        return true
      end

      def read()
        @pbar.inc(@lastread)
        val = @file.read(Excon::CHUNK_SIZE).to_s
        @lastread = val.length
        return val
      end

      def write(data)
        @file.write(data)
        return true
      end

      def close()
        unless @pbar.nil?
          @pbar.inc(@lastread) unless @lastread.nil?
          @pbar.finish
        end
        @lastread = 0
        @pbar = nil
        @file.close unless @file.nil?
        @file = nil
        return true
      end

      def copy(from)
        if ! from.valid_source() then return false end
        if ! set_destination(from) then return false end
        if ! open(true) then return false end

        result = true
        if from.isLocal()
          if (from.open() == true)
            while ((chunk = from.read()) != nil) do
              if chunk.empty?
                break
              end
              if ! write(chunk.to_s) then result = false end
            end
            result = from.close()
          else
            result = false
          end
        else
          Connection.instance.storage.get_object(from.container, from.path) { |chunk, remaining, total|
            if ! write(chunk) then result = false end
          }
        end
        if ! close() then return false end
        return result
      end

      def foreach(&block)
        yield self
        if (isDirectory() == false)
          return
        end
        Dir.foreach(path) { |x|
          if ((x != '.') && (x != '..')) then
            Resource.create(path + '/' + x).foreach(&block)
          end
        }
      end
    end

    class RemoteResource < Resource
      def valid_source()
        return valid_container()
      end

      def valid_container()
        begin
          connection = Connection.instance.storage()
          directory = connection.directories.get(@container)
          if directory.nil?
            @error_string = "You don't have a container '#{@container}'."
            @error_code = :not_found
            return false
          end
        rescue Excon::Errors::Forbidden => e
          resp = ErrorResponse.new(e)
          # @error_string  = "You don't have permission to access the container '#{@container}'."
          @error_string  = resp.error_string
          @error_code = :permission_denied
          return false
        end
        return true
      end

      def set_destination(from)
        if ! valid_container()
          return false
        end
        if @path.to_s.empty?
          @destination = File.basename(from.path)
        elsif @fname[-1,1] == '/'
          @destination = @path + '/' + File.basename(from.path)
        else
          @destination = @path
        end
        return true
      end

      def copy(from)
        if ! from.valid_source() then return false end
        if ! set_destination(from) then return false end
        if from.isLocal()
          if (from.open() == false) then return false end
          options = { 'Content-Type' => from.get_mime_type() }
          Connection.instance.storage.put_object(@container, @destination, {}, options) {
            return from.read(Excon::CHUNK_SIZE).to_s
          }
          return from.close()
        else
          begin
            Connection.instance.storage.put_object(@container, @path, nil, {'X-Copy-From' => "/#{from.container}/#{from.path}" })
          rescue Fog::Storage::HP::NotFound => e
            @error_string = "The specified object does not exist."
            @error_code = :not_found
            return false
          end
        end
        return true
      end

      def foreach(&block)
        connection = Connection.instance.storage()
        directory = connection.directories.get(@container)
        return if directory.nil?
        directory.files.each { |x|
          puts '==== ' + x.to_s + " match: ^" +  path.to_s
          yield Resource.create(':' + container + '/' + x) if ! x.match("^" + path).nil?
        }
      end
    end
  end
end
