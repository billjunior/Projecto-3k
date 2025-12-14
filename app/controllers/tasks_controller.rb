class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @pending_tasks = policy_scope(Task).pending.order(due_date: :asc)
    @completed_tasks = policy_scope(Task).completed.order(updated_at: :desc).limit(20)
  end

  def show
    # Pundit: Authorize show action
    authorize @task
  end

  def new
    @task = Task.new
    # Pundit: Authorize new action (checks create?)
    authorize @task

    @users = User.all
  end

  def create
    @task = Task.new(task_params)
    # Pundit: Authorize create action
    authorize @task

    @task.created_by_user = current_user

    if @task.save
      redirect_to tasks_path, notice: 'Tarefa criada com sucesso.'
    else
      @users = User.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @task

    @users = User.all
  end

  def update
    # Pundit: Authorize update action
    authorize @task

    if @task.update(task_params)
      redirect_to tasks_path, notice: 'Tarefa atualizada com sucesso.'
    else
      @users = User.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @task

    @task.destroy
    redirect_to tasks_path, notice: 'Tarefa removida com sucesso.'
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :status, :assigned_to_user_id, :related_type, :related_id)
  end
end
