require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get register" do
    get api_v1_auth_register_url
    assert_response :success
  end

  test "should get login" do
    get api_v1_auth_login_url
    assert_response :success
  end
end
