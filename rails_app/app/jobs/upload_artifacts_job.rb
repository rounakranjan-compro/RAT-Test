class UploadArtifactsJob < ApplicationJob
  queue_as :default

  def perform(test_run_id)
    test_run = TestRun.find(test_run_id)
    artifacts_root = Rails.root.join("automation/artifacts")

    return unless Dir.exist?(artifacts_root)

    # ↓ CHANGED: find the run-{test_run_id} folder directly
    run_folder = File.join(artifacts_root, "run-#{test_run_id}")
    return unless Dir.exist?(run_folder)

    # ↓ CHANGED: find the attempt subfolder inside run folder
    attempt_folder = Dir.children(run_folder)
                        .map { |f| [f, File.mtime(File.join(run_folder, f))] }
                        .max_by(&:last)&.first

    return unless attempt_folder

    result_json_path = File.join(run_folder, attempt_folder, "result.json")
    return unless File.exist?(result_json_path)

    data = JSON.parse(File.read(result_json_path))

    results = data.dig("suites", 0, "specs", 0, "tests", 0, "results") || []
    failed_result = results.find { |r| r["errors"]&.any? }

    unless failed_result
      Rails.logger.info("No errors found, skipping artifact upload")
      return
    end

    Artifact.create!(
      test_run: test_run,
      kind: "error_log",
      file_url: nil,
      metadata: failed_result["errors"]
    )

    attachments = failed_result["attachments"] || []

    attachments.each do |att|
      next if att["name"] == "error-context"

      url = CloudinaryUploadService.upload_file(att["path"], folder: Rails.env)
      next unless url

      Artifact.create!(
        test_run: test_run,
        kind: att["name"],
        file_url: url
      )
    end

  rescue => e
    Rails.logger.error("UploadArtifactsJob failed: #{e.message}")

  ensure
    # ↓ CHANGED: only delete THIS run's folder, not the entire artifacts dir
    cleanup_run_folder(test_run_id)
  end

  private

  def cleanup_run_folder(test_run_id)
    run_folder = Rails.root.join("automation/artifacts/run-#{test_run_id}")
    FileUtils.rm_rf(run_folder) if Dir.exist?(run_folder)
  end
end