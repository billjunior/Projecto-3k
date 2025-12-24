require 'prawn'
require 'prawn/table'

class TrainingCoursesReportPdf < BasePdf
  def initialize(tenant, month, year)
    super(tenant)
    @month = month
    @year = year
    @courses = fetch_courses
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Formações Profissionais", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "#{Date::MONTHNAMES[@month]} de #{@year}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      summary_data = [
        ["Total de Formações:", @courses.count.to_s],
        ["Formações Ativas:", @courses.where(status: 'active').count.to_s],
        ["Formações Concluídas:", @courses.where(status: 'completed').count.to_s],
        ["Valor Total:", format_currency(total_value)],
        ["Total Pago:", format_currency(total_paid)],
        ["Saldo Pendente:", format_currency(total_balance)]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Courses table
      if @courses.any?
        pdf.font_size 14
        pdf.text "Detalhes das Formações", style: :bold
        pdf.move_down 10

        pdf.font_size 8
        table_data = [["Cliente", "Curso", "Data Início", "Data Fim", "Valor", "Pago", "Status"]]

        @courses.order(start_date: :desc).each do |course|
          table_data << [
            course.customer.name.truncate(25),
            course.course_name.truncate(30),
            course.start_date.strftime('%d/%m/%Y'),
            course.end_date ? course.end_date.strftime('%d/%m/%Y') : "N/A",
            format_currency(course.total_value || 0),
            format_currency(course.amount_paid || 0),
            translate_status(course.status)
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [80, 95, 60, 60, 65, 65, 90]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'
        end
      else
        pdf.text "Nenhuma formação registrada neste período.", style: :italic
      end

      # Payment status breakdown
      if @courses.any?
        pdf.move_down 20
        pdf.font_size 12
        pdf.text "Resumo de Pagamentos", style: :bold
        pdf.move_down 10

        fully_paid = @courses.select { |c| (c.total_value || 0) == (c.amount_paid || 0) && c.total_value > 0 }
        partial_paid = @courses.select { |c| (c.amount_paid || 0) > 0 && (c.amount_paid || 0) < (c.total_value || 0) }
        unpaid = @courses.select { |c| (c.amount_paid || 0) == 0 && (c.total_value || 0) > 0 }

        payment_summary = [
          ["Formações Pagas Totalmente:", fully_paid.count.to_s, format_currency(fully_paid.sum { |c| c.total_value || 0 })],
          ["Formações Parcialmente Pagas:", partial_paid.count.to_s, format_currency(partial_paid.sum { |c| c.total_value || 0 })],
          ["Formações Não Pagas:", unpaid.count.to_s, format_currency(unpaid.sum { |c| c.total_value || 0 })]
        ]

        pdf.font_size 9
        pdf.table(payment_summary,
          cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
          column_widths: [250, 100, 150]) do |table|
          table.column(0).font_style = :bold
        end
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def fetch_courses
    TrainingCourse.for_month(@month, @year)
  end

  def total_value
    @courses.sum(:total_value) || 0
  end

  def total_paid
    @courses.sum(:amount_paid) || 0
  end

  def total_balance
    total_value - total_paid
  end

  def translate_status(status)
    {
      'active' => 'Ativa',
      'completed' => 'Concluída',
      'cancelled' => 'Cancelada',
      'pending' => 'Pendente'
    }[status] || status.capitalize
  end
end
