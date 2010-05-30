
require 'spec/spec_helper'

describe FileGroup do
  describe "#sorted_tests_in_groups" do
  end

  describe "#distribute_tests_in_groups" do
    it "partitions by round-robin when not sorting" do
      files = ["file1.rb", "file2.rb", "file3.rb", "file4.rb"]
      file_group = FileGroup.new(files, 2, options[:no_sort] = true)
      file_group.should_receive(:find_tests).and_return(files)

      groups = file_group.distribute_tests_in_groups 
      groups[0].should == ["file1.rb", "file3.rb"]
      groups[1].should == ["file2.rb", "file4.rb"]
    end
  end

  describe "#find_tests_with_sizes" do
    it "groups when given an array of files" do
      list_of_files = Dir["spec/**/*_spec.rb"]
      found = FileGroup.new(list_of_files, 2, {}).send(:find_tests_with_sizes)
      found.should =~ list_of_files.map{ |file| [file, File.stat(file).size]}
    end
  end

  describe ".get" do
    it "does not sort when passed false do_sort option" do
      options = [[], 1, {:no_sort => true}]
      file_group = FileGroup.new *options
      FileGroup.stub!(:new).and_return(file_group)

      file_group.should_not_receive(:sorted_tests_in_groups)
      file_group.should_receive(:distribute_tests_in_groups)
      FileGroup.get(*options)
    end

    it "does sort when not passed do_sort option" do
      options = [[], 1, {}]
      file_group = FileGroup.new *options
      FileGroup.stub!(:new).and_return(file_group)

      file_group.should_receive(:sorted_tests_in_groups)
      FileGroup.get(*options)
    end

    it "does sort when passed false no_sort option" do
      options = [[], 1, {:no_sort => false}]
      file_group = FileGroup.new *options
      FileGroup.stub!(:new).and_return(file_group)

      file_group.should_receive(:sorted_tests_in_groups)
      FileGroup.get(*options)
    end
  end
end

