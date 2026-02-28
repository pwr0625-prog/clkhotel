require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "is valid with title and content" do
    post = Post.new(title: "제목", content: "내용")

    assert post.valid?
  end

  test "is invalid without title" do
    post = Post.new(content: "내용")

    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "is invalid without content" do
    post = Post.new(title: "제목")

    assert_not post.valid?
    assert_includes post.errors[:content], "can't be blank"
  end

  test "is invalid with too long title" do
    post = Post.new(title: "a" * 101, content: "내용")

    assert_not post.valid?
    assert_includes post.errors[:title], "is too long (maximum is 100 characters)"
  end

  test "is invalid with too long content" do
    post = Post.new(title: "제목", content: "a" * 5001)

    assert_not post.valid?
    assert_includes post.errors[:content], "is too long (maximum is 5000 characters)"
  end
end
