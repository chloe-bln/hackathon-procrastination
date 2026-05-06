import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_decoration.dart';
import '../widgets/pastel_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: 48, left: 42, child: FlowerDecoration(size: 74)),
          const Positioned(bottom: 50, right: 50, child: FlowerDecoration(size: 54)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 520),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
                ),
                child: PastelCard(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome to Cozy Goals 🌷',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: CozyColors.cocoa),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A gentle local-first place to build momentum without pressure.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a username' : null,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.cake_rounded),
                          label: Text(_birthDate == null
                              ? 'Choose birth date'
                              : 'Birth date: ${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.spa_rounded),
                          label: const Text('Start softly'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: DateTime(now.year - 20),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a birth date.')));
      return;
    }
    await ref.read(appControllerProvider.notifier).completeOnboarding(username: _username.text, birthDate: _birthDate!);
  }
}
