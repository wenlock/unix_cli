require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Move command" do
  
  before(:all) do
    purge_buckets
    @kvs = storage_connection
    @kvs.put_bucket('move_source_bucket')
    @kvs.put_bucket('move_target_bucket')
  end
  
  context "Moving an object inside of a bucket" do
    
    context "when source bucket can't be found" do
      it "should display error message" do
        response = capture(:stderr){ HPCloud::CLI.start(['move', ':missing_bucket/missing_file', ':missing_bucket/new/my_file']) }
        response.should eql("You don't have a bucket 'missing_bucket'.\n")
      end
    end
    
    context "when target file can't be found" do
      it "should display error message" do
        response = capture(:stderr){ HPCloud::CLI.start(['move', ':move_source_bucket/missing_file', ':move_source_bucket/new/my_file']) }
        response.should eql("The specified object does not exist.\n")
      end
    end
    
    pending "when destination file can't be written" do
    end
    
    context "when move is completed successfully" do
      
      before(:all) do
        @kvs.put_object('move_source_bucket', 'foo.txt', read_file('foo.txt'))
        @response = capture(:stdout){ HPCloud::CLI.start(['move', ':move_source_bucket/foo.txt', ':move_source_bucket/new/foo.txt']) }
      end
      
      it "should have created new object at destination" do
        @kvs.head_object('move_source_bucket', 'new/foo.txt').status.should eql(200)
      end
      
      it "should have removed source object" do
        lambda {
          @kvs.head_object('move_source_bucket', 'foo.txt')
        }.should raise_error(Excon::Errors::NotFound)
      end
      
      it "should display success message" do
        @response.should eql("Moved :move_source_bucket/foo.txt => :move_source_bucket/new/foo.txt\n")
      end
      
    end
    
  end
  
  context "Moving an object between buckets" do
    
    # context "when target file can't be found" do
    #   it "should display error message" do
    #     response = capture(:stderr){ HPCloud::CLI.start(['move', ':missing_bucket/missing_file', ':my_bucket']) }
    #     response.should eql("The object 'missing_bucket/missing_file' cannot be found.\n")
    #   end
    # end
    
  end
  
  context "Moving an object from a bucket to the local filesystem" do
    
  end
  
  context "Trying to move a non-object resource" do
    it "should give error message" do
      response = capture(:stderr){ HPCloud::CLI.start(['move', 'spec/fixtures/files/foo.txt', ':my_bucket']) }
      response.should eql("Move is limited to objects within buckets. Please use 'hpcloud copy' instead.\n")
    end
  end
  
  after(:all) do
    purge_bucket('move_source_bucket')
    purge_bucket('move_target_bucket')
  end
  
end