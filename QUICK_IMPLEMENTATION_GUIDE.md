# Guia Rápido de Implementação - Pundit nos Controllers Restantes

## Visão Geral

Este guia mostra como adicionar autorização Pundit aos controllers restantes do CRM 3K, seguindo o padrão implementado no CustomersController.

---

## Padrão Básico

### Template para qualquer Controller CRM

```ruby
class NomeDoController < ApplicationController
  before_action :set_resource, only: [:show, :edit, :update, :destroy]

  def index
    # Use policy_scope para filtrar recursos autorizados
    @resources = policy_scope(Resource)
                   .includes(:associations)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(20)
  end

  def show
    # Authorize antes de mostrar
    authorize @resource
    # ... resto do código
  end

  def new
    @resource = Resource.new
    # Authorize new (checa create?)
    authorize @resource
  end

  def create
    @resource = Resource.new(resource_params)
    # Authorize antes de criar
    authorize @resource

    if @resource.save
      redirect_to @resource, notice: 'Recurso criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Authorize edit (checa update?)
    authorize @resource
  end

  def update
    # Authorize antes de atualizar
    authorize @resource

    if @resource.update(resource_params)
      redirect_to @resource, notice: 'Recurso atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Authorize antes de deletar
    authorize @resource

    if @resource.destroy
      redirect_to resources_path, notice: 'Recurso removido com sucesso.'
    else
      redirect_to resources_path, alert: 'Não foi possível remover este recurso.'
    end
  end

  private

  def set_resource
    @resource = Resource.find(params[:id])
  end

  def resource_params
    params.require(:resource).permit(:campo1, :campo2, ...)
  end
end
```

---

## Controllers a Atualizar

### 1. ProductsController

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = policy_scope(Product)
                  .order(name: :asc)
                  .page(params[:page])
                  .per(20)
  end

  def show
    authorize @product
  end

  def new
    @product = Product.new
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product

    if @product.save
      redirect_to @product, notice: 'Produto criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @product
  end

  def update
    authorize @product

    if @product.update(product_params)
      redirect_to @product, notice: 'Produto atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product

    if @product.destroy
      redirect_to products_path, notice: 'Produto removido com sucesso.'
    else
      redirect_to products_path, alert: 'Não foi possível remover este produto.'
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :category, :unit, :base_price, :active)
  end
end
```

### 2. EstimatesController

```ruby
class EstimatesController < ApplicationController
  before_action :set_estimate, only: [:show, :edit, :update, :destroy, :approve]

  def index
    @estimates = policy_scope(Estimate)
                   .includes(:customer)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(20)
  end

  def show
    authorize @estimate
  end

  def new
    @estimate = Estimate.new
    authorize @estimate
  end

  def create
    @estimate = Estimate.new(estimate_params)
    authorize @estimate

    if @estimate.save
      redirect_to @estimate, notice: 'Orçamento criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @estimate
  end

  def update
    authorize @estimate

    if @estimate.update(estimate_params)
      redirect_to @estimate, notice: 'Orçamento atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @estimate

    if @estimate.destroy
      redirect_to estimates_path, notice: 'Orçamento removido com sucesso.'
    else
      redirect_to estimates_path, alert: 'Não foi possível remover este orçamento.'
    end
  end

  def approve
    authorize @estimate, :approve?  # Custom policy method

    if @estimate.update(status: :approved)
      redirect_to @estimate, notice: 'Orçamento aprovado com sucesso.'
    else
      redirect_to @estimate, alert: 'Erro ao aprovar orçamento.'
    end
  end

  private

  def set_estimate
    @estimate = Estimate.find(params[:id])
  end

  def estimate_params
    params.require(:estimate).permit(:customer_id, :status, :notes, ...)
  end
end
```

### 3. JobsController

```ruby
class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy, :upload_file]

  def index
    @jobs = policy_scope(Job)
              .includes(:customer)
              .order(created_at: :desc)
              .page(params[:page])
              .per(20)
  end

  def show
    authorize @job
  end

  def new
    @job = Job.new
    authorize @job
  end

  def create
    @job = Job.new(job_params)
    authorize @job

    if @job.save
      redirect_to @job, notice: 'Trabalho criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @job
  end

  def update
    authorize @job

    if @job.update(job_params)
      redirect_to @job, notice: 'Trabalho atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job

    if @job.destroy
      redirect_to jobs_path, notice: 'Trabalho removido com sucesso.'
    else
      redirect_to jobs_path, alert: 'Não foi possível remover este trabalho.'
    end
  end

  def upload_file
    authorize @job, :upload_file?  # Custom policy method

    # ... lógica de upload
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.require(:job).permit(:customer_id, :estimate_id, :status, ...)
  end
