require "test_helper"

class Studio::NoteTest < ActiveSupport::TestCase
  test "find returns a listed note and nothing else" do
    assert_equal "what-leaves-your-business", Studio::Note.find("what-leaves-your-business").slug
    assert_equal "studio/notes/what_leaves_your_business", Studio::Note.find("what-leaves-your-business").template
    [ "nope", "", nil, "../layouts/studio", "what-leaves-your-business/../index" ].each { |slug| assert_nil Studio::Note.find(slug) }
  end

  test "every note has a template on disk" do
    Studio::Note.all.each { |note| assert Rails.root.join("app/views/#{note.template}.html.erb").exist?, note.slug }
  end
end
