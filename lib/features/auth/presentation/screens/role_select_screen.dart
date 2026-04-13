import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String? _selectedRole;
  final _nameController = TextEditingController();

  void _handleComplete() async {
    final name = _nameController.text.trim();
    if (_selectedRole == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and select a role')));
      return;
    }

    final vm = context.read<AuthViewModel>();
    await vm.selectRoleAndComplete(_selectedRole!, name);

    if (vm.errorMessage == null && context.mounted) {
      if (_selectedRole == 'customer') {
        context.go('/customer');
      } else {
        context.go('/worker');
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'How will you use Servix?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 30),
            
            _buildRoleCard('Customer', 'I want to book services.', Icons.person, 'customer', 200),
            _buildRoleCard('Provider', 'I want to offer my services.', Icons.handyman, 'worker', 300),
            
            const SizedBox(height: 40),
            Text(
              'What is your name?',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),
            
            const SizedBox(height: 40),
            vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : BrandedButton(
                    label: 'Complete Setup',
                    onPressed: _handleComplete,
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon, String value, int delayMs) {
    final isSelected = _selectedRole == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: () => setState(() => _selectedRole = value),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: colorScheme.primary, width: 2) : Border.all(color: Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: isSelected ? Colors.white : colorScheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideY(begin: 0.2);
  }
}
