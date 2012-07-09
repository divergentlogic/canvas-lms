require File.dirname(__FILE__) + '/spec_helper'

describe Moodle::Converter do

  before(:all) do
    fixture_dir = require File.dirname(__FILE__) + '/fixtures'
    archive_file_path = File.join(fixture_dir, 'non_existent_moodle_1_9.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "moodle_#{File.basename(archive_file_path, '.zip')}", 'oi')
    convert_folder = File.join(File.dirname(archive_file_path), "moodle_test_export")
    @exporter = Moodle::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    @converter.export
    @course_data = @converter.course.with_indifferent_access
    @converter.delete_unzipped_archive
    if File.exists?(convert_folder)
      FileUtils::rm_rf(convert_folder)
    end
  end

  before(:each) do
    @course = Course.create(:name => "test course")
    @cm = ContentMigration.create(:context => @course)
  end

  # you can test by importing individual types
  it "should convert discussion topics" do
    DiscussionTopic.process_migration(@course_data, @cm)
    @cm.migration_settings[:warnings].should be_nil
    @course.discussion_topics.count.should == 6

    dt = @course.discussion_topics.find_by_migration_id('33')
    dt.title.should == "Topic title"
    dt.message.should == "No message"
  end

  # Or you can import the whole course
  it "should successfully import the course" do
    @course.import_from_migration(@course_data, nil, @cm)

    # everything should be imported

    # This is slower though. You can put it in the before(:all) but that doesn't
    # clean up after itself, so that's annoying
    # You can try to that in the before(:each), if it's not too slow that'll work great
  end

end