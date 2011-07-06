require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Remove command" do

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
        response, exit_status = capture_with_status(:stderr){ HP::Scalene::CLI.start(['remove', ':my_bucket/nonexistant.txt']) }
        response.should eql("You don't have a object named 'nonexistant.txt'.\n")
        exit_status.should be_exit(:not_found)
      end
    end

    context "when bucket does not exist" do
      it "should exit with bucket not found" do
        response, exit_status = capture_with_status(:stderr){ HP::Scalene::CLI.start(['remove', ':nonexistant_bucket']) }
        response.should eql("You don't have a bucket named 'nonexistant_bucket'\n")
        exit_status.should be_exit(:not_found)
      end
    end

    context "when removing an object that isn't controlled by the user" do
      before(:all) do
        @kvs_other_user = storage_connection(:secondary)
        @kvs_other_user.put_container('notmybucket')
        @kvs_other_user.put_object('notmybucket', 'foo.txt', read_file('foo.txt'), {'Content-Type' => 'text/plain'})
        @response, @exit_status = capture_with_status(:stderr){ HP::Scalene::CLI.start(['rm', ':notmybucket/foo.txt']) }
      end

      #### Swift does not have acls, so it just cannot see the bucket
      it "should exit with access denied" do
        @response.should eql("You don't have a bucket named 'notmybucket'\n")
      end

      #### Swift does not have acls, so it just cannot see the bucket
      pending "should exit with denied status" do
        @exit_status.should be_exit(:permission_denied)
      end

      after(:all) do
        purge_bucket('notmybucket', {:connection => @kvs_other_user})
      end
    end

    context "when object and bucket exist" do
      before(:all) do
      end
      it "should report success" do
        response, exit_status = capture_with_status(:stdout){ HP::Scalene::CLI.start(['remove', ':my_bucket/foo.txt']) }
        response.should eql("Removed object ':my_bucket/foo.txt'.\n")
        exit_status.should be_exit(:success)
      end
    end

    context "when syntax is not correct" do
      it "should exit with message about bad syntax" do
        response, exit_status = capture_with_status(:stderr){ HP::Scalene::CLI.start(['remove', '/foo/foo']) }
        response.should eql("Could not find resource '/foo/foo'. Correct syntax is :bucketname/objectname.\n")
        exit_status.should be_exit(:incorrect_usage)
      end
    end

    after(:all) do
    end

  end


end