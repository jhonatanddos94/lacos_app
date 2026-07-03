# Projeto Laços

> **Documento 03 — Modelo de Domínio**
>
> **Versão:** 1.0
> **Status:** Em desenvolvimento
> **Última atualização:** Julho/2026

---

# Objetivo do Documento

Este documento descreve o Modelo de Domínio do projeto **Laços**.

Seu objetivo é definir as responsabilidades de cada entidade do sistema, seus limites, relacionamentos e conceitos de negócio.

Este documento não descreve banco de dados nem implementação.

Ele representa a visão do negócio sobre cada entidade do domínio.

---

# Visão Geral do Domínio

O domínio do Laços é centrado no relacionamento entre profissionais da beleza e seus clientes.

Todas as entidades existem para apoiar esse relacionamento.

O Cliente representa o centro do domínio.

As Memórias representam o conhecimento construído ao longo do relacionamento.

Os Agendamentos organizam os próximos atendimentos.

O Histórico registra tecnicamente tudo aquilo que foi realizado.

Os Serviços representam aquilo que o salão oferece.

Os Profissionais executam os serviços.

O Salão representa o estabelecimento responsável pelo atendimento.

---

# Entidade — Cliente

## Objetivo

Representar a pessoa que recebe os serviços prestados pelo salão.

O Cliente é o elemento central do domínio do Laços.

Todo o relacionamento construído entre profissional e cliente acontece a partir desta entidade.

---

## Propriedade

Conceitualmente, um cliente pertence ao salão.

Na versão 1.0, como cada usuário administra apenas um salão, essa propriedade é controlada pelo proprietário da conta.

A arquitetura deverá permitir evolução futura para múltiplos salões.

---

## Responsabilidade

O Cliente é responsável por centralizar todas as informações relacionadas à pessoa atendida pelo salão.

A partir dele são organizados:

- Histórico de atendimentos
- Memórias
- Agendamentos
- Preferências
- Informações cadastrais

---

## Relacionamentos

O Cliente possui relacionamento com:

- Agendamentos
- Histórico de Atendimento
- Memórias
- Profissional Preferencial
- Proprietário da Conta

---

## É responsável por

- Identificar a pessoa atendida.
- Centralizar seu histórico.
- Centralizar suas memórias.
- Manter informações cadastrais.
- Permitir identificação do profissional preferencial.

---

## Não é responsável por

- Registrar procedimentos realizados.
- Armazenar observações técnicas.
- Registrar produtos utilizados.
- Registrar informações financeiras.
- Controlar a agenda.

Essas responsabilidades pertencem a outras entidades do domínio.

---

## Exemplo

Ana é cliente do salão desde 2026.

Ao longo dos anos realizou diversos atendimentos, criou um histórico de procedimentos e acumulou memórias importantes.

Toda essa informação gira em torno da entidade Cliente.

---

## Possíveis Evoluções

- Tags personalizadas.
- Segmentação de clientes.
- Perfil inteligente.
- Classificação automática por IA.

---

# Entidade — Memória

> A Memória representa o principal diferencial competitivo do Laços.

---

## Objetivo

Representar informações compartilhadas espontaneamente pela cliente durante os atendimentos.

Seu propósito é fortalecer o relacionamento entre profissional e cliente, permitindo que conversas importantes sejam retomadas naturalmente em atendimentos futuros.

---

## O que é uma Memória?

Uma memória representa qualquer informação compartilhada pela cliente que possa contribuir para um relacionamento mais próximo, um atendimento mais personalizado ou uma melhor experiência em futuros atendimentos.

O objetivo não é registrar tudo o que a cliente fala.

O objetivo é registrar aquilo que agrega valor ao relacionamento.

---

## Quando criar uma Memória?

As memórias poderão ser registradas:

- Durante o atendimento, em momentos de espera.
- Após o atendimento.

O sistema nunca deve incentivar que o profissional interrompa um procedimento para registrar informações.

---

## Quem pode criar?

Todos os profissionais autorizados poderão registrar memórias.

---

## Quem pode visualizar?

A visualização das memórias será configurável pelo proprietário do salão.

Exemplos:

- Todos os profissionais.
- Apenas o profissional que registrou.
- Apenas profissionais autorizados.
- Proprietário e profissional.

Essa configuração permite que cada salão adapte o sistema à sua forma de trabalho.

---

## Autor

Toda memória possui:

- Autor.
- Data de criação.

Isso garante rastreabilidade e contexto.

---

## Edição

Correções de escrita ou erros de digitação poderão ser editados.

Mudanças no contexto da história da cliente nunca deverão substituir a memória original.

Sempre que a situação mudar, uma nova memória deverá ser criada.

