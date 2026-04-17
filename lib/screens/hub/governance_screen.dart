import 'package:flutter/material.dart';

import '../../services/governance_service.dart';

class GovernanceScreen extends StatefulWidget {
  const GovernanceScreen({super.key});

  @override
  State<GovernanceScreen> createState() => _GovernanceScreenState();
}

class _GovernanceScreenState extends State<GovernanceScreen> {
  @override
  void initState() {
    super.initState();
    GovernanceService.ensureSeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'ETHIC COUNCIL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: StreamBuilder<Map<String, String>>(
        stream: GovernanceService.streamMyVotes(),
        builder: (context, voteSnapshot) {
          final myVotes = voteSnapshot.data ?? const <String, String>{};

          return StreamBuilder<List<GovernanceProposal>>(
            stream: GovernanceService.streamProposals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              }

              final proposals = snapshot.data ?? const <GovernanceProposal>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF121A2B), Color(0xFF27142F)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yapay Zeka Yasama ve Etik Konseyi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Likid demokrasi mantığında küçük ama sürekli oylamalarla algoritma, pasif katkı ve dijital miras kuralları şekillenir.',
                          style: TextStyle(color: Colors.white70, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...proposals.map(
                    (proposal) => _ProposalCard(
                      proposal: proposal,
                      currentChoice: myVotes[proposal.id] ?? '',
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final GovernanceProposal proposal;
  final String currentChoice;

  const _ProposalCard({
    required this.proposal,
    required this.currentChoice,
  });

  @override
  Widget build(BuildContext context) {
    final total = proposal.yesCount + proposal.noCount + proposal.abstainCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proposal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  proposal.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            proposal.description,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VoteChip(
                  label: 'Evet ${proposal.yesCount}',
                  accent: Colors.greenAccent,
                  selected: currentChoice == 'yes',
                  onTap: () => GovernanceService.castVote(
                    proposalId: proposal.id,
                    choice: 'yes',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VoteChip(
                  label: 'Hayır ${proposal.noCount}',
                  accent: Colors.redAccent,
                  selected: currentChoice == 'no',
                  onTap: () => GovernanceService.castVote(
                    proposalId: proposal.id,
                    choice: 'no',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VoteChip(
                  label: 'Çekimser ${proposal.abstainCount}',
                  accent: Colors.orangeAccent,
                  selected: currentChoice == 'abstain',
                  onTap: () => GovernanceService.castVote(
                    proposalId: proposal.id,
                    choice: 'abstain',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Toplam mikro oy: $total',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _VoteChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? accent : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
