import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../screens/dictionary_screen.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/geo_top_bar.dart';
import '../widgets/glass_card.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GeoBackground(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: GeoTopBar(title: 'AYARLAR'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(10),
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return Column(
                          children: [
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: const Text(
                                'Ses Efektleri',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Doğru/Yanlış sesleri',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              secondary: Icon(
                                settings.isSoundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: settings.isSoundEnabled
                                    ? AppColors.primaryBlue
                                    : AppColors.textMuted,
                              ),
                              activeColor: AppColors.primaryBlue,
                              value: settings.isSoundEnabled,
                              onChanged: (value) {
                                Provider.of<SettingsProvider>(
                                  context,
                                  listen: false,
                                ).triggerButtonVibration();
                                settings.toggleSound(value);
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              title: const Text(
                                'Titreşim',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Buton tıklama hissi',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              secondary: Icon(
                                settings.isVibrationEnabled
                                    ? Icons.vibration_rounded
                                    : Icons.smartphone_rounded,
                                color: settings.isVibrationEnabled
                                    ? AppColors.primaryBlue
                                    : AppColors.textMuted,
                              ),
                              activeColor: AppColors.primaryBlue,
                              value: settings.isVibrationEnabled,
                              onChanged: (value) {
                                Provider.of<SettingsProvider>(
                                  context,
                                  listen: false,
                                ).triggerButtonVibration();
                                settings.toggleVibration(value);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    onTap: () {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).triggerButtonVibration();
                      Navigator.of(
                        context,
                      ).push(FadePageRoute(page: const DictionaryScreen()));
                    },
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Öğren & Keşfet',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ülkeler, başkentler ve kıtalar',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'İpuçları',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Skor ve hız için soruları seri çöz.\n'
                          '• Sıralama sekmesinden kategori seçerek listeye gir.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
