require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    invalid_emails = %w[invalid_email @example.com user@ user@]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email} should be invalid"
    end
  end

  test "should require password" do
    @user.password = nil
    @user.password_confirmation = nil
    assert_not @user.valid?
  end

  test "should require password confirmation to match" do
    @user.password_confirmation = "different_password"
    assert_not @user.valid?
  end

  test "should downcase email before save" do
    @user.email = "TEST@EXAMPLE.COM"
    @user.save!
    assert_equal "test@example.com", @user.reload.email
  end

  test "should have many polls" do
    @user.save!
    poll1 = @user.polls.create!(
      title: "Test Poll 1",
      description: "Description",
      expires_at: 1.week.from_now
    )
    poll2 = @user.polls.create!(
      title: "Test Poll 2",
      description: "Description",
      expires_at: 1.week.from_now
    )

    assert_equal 2, @user.polls.count
    assert_includes @user.polls, poll1
    assert_includes @user.polls, poll2
  end

  test "should destroy associated polls when user is destroyed" do
    @user.save!
    poll = @user.polls.create!(
      title: "Test Poll",
      description: "Description",
      expires_at: 1.week.from_now
    )

    assert_difference "Poll.count", -1 do
      @user.destroy
    end
  end
end
