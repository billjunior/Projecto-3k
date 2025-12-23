require 'prawn'
require 'prawn/table'

class DailyRevenueReportPdf < BasePdf
  def initialize(tenant, month, year)
    super(tenant)
    @month = month
    @year = year
    @revenues = fetch_revenues
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Receitas Diárias", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "#{Date::MONTHNAMES[@month]} de #{@year}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      summary_data = [
        ["Total de Entradas:", format_currency(total_entries)],
        ["Total de Saídas:", format_currency(total_exits)],
        ["Saldo:", format_currency(total_balance)],
        ["Lançamentos de Entrada:", entries_count.to_s],
        ["Lançamentos de Saída:", exits_count.to_s],
        ["Total de Lançamentos:", @revenues.count.to_s]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Revenues table
      if @revenues.any?
        pdf.font_size 14
        pdf.text "Detalhes dos Lançamentos", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        table_data = [["Data", "Descrição", "Qtd", "Preço Unit.", "Entrada", "Saída", "Tipo"]]

        @revenues.order(date: :desc).each do |revenue|
          table_data << [
            revenue.date.strftime('%d/%m/%Y'),
            revenue.description.truncate(30),
            revenue.quantity&.to_i || "-",
            revenue.unit_price ? format_currency(revenue.unit_price) : "-",
            revenue.entry.to_f > 0 ? format_currency(revenue.entry) : "-",
            revenue.exit.to_f > 0 ? format_currency(revenue.exit) : "-",
            translate_payment_type(revenue.payment_type)
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [60, 120, 35, 65, 75, 75, 85]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhuma receita registrada neste período.", style: :italic
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def fetch_revenues
    DailyRevenue.for_month(@month, @year)
  end

  def total_entries
    @revenues.sum(:entry) || 0
  end

  def total_exits
    @revenues.sum(:exit) || 0
  end

  def total_balance
    total_entries - total_exits
  end

  def entries_count
    @revenues.with_entries.count
  end

  def exits_count
    @revenues.with_exits.count
  end

  def translate_payment_type(payment_type)
    {
      'manual' => 'Manual',
      'bank_transfer' => 'Transf. Bancária'
    }[payment_type] || payment_type
  end
end
