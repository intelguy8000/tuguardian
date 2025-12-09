import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/sms_provider.dart';
import '../../core/app_colors.dart';
import '../../services/retention_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  RetentionPeriod _selectedRetentionPeriod = RetentionSettingsService.currentPeriod;
  bool _isLoadingRetention = false;

  @override
  void initState() {
    super.initState();
    _loadRetentionSetting();
  }

  Future<void> _loadRetentionSetting() async {
    await RetentionSettingsService.initialize();
    if (mounted) {
      setState(() {
        _selectedRetentionPeriod = RetentionSettingsService.currentPeriod;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
            // Protección (NUEVO)
            _buildSectionHeader('Protección', isDark),
            const SizedBox(height: 12),
            _buildProtectionCard(isDark),

            const SizedBox(height: 16),

            // Período de mensajes
            _buildSettingsCard(
              isDark,
              children: [
                _buildRetentionPeriodTile(isDark),
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

  /// Widget para seleccionar período de retención de mensajes
  Widget _buildRetentionPeriodTile(bool isDark) {
    return ListTile(
      leading: Icon(
        Icons.schedule,
        color: AppColors.primary,
        size: 24,
      ),
      title: Text(
        'Período de mensajes',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _selectedRetentionPeriod.label,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: _isLoadingRetention
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
            ),
      onTap: _isLoadingRetention ? null : () => _showRetentionPeriodDialog(isDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  /// Muestra diálogo para seleccionar período de retención
  void _showRetentionPeriodDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Text(
          'Período de mensajes',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona cuántos mensajes históricos mostrar:',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...RetentionPeriod.values.map((period) => _buildRetentionOption(period, isDark)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Opción individual de período de retención
  Widget _buildRetentionOption(RetentionPeriod period, bool isDark) {
    final isSelected = _selectedRetentionPeriod == period;
    final isUnlimited = period == RetentionPeriod.unlimited;

    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _updateRetentionPeriod(period);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.label,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isUnlimited)
                    Text(
                      'Puede ser lento en dispositivos con muchos SMS',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (period == RetentionPeriod.sixMonths)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recomendado',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Actualiza el período de retención y recarga los mensajes
  Future<void> _updateRetentionPeriod(RetentionPeriod period) async {
    if (period == _selectedRetentionPeriod) return;

    setState(() {
      _isLoadingRetention = true;
    });

    // Guardar preferencia
    await RetentionSettingsService.setPeriod(period);

    setState(() {
      _selectedRetentionPeriod = period;
    });

    // Recargar mensajes con nuevo período
    final smsProvider = Provider.of<SMSProvider>(context, listen: false);

    // Mostrar snackbar de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Recargando mensajes (${period.label})...'),
            ),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Recargar mensajes
      await smsProvider.enableRealMode();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${smsProvider.realMessages.length} mensajes cargados'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error recargando mensajes'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoadingRetention = false;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.security_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('TuGuardian'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu protector personal contra amenazas de smishing. '
                'Protegemos tu seguridad digital con inteligencia artificial avanzada.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Desarrollador',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Juan Andrés García\nMedellín, Colombia',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contacto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Email: 300hbk117@gmail.com\nTeléfono: +57 321 772 6074',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildLegalButton(
                'Política de Privacidad',
                Icons.privacy_tip_outlined,
                () => _openUrl('https://intelguy8000.github.io/tuguardian/privacy-policy-es'),
              ),
              const SizedBox(height: 8),
              _buildLegalButton(
                'Términos y Condiciones',
                Icons.description_outlined,
                () => _openUrl('https://intelguy8000.github.io/tuguardian/terms-of-service-es'),
              ),
              const SizedBox(height: 8),
              _buildLegalButton(
                'Aviso Legal',
                Icons.warning_amber_outlined,
                () => _openUrl('https://intelguy8000.github.io/tuguardian/disclaimer-es'),
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

  Widget _buildLegalButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $urlString')),
        );
      }
    }
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
        title: Row(
          children: const [
            Icon(Icons.support_agent, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Soporte Técnico'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para ayuda o reportar problemas:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email_outlined,
              'Email',
              '300hbk117@gmail.com',
              () => _openUrl('mailto:300hbk117@gmail.com'),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              Icons.phone_outlined,
              'Teléfono',
              '+57 321 772 6074',
              () => _openUrl('tel:+573217726074'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Horario de atención:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lunes a Viernes\n9:00 AM - 6:00 PM (GMT-5)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
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

  Widget _buildContactItem(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// NUEVO: Card de protección con botón para activar modo real
  Widget _buildProtectionCard(bool isDark) {
    final smsProvider = Provider.of<SMSProvider>(context);
    final isProtectionActive = smsProvider.isRealModeEnabled;
    final realMessageCount = smsProvider.realMessages.length;

    return _buildSettingsCard(
      isDark,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isProtectionActive ? Icons.shield : Icons.shield_outlined,
                    color: isProtectionActive ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProtectionActive ? 'Protección Activa' : 'Protección Inactiva',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isProtectionActive
                              ? '$realMessageCount SMS analizados'
                              : 'Activa la protección para analizar tus SMS',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProtectionActive ? null : () async {
                    // Mostrar loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Activar protección
                    bool success = await smsProvider.enableRealMode();

                    // Cerrar loading
                    Navigator.pop(context);

                    // Mostrar resultado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '✅ Protección activada - ${smsProvider.realMessages.length} SMS cargados'
                              : '❌ Error activando protección',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProtectionActive ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isProtectionActive ? 'Protección Activa' : 'Activar Protección',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}