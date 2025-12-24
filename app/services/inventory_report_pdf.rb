require 'prawn'
require 'prawn/table'

class InventoryReportPdf < BasePdf
  def initialize(tenant, inventory_items)
    super(tenant)
    @inventory_items = inventory_items
  end

  def generate
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Company Header with Logo
      add_company_header(pdf)

      pdf.move_down 20

      pdf.font_size 16
      pdf.text "Relatório de Inventário", align: :center, style: :bold
      pdf.move_down 5

      pdf.font_size 12
      pdf.text "Gerado em #{Time.current.strftime('%d/%m/%Y')}", align: :center
      pdf.move_down 20

      # Summary
      pdf.font_size 10
      total_items = InventoryItem.count
      low_stock_items = InventoryItem.low_stock.count
      out_of_stock_items = InventoryItem.out_of_stock.count
      total_value = @inventory_items.sum { |item| (item.net_quantity || 0) * (item.purchase_price || 0) }

      summary_data = [
        ["Total de Produtos:", total_items.to_s],
        ["Produtos com Estoque Baixo:", low_stock_items.to_s],
        ["Produtos sem Estoque:", out_of_stock_items.to_s],
        ["Valor Total do Estoque:", format_currency(total_value)]
      ]

      pdf.table(summary_data,
        cell_style: { borders: [:bottom], border_width: 0.5, padding: 5 },
        column_widths: [200, 300]) do |table|
        table.column(0).font_style = :bold
      end

      pdf.move_down 20

      # Inventory items table
      if @inventory_items.any?
        pdf.font_size 14
        pdf.text "Detalhes do Inventário", style: :bold
        pdf.move_down 10

        pdf.font_size 7
        table_data = [["Produto", "Qtd Bruta", "Qtd Líquida", "Preço Compra", "Valor Total", "Est. Mín.", "Status"]]

        @inventory_items.limit(100).each do |item|
          total_item_value = (item.net_quantity || 0) * (item.purchase_price || 0)
          status = if (item.net_quantity || 0) == 0
                    'Sem estoque'
                  elsif item.minimum_stock && (item.net_quantity || 0) <= item.minimum_stock
                    'Estoque baixo'
                  else
                    'Normal'
                  end

          table_data << [
            item.product_name.truncate(30),
            (item.gross_quantity || 0).to_i.to_s,
            (item.net_quantity || 0).to_i.to_s,
            format_currency(item.purchase_price || 0),
            format_currency(total_item_value),
            (item.minimum_stock || 0).to_i.to_s,
            status
          ]
        end

        pdf.table(table_data,
          header: true,
          cell_style: { padding: 3, size: 7 },
          column_widths: [120, 55, 55, 70, 70, 50, 95]) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'DDDDDD'

          # Color code status
          table.column(6).filter do |cell|
            case cell.content
            when 'Sem estoque'
              cell.background_color = 'FFEBEE'
            when 'Estoque baixo'
              cell.background_color = 'FFF9C4'
            when 'Normal'
              cell.background_color = 'E8F5E9'
            end
          end
        end
      else
        pdf.text "Nenhum item no inventário.", style: :italic
      end

      # Low stock items section
      pdf.start_new_page if low_stock_items > 0

      if low_stock_items > 0
        pdf.move_down 20
        pdf.font_size 14
        pdf.text "Produtos com Estoque Baixo", style: :bold, color: 'FF6B6B'
        pdf.move_down 10

        low_stock_list = InventoryItem.low_stock.limit(20)

        if low_stock_list.any?
          pdf.font_size 8
          low_stock_data = [["Produto", "Qtd Atual", "Estoque Mínimo", "Telefone Fornecedor"]]

          low_stock_list.each do |item|
            low_stock_data << [
              item.product_name.truncate(35),
              (item.net_quantity || 0).to_i.to_s,
              (item.minimum_stock || 0).to_i.to_s,
              item.supplier_phone || "N/A"
            ]
          end

          pdf.table(low_stock_data,
            header: true,
            cell_style: { padding: 4, size: 8 },
            column_widths: [200, 80, 100, 135]) do |table|
            table.row(0).font_style = :bold
            table.row(0).background_color = 'FFEBEE'
          end
        end
      end

      # Footer
      add_standard_footer(pdf)
    end.render
  end
end
