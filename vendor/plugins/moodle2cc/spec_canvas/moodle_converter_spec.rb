require File.dirname(__FILE__) + '/spec_helper'

describe Moodle::Converter do

  before(:all) do
    fixture_dir = File.dirname(__FILE__) + '/fixtures'
    archive_file_path = File.join(fixture_dir, 'moodle_backup_1_9.zip')
    unzipped_file_path = File.join(File.dirname(archive_file_path), "moodle_#{File.basename(archive_file_path, '.zip')}", 'oi')
    @converter = Moodle::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    @converter.export
    @course_data = @converter.course.with_indifferent_access
    @converter.delete_unzipped_archive
    if File.exists?(unzipped_file_path)
      FileUtils::rm_rf(unzipped_file_path)
    end
  end

  before(:each) do
    @course = Course.create(:name => "test course")
    @cm = ContentMigration.create(:context => @course)
  end

  it "should convert discussion topics" do
    DiscussionTopic.process_migration(@course_data, @cm)
    @cm.migration_settings[:warnings].should be_nil
    @course.discussion_topics.count.should == 1

    dt = @course.discussion_topics.first
    dt.title.should == "News forum"
    dt.message.should == "<p>General news and announcements</p>"
  end

  it "should convert assignments" do
    Assignment.process_migration(@course_data, @cm)
    @cm.migration_settings[:warnings].should be_nil
    @course.assignments.count.should == 5

    assignment = @course.assignments[0]
    assignment.title.should == "Create a Rails site"
    assignment.description.should == "<p>Use `rails new` to create your first Rails site</p>"
  end

  it "should convert wikis" do
    # must run twice for link references
    WikiPage.process_migration(@course_data, @cm)
    WikiPage.process_migration(@course_data, @cm)

    @cm.migration_settings[:warnings].should be_nil
    wiki = @course.wiki
    wiki.should_not be_nil
    wiki.wiki_pages.count.should == 3

    page = wiki.wiki_pages[0]
    page.title.should == "My Wiki"
    page.url.should == 'my-wiki-my-wiki'
    html = Nokogiri::HTML(page.body)
    href = html.search('a').first.attributes['href'].value
    href.should == "/courses/#{@course.id}/wiki/my-wiki-link"

    page = wiki.wiki_pages[1]
    page.title.should == "link"
    page.url.should == 'my-wiki-link'

    page = wiki.wiki_pages[2]
    page.title.should == "New Wiki"
    page.url.should == 'new-wiki-new-wiki'
  end

  it "should convert quizzes" do
    @course.import_from_migration(@course_data, nil, @cm)
    @course.quizzes.count.should == 3
  end

  it "should convert Moodle Choice module to a quiz" do
    @course.import_from_migration(@course_data, nil, @cm)
    quiz = @course.quizzes.find_by_title "My Choice"
    quiz.quiz_questions.count.should == 1
    question = quiz.quiz_questions.first
    question.question_data[:question_name].should == "My Choice"
    question.question_data[:question_text].should == "What is your choice?"
  end

  it "should successfully import the course" do
    @course.import_from_migration(@course_data, nil, @cm)

    # everything should be imported

    # This is slower though. You can put it in the before(:all) but that doesn't
    # clean up after itself, so that's annoying
    # You can try to that in the before(:each), if it's not too slow that'll work great
  end

end
