class Api::FeaturesController < ApplicationController
  def index
    features = current_user.features.includes(tests: { test_runs: :artifacts })
    render json: features.map { |f| build_feature_data(f) }
  end

  def show
    feature = current_user.features.includes(tests: { test_runs: :artifacts }).find(params[:id])
    render json: build_feature_data(feature)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Feature not found' }, status: :not_found
  end

  def create
    feature = current_user.features.find_or_create_by!(name: params[:name].to_s.strip)
    render json: build_feature_data(feature), status: :created
  end

  def destroy
    feature = current_user.features.find(params[:id])
    feature.destroy
    render json: { message: 'Feature deleted' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Feature not found' }, status: :not_found
  end

  # Runs every test in the feature, or a scoped subset when `test_ids` is
  # passed (e.g. from the "Run Failed Only" action in the settings dialog).
  def run_all
    feature = current_user.features.includes(:tests).find(params[:id])
    tests_to_run = scoped_tests(feature)

    if tests_to_run.empty?
      return render json: { error: 'No matching tests to run' }, status: :unprocessable_entity
    end

    results = tests_to_run.map { |test| enqueue_test_run(test) }
    render json: { message: "#{results.size} test(s) started", results: results }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :internal_server_error
  end

  # Runs only the tests in the feature whose most recent test_run failed.
  # Thin wrapper around run_all so both endpoints share the same enqueue logic.
  def run_failed
    feature = current_user.features.includes(:tests).find(params[:id])
    failed_tests = feature.tests.select { |t| latest_status(t) == 'failed' }

    if failed_tests.empty?
      return render json: { message: 'No failed tests to rerun', results: [] }, status: :ok
    end

    results = failed_tests.map { |test| enqueue_test_run(test) }
    render json: { message: "#{results.size} failed test(s) restarted", results: results }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :internal_server_error
  end

  # Applies environment / retries_on_failure / tags to every test in the
  # feature in a single request, instead of one PATCH per test.
  def bulk_update_tests
    feature = current_user.features.includes(:tests).find(params[:id])
    attrs = bulk_update_params
    return render json: { error: 'No updatable fields provided' }, status: :unprocessable_entity if attrs.empty?

    updated_ids = []
    Test.transaction do
      feature.tests.each do |test|
        test.update!(attrs)
        updated_ids << test.id
      end
    end

    render json: { message: "Updated #{updated_ids.size} test(s)", test_ids: updated_ids, applied: attrs }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Lightweight status summary for the feature (passed/failed/running/new
  # counts) — mirrors what the settings dialog computes client-side, useful
  # for polling without re-fetching the full nested payload.
  def stats
    feature = current_user.features.includes(tests: :test_runs).find(params[:id])
    counts = Hash.new(0)
    feature.tests.each do |t|
      status = latest_status(t) || 'new'
      counts[status] += 1
    end
    render json: { feature_id: feature.id, counts: counts, total: feature.tests.size }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Feature not found' }, status: :not_found
  end

  private

  # Returns the tests to run for #run_all: either the full set, or a
  # filtered subset when the caller passes test_ids: [...].
  def scoped_tests(feature)
    if params[:test_ids].present?
      requested_ids = Array(params[:test_ids]).map(&:to_i)
      feature.tests.select { |t| requested_ids.include?(t.id) }
    else
      feature.tests
    end
  end

  def enqueue_test_run(test)
    test_run = test.test_runs.create!(
      script_id:          test.script_id,
      environment:        params[:environment] || 'QA',
      runner_mode:        params[:runner_mode] || 'headless',
      retries_on_failure: params[:retries_on_failure] || 0,
      started_at:         Time.current,
      tags:               [],
      status:             TestRun.exists?(status: 'running') ? 'queued' : 'running'
    )
    RunPlaywrightJob.perform_later(test_run.id) unless test_run.status == 'queued'
    { test_id: test.id, test_run_id: test_run.id, status: test_run.status }
  end

  def latest_status(test)
    test.test_runs.max_by(&:created_at)&.status
  end

  def bulk_update_params
    params.permit(:environment, :retries_on_failure, tags: []).to_h.symbolize_keys
  end

  def build_feature_data(feature)
    {
      id:          feature.id,
      name:        feature.name,
      tests_count: feature.tests.count,
      tests:       feature.tests.map do |t|
        last_run = t.test_runs.order(created_at: :desc).first
        {
          id:        t.id,
          title:     t.title,
          status:    last_run&.status || 'NEW',
          lastRun:   last_run&.finished_at,
          startedAt: last_run&.created_at,
          duration:  calculate_duration(last_run)
        }
      end
    }
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