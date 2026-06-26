class Api::TestsController < ApplicationController
  before_action :authenticate_user!
  SCRIPTS_DIR = Rails.root.join('automation', 'tests')

  def index
    tests = current_user.tests.includes(test_runs: :artifacts)
    data = tests.map do |t|
      last_run = t.test_runs.order(created_at: :desc).first
      build_test_data(t, last_run)
    end
    render json: data
  end

  def show
    test     = current_user.tests.includes(test_runs: :artifacts).find(params[:id])
    last_run = test.test_runs.order(created_at: :desc).first
    render json: build_test_data(test, last_run)
  end

  def update
    test = current_user.tests.find(params[:id])

    if params[:tags].present?
      raw = params[:tags]
      cleaned = Array(raw).flat_map do |t|
        loop do
          break t unless t.is_a?(String) && t.start_with?('[', '"')
          parsed = JSON.parse(t) rescue break
          t = parsed
        end
        Array(t)
      end.map(&:to_s).map(&:strip).reject(&:blank?).uniq
      test.tags = cleaned.join(',')
    else
      # explicitly clear tags if empty array or blank sent
      test.tags = '' if params.key?(:tags)
    end

    if test.update(test_params.except(:tags))
      render json: { message: 'Test updated' }, status: :ok
    else
      render json: test.errors, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Test not found' }, status: :not_found
  end

  def script
    test = current_user.tests.find(params[:id])
    render json: { script: { raw: test.script.raw_content, normalized: test.script.normalized_content } }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Test not found' }, status: :not_found
  end

  def destroy
    test = current_user.tests.find(params[:id])
    test.destroy
    render json: { message: 'Test deleted' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Test not found' }, status: :not_found
  end

  private

  def test_params
    params.permit(
      :environment,
      :runner_mode,
      :retries_on_failure,
      tags: []
    )
  end

def build_test_data(test, last_run)
  {
    id:                 test.id,
    title:              test.title,
    environment:        test.environment || 'QA',
    status:             last_run&.status || "NEW",
    lastRun:            last_run&.finished_at,
    startedAt:          last_run&.created_at,
    finishedAt:         last_run&.updated_at,
    duration:           calculate_duration(last_run),
    tags:               test.tags_list || [],
    retries_on_failure: test.retries_on_failure || 2,
    runner_mode:        test.runner_mode || 'headless',
    vnc_url:            last_run&.vnc_url.presence || test.vnc_url,
    script:             load_script_content(test.script_id),
    artifacts:          last_run&.artifacts&.map do |a|
      { kind: a.kind, url: a.file_url, metadata: a.metadata }
    end || []
  }
end

  def load_script_content(script_id)
    return { raw: nil, normalized: nil } if script_id.blank?
    script = Script.find_by(id: script_id)
    return { raw: nil, normalized: nil } unless script
    normalized = normalize_script(script.raw_content, script_id)
    { raw: script.raw_content, normalized: normalized }
  rescue StandardError => e
    Rails.logger.error("Error loading script #{script_id}: #{e.message}")
    { raw: nil, normalized: nil }
  end

  def normalize_script(raw, script_id = nil)
    return nil if raw.blank?
    lines = raw.lines
    lines = lines.reject { |l| l.strip.start_with?('import ') }
    lines = lines.reject { |l| l.strip.start_with?("test('") || l.strip == '});' }
    lines = lines.drop_while { |l| l.strip.empty? }
    lines = lines.reverse.drop_while { |l| l.strip.empty? }.reverse
    lines = lines.map { |l| l.start_with?('  ') ? l[2..] : l }
    normalized = lines.join
    normalized = normalized.gsub(/page\.goto\(['"]https?:\/\/[^'"]+['"]\)/, "page.goto('/')")
    normalized = normalized.gsub(
      /(getByRole\(['"]textbox['"],\s*\{\s*name:\s*['"](?:email|Email|username|Username|user|User)['"'][^}]*\}\s*\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_USERNAME'
    )
    normalized = normalized.gsub(
      /(getBy(?:Label|Placeholder)\(['"](?:email|Email|username|Username|user|User)['"]\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_USERNAME'
    )
    normalized = normalized.gsub(
      /(getByRole\(['"]textbox['"],\s*\{\s*name:\s*['"](?:password|Password|passwd|Passwd)['"'][^}]*\}\s*\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_PASSWORD'
    )
    normalized = normalized.gsub(
      /(getBy(?:Label|Placeholder)\(['"](?:password|Password|passwd|Passwd)['"]\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_PASSWORD'
    )
    normalized = normalized.gsub(
      /(getBy(?:Role|Label|Placeholder)\([^)]*['"](?:phone|Phone|mobile|Mobile|tel|Tel)['"'][^)]*\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_PHONE'
    )
    normalized = normalized.gsub(
      /(getBy(?:Role|Label|Placeholder)\([^)]*['"](?:otp|OTP|code|Code|verification|Verification)['"'][^)]*\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_OTP'
    )
    normalized = normalized.gsub(
      /(getBy(?:Role|Label|Placeholder)\([^)]*['"](?:card|Card|credit|Credit|cvv|CVV)['"'][^)]*\)\.fill\()['"][^'"]*['"]/,
      '\1process.env.TEST_CARD'
    )
    Script.find_by(id: script_id)&.update!(normalized_content: normalized) if script_id.present?
    normalized
  rescue StandardError => e
    Rails.logger.error("Error normalizing script: #{e.message}")
    raw
  end

  def calculate_duration(test_run)
    return nil unless test_run&.created_at && test_run&.updated_at
    duration_seconds = (test_run.updated_at - test_run.created_at).to_i
    if duration_seconds < 60
      "#{duration_seconds}s"
    else
      minutes = duration_seconds / 60
      seconds = duration_seconds % 60
      "#{minutes}m #{seconds}s"
    end
  end
end