Exemplo:

2026

"Vai casar."

2027

"Casou."

Dessa forma o sistema preserva a linha do tempo do relacionamento.

---

## Arquivamento

Memórias poderão ser arquivadas.

Arquivar significa apenas retirar determinada memória do uso cotidiano.

Ela continuará fazendo parte da história da cliente.

---

## Exclusão

O sistema utilizará Soft Delete.

Nenhuma memória será removida fisicamente.

---

## Validade

As memórias não possuem prazo de validade.

Mesmo quando deixam de ser relevantes para futuras conversas, continuam fazendo parte da história da cliente.

---

## Memórias desatualizadas

Uma memória poderá deixar de representar a realidade atual.

Isso não reduz seu valor histórico.

A Inteligência Artificial deverá considerar o contexto temporal antes de utilizá-la em sugestões.

---

## Memórias Sensíveis

Memórias sensíveis representam acontecimentos capazes de despertar emoções delicadas.

Exemplos:

- Doença.
- Falecimento.
- Separação.
- Problemas familiares.
- Situações financeiras difíceis.

Essas memórias existem para orientar um atendimento mais humano.

Nunca deverão ser utilizadas automaticamente como sugestão de conversa.

---

## Tipos de Memória

As memórias não possuem categorias obrigatórias.

Naturalmente poderão representar assuntos como:

- Família.
- Trabalho.
- Estudos.
- Viagens.
- Animais.
- Gostos pessoais.
- Preferências.
- Eventos importantes.
- Experiências anteriores em outros salões.
- Preferências relacionadas ao cabelo.

A Inteligência Artificial poderá identificar esses assuntos automaticamente no futuro.

---

## Linha do Tempo

As memórias representam a evolução do relacionamento entre cliente e salão.

Elas não devem ser vistas como anotações isoladas.

Constituem uma linha do tempo construída ao longo dos anos.

---

## Filosofia das Memórias

As memórias representam a fonte oficial do conhecimento sobre o relacionamento entre cliente e salão.

Toda funcionalidade inteligente do Laços deverá partir desse princípio.

---

# Inteligência Artificial

## Princípio

A Inteligência Artificial do Laços nunca será a fonte da verdade.

A fonte da verdade sempre serão as memórias registradas pelos profissionais.

A IA apenas interpreta essas informações.

---

## Responsabilidades da IA

A IA poderá:

- Gerar resumos.
- Identificar padrões.
- Destacar acontecimentos importantes.
- Gerar sugestões.
- Apontar oportunidades de relacionamento.
- Auxiliar na oferta de serviços e produtos quando houver contexto.

---

## Limitações

A IA nunca poderá:

- Alterar memórias.
- Excluir memórias.
- Criar informações inexistentes.
- Tomar decisões pelo profissional.

A decisão final sempre será humana.

---

## Filosofia

A IA existe para auxiliar.

Ela nunca substitui o profissional.

Ela apenas transforma informação em contexto.

---

## Visão de Longo Prazo

O Laços utilizará Inteligência Artificial para interpretar a Base de Conhecimento construída pelas memórias do cliente.

Essa interpretação permitirá gerar:

- Resumo inteligente da cliente.
- Linha do tempo resumida.
- Sugestões de relacionamento.
- Oportunidades de serviços.
- Sugestões de produtos.
- Lembretes contextualizados.

A IA nunca modificará os dados originais.

As memórias continuarão sendo a fonte oficial da história do relacionamento.

---

# Entidade — Agendamento

## Objetivo

Representar a reserva de um horário na agenda de um profissional para atendimento futuro de uma cliente.

O agendamento existe para organizar o tempo do profissional e garantir que determinado período esteja reservado.

---

## Responsabilidade

Organizar os compromissos futuros do profissional.

O Agendamento representa aquilo que foi combinado entre cliente e profissional.

Ele não representa, necessariamente, aquilo que será realizado.

---

## O que representa?

O Agendamento representa uma intenção de atendimento.

Já o Histórico de Atendimento representa aquilo que realmente aconteceu.

Esses dois conceitos são independentes.

---

## Relacionamentos

O Agendamento relaciona:

- Cliente.
- Profissional.
- Serviço.
- Data e horário.

Após sua conclusão poderá originar um Histórico de Atendimento.

---

## Ciclo de Vida

Um agendamento poderá passar pelos seguintes estados:

- Agendado
- Confirmado
- Em atendimento
- Finalizado
- Cancelado
- Não compareceu

Cada estado representa uma etapa do ciclo de vida daquele horário reservado.

---

## Cancelamento

Quando um agendamento é cancelado, o horário volta a ficar disponível para novos atendimentos.

