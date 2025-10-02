import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/sms_provider.dart';
import '../../core/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBlock = false;
  bool _biometricLock = false;
  double _sensitivityLevel = 0.8;
  String _selectedLanguage = 'Español';
  bool _shareAnonymousData = false;
  bool _isLoadingRealMode = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final smsProvider = Provider.of<SMSProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Protección
            _buildSectionHeader('Protección', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark,
              children: [
                _buildRealModeSwitch(smsProvider, isDark),
                _buildDivider(isDark),
                _buildSwitchTile(
                  'Bloqueo automático',
                  'Bloquea amenazas automáticamente',
                  _autoBlock,
                  (value) => setState(() => _autoBlock = value),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildSliderTile(
                  'Nivel de sensibilidad',
                  'Ajusta qué tan estricto es el filtro',
                  _sensitivityLevel,
                  (value) => setState(() => _sensitivityLevel = value),
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notificaciones
            _buildSectionHeader('Notificaciones', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  'Notificaciones push',
                  'Recibe alertas de amenazas',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacidad y Seguridad
            _buildSectionHeader('Privacidad y Seguridad', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  'Bloqueo biométrico',
                  'Usa huella/Face ID para abrir la app',
                  _biometricLock,
                  (value) => setState(() => _biometricLock = value),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  'Compartir datos anónimos',
                  'Ayuda a mejorar la detección',
                  _shareAnonymousData,
                  (value) => setState(() => _shareAnonymousData = value),
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Apariencia
            _buildSectionHeader('Apariencia', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSwitchTile(
                  'Modo oscuro',
                  'Cambia el tema de la aplicación',
                  isDark,
                  (value) => themeProvider.toggleTheme(),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildDropdownTile(
                  'Idioma',
                  'Selecciona el idioma de la app',
                  _selectedLanguage,
                  ['Español', 'English', 'Français', 'Português'],
                  (value) => setState(() => _selectedLanguage = value!),
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Información
            _buildSectionHeader('Información', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark,
              children: [
                _buildTapTile(
                  'Acerca de TuGuardian',
                  'Versión y información legal',
                  () => _showAboutDialog(),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildTapTile(
                  'Política de privacidad',
                  'Términos y condiciones',
                  () => _showPrivacyPolicy(),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildTapTile(
                  'Soporte técnico',
                  'Contacto y ayuda',
                  () => _showSupport(),
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRealModeSwitch(SMSProvider smsProvider, bool isDark) {
    return ListTile(
      title: Text(
        'Protección en tiempo real',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        smsProvider.isRealModeEnabled
          ? '✅ Activa - ${smsProvider.allMessages.length} mensajes analizados'
          : '⚙️ Inicializando...',
        style: TextStyle(
          color: smsProvider.isRealModeEnabled
              ? Colors.green
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: smsProvider.isRealModeEnabled
        ? Icon(
            Icons.shield_outlined,
            color: Colors.green,
            size: 28,
          )
        : SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
      onTap: smsProvider.isRealModeEnabled
          ? null
          : () async {
              // If not enabled yet, try to enable on tap
              setState(() => _isLoadingRealMode = true);
              try {
                await smsProvider.enableRealMode();
                if (mounted) {
                  int totalMessages = smsProvider.realMessages.length;
                  int threats = smsProvider.realMessages.where((m) => m.isDangerous).length;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Protección activada!\n'
                        '📱 $totalMessages mensajes analizados\n'
                        '${threats > 0 ? "🚫 $threats amenazas bloqueadas" : "✅ Ninguna amenaza detectada"}'
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoadingRealMode = false);
                }
              }
            },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    ValueChanged<double> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Bajo',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  inactiveColor: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              Text(
                'Alto',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        underline: Container(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildTapTile(
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TuGuardian'),
        content: const Text(
          'Versión 1.0.0\n\n'
          'Tu protector personal contra amenazas de smishing. '
          'Protegemos tu seguridad digital con inteligencia artificial avanzada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidad y Términos'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PROCESAMIENTO DE DATOS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'TuGuardian procesa los mensajes SMS localmente en tu dispositivo. '
                'No compartimos ni vendemos tu información personal. '
                'Los datos son utilizados únicamente para detectar amenazas de smishing.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'ELIMINACIÓN DE MENSAJES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'IMPORTANTE: Al eliminar conversaciones en TuGuardian, los mensajes se eliminan únicamente de la base de datos local de TuGuardian. '
                'Los mensajes SMS permanecerán en el sistema Android y seguirán visibles en otras aplicaciones de mensajería (como Google Messages). '
                'TuGuardian no tiene permiso para eliminar mensajes del sistema Android.\n\n'
                'Si desinstalas y reinstalas TuGuardian, los mensajes "eliminados" volverán a aparecer, '
                'ya que la aplicación los cargará nuevamente desde el sistema Android.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'ALMACENAMIENTO LOCAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toda la información se almacena exclusivamente en tu dispositivo. '
                'No utilizamos servidores externos para almacenar tus mensajes.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soporte Técnico'),
        content: const Text(
          'Para soporte técnico, contacta:\n\n'
          'Email: soporte@tuguardian.com\n'
          'Teléfono: +57 300 123 4567\n'
          'Web: www.tuguardian.com/soporte',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}