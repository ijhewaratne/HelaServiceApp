import 'package:flutter/material.dart';
import '../../../../core/widgets/branded_widgets.dart';

class SkillSelectionPage extends StatefulWidget {
  const SkillSelectionPage({super.key});

  @override
  State<SkillSelectionPage> createState() => _SkillSelectionPageState();
}

class _SkillSelectionPageState extends State<SkillSelectionPage> {
  final Map<String, bool> _skills = {
    'Home Cleaning': false,
    'Babysitting': false,
    'Elderly Care': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Skills')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What services do you provide?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select all that apply. You will only receive job requests for these categories.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            ..._skills.keys.map((skill) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CheckboxListTile(
                  title: Text(skill, style: const TextStyle(fontWeight: FontWeight.w500)),
                  value: _skills[skill],
                  activeColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.grey.shade50,
                  onChanged: (bool? value) {
                    setState(() {
                      _skills[skill] = value ?? false;
                    });
                  },
                ),
              );
            }).toList(),

            const Spacer(),
            BrandedButton(
              label: 'Save Skills',
              onPressed: _skills.values.any((element) => element) 
                ? () {
                    // Navigate to next step: Training Video
                    // context.go('/worker/onboarding/training');
                  } 
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one skill.')),
                    );
                  },
              backgroundColor: _skills.values.any((element) => element) ? Colors.indigo : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
