require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Remove command," do
  
  before(:all) do
    @kvs = storage_connection
  end
  
  context "removing an object from bucket" do

    before(:all) do
      purge_bucket('my_bucket')
      create_bucket_with_files('my_bucket', 'foo.txt')
    end

    context "when object does not exist" do
      it "should exit with object not found" do
        response = capture(:stderr){ HPCloud::CLI.start(['remove', ':my_bucket/nonexistant.txt']) }
        response.should eql("You don't have a object named 'nonexistant.txt'.\n")
      end
    end
    
    context "when bucket does not exist" do
      it "should exit with bucket not found" do
        response = capture(:stderr){ HPCloud::CLI.start(['remove', ':nonexistant_bucket']) }
        response.should eql("You don't have a bucket named 'nonexistant_bucket'\n")
      end
    end
    
    context "when object and bucket exist" do
      before(:all) do
      end
      it "should report success" do
        response = capture(:stdout){ HPCloud::CLI.start(['remove', ':my_bucket/foo.txt']) }
        response.should eql("Removed object ':my_bucket/foo.txt'.\n")
      end
    end

    context "when syntax is not correct" do
      it "should exit with message about bad syntax" do
        response = capture(:stderr){ HPCloud::CLI.start(['remove', '/foo/foo']) }
        response.should eql("Could not find resource '/foo/foo'. Correct syntax is :bucketname/objectname.\n")
      end
    end

    after(:all) do
    end

  end

  
end