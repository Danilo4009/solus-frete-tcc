import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/tema.dart';
import '../core/widgets/comuns.dart';
import '../estado/sessao.dart';
import 'carteira.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<Sessao>();
    final usuario = sessao.usuario;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Bloco(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Cores.fundo,
                child: Icon(Icons.person, size: 30, color: Cores.primaria),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario?.nomeCompleto ?? 'Cliente Solus',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 14, color: Cores.sucesso),
                        const SizedBox(width: 4),
                        Text('+55 ${usuario?.telefone ?? ''}',
                            style: const TextStyle(
                                fontSize: 12.5, color: Cores.textoFraco)),
                      ],
                    ),
                    if (usuario?.email != null)
                      Text(usuario!.email!,
                          style: const TextStyle(
                              fontSize: 12.5, color: Cores.textoFraco)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TituloSecao('Conta'),
        Bloco(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Item(
                icone: Icons.badge_outlined,
                titulo: 'Informacoes pessoais',
                subtitulo: 'Nome, telefone, e-mail e setor',
                onTap: () {},
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.account_balance_wallet_outlined,
                titulo: 'Minha carteira',
                subtitulo: 'Saldo, extrato e cupons',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TelaCarteira()),
                ),
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.apartment_outlined,
                titulo: 'Perfil comercial (PJ)',
                subtitulo: usuario?.empresa == null
                    ? 'Relatorios mensais, carteira compartilhada e usuarios'
                    : usuario!.empresa!.razaoSocial,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TituloSecao('Preferencias'),
        Bloco(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Item(
                icone: Icons.assignment_turned_in_outlined,
                titulo: 'Comprovante de entrega',
                subtitulo: 'Exigir foto ou assinatura por padrao',
                onTap: () {},
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.mail_outline,
                titulo: 'Recibos por e-mail',
                subtitulo: 'Enviar recibo eletronico apos cada pedido',
                onTap: () {},
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.notifications_none_rounded,
                titulo: 'Notificacoes',
                subtitulo: 'Etapas do pedido e promocoes',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TituloSecao('Sobre'),
        Bloco(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Item(
                icone: Icons.privacy_tip_outlined,
                titulo: 'Privacidade e LGPD',
                subtitulo: 'Como tratamos seus dados',
                onTap: () {},
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.price_change_outlined,
                titulo: 'Padrao de precos',
                subtitulo: 'Tabela por cidade e veiculo',
                onTap: () {},
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              _Item(
                icone: Icons.help_outline,
                titulo: 'Central de ajuda',
                subtitulo: 'Perguntas frequentes e atendimento',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Bloco(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Modo do prototipo'),
              Text(
                Config.usarApi
                    ? 'Consumindo a API em ${Config.baseUrl}'
                    : 'Rodando com dados simulados em memoria. '
                        'Para conectar ao MySQL, mude Config.usarApi para true.',
                style: const TextStyle(fontSize: 12.5, color: Cores.textoFraco, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Cores.alerta,
            side: const BorderSide(color: Cores.alerta),
          ),
          onPressed: sessao.sair,
          icon: const Icon(Icons.logout),
          label: const Text('Sair da conta'),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text('Solus Frete - prototipo TCC v1.0',
              style: TextStyle(fontSize: 11.5, color: Cores.textoFraco)),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: Cores.primaria),
      title: Text(titulo, style: const TextStyle(fontSize: 14.5)),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
