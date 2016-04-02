class TasksController < ApplicationController
  respond_to :json, :xml

  def show
    @task = Task.find(params[:id])
    respond_to do |format|
      format.json { render json: @task, serializer: TaskSerializer }
    end
  end
end
