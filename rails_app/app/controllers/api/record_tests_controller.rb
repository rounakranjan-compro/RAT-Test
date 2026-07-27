class Api::RecordTestsController < ApplicationController
  before_action :validate_title, only: :create

  def create
    prepare_test_details
    check_duplicates

    ActiveRecord::Base.transaction do
      create_script
      create_test
      rename_existing_file
    end

    Rails.env.production? ? trigger_github_actions : run_locally

  rescue ActiveRecord::RecordInvalid => e
    cleanup
    render json: { error: e.message }, status: :unprocessable_entity

  rescue => e
    cleanup
    Rails.logger.error("RecordTests#create failed: #{e.message}")

    render json: {
      error: "Unexpected error occurred"
    }, status: :internal_server_error
  end

  def index
    render json: recorded_files
  end

  def vnc_url
    test = Test.find_by(id: params[:id])
    return render_not_found unless test

    test.update!(vnc_url: params[:vnc_url].presence)

    render json: { ok: true }
  end

  def script_content
    test = Test.find_by(id: params[:id])
    return render_not_found unless test

    content = params[:content].to_s

    return render json: {
      error: "content is blank"
    }, status: :bad_request if content.blank?

    script = test.script || test.build_script(
      name: "#{test.title}.spec.js",
      language: "javascript"
    )

    script.update!(
      raw_content: content,
      normalized_content: content
    )

    test.update!(script: script) unless test.script_id == script.id

    render json: {
      ok: true,
      script_id: script.id
    }
  end

  private

  ####################################################
  # Validation
  ####################################################

  def validate_title
    render(
      json: { error: "Title missing" },
      status: :bad_request
    ) and return if title.blank?
  end

  ####################################################
  # Setup
  ####################################################

  def prepare_test_details
    @tests_dir = Rails.root.join("automation", "tests")

    @file_name =
      title.ends_with?(".spec.js") ? title : "#{title}.spec.js"

    @test_title = @file_name.delete_suffix(".spec.js")

    @file_path = @tests_dir.join(@file_name)
  end

  ####################################################
  # Duplicate Validation
  ####################################################

  def check_duplicates
    if File.exist?(@file_path)
      render json: {
        error: "File already exists on disk"
      }, status: :conflict
    end

    if Test.exists?(title: @test_title)
      render json: {
        error: "Test already exists in database"
      }, status: :conflict
    end
  end

  ####################################################
  # Database
  ####################################################

  def create_script
    @script = Script.create!(
      name: @file_name,
      raw_content: nil,
      normalized_content: nil,
      language: "javascript"
    )
  end

  def create_test
    @test = Test.create!(
      title: @test_title,
      script: @script,
      user: current_user
    )
  end

  ####################################################
  # Files
  ####################################################

  def rename_existing_file
    return unless File.exist?(@file_path)

    new_name = "#{@test_title}_#{@test.id}.spec.js"

    File.rename(
      @file_path,
      @tests_dir.join(new_name)
    )

    @file_path = @tests_dir.join(new_name)

    @test.update!(title: "#{@test_title}_#{@test.id}")
    @script.update!(name: new_name)
  end

  ####################################################
  # Recording
  ####################################################

  def trigger_github_actions
    response = HTTParty.post(
      github_dispatch_url,
      headers: github_headers,
      body: github_body.to_json,
      timeout: 10
    )

    unless response.code == 204
      cleanup

      return render json: {
        error: "Failed to trigger workflow"
      }, status: :unprocessable_entity
    end

    render json: recording_response("headed"),
           status: :accepted
  end

  def run_locally
    node = `which node`.strip

    unless node.present?
      cleanup
      return render json: {
        error: "Node not found"
      }, status: :internal_server_error
    end

    script_path = Rails.root.join("automation", "record.js")

    unless File.exist?(script_path)
      cleanup
      return render json: {
        error: "record.js not found"
      }, status: :internal_server_error
    end

    command =
      "TEST_ID=#{@test.id} RAILS_URL=http://localhost:3000 #{node} #{script_path} record #{@script.name}"

    pid = Process.spawn(
      command,
      chdir: Rails.root.join("automation").to_s
    )

    Process.detach(pid)

    sync_script_after_recording(pid)

    render json: recording_response("local"),
           status: :accepted
  end

  ####################################################
  # Background Sync
  ####################################################

  def sync_script_after_recording(pid)
    script_id = @script.id
    file = @file_path

    Thread.new do
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
      end

      sleep 2

      next unless File.exist?(file)
      next if File.zero?(file)

      raw = File.read(file)

      Script.find(script_id).update!(
        raw_content: raw,
        normalized_content: raw
      )
    rescue => e
      Rails.logger.error(e.message)
    end
  end

  ####################################################
  # Helpers
  ####################################################

  def github_dispatch_url
    "https://api.github.com/repos/AmritGaurCompro/regression-automation-platform/actions/workflows/record.yml/dispatches"
  end

  def github_headers
    {
      "Authorization" => "Bearer #{ENV["GITHUB_PAT"]}",
      "Accept" => "application/vnd.github.v3+json",
      "Content-Type" => "application/json"
    }
  end

  def github_body
    {
      ref: "QA4.0",
      inputs: {
        file_name: @script.name,
        test_id: @test.id.to_s
      }
    }
  end

  def recording_response(mode)
    {
      file: @script.name,
      mode: mode,
      status: "recording_started",
      new_test: {
        id: @test.id,
        title: @test.title,
        status: "NEW"
      }
    }
  end

  def recorded_files
    Dir.glob(Rails.root.join("automation", "tests", "*.spec.js")).map do |file|
      {
        name: File.basename(file),
        path: file
      }
    end
  end

  def cleanup
    @test&.destroy
    @script&.destroy
  end

  def render_not_found
    render json: {
      error: "Test not found"
    }, status: :not_found
  end

  def title
    params[:title].to_s.strip
  end
end