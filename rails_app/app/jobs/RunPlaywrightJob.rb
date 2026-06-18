class RunPlaywrightJob < ApplicationJob
  queue_as :default

  def perform(test_run_id)
    test_run = TestRun.find(test_run_id)

    case runner_mode_context(test_run)
    when :github_headed
      trigger_github_actions(test_run)
    when :local_headed
      run_locally(test_run, headed: true)
    else
      run_locally(test_run, headed: false)
    end
  rescue => e
    test_run.update!(status: "failed", finished_at: Time.current) if test_run
    puts "Playwright job failed: #{e.message}"
    puts e.backtrace.join("\n")
    $stdout.flush
  end

  private

  # ↓ ADDED: extract queue trigger to reusable method
  def trigger_next_queued_run
    next_run = TestRun.where(status: 'queued').order(created_at: :asc).first
    if next_run
      next_run.update!(status: 'running', started_at: Time.current)
      RunPlaywrightJob.perform_later(next_run.id)
    end
  end

  def runner_mode_context(test_run)
    if test_run.runner_mode == 'headed'
      ENV['LOCAL_HEADED_OVERRIDE'] == 'true' ? :local_headed : :github_headed
    else
      :local_headless
    end
  end

  def trigger_github_actions(test_run)
    test = test_run.test
    spec_name = resolved_spec_name_for(test)

    puts "=== TRIGGER GITHUB ACTIONS ==="
    puts "spec_name: #{spec_name}"
    puts "test_run_id: #{test_run.id}"
    puts "test_id: #{test.id}"
    puts "GITHUB_PAT present: #{ENV['GITHUB_PAT'].present?}"
    puts "GITHUB_PAT starts with: #{ENV['GITHUB_PAT']&.first(10)}"
    $stdout.flush

    begin
      response = HTTParty.post(
        "https://api.github.com/repos/AmritGaurCompro/regression-automation-platform/actions/workflows/run-headed.yml/dispatches",
        headers: {
          "Authorization" => "Bearer #{ENV['GITHUB_PAT']}",
          "Accept" => "application/vnd.github.v3+json",
          "Content-Type" => "application/json"
        },
        body: {
          ref: "QA4.0",
          inputs: {
            environment: test_run.environment.to_s,
            retries: test_run.retries_on_failure.to_s,
            test_run_id: test_run.id.to_s,
            test_id: test.id.to_s
          }
        }.to_json,
        timeout: 10
      )

      puts "=== GITHUB ACTIONS RESPONSE ==="
      puts "response code: #{response.code}"
      puts "response body: #{response.body}"
      $stdout.flush

      if response.code == 204
        puts "GitHub Actions triggered successfully for test_run #{test_run.id}"
        $stdout.flush
        test_run.update!(status: "running")
      else
        puts "GitHub Actions trigger failed: #{response.body}"
        $stdout.flush
        test_run.update!(status: "failed", finished_at: Time.current)
        trigger_next_queued_run # ↓ ADDED
      end
    rescue => e
      puts "=== HTTPARTY ERROR ==="
      puts e.message
      puts e.backtrace.join("\n")
      $stdout.flush
      test_run.update!(status: "failed", finished_at: Time.current)
      trigger_next_queued_run # ↓ ADDED
    end
  end

  def run_locally(test_run, headed: false)
    test = test_run.test
    node_path = `which node`.strip
    script_path = Rails.root.join('automation/run.js')
    spec_name = ensure_spec_file_for_local_run!(test)

    puts "=== RUN LOCALLY (headed: #{headed}) ==="
    puts "Running Playwright locally with spec: #{spec_name}"
    $stdout.flush

    env_vars = {
      'PW_RETRIES'  => test_run.retries_on_failure.to_s,
      'PW_HEADED'   => headed ? 'true' : 'false',
      'TEST_RUN_ID' => test_run.id.to_s,
      'ENVIRONMENT' => test_run.environment.to_s,
      'RUN_ATTEMPT'  => Time.current.to_i.to_s
    }

    env_string = env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')
    command = "#{env_string} #{node_path} #{script_path} #{spec_name} 2>&1"

    puts "Running command: #{command}"
    $stdout.flush

    output = ""
    IO.popen(command) { |io| io.each { |line| output << line } }

    if output =~ /---RESULT---(.*?)---END---/m
      result = JSON.parse($1)
      test_run.update!(
        status: result["success"] ? "passed" : "failed",
        finished_at: Time.current
      )
    else
      test_run.update!(status: "failed", finished_at: Time.current)
    end

    UploadArtifactsJob.perform_later(test_run.id)
    trigger_next_queued_run # ↓ ADDED
  end

  def resolved_spec_name_for(test)
    name = test.script&.name.presence || "#{test.title}.spec.js"
    base = File.basename(name)
    base.ends_with?('.spec.js') ? base : "#{base}.spec.js"
  end

  def ensure_spec_file_for_local_run!(test)
    spec_name = resolved_spec_name_for(test)
    script_content = test.script&.raw_content.presence || test.script&.normalized_content

    raise "Script content is missing for test ##{test.id}" if script_content.blank?

    tests_dir = Rails.root.join('automation', 'tests')
    FileUtils.mkdir_p(tests_dir)
    file_path = tests_dir.join(spec_name)

    should_write = !File.exist?(file_path) || File.read(file_path) != script_content
    if should_write
      File.write(file_path, script_content)
      Rails.logger.info("RunPlaywrightJob: synced spec file #{spec_name} from DB")
    end

    spec_name
  end
end