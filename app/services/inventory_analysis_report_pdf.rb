require 'prawn'
require 'prawn/table'

class InventoryAnalysisReportPdf < BasePdf
  def initialize(tenant, most_purchased, most_exits, daily_movements, movements_comparison, selected_month = nil, selected_year = nil)
    super(tenant)
    @most_purchased = most_purchased.to_a
    @most_exits = most_exits.to_a
    @daily_movements = daily_movements.to_a
    @movements_comparison = movements_comparison || {}
    @selected_month = selected_month
    @selected_year = selected_year
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40, page_layout: :landscape) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      # Title
      pdf.font_size 18
      pdf.text "Análise de Movimentos de Inventário", align: :center, style: :bold
      pdf.move_down 5

      # Period
      pdf.font_size 12
      period_text = if @selected_month && @selected_year
        month_name = nome_mes_helper(@selected_month)
        "Período: #{month_name} #{@selected_year}"
      else
        "Período: Todos os registos"
      end
      pdf.text period_text, align: :center
      pdf.move_down 5
      pdf.font_size 10
      pdf.text "Gerado em #{Time.current.strftime('%d/%m/%Y às %H:%M')}", align: :center
      pdf.move_down 20

      # Most Purchased Section (Entries)
      pdf.font_size 14
      pdf.fill_color '27AE60'
      pdf.text "📥 Produtos Mais Comprados (Entradas)", style: :bold
      pdf.fill_color '000000'
      pdf.move_down 10

      if @most_purchased.any?
        pdf.font_size 8
        table_data = [["#", "Produto", "Fornecedor", "Total Entradas", "Stock Atual", "Preço Compra", "Valor Investido"]]

        @most_purchased.each_with_index do |item, index|
          total_entries = item.respond_to?(:total_entries) ? item.total_entries : 0
          total_value = (item.purchase_price || 0) * (total_entries || 0)

          rank = case index
                 when 0 then "🥇"
                 when 1 then "🥈"
                 when 2 then "🥉"
                 else (index + 1).to_s
                 end

          table_data << [
            rank,
            (item.product_name || 'N/A').truncate(35),
            (item.supplier_phone || 'N/A').truncate(20),
            format_number(total_entries),
            format_number(item.net_quantity || 0),
            format_currency(item.purchase_price || 0),
            format_currency(total_value)
          ]
        end

        # Totals row
        total_entries_sum = @most_purchased.sum { |i| i.respond_to?(:total_entries) ? i.total_entries.to_f : 0 }
        total_investment = @most_purchased.sum { |i| (i.purchase_price || 0) * (i.respond_to?(:total_entries) ? i.total_entries.to_f : 0) }

        table_data << [
          { content: "TOTAL:", colspan: 3, font_style: :bold },
          { content: format_number(total_entries_sum), font_style: :bold },
          "",
          "",
          { content: format_currency(total_investment), font_style: :bold }
        ]

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [30, 150, 100, 80, 80, 80, 95]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'D5F5E3'
          table.row(0).align = :center

          # Highlight top 3
          (1..3).each do |i|
            table.row(i).background_color = 'E8F8F5' if i < table_data.length - 1
          end

          # Totals row styling
          table.row(-1).background_color = 'ABEBC6'
          table.row(-1).font_style = :bold

          # Align numeric columns
          table.columns(3..6).align = :right
        end
      else
        pdf.text "Nenhuma entrada registada no período selecionado.", style: :italic, color: '999999'
      end

      pdf.move_down 30

      # Most Exits Section
      pdf.font_size 14
      pdf.fill_color 'E74C3C'
      pdf.text "📤 Produtos com Mais Saídas", style: :bold
      pdf.fill_color '000000'
      pdf.move_down 10

      if @most_exits.any?
        pdf.font_size 8
        exits_table_data = [["#", "Produto", "Fornecedor", "Total Saídas", "Stock Atual", "Status"]]

        @most_exits.each_with_index do |item, index|
          total_exits = item.respond_to?(:total_exits) ? item.total_exits : 0

          rank = case index
                 when 0 then "🥇"
                 when 1 then "🥈"
                 when 2 then "🥉"
                 else (index + 1).to_s
                 end

          status = if (item.net_quantity || 0) == 0
                     'Sem Stock'
                   elsif item.minimum_stock && (item.net_quantity || 0) <= item.minimum_stock
                     'Stock Baixo'
                   else
                     'Normal'
                   end

          exits_table_data << [
            rank,
            (item.product_name || 'N/A').truncate(40),
            (item.supplier_phone || 'N/A').truncate(20),
            format_number(total_exits),
            format_number(item.net_quantity || 0),
            status
          ]
        end

        # Totals row
        total_exits_sum = @most_exits.sum { |i| i.respond_to?(:total_exits) ? i.total_exits.to_f : 0 }

        exits_table_data << [
          { content: "TOTAL:", colspan: 3, font_style: :bold },
          { content: format_number(total_exits_sum), font_style: :bold },
          { content: "", colspan: 2 }
        ]

        pdf.table(exits_table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [30, 200, 120, 100, 100, 95]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'FADBD8'
          table.row(0).align = :center

          # Highlight top 3
          (1..3).each do |i|
            table.row(i).background_color = 'FDEDEC' if i < exits_table_data.length - 1
          end

          # Totals row styling
          table.row(-1).background_color = 'F5B7B1'
          table.row(-1).font_style = :bold

          # Align numeric columns
          table.columns(3..4).align = :right
          table.column(5).align = :center

          # Color code status column
          table.column(5).filter do |cell|
            next if cell.row == 0 || cell.row == exits_table_data.length - 1 # Skip header and total
            case cell.content
            when 'Sem Stock'
              cell.background_color = 'FFEBEE'
              cell.text_color = 'B71C1C'
            when 'Stock Baixo'
              cell.background_color = 'FFF9C4'
              cell.text_color = 'F57F17'
            when 'Normal'
              cell.background_color = 'E8F5E9'
              cell.text_color = '2E7D32'
            end
          end
        end
      else
        pdf.text "Nenhuma saída registada no período selecionado.", style: :italic, color: '999999'
      end

      # New page for daily movements
      if @daily_movements.any?
        pdf.start_new_page

        pdf.font_size 14
        pdf.fill_color '3498DB'
        pdf.text "📊 Movimentos Diários de Entrada e Saída", style: :bold
        pdf.fill_color '000000'
        pdf.move_down 5

        pdf.font_size 10
        period_text = if @selected_month && @selected_year
          month_name = nome_mes_helper(@selected_month)
          "#{month_name} #{@selected_year}"
        else
          "Últimos 30 dias"
        end
        pdf.text "Período: #{period_text}", color: '555555'
        pdf.move_down 10

        pdf.font_size 8
        movements_table_data = [["Data", "Entradas", "Saídas", "Diferença"]]

        total_entries = 0
        total_exits = 0

        @daily_movements.each do |movement|
          entries = movement.respond_to?(:entries) ? movement.entries.to_f : 0
          exits = movement.respond_to?(:exits) ? movement.exits.to_f : 0
          diff = entries - exits

          total_entries += entries
          total_exits += exits

          date_str = if movement.respond_to?(:movement_date)
            movement.movement_date.is_a?(String) ? Date.parse(movement.movement_date).strftime('%d/%m/%Y') : movement.movement_date.strftime('%d/%m/%Y')
          else
            'N/A'
          end

          movements_table_data << [
            date_str,
            format_number(entries),
            format_number(exits),
            "#{diff >= 0 ? '+' : ''}#{format_number(diff)}"
          ]
        end

        # Totals row
        total_diff = total_entries - total_exits
        movements_table_data << [
          { content: "TOTAL:", font_style: :bold },
          { content: format_number(total_entries), font_style: :bold },
          { content: format_number(total_exits), font_style: :bold },
          { content: "#{total_diff >= 0 ? '+' : ''}#{format_number(total_diff)}", font_style: :bold }
        ]

        pdf.table(movements_table_data,
          header: true,
          cell_style: { padding: 4, size: 8 },
          column_widths: [150, 150, 150, 150]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'E3F2FD'
          table.row(0).align = :center

          # Totals row styling
          table.row(-1).background_color = 'BBDEFB'
          table.row(-1).font_style = :bold

          # Align numeric columns
          table.columns(1..3).align = :right

          # Color code difference column
          table.column(3).filter do |cell|
            next if cell.row == 0 || cell.row == movements_table_data.length - 1 # Skip header and total
            value = cell.content.gsub(/[^\d\-,]/, '').gsub(',', '.').to_f
            if value > 0
              cell.text_color = '27AE60'
            elsif value < 0
              cell.text_color = 'E74C3C'
            end
          end
        end

        # Summary stats
        pdf.move_down 15
        pdf.font_size 9
        pdf.fill_color '555555'

        summary_data = [
          ["Total de Entradas:", format_number(total_entries)],
          ["Total de Saídas:", format_number(total_exits)],
          ["Diferença (Saldo):", "#{total_diff >= 0 ? '+' : ''}#{format_number(total_diff)}"]
        ]

        pdf.table(summary_data,
          cell_style: { borders: [], padding: 3, size: 9 },
          column_widths: [200, 150]) do |table|
          table.column(0).font_style = :bold
          table.column(1).align = :right
          # Color code the difference
          if total_diff >= 0
            table.row(2).column(1).text_color = '27AE60'
          else
            table.row(2).column(1).text_color = 'E74C3C'
          end
        end
        pdf.fill_color '000000'
      end

      # Footer with insights
      pdf.move_down 30
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      pdf.font_size 9
      pdf.fill_color '555555'
      insights = []

      if @most_purchased.any?
        top_product = @most_purchased.first
        insights << "• Produto mais comprado: #{top_product.product_name} (#{format_number(top_product.respond_to?(:total_entries) ? top_product.total_entries : 0)} unidades)"
      end

      if @most_exits.any?
        top_exit = @most_exits.first
        insights << "• Produto com mais saídas: #{top_exit.product_name} (#{format_number(top_exit.respond_to?(:total_exits) ? top_exit.total_exits : 0)} unidades)"

        low_stock_count = @most_exits.count { |i| i.minimum_stock && (i.net_quantity || 0) <= i.minimum_stock }
        insights << "• Produtos com stock baixo na lista: #{low_stock_count}" if low_stock_count > 0
      end

      # Add movement insights
      if @movements_comparison.any?
        total_entries = @movements_comparison['Entradas'] || 0
        total_exits = @movements_comparison['Saídas'] || 0
        balance = total_entries - total_exits

        if balance > 0
          insights << "• Saldo positivo: +#{format_number(balance)} unidades (mais entradas que saídas)"
        elsif balance < 0
          insights << "• Saldo negativo: #{format_number(balance)} unidades (mais saídas que entradas)"
        else
          insights << "• Saldo equilibrado: entradas e saídas equivalentes"
        end
      end

      pdf.text "Observações:", style: :bold if insights.any?
      insights.each { |insight| pdf.text insight }
      pdf.fill_color '000000'

      # Standard footer
      add_standard_footer(pdf)
    end.render
  end

  private

  def nome_mes_helper(month_number)
    month_names = {
      1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
      5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
      9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro'
    }
    month_names[month_number] || month_number.to_s
  end

  def format_number(number)
    sprintf("%.2f", number.to_f).gsub('.', ',')
  end
end
