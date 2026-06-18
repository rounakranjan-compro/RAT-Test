class Api::RecordTestsController < ApplicationController
  def create
    title = params[:title].to_s.strip
    return render json: { error: 'Title missing' }, status: :bad_request if title.blank?
    file_name  = title.ends_with?('.spec.js') ? title : "#{title}.spec.js"
    test_title = file_name.delete_suffix('.spec.js')
    tests_dir  = Rails.root.join('automation/tests')
    file_path  = tests_dir.join(file_name)
    return render json: { error: 'File already exists on disk' },     status: :conflict if File.exist?(file_path)
    return render json: { error: 'Test already exists in database' }, status: :conflict if Test.exists?(title: test_title)
    script = Script.create!(
      name:               file_name,
      raw_content:        nil,
      normalized_content: nil,
      language:           'javascript'
    )
    test = Test.create!(title: test_title, script: script, user: current_user)
    new_file_name = "#{test_title}_#{test.id}.spec.js"
    new_file_path = tests_dir.join(new_file_name)
    File.rename(file_path, new_file_path) if File.exist?(file_path)
    test.update!(title: "#{test_title}_#{test.id}")
    script.update!(name: new_file_name)
    if Rails.env.production?
      trigger_github_actions(test, script, new_file_name)
    else
      run_locally(test, script, new_file_name, new_file_path)
    end
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
  def index
    tests_dir = Rails.root.join('automation/tests')
    files = Dir.glob(tests_dir.join('*.spec.js')).map do |f|
      { name: File.basename(f), path: f }
    end
    render json: files
  end
  def vnc_url
    test = Test.find_by(id: params[:id])
    return render json: { error: 'Test not found' }, status: :not_found unless test
    test.update!(vnc_url: params[:vnc_url].presence)
    render json: { ok: true }
  end
  def script_content
    test = Test.find_by(id: params[:id])
    return render json: { error: 'Test not found' }, status: :not_found unless test
    content = params[:content].to_s.strip
    return render json: { error: 'content is blank' }, status: :bad_request if content.blank?
    script = test.script || test.build_script(
      name:     "#{test.title}.spec.js",
      language: 'javascript'
    )
    script.update!(raw_content: content, normalized_content: content)
    test.update!(script: script) unless test.script_id == script.id
    Rails.logger.info("RecordTests: script saved to DB for test ##{test.id}")
    render json: { ok: true, script_id: script.id }
  end
  private
  def trigger_github_actions(test, script, file_name)
    response = HTTParty.post(
      "https://api.github.com/repos/AmritGaurCompro/regression-automation-platform/actions/workflows/record.yml/dispatches",
      headers: {
        "Authorization" => "Bearer #{ENV['GITHUB_PAT']}",
        "Accept"        => "application/vnd.github.v3+json",
        "Content-Type"  => "application/json"
      },
      body: {
        ref: "QA4.0",
        inputs: {
          file_name: file_name,
          test_id:   test.id.to_s
        }
      }.to_json,
      timeout: 10
    )
    unless response.code == 204
      test.destroy
      script.destroy
      return render json: { error: "Failed to trigger workflow: #{response.body}" },
                    status: :unprocessable_entity
    end
    render json: {
      file:     file_name,
      mode:     'headed',
      status:   'recording_started',
      new_test: { id: test.id, title: test.title, status: 'NEW' }
    }, status: :accepted
  end
  def run_locally(test, script, file_name, file_path)
    node_path   = `which node`.strip
    script_path = Rails.root.join('automation/record.js')
    unless node_path.present?
      test.destroy; script.destroy
      return render json: { error: 'Node not found' }, status: :internal_server_error
    end
    unless File.exist?(script_path)
      test.destroy; script.destroy
      return render json: { error: 'record.js not found' }, status: :internal_server_error
    end
    command = "TEST_ID=#{test.id} RAILS_URL=http://localhost:3000 #{node_path} #{script_path} record #{file_name}"
    pid = Process.spawn(command, chdir: Rails.root.join('automation').to_s)
    Process.detach(pid)
    script_id = script.id
    Thread.new do
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
      end
      sleep 2
      if File.exist?(file_path) && File.size(file_path) > 0
        begin
          raw = File.read(file_path)
          Script.find(script_id).update!(
            raw_content:        raw,
            normalized_content: raw
          )
          Rails.logger.info("Script synced after local recording: #{file_name}")
        rescue => e
          Rails.logger.error("Failed to sync script #{file_name}: #{e.message}")
        end
      else
        Rails.logger.warn("File missing or empty after recording: #{file_path}")
      end
    end
    render json: {
      file:     file_name,
      mode:     'local',
      status:   'recording_started',
      new_test: { id: test.id, title: test.title, status: 'NEW' }
    }, status: :accepted
  end
end