class TrainingCoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_training_course, only: [:show, :edit, :update, :destroy]

  def index
    # Pundit: Use policy_scope for index action
    @month = params[:month]&.to_i || Date.today.month
    @year = params[:year]&.to_i || Date.today.year

    @training_courses = policy_scope(TrainingCourse).for_month(@month, @year).by_date.page(params[:page]).per(20)

    # Calculate monthly totals
    all_month_courses = policy_scope(TrainingCourse).for_month(@month, @year)
    @total_value = all_month_courses.sum(:total_value)
    @total_paid = all_month_courses.sum(:amount_paid)
    @total_balance = @total_value - @total_paid
    @active_courses = all_month_courses.where(status: 'active').count
    @completed_courses = all_month_courses.where(status: 'completed').count
  end

  def show
    # Pundit: Authorize show action
    authorize @training_course
  end

  def new
    @training_course = TrainingCourse.new(start_date: Date.today, status: :active, payment_type: :manual)
    # Pundit: Authorize new action (checks create?)
    authorize @training_course
  end

  def create
    @training_course = TrainingCourse.new(training_course_params)
    # Pundit: Authorize create action
    authorize @training_course

    if @training_course.save
      redirect_to training_courses_path(month: @training_course.start_date.month, year: @training_course.start_date.year),
                  notice: 'Curso de formação registado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Pundit: Authorize edit action (checks update?)
    authorize @training_course
  end

  def update
    # Pundit: Authorize update action
    authorize @training_course

    if @training_course.update(training_course_params)
      redirect_to training_courses_path(month: @training_course.start_date.month, year: @training_course.start_date.year),
                  notice: 'Curso de formação actualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Pundit: Authorize destroy action
    authorize @training_course

    month = @training_course.start_date.month
    year = @training_course.start_date.year
    @training_course.destroy
    redirect_to training_courses_path(month: month, year: year),
                notice: 'Curso de formação eliminado com sucesso.'
  end

  private

  def set_training_course
    @training_course = TrainingCourse.find(params[:id])
  end

  def training_course_params
    params.require(:training_course).permit(
      :student_name, :module_name, :total_value, :amount_paid,
      :training_days, :start_date, :end_date, :payment_type,
      :status, :notes
    )
  end
end