end
```

### 4. InvoicesController

```ruby
class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :finalize]

  def index
    @invoices = policy_scope(Invoice)
                  .includes(:customer)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(20)
  end

  def show
    authorize @invoice
  end

  def new
    @invoice = Invoice.new
    authorize @invoice
  end

  def create
    @invoice = Invoice.new(invoice_params)
    authorize @invoice

    if @invoice.save
      redirect_to @invoice, notice: 'Fatura criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @invoice
  end

  def update
    authorize @invoice

    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: 'Fatura atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invoice

    if @invoice.destroy
      redirect_to invoices_path, notice: 'Fatura removida com sucesso.'
    else
      redirect_to invoices_path, alert: 'Não foi possível remover esta fatura.'
    end
  end

  def finalize
    authorize @invoice, :finalize?  # Custom policy method

    if @invoice.update(status: :finalized)
      redirect_to @invoice, notice: 'Fatura finalizada com sucesso.'
    else
      redirect_to @invoice, alert: 'Erro ao finalizar fatura.'
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:customer_id, :status, :total, ...)
  end
end
```

### 5. PaymentsController

```ruby
class PaymentsController < ApplicationController
  before_action :set_payment, only: [:show, :edit, :update, :destroy]

  def index
    @payments = policy_scope(Payment)
                  .includes(:invoice)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(20)
  end

  def show
    authorize @payment
  end

  def new
    @payment = Payment.new
    authorize @payment
  end

  def create
    @payment = Payment.new(payment_params)
    authorize @payment

    if @payment.save
      redirect_to @payment, notice: 'Pagamento registrado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @payment
  end

  def update
    authorize @payment

    if @payment.update(payment_params)
      redirect_to @payment, notice: 'Pagamento atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @payment

    if @payment.destroy
      redirect_to payments_path, notice: 'Pagamento removido com sucesso.'
    else
      redirect_to payments_path, alert: 'Não foi possível remover este pagamento.'
    end
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:invoice_id, :amount, :payment_method, ...)
  end
end
```

### 6. LeadsController

```ruby
class LeadsController < ApplicationController
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :convert_to_opportunity]

  def index
    @leads = policy_scope(Lead)
               .order(created_at: :desc)
               .page(params[:page])
               .per(20)
  end

  def show
    authorize @lead
  end

  def new
    @lead = Lead.new
    authorize @lead
  end

  def create
    @lead = Lead.new(lead_params)
    authorize @lead

    if @lead.save
      redirect_to @lead, notice: 'Lead criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @lead
  end

  def update
    authorize @lead

    if @lead.update(lead_params)
      redirect_to @lead, notice: 'Lead atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @lead

    if @lead.destroy
      redirect_to leads_path, notice: 'Lead removido com sucesso.'
    else
      redirect_to leads_path, alert: 'Não foi possível remover este lead.'
    end
  end

  def convert_to_opportunity
    authorize @lead, :convert_to_opportunity?

    # Lógica de conversão
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:name, :email, :phone, :status, ...)
  end
end
```

### 7. OpportunitiesController

```ruby
class OpportunitiesController < ApplicationController
  before_action :set_opportunity, only: [:show, :edit, :update, :destroy, :convert_to_customer]

  def index
    @opportunities = policy_scope(Opportunity)
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(20)
  end

  def show
    authorize @opportunity
  end

  def new
    @opportunity = Opportunity.new
    authorize @opportunity
  end

  def create
    @opportunity = Opportunity.new(opportunity_params)
    authorize @opportunity

    if @opportunity.save
      redirect_to @opportunity, notice: 'Oportunidade criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @opportunity
  end

  def update
    authorize @opportunity

    if @opportunity.update(opportunity_params)
      redirect_to @opportunity, notice: 'Oportunidade atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @opportunity

    if @opportunity.destroy
      redirect_to opportunities_path, notice: 'Oportunidade removida com sucesso.'
    else
      redirect_to opportunities_path, alert: 'Não foi possível remover esta oportunidade.'
    end
  end

  def convert_to_customer
    authorize @opportunity, :convert_to_customer?

    # Lógica de conversão
  end

  private

  def set_opportunity
    @opportunity = Opportunity.find(params[:id])
  end

  def opportunity_params
    params.require(:opportunity).permit(:name, :email, :phone, :status, ...)
  end
