module ApplicationHelper
  MESES_PT = [
    nil,
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ].freeze

  def nome_mes(numero)
    MESES_PT[numero]
  end

  def opcoes_meses
    (1..12).map { |m| [MESES_PT[m], m] }
  end
end
