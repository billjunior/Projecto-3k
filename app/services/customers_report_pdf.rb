require 'prawn'
require 'prawn/table'

class CustomersReportPdf < BasePdf
  def initialize(tenant, customers)
    super(tenant)
    @customers = customers
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Clientes", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Gerado em #{Time.current.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      customers_by_type = Customer.group(:customer_type).count
      summary_data = [
        ["Total de Clientes:", Customer.count.to_s],
        ["Clientes Particulares:", customers_by_type['particular'].to_i.to_s],
        ["Clientes Empresas:", customers_by_type['empresa'].to_i.to_s],
        ["Clientes com Faturas:", @customers.joins(:invoices).distinct.count.to_s]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Customers table
      if @customers.any?
        pdf.font_size 14
        pdf.text "Detalhes dos Clientes", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        table_data = [["Nome", "Tipo", "Telefone", "Email", "Nº Faturas", "Total Gasto"]]

        @customers.order(created_at: :desc).limit(100).each do |customer|
          total_spent = customer.invoices.sum(:total_value)
          table_data << [
            customer.name.truncate(30),
            customer.customer_type == 'particular' ? 'Particular' : 'Empresa',
            customer.phone&.truncate(15) || "N/A",
            customer.email&.truncate(30) || "N/A",
            customer.invoices.count.to_s,
            format_currency(total_spent)
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [100, 55, 70, 100, 55, 75]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhum cliente cadastrado.", style: :italic
      end

      # Top customers section
      if @customers.any?
        pdf.move_down 20
        pdf.font_size 14
        pdf.text "Top 10 Clientes por Valor Gasto", style: :bold
        pdf.move_down 10

        top_customers = @customers.joins(:invoices)
                                  .select('customers.*, SUM(invoices.total_value) as total_spent')
                                  .group('customers.id')
                                  .order('total_spent DESC')
                                  .limit(10)

        if top_customers.any?
          pdf.font_size 8
          top_table_data = [["#", "Nome", "Tipo", "Total Gasto"]]

          top_customers.each_with_index do |customer, index|
            top_table_data << [
              (index + 1).to_s,
              customer.name.truncate(35),
              customer.customer_type == 'particular' ? 'Particular' : 'Empresa',
              format_currency(customer.total_spent)
            ]
          end

          pdf.table(top_table_data,
            header: true,
            cell_style: { padding: 4, size: 8 },
            column_widths: [30, 200, 80, 100]) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = 'DDDDDD'
          end
        end
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end
end
