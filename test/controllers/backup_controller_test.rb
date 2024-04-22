# frozen_string_literal: true

require "test_helper"

class BackupControllerTest < ActionDispatch::IntegrationTest
  test "should get load" do
    get backup_load_url
    assert_response :success
  end
end