O cancelamento não remove o histórico daquele agendamento.

---

## Não Comparecimento

O status **Não compareceu** representa que a cliente possuía um horário reservado, porém não compareceu.

Esse comportamento faz parte do histórico da cliente e deve ser preservado.

---

## Remarcação

Uma remarcação deverá gerar um novo agendamento.

O agendamento original permanecerá registrado para preservar o histórico.

---

## Atendimento Simultâneo

Um profissional poderá possuir mais de um atendimento em andamento ao mesmo tempo.

Essa situação representa a rotina real de salões de beleza, onde diferentes clientes podem estar em etapas distintas do atendimento.

O sistema não deverá impedir múltiplos atendimentos simultâneos.

A organização prática desses atendimentos será responsabilidade do profissional.

---

## Controle de Tempo

O Laços não realizará controle rígido da duração dos atendimentos.

A duração dos serviços poderá existir apenas como referência futura.

O profissional será responsável por administrar seu próprio tempo.

---

## Alterações Durante o Atendimento

O serviço inicialmente agendado poderá ser diferente do serviço efetivamente realizado.

Exemplo:

Agendado:

- Corte.

Realizado:

- Corte.
- Hidratação.

Essa diferença faz parte da rotina do salão.

O Agendamento representa o planejamento.

O Histórico representa a execução.

---

## Filosofia

O Agendamento existe para organizar a agenda do profissional.

Ele não controla a rotina do salão.

O sistema auxilia.

Quem decide é sempre o profissional.

---

# Entidade — Serviço

## Objetivo

Representar um procedimento oferecido pelo salão.

Exemplos:

- Corte
- Escova
- Hidratação
- Coloração
- Progressiva
- Botox capilar

---

## Responsabilidade

O Serviço serve como referência para identificar o que foi planejado em um agendamento e o que foi realizado em um atendimento.

Ele ajuda a padronizar o cadastro e facilita a consulta do histórico da cliente.

---

## O que representa?

O Serviço representa o nome e a descrição de um procedimento oferecido pelo salão.

Na versão 1.0, ele não terá responsabilidade financeira.

---

## Relacionamentos

O Serviço pode estar relacionado com:

- Agendamentos
- Histórico de Atendimento

---

## Serviços pré-estabelecidos

O sistema poderá oferecer uma lista inicial de serviços comuns para facilitar o cadastro.

Exemplos:

- Corte feminino
- Escova
- Hidratação
- Coloração
- Luzes
- Progressiva

O proprietário poderá cadastrar, editar, desativar ou adaptar os serviços conforme a realidade do salão.

---

## Preço

Na versão 1.0, o Serviço não terá preço obrigatório.

Qualquer controle financeiro, precificação detalhada, cobrança, comissão ou integração com pagamento ficará para versões futuras.

---

## Desativação

Serviços poderão ser desativados.

Um serviço desativado não deverá aparecer como opção para novos agendamentos, mas continuará preservado no histórico de atendimentos anteriores.

---

## O que NÃO pertence ao Serviço?

O Serviço não deve ser responsável por:

- Controle financeiro.
- Pagamentos.
- Comissões.
- Cobranças.
- Integrações com APIs de pagamento.
- Definir duração rígida do atendimento.
- Registrar produtos utilizados.

Essas responsabilidades pertencem a evoluções futuras ou ao Histórico de Atendimento.

---

## Filosofia

O Serviço existe para organizar e padronizar os procedimentos oferecidos pelo salão.

Ele deve facilitar o agendamento e o registro do atendimento, sem transformar o MVP em um sistema financeiro complexo.

---

## Possíveis Evoluções

- Preço de referência.
- Comissão por profissional.
- Duração média.
- Pacotes de serviços.
- Integração com pagamentos.
- Controle financeiro.
- Produtos vinculados ao serviço.
---
# Entidade — Profissional

## Objetivo

Representar a pessoa responsável pela execução dos serviços oferecidos pelo salão.

O profissional participa dos agendamentos, realiza atendimentos e contribui para a construção do relacionamento com as clientes.

---

## Responsabilidade

O profissional é responsável por executar os procedimentos oferecidos pelo salão.

Sua participação é registrada nos agendamentos, históricos de atendimento e memórias, permitindo identificar quem realizou cada atendimento.

---

## O que representa?

O profissional representa quem presta o serviço.

Ele não representa um usuário do sistema.

Na versão 1.0, o acesso ao aplicativo será exclusivo do proprietário da conta.

---

## Relacionamentos

O profissional poderá estar relacionado com:

- Agendamentos
- Histórico de Atendimento
- Memórias
- Clientes (como profissional preferencial)

---

## Cadastro