end
```

### 8. TasksController

```ruby
class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    @tasks = policy_scope(Task)
               .order(due_date: :asc)
               .page(params[:page])
               .per(20)
  end

  def show
    authorize @task
  end

  def new
    @task = Task.new
    authorize @task
  end

  def create
    @task = Task.new(task_params)
    @task.created_by_id = current_user.id
    authorize @task

    if @task.save
      redirect_to @task, notice: 'Tarefa criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
  end

  def update
    authorize @task

    if @task.update(task_params)
      redirect_to @task, notice: 'Tarefa atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task

    if @task.destroy
      redirect_to tasks_path, notice: 'Tarefa removida com sucesso.'
    else
      redirect_to tasks_path, alert: 'Não foi possível remover esta tarefa.'
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :assigned_to_id, :due_date, :status, ...)
  end
end
```

---

## Controllers Cyber Café

### 9. LanMachinesController

```ruby
class LanMachinesController < ApplicationController
  before_action :set_lan_machine, only: [:show, :edit, :update, :destroy]

  def index
    @lan_machines = policy_scope(LanMachine)
                      .order(name: :asc)
                      .page(params[:page])
                      .per(20)
  end

  def show
    authorize @lan_machine
  end

  def new
    @lan_machine = LanMachine.new
    authorize @lan_machine
  end

  def create
    @lan_machine = LanMachine.new(lan_machine_params)
    authorize @lan_machine

    if @lan_machine.save
      redirect_to @lan_machine, notice: 'Máquina criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @lan_machine
  end

  def update
    authorize @lan_machine

    if @lan_machine.update(lan_machine_params)
      redirect_to @lan_machine, notice: 'Máquina atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @lan_machine

    if @lan_machine.destroy
      redirect_to lan_machines_path, notice: 'Máquina removida com sucesso.'
    else
      redirect_to lan_machines_path, alert: 'Não foi possível remover esta máquina.'
    end
  end

  private

  def set_lan_machine
    @lan_machine = LanMachine.find(params[:id])
  end

  def lan_machine_params
    params.require(:lan_machine).permit(:name, :status, :hourly_rate, :notes)
  end
end
```

### 10. LanSessionsController

Seguir o mesmo padrão, usando `authorize` antes de cada ação.

### 11-15. Demais Controllers Cyber

Aplicar o mesmo padrão para:
- InventoryItemsController
- DailyRevenuesController
- TrainingCoursesController

---

## Checklist de Implementação

Para cada controller:

- [ ] Adicionar `policy_scope` no método `index`
- [ ] Adicionar `authorize @resource` em `show`
- [ ] Adicionar `authorize @resource` em `new`
- [ ] Adicionar `authorize @resource` em `create`
- [ ] Adicionar `authorize @resource` em `edit`
- [ ] Adicionar `authorize @resource` em `update`
- [ ] Adicionar `authorize @resource` em `destroy`
- [ ] Adicionar `authorize @resource, :custom_action?` para ações customizadas (approve, finalize, etc)

---

## Erros Comuns e Soluções

### Erro: "Pundit::NotAuthorizedError"
**Solução:** Usuário não tem permissão. Verifique a policy correspondente.

### Erro: "unable to find policy"
**Solução:** Certifique-se que existe um arquivo `app/policies/nome_do_model_policy.rb`

### Erro: "Pundit::AuthorizationNotPerformedError"
**Solução:** Você esqueceu de chamar `authorize` em alguma action. Adicione `skip_authorization` se não precisar.

### Erro: "Pundit::PolicyScopingNotPerformedError"
**Solução:** Você esqueceu de chamar `policy_scope` no index. Adicione `skip_policy_scope` se não precisar.

---

## Desabilitar Verificação em Actions Específicas

Se precisar desabilitar autorização em alguma action:

```ruby
class SomeController < ApplicationController
  skip_after_action :verify_authorized, only: [:public_action]
  skip_after_action :verify_policy_scoped, only: [:index]

  def public_action
    # Não precisa de autorização
  end
end
```

---

## Testando a Implementação

### Via Rails Console

```ruby
# Testar se cyber_tech não pode acessar customers
user = User.find_by(email: 'cyber@3k.com')
customer = Customer.first
CustomerPolicy.new(user, customer).index?
# => false

# Testar se commercial pode criar customers
user = User.find_by(email: 'comercial@3k.com')
customer = Customer.new
CustomerPolicy.new(user, customer).create?
# => true

# Testar se production pode atualizar jobs
user = User.find_by(email: 'producao@3k.com')
job = Job.first
JobPolicy.new(user, job).update?
# => true
```

### Via Browser

1. Fazer login com diferentes usuários
2. Tentar acessar recursos não autorizados
3. Verificar se recebe erro de "não autorizado"

---

## Próximas Etapas

1. Aplicar este padrão a TODOS os controllers
2. Testar cada controller com diferentes roles
3. Atualizar views para esconder botões não autorizados
4. Implementar namespace Cyber (opcional)
5. Criar testes automatizados

---

**Sucesso na implementação!**
