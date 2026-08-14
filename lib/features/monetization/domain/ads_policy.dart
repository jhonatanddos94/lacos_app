/// Política comercial V1 de monetização do Laços.
///
/// Ads nunca interrompem uma tarefa operacional.
///
/// NUNCA:
/// - tap Agendar → anúncio
/// - Salvar cliente → anúncio
/// - Abrir atendimento → anúncio
/// - Concluir atendimento → anúncio
/// - Trocar tab → anúncio
/// - Abrir app → app-open ad
///
/// A monetização V1 é passiva: um banner adaptativo discreto no fim da Home,
/// depois do conteúdo operacional, e somente para o plano Free.
abstract final class AdsPolicy {
  static const String description =
      'Ads nunca interrompem uma tarefa operacional.';
}
