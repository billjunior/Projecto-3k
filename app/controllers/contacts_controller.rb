class ContactsController < ApplicationController
  before_action :set_contactable
  before_action :set_contact, only: [:show, :edit, :update, :destroy, :set_as_primary]

  def index
    @contacts = policy_scope(Contact).where(contactable: @contactable).recent
    authorize Contact
  end

  def show
    authorize @contact
  end

  def new
    @contact = @contactable.contacts.build
    authorize @contact
  end

  def create
    @contact = @contactable.contacts.build(contact_params)
    authorize @contact

    if @contact.save
      redirect_to_contactable, notice: 'Contacto criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @contact
  end

  def update
    authorize @contact

    if @contact.update(contact_params)
      redirect_to_contactable, notice: 'Contacto atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @contact

    @contact.destroy
    redirect_to_contactable, notice: 'Contacto removido com sucesso.'
  end

  def set_as_primary
    authorize @contact, :set_primary?

    # Remove primary from other contacts
    @contactable.contacts.where.not(id: @contact.id).update_all(primary: false)
    @contact.update!(primary: true)

    redirect_to_contactable, notice: 'Contacto definido como principal.'
  end

  private

  def set_contactable
    if params[:customer_id]
      @contactable = Customer.find(params[:customer_id])
    elsif params[:lead_id]
      @contactable = Lead.find(params[:lead_id])
    else
      redirect_to root_path, alert: 'Recurso não encontrado.'
    end
  end

  def set_contact
    @contact = @contactable.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :name, :email, :phone, :whatsapp, :position, :department, :primary, :notes
    )
  end

  def redirect_to_contactable
    case @contactable
    when Customer
      redirect_to customer_path(@contactable)
    when Lead
      redirect_to lead_path(@contactable)
    else
      redirect_to root_path
    end
  end
end
