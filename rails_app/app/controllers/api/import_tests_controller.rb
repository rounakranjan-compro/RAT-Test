class Api::ImportTestsController < ApplicationController
  def create
    saved_filename       = params[:saved_filename].to_s.strip
    saved_script_content = params[:saved_script_content].to_s
    feature_name         = params[:feature_name].to_s.strip  # ← new

    return render json: { error: 'File name is missing' },      status: :unprocessable_entity if saved_filename.blank?
    return render json: { error: 'Script content is missing' }, status: :unprocessable_entity if saved_script_content.blank?

    base_name  = File.basename(saved_filename)
    file_name  = base_name.ends_with?('.spec.js') ? base_name : "#{base_name}.spec.js"
    tests_dir  = Rails.root.join('automation', 'tests')
    FileUtils.mkdir_p(tests_dir)
    file_path  = tests_dir.join(file_name)
    test_title = file_name.sub('.spec.js', '')

    if Test.exists?(title: test_title)
      return render json: { error: 'A Test file with that name already exists, Please try some other name!!' }, status: :conflict
    end
    return render json: { error: 'A Test file with that name already exists, Please try some other name!!' }, status: :conflict if File.exist?(file_path)

    begin
      File.write(file_path, saved_script_content)
    rescue => e
      Rails.logger.error("ImportTests#create – could not write file: #{e.message}")
      return render json: { error: 'Failed to write test file' }, status: :internal_server_error
    end

    title   = file_name.delete_suffix('.spec.js')
    feature = nil  # ← new
    script  = nil
    test    = nil

    ActiveRecord::Base.transaction do
      # ← new: find or create feature if name provided
      if feature_name.present?
        feature = current_user.features.find_or_create_by!(name: feature_name)
      end

      script = Script.create!(
        name:               file_name,
        raw_content:        saved_script_content,
        normalized_content: saved_script_content,
        language:           'javascript'
      )

      test = Test.create!(
        title:   title,
        script:  script,
        user:    current_user,
        feature: feature  # ← new: assign feature if present
      )

      new_file_name = "#{title}_#{test.id}.spec.js"
      new_file_path = tests_dir.join(new_file_name)
      File.rename(file_path, new_file_path)
      test.update!(title: "#{title}_#{test.id}")
      script.update!(name: new_file_name)
    end

    render json: {
      test:    { id: test.id,   title: test.title },
      script:  { id: script.id, name:  script.name },
      feature: feature ? { id: feature.id, name: feature.name } : nil  # ← new
    }, status: :created

  rescue ActiveRecord::RecordInvalid => e
    File.delete(file_path) if File.exist?(file_path)
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    File.delete(file_path) if File.exist?(file_path)
    Rails.logger.error("ImportTests#create failed: #{e.message}")
    render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
  end
end