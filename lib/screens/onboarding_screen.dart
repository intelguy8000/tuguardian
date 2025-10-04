import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '¡Bienvenido a TuGuardian!',
      subtitle: 'Tu protector personal contra mensajes fraudulentos',
      description: 'Protegemos a ti y tu familia de estafas por SMS que roban dinero y datos personales. Con inteligencia artificial avanzada, detectamos amenazas antes de que puedas hacer clic.',
      icon: Icons.security_rounded,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Detectamos Amenazas',
      subtitle: 'Inteligencia artificial en tiempo real',
      description: 'Nuestra IA analiza cada mensaje instantáneamente, detectando patrones sospechosos, enlaces maliciosos y técnicas de manipulación emocional.',
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Te Ayudamos a Verificar',
      subtitle: 'Canales oficiales seguros',
      description: 'Si tienes dudas sobre un mensaje de tu banco o empresa, te conectamos directamente con sus canales oficiales verificados.',
      icon: Icons.verified_user,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Configuración de Permisos',
      subtitle: 'Para protegerte necesitamos acceso a SMS',
      description: 'Solo analizamos el contenido para detectar amenazas. Tu privacidad es sagrada - nunca compartimos ni vendemos tus datos.',
      icon: Icons.message,
      color: Colors.orange,
      isPermissionPage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Skip button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: () => _skipToEnd(),
              child: Text(
                'Saltar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
          else
            SizedBox(width: 60),
          
          Spacer(),
          
          // Dots indicator
          Row(
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? _pages[_currentPage].color 
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          Spacer(),
          SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: 40),
          
          // Icon/Animation
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.color.withOpacity(0.1),
                  page.color.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(90),
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          
          SizedBox(height: 40),
          
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.2,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: page.color,
            ),
          ),
          
          SizedBox(height: 24),
          
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: 40),
          
          // Special content for permission page
          if (page.isPermissionPage) ...[
            _buildPermissionExplanation(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionExplanation() {
    return Container(
      constraints: BoxConstraints(maxHeight: 280), // Límite de altura
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permisos necesarios para tu protección',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPermissionItem(
              Icons.message,
              'Leer mensajes SMS',
              'Para analizar y detectar mensajes peligrosos en tiempo real',
            ),
            _buildPermissionItem(
              Icons.notification_important,
              'Mostrar notificaciones',
              'Para alertarte inmediatamente sobre amenazas detectadas',
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.green[600], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los datos se procesan localmente en tu dispositivo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[600], size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Main action button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1 
                  ? _requestPermissions
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_currentPage].color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentPage == _pages.length - 1 
                    ? 'Activar Protección TuGuardian'
                    : 'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          if (_currentPage > 0) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: _previousPage,
              child: Text(
                'Anterior',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestPermissions() async {
    _showLoadingDialog();

    try {
      // Request SMS permission (CRITICAL - core functionality)
      PermissionStatus smsStatus = await Permission.sms.request();

      // Request notification permission (important for alerts)
      await Permission.notification.request();

      Navigator.of(context).pop(); // Close loading dialog

      if (smsStatus.isGranted) {
        // Save onboarding completion
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
        
        _showSuccessDialog();
      } else {
        _showPermissionErrorDialog();
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showPermissionErrorDialog();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Configurando tu protección...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                '¡Protección Activada!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TuGuardian ahora protege tus mensajes contra amenazas de smishing',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: Text('¡Empezar a usar TuGuardian!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permisos Necesarios'),
        content: Text(
          'TuGuardian necesita acceso a tus mensajes SMS para poder protegerte contra amenazas de smishing. '
          'Sin estos permisos, no podemos detectar mensajes maliciosos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Intentar Después'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPermissionPage;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.isPermissionPage = false,
  });
}