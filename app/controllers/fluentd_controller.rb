class FluentdController < ApplicationController
  before_action :find_fluentd, only: [:show, :edit, :update, :destroy, :log, :raw_log]
  before_action :check_fluentd_exists, only: [:edit, :log, :raw_log]

  def show
  end

  def new
    @fluentd = Fluentd.new(variant: params[:variant] || "fluentd")
    @fluentd.load_settings_from_agent_default
  end

  def create
    @fluentd = Fluentd.new(fluentd_params)
    unless @fluentd.save
      return render :new
    end
    redirect_to fluentd_path
  end

  def edit
  end

  def update
    # TODO: should restart if changed file path? or just do "dirty" flagged?
    @fluentd.update_attributes(fluentd_params)
    unless @fluentd.save
      return render :edit
    end
    redirect_to fluentd_path
  end
  
  def destroy
    @fluentd.agent.stop if @fluentd.agent.running?
    @fluentd.destroy
    redirect_to root_path
  end

  def log
    @error_duration_days = 5
    @errors = @fluentd.agent.errors_since(@error_duration_days.days.ago)
  end

  def raw_log
    send_data @fluentd.agent.log, type: "application/octet-stream", filename: File.basename(@fluentd.log_file)
  end

  private

  def fluentd_params
    params.require(:fluentd).permit(:log_file, :pid_file, :config_file, :variant, :api_endpoint)
  end

  def check_fluentd_exists
    unless find_fluentd
      redirect_to root_path
    end
  end
end