Cada profissional poderá possuir informações como:

- Nome
- Cargo ou função
- Especialidades
- Situação (Ativo ou Inativo)

Outras informações poderão ser adicionadas em versões futuras.

---

## Profissional Preferencial

Uma cliente poderá definir um profissional preferencial.

Essa preferência não impede que outros profissionais realizem atendimentos quando necessário.

Os clientes pertencem ao salão, e não ao profissional.

---

## Desativação

Profissionais poderão ser desativados.

A desativação nunca removerá atendimentos, memórias ou históricos já registrados.

Todo o histórico deverá permanecer preservado.

---

## Utilização do Sistema

Na versão 1.0, apenas o proprietário da conta utilizará o aplicativo.

Os profissionais cadastrados não possuirão acesso individual ao sistema.

Caso uma ajudante ou outro profissional obtenha informações relevantes durante um atendimento, caberá ao proprietário registrar essas informações no sistema.

Essa decisão simplifica o MVP e reduz a complexidade de autenticação, permissões e sincronização entre múltiplos usuários.

---

## O que NÃO pertence ao Profissional?

O profissional não é responsável por:

- Possuir login individual.
- Administrar o salão.
- Ser proprietário dos clientes.
- Controlar informações financeiras.
- Definir permissões do sistema.

Essas responsabilidades pertencem ao proprietário da conta.

---

## Filosofia

O profissional representa quem executa o atendimento.

O relacionamento construído com a cliente é preservado pelo salão, garantindo continuidade mesmo quando houver troca de profissionais ou afastamentos.

---

## Possíveis Evoluções

- Login individual para profissionais.
- Controle de permissões.
- Agenda individual.
- Comissão por profissional.
- Horário de trabalho.
- Metas e indicadores.
- Especialidades avançadas.
- Vínculo com múltiplos salões.

---

# Entidade — Salão

## Objetivo

Representar o estabelecimento administrado pelo proprietário da conta.

O Salão é a principal unidade organizacional do Laços, reunindo clientes, profissionais, serviços e todo o histórico construído ao longo dos atendimentos.

---

## Responsabilidade

O Salão é responsável por organizar todo o contexto operacional do negócio.

A partir dele são agrupados:

- Profissionais
- Clientes
- Serviços
- Agendamentos
- Históricos de Atendimento
- Memórias

Todo relacionamento registrado no sistema pertence ao salão.

---

## O que representa?

O Salão representa o negócio do proprietário.

Embora diferentes profissionais possam atender uma mesma cliente, o relacionamento permanece vinculado ao salão, garantindo continuidade mesmo diante de férias, afastamentos ou troca de profissionais.

---

## Propriedade

Todo salão pertence a um proprietário.

Na versão 1.0, cada proprietário poderá administrar apenas um salão.

A arquitetura deverá permitir evolução futura para múltiplos salões por proprietário.

---

## Relacionamentos

O Salão possui relacionamento com:

- Proprietário
- Profissionais
- Clientes
- Serviços
- Agendamentos
- Históricos de Atendimento
- Memórias

Todas essas entidades existem dentro do contexto do salão.

---

## Cadastro

O salão poderá possuir informações como:

- Nome
- Telefone
- Endereço
- Cidade
- Estado

Outras informações poderão ser adicionadas futuramente.

---

## Desativação

Um salão poderá ser desativado.

A desativação nunca removerá clientes, profissionais, serviços, históricos ou memórias já cadastrados.

Todo o histórico deverá permanecer preservado.

---

## O que NÃO pertence ao Salão?

O Salão não é responsável por:

- Executar atendimentos.
- Registrar memórias.
- Agendar clientes.
- Controlar autenticação dos usuários.
- Gerenciar pagamentos na versão 1.0.

Essas responsabilidades pertencem às respectivas entidades do domínio.

---

## Filosofia

O Salão representa muito mais do que um estabelecimento físico.

Ele representa o ambiente onde relacionamentos são construídos, histórias são registradas e experiências são criadas.

No Laços, o vínculo principal da cliente é com o salão, e não exclusivamente com um profissional.

---

## Possíveis Evoluções

- Múltiplos salões por proprietário.
- Franquias e unidades.
- Configurações específicas por salão.
- Horários de funcionamento.
- Dias de atendimento.
- Identidade visual personalizada.
- Catálogo de serviços público.
- Preços de referência por serviço.
- Promoções por período.
- Promoções para serviços específicos.
- Produtos vinculados aos serviços.

# Histórico de Alterações

| Versão | Data | Descrição |
|---------|------|-----------|
| 1.0 | Julho/2026 | Criação do documento e modelagem das entidades Cliente e Memória. |