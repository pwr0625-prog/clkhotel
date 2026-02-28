require "test_helper"

class PostsFlowTest < ActionDispatch::IntegrationTest
  test "paginates posts with page param" do
    Post.delete_all
    7.times { |i| Post.create!(title: "제목 #{i + 1}", content: "내용 #{i + 1}") }

    get posts_url
    assert_response :success
    assert_select "li h2", 5
    assert_select "nav", /1 \/ 2/
    assert_select "a", "다음"

    get posts_url(page: 2)
    assert_response :success
    assert_select "li h2", 2
    assert_select "nav", /2 \/ 2/
    assert_select "a", "이전"
  end

  test "can list posts" do
    get posts_url

    assert_response :success
    assert_select "h1", "블로그 게시글 목록"
  end

  test "can create post" do
    assert_difference("Post.count", 1) do
      post posts_url, params: { post: { title: "새 글", content: "새 내용" } }
    end

    created_post = Post.order(:created_at).last
    assert_redirected_to post_url(created_post)
    follow_redirect!
    assert_response :success
    assert_select "h1", "새 글"
  end

  test "invalid create renders errors" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { title: "", content: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "h2", /error/
  end

  test "can update post" do
    post_record = posts(:one)

    patch post_url(post_record), params: { post: { title: "수정된 제목", content: post_record.content } }

    assert_redirected_to post_url(post_record)
    post_record.reload
    assert_equal "수정된 제목", post_record.title
  end

  test "can destroy post" do
    post_record = posts(:one)

    assert_difference("Post.count", -1) do
      delete post_url(post_record)
    end

    assert_redirected_to posts_url
  end
end
