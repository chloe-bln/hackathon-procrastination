import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/reward.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_preview.dart';
import '../widgets/pastel_card.dart';

class AvatarScreen extends ConsumerWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final state = app.appState!;
    final hairItems = app.inventory.where((i) => i.type == 'hair').toList();
    final clothesItems = app.inventory.where((i) => i.type == 'clothes').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Avatar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                PastelCard(
                  child: Column(
                    children: [
                      AvatarPreview(hair: state.avatarHair, clothes: state.avatarClothes, size: 210),
                      const SizedBox(height: 12),
                      Text('Unlock cosmetics by leveling up.', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _PickerSection(
                  title: 'Hair',
                  selectedId: state.avatarHair,
                  items: hairItems,
                  onSelected: (item) => ref.read(appControllerProvider.notifier).selectAvatar(hair: item.id),
                ),
                const SizedBox(height: 18),
                _PickerSection(
                  title: 'Clothes',
                  selectedId: state.avatarClothes,
                  items: clothesItems,
                  onSelected: (item) => ref.read(appControllerProvider.notifier).selectAvatar(clothes: item.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerSection extends StatelessWidget {
  const _PickerSection({required this.title, required this.items, required this.selectedId, required this.onSelected});

  final String title;
  final List<Reward> items;
  final String selectedId;
  final ValueChanged<Reward> onSelected;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (item) => ChoiceChip(
                    selected: selectedId == item.id,
                    selectedColor: CozyColors.mint,
                    label: Text(item.label),
                    onSelected: (_) => onSelected(item),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
