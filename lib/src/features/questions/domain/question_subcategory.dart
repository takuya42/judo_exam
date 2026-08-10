import 'package:flutter/material.dart';

/// Presentation metadata for a question subcategory.
///
/// Keeping this separate from [Question] makes the selection UI reusable as
/// more subjects add ordered subcategories.
@immutable
class QuestionSubcategory {
  const QuestionSubcategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const anatomySubcategories = <QuestionSubcategory>[
  QuestionSubcategory(label: '解剖学総論', icon: Icons.menu_book_rounded),
  QuestionSubcategory(label: '骨格系', icon: Icons.accessibility_new_rounded),
  QuestionSubcategory(label: '関節・靱帯', icon: Icons.device_hub_rounded),
  QuestionSubcategory(label: '筋系', icon: Icons.fitness_center_rounded),
  QuestionSubcategory(label: '神経系', icon: Icons.account_tree_rounded),
  QuestionSubcategory(label: '循環器系', icon: Icons.favorite_rounded),
  QuestionSubcategory(label: 'リンパ系', icon: Icons.bubble_chart_rounded),
  QuestionSubcategory(label: '呼吸器系', icon: Icons.air_rounded),
  QuestionSubcategory(label: '消化器系', icon: Icons.restaurant_rounded),
  QuestionSubcategory(label: '泌尿器系', icon: Icons.water_drop_rounded),
  QuestionSubcategory(label: '生殖器系', icon: Icons.family_restroom_rounded),
  QuestionSubcategory(label: '内分泌系', icon: Icons.science_rounded),
  QuestionSubcategory(label: '感覚器', icon: Icons.visibility_rounded),
];
