require "test_helper"

class PollTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @poll = Poll.new(
      title: "Test Poll",
      description: "Test Description",
      user: @user,
      expires_at: 1.week.from_now
    )
  end

  test "should be valid with valid attributes" do
    assert @poll.valid?
  end

  test "should require title" do
    @poll.title = nil
    assert_not @poll.valid?
    assert_includes @poll.errors[:title], "can't be blank"
  end

  test "should require title to be at least 5 characters" do
    @poll.title = "Hi"
    assert_not @poll.valid?
    assert_includes @poll.errors[:title], "is too short (minimum is 5 characters)"
  end

  test "should require expires_at" do
    @poll.expires_at = nil
    assert_not @poll.valid?
    assert_includes @poll.errors[:expires_at], "can't be blank"
  end

  test "should not allow expires_at in the past" do
    @poll.expires_at = 1.hour.ago
    assert_not @poll.valid?
    assert_includes @poll.errors[:expires_at], "can't be in the past"
  end

  test "should be active by default" do
    @poll.save!
    assert @poll.active?
  end

  test "should calculate total votes correctly" do
    @poll.save!
    option1 = @poll.options.create!(text: "Option 1")
    option2 = @poll.options.create!(text: "Option 2")

    user2 = users(:bob)
    user3 = users(:charlie)

    Vote.create!(user: @user, poll: @poll, option: option1)
    Vote.create!(user: user2, poll: @poll, option: option2)
    Vote.create!(user: user3, poll: @poll, option: option1)

    assert_equal 3, @poll.total_votes
  end

  test "should calculate results correctly" do
    @poll.save!
    option1 = @poll.options.create!(text: "Option 1")
    option2 = @poll.options.create!(text: "Option 2")

    user2 = users(:bob)

    Vote.create!(user: @user, poll: @poll, option: option1)
    Vote.create!(user: user2, poll: @poll, option: option1)

    results = @poll.results

    assert_equal 2, results.find { |r| r[:id] == option1.id }[:votes_count]
    assert_equal 100.0, results.find { |r| r[:id] == option1.id }[:percentage]
    assert_equal 0, results.find { |r| r[:id] == option2.id }[:votes_count]
    assert_equal 0.0, results.find { |r| r[:id] == option2.id }[:percentage]
  end

  test "should know when expired" do
    @poll.expires_at = 1.hour.ago
    assert @poll.expired?

    @poll.expires_at = 1.hour.from_now
    assert_not @poll.expired?
  end

  test "should have scopes" do
    active_poll = Poll.create!(
      title: "Active Poll",
      user: @user,
      expires_at: 1.week.from_now,
      active: true
    )

    inactive_poll = Poll.create!(
      title: "Inactive Poll",
      user: @user,
      expires_at: 1.week.from_now,
      active: false
    )

    expired_poll = Poll.create!(
      title: "Expired Poll",
      user: @user,
      expires_at: 1.hour.ago,
      active: true
    )

    assert_includes Poll.active, active_poll
    assert_not_includes Poll.active, inactive_poll

    assert_includes Poll.inactive, inactive_poll
    assert_not_includes Poll.inactive, active_poll

    assert_includes Poll.expired, expired_poll
    assert_not_includes Poll.not_expired, expired_poll
  end
end
