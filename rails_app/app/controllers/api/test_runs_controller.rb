class Api::TestRunsController < ApplicationController
    
def index
  test = Test.find(params[:test_id])

  runs = test.test_runs
             .order(created_at: :desc)
             .limit(5)

  render json: runs.map { |run|
    {
      id: run.id,
      test_id: run.test_id,
      status: run.status,
      environment: run.environment,
      runner_mode: run.runner_mode,
      retries_on_failure: run.retries_on_failure,
      started_at: run.started_at,
      finished_at: run.finished_at,
      created_at: run.created_at,
      duration: calculate_duration(run),
      vnc_url: run.vnc_url,
      artifacts: run.artifacts.map do |a|
          {
            kind: a.kind,
            file_url: a.file_url,
            metadata: a.metadata
          }
        end
      }
    }
end

  def show
    test_run = TestRun.find(params[:id])
    render json: test_run
  end

  def create
    test = Test.find(params[:test_id])

    test_run = test.test_runs.create!(
      script_id: test.script_id,
      environment: params[:environment] || "QA",
      runner_mode: params[:runner_mode] || "headless",
      retries_on_failure: params[:retries_on_failure] || 0,
      started_at: Time.current,
      tags: params[:tags] || "default",
      status: TestRun.exists?(status: 'running') ? 'queued' : 'running'
 )

    RunPlaywrightJob.perform_later(test_run.id) unless test_run.queued?

    render json: {
      test_run_id: test_run.id,
      status: test_run.status
    }, status: :created
  end
  
  def any_running
  render json: {
    running: TestRun.exists?(status: 'running'),
    queued: TestRun.where(status: 'queued').order(created_at: :asc).pluck(:test_id)
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

def update_vnc_url
  test_run = TestRun.find(params[:id])
  test_run.update!(vnc_url: params[:vnc_url])
  render json: { success: true }
rescue => e
  render json: { error: e.message }, status: 422
end

    def receive_artifacts
  test_run = TestRun.find(params[:id])

  # Save error log
  if params[:errors].present?
    Artifact.create!(
      test_run: test_run,
      kind: 'error_log',
      file_url: nil,
      metadata: params[:errors]
    )
  end

  # Save cloudinary URLs
  (params[:artifacts] || []).each do |att|
    Artifact.create!(
      test_run: test_run,
      kind: att[:kind],
      file_url: att[:file_url]
    )
  end

  test_run.update!(
    status: params[:success] ? 'passed' : 'failed',
    finished_at: Time.current
  )
   next_run = TestRun.where(status: 'queued').order(created_at: :asc).first
  if next_run
    next_run.update!(status: 'running', started_at: Time.current)
    RunPlaywrightJob.perform_later(next_run.id)
  end

  render json: { success: true }
rescue => e
  render json: { error: e.message }, status: 422
end

end
