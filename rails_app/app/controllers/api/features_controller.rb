class Api::FeaturesController < ApplicationController
  def index
    features = current_user.features.includes(tests: { test_runs: :artifacts })
    render json: features.map { |f| build_feature_data(f) }
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

  def run_all
    feature = current_user.features.includes(:tests).find(params[:id])
    results = []
    feature.tests.each do |test|
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
      results << { test_id: test.id, test_run_id: test_run.id, status: test_run.status }
    end
    render json: { message: 'All tests started', results: results }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :internal_server_error
  end

  private

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