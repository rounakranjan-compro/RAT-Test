class Api::ImportTestsController < ApplicationController
  before_action :validate_params

  def create
    prepare_file_details
    check_duplicate_test

    write_test_file

    ActiveRecord::Base.transaction do
      create_feature
      create_script
      create_test
      rename_file
    end

    render json: response_payload, status: :created

  rescue ActiveRecord::RecordInvalid => e
    cleanup_file
    render json: { error: e.message }, status: :unprocessable_entity

  rescue => e
    cleanup_file
    Rails.logger.error("ImportTests#create failed: #{e.message}")

    render json: {
      error: "An unexpected error occurred"
    }, status: :internal_server_error
  end

  private

  #################################################
  # Validation
  #################################################

  def validate_params
    render(json: { error: "File name is missing" }, status: :unprocessable_entity) and return if saved_filename.blank?
    render(json: { error: "Script content is missing" }, status: :unprocessable_entity) and return if saved_script_content.blank?
  end

  #################################################
  # Helpers
  #################################################

  def prepare_file_details
    @tests_dir = Rails.root.join("automation", "tests")
    FileUtils.mkdir_p(@tests_dir)

    base_name = File.basename(saved_filename)

    @file_name =
      base_name.ends_with?(".spec.js") ? base_name : "#{base_name}.spec.js"

    @title = @file_name.delete_suffix(".spec.js")

    @file_path = @tests_dir.join(@file_name)
  end

  def check_duplicate_test
    if Test.exists?(title: @title) || File.exist?(@file_path)
      render json: {
        error: "A Test file with that name already exists. Please try another name."
      }, status: :conflict
    end
  end

  def write_test_file
    File.write(@file_path, saved_script_content)
  rescue => e
    Rails.logger.error("Unable to write file: #{e.message}")
    raise
  end

  #################################################
  # Database
  #################################################

  def create_feature
    return unless feature_name.present?

    @feature = current_user.features.find_or_create_by!(
      name: feature_name
    )
  end

  def create_script
    @script = Script.create!(
      name: @file_name,
      raw_content: saved_script_content,
      normalized_content: saved_script_content,
      language: "javascript",

      # Future PR metadata
      metadata: {
        pr_number: params[:pr_number],
        repository: params[:repository],
        branch: params[:branch],
        pr_diff: params[:pr_diff]
      }.compact
    )
  end

  def create_test
    @test = Test.create!(
      title: @title,
      script: @script,
      feature: @feature,
      user: current_user
    )
  end

  #################################################
  # File Rename
  #################################################

  def rename_file
    new_file_name = "#{@title}_#{@test.id}.spec.js"
    new_file_path = @tests_dir.join(new_file_name)

    File.rename(@file_path, new_file_path)

    @test.update!(title: "#{@title}_#{@test.id}")
    @script.update!(name: new_file_name)

    @file_path = new_file_path
  end

  #################################################
  # Response
  #################################################

  def response_payload
    {
      test: {
        id: @test.id,
        title: @test.title
      },

      script: {
        id: @script.id,
        name: @script.name
      },

      feature: @feature && {
        id: @feature.id,
        name: @feature.name
      },

      # Future functionality
      pr: {
        number: params[:pr_number],
        repository: params[:repository],
        branch: params[:branch],
        has_diff: params[:pr_diff].present?
      }.compact
    }
  end

  #################################################
  # Cleanup
  #################################################

  def cleanup_file
    File.delete(@file_path) if @file_path.present? && File.exist?(@file_path)
  end

  #################################################
  # Params
  #################################################

  def saved_filename
    params[:saved_filename].to_s.strip
  end

  def saved_script_content
    params[:saved_script_content].to_s
  end

  def feature_name
    params[:feature_name].to_s.strip
  end
end