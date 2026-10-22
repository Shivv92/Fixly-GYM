import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import 'dart:convert';

// Your actual keys
const supabaseUrl = 'https://tjffhmeedaolhzimxfkh.supabase.co';
const supabaseKey = 'sb_publishable_cdpJ34F0Pi3v-jZCgMFiXQ_1SyRDSws';

// Global Camera List
List<CameraDescription> globalCameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  // Initialize Hardware Cameras securely
  try {
    globalCameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera init error: $e');
  }

  runApp(const FixlyGymApp());
}

class FixlyGymApp extends StatelessWidget {
  const FixlyGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixly Gym SaaS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> _getUserRole(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return data['role'] as String;
    } catch (e) {
      return 'member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return FutureBuilder<String>(
            future: _getUserRole(session.user.id),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))));
              }
              final role = roleSnapshot.data ?? 'member';
              
              if (role == 'manager') return const ManagerHub();
              if (role == 'trainer') return const TrainerHub();
              return const MemberDashboard();
            },
          );
        }
        return const PublicLandingScreen();
      },
    );
  }
}

// -----------------------------------------------------------------------------
// PUBLIC LANDING PAGE
// -----------------------------------------------------------------------------
class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Fixly Gym SaaS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.5)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, 
                    end: Alignment.bottomCenter, 
                    colors: [const Color(0xFF06B6D4).withValues(alpha: 0.3), const Color(0xFF030712)]
                  ),
                ),
                child: const Center(child: Icon(Icons.bolt, size: 80, color: Color(0xFF06B6D4))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next-Gen Gym Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  const Text('An intelligent, white-label fitness ecosystem connecting members, trainers, and gym owners with real-time biometric metrics.', style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
                  const SizedBox(height: 36),
                  
                  const Text('Platform Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  const _FeatureRow(icon: Icons.view_in_ar, title: '3D AI Biometric Hologram', subtitle: 'Captures physique metrics via native camera and generates interactive 3D topology tracking muscle hypertrophy over time.'),
                  const _FeatureRow(icon: Icons.notifications_active, title: 'Live Push Notifications', subtitle: 'Members receive instant alerts via WebSocket the second a trainer assigns a custom routine.'),
                  const _FeatureRow(icon: Icons.shield, title: 'Multi-Tenant Privacy', subtitle: 'Row-Level cloud isolation guarantees each gym completely owns and protects their member data.'),
                  const SizedBox(height: 36),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: const Color(0xFF334155), width: 1.5)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars, color: Color(0xFF06B6D4), size: 28), 
                            SizedBox(width: 12), 
                            Text('SaaS Licensing Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))
                          ]
                        ),
                        const SizedBox(height: 12),
                        const Text('Unlock full multi-tenant capabilities for your gym.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 20),
                        const _PricingTierCard(title: '15-Day Pass', price: '₹499', desc: 'Quick trial access for testing.', color: Colors.white),
                        const SizedBox(height: 12),
                        const _PricingTierCard(title: 'Annual Pro', price: '₹8,499', desc: 'Full priority access + unlimited scaling.', color: Colors.purpleAccent),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4), 
                              foregroundColor: Colors.black, 
                              elevation: 0, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                            ),
                            icon: const Icon(Icons.business),
                            label: const Text('Subscribe & Register Gym', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isSignUpMode: true))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155), width: 1.5), 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.person),
                      label: const Text('Student / Trainer Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isSignUpMode: false))),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingTierCard extends StatelessWidget {
  final String title;
  final String price;
  final String desc;
  final Color color;
  const _PricingTierCard({required this.title, required this.price, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF030712), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: const Color(0xFF1E293B))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)), 
                const SizedBox(height: 4), 
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12))
              ]
            )
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECURE LOGIN
// -----------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final bool isSignUpMode;
  const LoginScreen({super.key, this.isSignUpMode = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUpMode;
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim(), 
          data: {'role': 'manager'}
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim()
        );
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, size: 72, color: Color(0xFF06B6D4)),
                const SizedBox(height: 20),
                Text('FIXLY GYM', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? 'Enter a valid email' : null,
                  decoration: InputDecoration(
                    labelText: 'Email Address', 
                    prefixIcon: const Icon(Icons.email_outlined), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                    filled: true, 
                    fillColor: const Color(0xFF0F172A)
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be 6+ chars' : null,
                  decoration: InputDecoration(
                    labelText: 'Password', 
                    prefixIcon: const Icon(Icons.lock_outline), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                    filled: true, 
                    fillColor: const Color(0xFF0F172A)
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4), 
                      foregroundColor: Colors.black, 
                      elevation: 0, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: _isLoading ? null : _authenticate,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : Text(_isSignUp ? 'Subscribe & Register' : 'Secure Login', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp), 
                  child: Text(
                    _isSignUp ? 'Student/Trainer? Login Here' : 'Gym Owner? Register Your Gym Here', 
                    style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 14)
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BIOMETRIC HUD CAMERA OVERLAY
// -----------------------------------------------------------------------------
class BiometricScannerScreen extends StatefulWidget {
  const BiometricScannerScreen({super.key});

  @override
  State<BiometricScannerScreen> createState() => _BiometricScannerScreenState();
}

class _BiometricScannerScreenState extends State<BiometricScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (globalCameras.isEmpty) return;
    
    CameraDescription selectedCamera = globalCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => globalCameras.first,
    );

    _cameraController = CameraController(selectedCamera, ResolutionPreset.high, enableAudio: false);
    
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      await _cameraController!.takePicture();

      if (!mounted) return;

      showDialog(context: context, barrierDismissible: false, builder: (context) => const _AnalysisOverlay());
      await Future.delayed(const Duration(seconds: 4));
      
      if (!mounted) return;
      
      Navigator.pop(context); // Pop Dialog
      Navigator.pop(context); // Pop Camera Screen
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const _HologramResultModal(),
      );

    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                stops: const [0.0, 0.2, 0.8],
              )
            ),
          ),

          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _HudAlignmentPainter(pulseValue: _animationController.value),
                size: Size.infinite,
              );
            },
          ),

          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF06B6D4))),
                child: const Text('ALIGN BODY WITHIN GUIDELINES', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text('STAND STILL FOR ACCURATE TOPOLOGY', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isProcessing ? null : _captureAndAnalyze,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF06B6D4), width: 4),
                      color: _isProcessing ? const Color(0xFF06B6D4).withValues(alpha: 0.5) : const Color(0xFF0F172A).withValues(alpha: 0.8),
                    ),
                    child: Center(
                      child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.fingerprint, color: Color(0xFF06B6D4), size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudAlignmentPainter extends CustomPainter {
  final double pulseValue;
  _HudAlignmentPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;

    final Paint linePaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5 + (pulseValue * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint dashPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double dashHeight = 10.0;
    const double dashSpace = 8.0;
    double startY = size.height * 0.15;
    
    while (startY < size.height * 0.75) {
      canvas.drawLine(Offset(cx, startY), Offset(cx, startY + dashHeight), dashPaint);
      startY += dashHeight + dashSpace;
    }

    final Rect headRect = Rect.fromCenter(center: Offset(cx, size.height * 0.25), width: size.width * 0.4, height: size.height * 0.18);
    canvas.drawOval(headRect, linePaint);

    final Path path = Path();
    path.moveTo(cx - (size.width * 0.15), size.height * 0.34);
    path.quadraticBezierTo(cx - (size.width * 0.35), size.height * 0.35, cx - (size.width * 0.4), size.height * 0.42);
    path.lineTo(cx - (size.width * 0.4), size.height * 0.65);

    path.moveTo(cx + (size.width * 0.15), size.height * 0.34);
    path.quadraticBezierTo(cx + (size.width * 0.35), size.height * 0.35, cx + (size.width * 0.4), size.height * 0.42);
    path.lineTo(cx + (size.width * 0.4), size.height * 0.65);
    
    canvas.drawPath(path, linePaint);

    const double bracketLen = 30.0;
    
    canvas.drawLine(const Offset(20, 100), const Offset(20 + bracketLen, 100), linePaint);
    canvas.drawLine(const Offset(20, 100), const Offset(20, 100 + bracketLen), linePaint);
    
    canvas.drawLine(Offset(size.width - 20, 100), Offset(size.width - 20 - bracketLen, 100), linePaint);
    canvas.drawLine(Offset(size.width - 20, 100), Offset(size.width - 20, 100 + bracketLen), linePaint);
    
    canvas.drawLine(Offset(20, size.height - 150), Offset(20 + bracketLen, size.height - 150), linePaint);
    canvas.drawLine(Offset(20, size.height - 150), Offset(20, size.height - 150 - bracketLen), linePaint);
    
    canvas.drawLine(Offset(size.width - 20, size.height - 150), Offset(size.width - 20 - bracketLen, size.height - 150), linePaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 150), Offset(size.width - 20, size.height - 150 - bracketLen), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}

// -----------------------------------------------------------------------------
// DASHBOARDS
// -----------------------------------------------------------------------------
class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});
  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final _weightController = TextEditingController();

  bool _isLoading = true;
  String _gymName = 'Loading...';
  String? _gymLogo;
  List<dynamic> _workouts = [];
  Map<String, dynamic>? _dailyStats;
  List<dynamic> _weightLogs = [];
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _setupRealtimeNotifications();
  }

  void _showTopNotification(String title, String message, IconData icon) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0, 
        behavior: SnackBarBehavior.floating, 
        backgroundColor: Colors.transparent, 
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 180, 
          left: 16, 
          right: 16
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95), 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: const Color(0xFF06B6D4), width: 1.5), 
            boxShadow: const [BoxShadow(color: Color(0x4006B6D4), blurRadius: 20)]
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.yellowAccent, size: 32), 
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)), 
                    const SizedBox(height: 4), 
                    Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13))
                  ]
                )
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _setupRealtimeNotifications() {
    Supabase.instance.client.channel('public:workouts').onPostgresChanges(
      event: PostgresChangeEvent.insert, 
      schema: 'public', 
      table: 'workouts', 
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: _userId),
      callback: (payload) {
        if (mounted) {
          _showTopNotification('Coach Update 💪', 'Your trainer assigned: ${payload.newRecord['name']}', Icons.fitness_center);
          _fetchDashboardData(); 
        }
      }
    ).subscribe();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client.from('profiles').select('gym_id, gyms(name, logo_url)').eq('id', _userId).single();
      final statsResponse = await Supabase.instance.client.from('daily_stats').select().eq('user_id', _userId).maybeSingle();
      final workoutsResponse = await Supabase.instance.client.from('workouts').select().eq('user_id', _userId).order('created_at', ascending: true);
      final weightsResponse = await Supabase.instance.client.from('weight_logs').select().eq('user_id', _userId).order('logged_at', ascending: false).limit(1);

      setState(() {
        if (profile['gyms'] != null) { 
          _gymName = profile['gyms']['name'] ?? 'Elite Fitness Hub'; 
          _gymLogo = profile['gyms']['logo_url']; 
        }
        _dailyStats = statsResponse; 
        _workouts = workoutsResponse; 
        _weightLogs = weightsResponse;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkout(String id, bool currentStatus) async {
    await Supabase.instance.client.from('workouts').update({'is_completed': !currentStatus}).eq('id', id);
    _fetchDashboardData();
  }

  Future<void> _updateWater(int change) async {
    if (_dailyStats == null) return;
    int newWater = ((_dailyStats!['water_glasses'] ?? 0) + change).clamp(0, 20) as int;
    await Supabase.instance.client.from('daily_stats').update({'water_glasses': newWater}).eq('id', _dailyStats!['id']);
    
    if (newWater == 8 && change > 0) {
      _showTopNotification('Goal Reached! 💧', 'You hit 8 glasses of water today. Great job!', Icons.water_drop);
    }
    _fetchDashboardData();
  }

  Future<void> _logWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 20 || weight > 300) return;
    
    await Supabase.instance.client.from('weight_logs').insert({'user_id': _userId, 'weight_kg': weight});
    
    if (!mounted) return;
    _weightController.clear();
    _fetchDashboardData();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))));
    
    final waterGlasses = _dailyStats?['water_glasses'] ?? 0;
    final latestWeight = _weightLogs.isNotEmpty ? _weightLogs.first['weight_kg'] : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_gymLogo != null && _gymLogo!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8), 
                child: Image.network(_gymLogo!, height: 32, width: 32, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 28))
              ), 
              const SizedBox(width: 12)
            ], 
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
          ]
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: () => Supabase.instance.client.auth.signOut())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, 
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), 
                borderRadius: BorderRadius.circular(28), 
                border: Border.all(color: const Color(0xFF334155), width: 1.5), 
                boxShadow: const [BoxShadow(color: Color(0x2006B6D4), blurRadius: 30, spreadRadius: -5)]
              ),
              child: Column(
                children: [
                  const Icon(Icons.vrpano_outlined, size: 56, color: Color(0xFF06B6D4)), 
                  const SizedBox(height: 20),
                  const Text('AI Body Scan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)), 
                  const SizedBox(height: 8),
                  const Text('Map your hypertrophy progress via biometric lens.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)), 
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity, 
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4), 
                        foregroundColor: Colors.black, 
                        elevation: 0, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.camera_alt, size: 22), 
                      label: const Text('Launch Scanner', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BiometricScannerScreen())),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                  const SizedBox(height: 16),
                  if (_workouts.isEmpty) 
                    const Text('No workouts assigned by your trainer yet.', style: TextStyle(color: Colors.grey))
                  else 
                    ..._workouts.map((workout) => ListTile(
                      contentPadding: EdgeInsets.zero, 
                      title: Text(
                        workout['name'], 
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          color: workout['is_completed'] ? Colors.grey : Colors.white, 
                          decoration: workout['is_completed'] ? TextDecoration.lineThrough : null
                        )
                      ), 
                      subtitle: Text(workout['sets_reps'], style: const TextStyle(color: Colors.grey, fontSize: 13)), 
                      trailing: IconButton(
                        icon: Icon(
                          workout['is_completed'] ? Icons.check_circle : Icons.circle_outlined, 
                          size: 28, 
                          color: workout['is_completed'] ? const Color(0xFF06B6D4) : Colors.grey
                        ), 
                        onPressed: () => _toggleWorkout(workout['id'], workout['is_completed'])
                      )
                    )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hydration Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text('$waterGlasses / 8 Glasses', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)), 
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 28), onPressed: () => _updateWater(-1)), 
                          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 28), onPressed: () => _updateWater(1))
                        ]
                      )
                    ]
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Body Weight Logging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                  const SizedBox(height: 6),
                  Text(latestWeight != null ? 'Latest Entry: $latestWeight kg' : 'No entries yet', style: const TextStyle(color: Colors.grey, fontSize: 13)), 
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController, 
                          keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                          decoration: InputDecoration(
                            hintText: 'Enter weight (kg)', 
                            filled: true, 
                            fillColor: const Color(0xFF030712), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                          )
                        )
                      ), 
                      const SizedBox(width: 12), 
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4), 
                          foregroundColor: Colors.black, 
                          elevation: 0, 
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ), 
                        onPressed: _logWeight, 
                        child: const Text('Log', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
                      )
                    ]
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class TrainerHub extends StatefulWidget {
  const TrainerHub({super.key});
  @override
  State<TrainerHub> createState() => _TrainerHubState();
}

class _TrainerHubState extends State<TrainerHub> {
  bool _isLoading = true; 
  String _gymName = 'Loading...'; 
  String? _gymLogo; 
  List<dynamic> _members = []; 
  String? _selectedMemberId;
  
  final _exerciseController = TextEditingController(); 
  final _setsController = TextEditingController(); 
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() { 
    super.initState(); 
    _fetchMembers(); 
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client.from('profiles').select('gym_id, gyms(name, logo_url)').eq('id', _userId).single();
      final response = await Supabase.instance.client.from('profiles').select('id, full_name, email').eq('role', 'member');
      setState(() { 
        if (profile['gyms'] != null) { 
          _gymName = profile['gyms']['name'] ?? 'Trainer Hub'; 
          _gymLogo = profile['gyms']['logo_url']; 
        } 
        _members = response; 
        if (_members.isNotEmpty) { 
          _selectedMemberId = _members.first['id']; 
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _assignWorkout() async {
    if (_selectedMemberId == null || _exerciseController.text.isEmpty || _setsController.text.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent)); 
      return; 
    }
    try {
      await Supabase.instance.client.from('workouts').insert({
        'user_id': _selectedMemberId, 
        'name': _exerciseController.text.trim(), 
        'sets_reps': _setsController.text.trim()
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout assigned! Member notified.'), backgroundColor: Colors.green));
      _exerciseController.clear(); 
      _setsController.clear(); 
      FocusScope.of(context).unfocus();
    } catch (e) { 
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_gymLogo != null && _gymLogo!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6), 
                child: Image.network(_gymLogo!, height: 28, width: 28, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 24))
              ), 
              const SizedBox(width: 10)
            ], 
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          ]
        ), 
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchMembers), 
          IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: () => Supabase.instance.client.auth.signOut())
        ]
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Container(
                  padding: const EdgeInsets.all(20), 
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text('Push Custom Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                      const SizedBox(height: 20), 
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMemberId, 
                        decoration: InputDecoration(
                          labelText: 'Select Client', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        ), 
                        dropdownColor: const Color(0xFF030712), 
                        items: _members.map<DropdownMenuItem<String>>((member) { 
                          final name = member['full_name'] ?? member['email'] ?? 'Unnamed Client'; 
                          return DropdownMenuItem<String>(value: member['id'], child: Text(name, style: const TextStyle(color: Colors.white))); 
                        }).toList(), 
                        onChanged: (String? newValue) => setState(() => _selectedMemberId = newValue)
                      ), 
                      const SizedBox(height: 16), 
                      TextField(
                        controller: _exerciseController, 
                        decoration: InputDecoration(
                          labelText: 'Exercise Name', 
                          hintText: 'e.g. Romanian Deadlifts', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 16), 
                      TextField(
                        controller: _setsController, 
                        decoration: InputDecoration(
                          labelText: 'Sets & Reps', 
                          hintText: 'e.g. 4 x 10', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 24), 
                      SizedBox(
                        width: double.infinity, 
                        height: 56, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4), 
                            foregroundColor: Colors.black, 
                            elevation: 0, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ), 
                          onPressed: _assignWorkout, 
                          child: const Text('Assign Workout & Notify Client', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
                        )
                      )
                    ]
                  )
                ), 
                const SizedBox(height: 32), 
                const Text('Active Client Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)), 
                const SizedBox(height: 16), 
                if (_members.isEmpty) 
                  const Text('No members found.', style: TextStyle(color: Colors.grey)) 
                else 
                  ..._members.map((member) => Card(
                    color: const Color(0xFF0F172A), 
                    elevation: 0, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))), 
                    margin: const EdgeInsets.only(bottom: 12), 
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                      leading: const CircleAvatar(backgroundColor: Color(0xFF030712), child: Icon(Icons.person, color: Color(0xFF06B6D4))), 
                      title: Text(member['full_name'] ?? member['email'] ?? 'Unnamed Client', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
                      subtitle: Text('ID: ${member['id'].toString().substring(0, 8)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)), 
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClientDetailsScreen(client: member)))
                    )
                  ))
              ]
            )
          ),
    );
  }
}

class ManagerHub extends StatefulWidget {
  const ManagerHub({super.key});
  @override
  State<ManagerHub> createState() => _ManagerHubState();
}

class _ManagerHubState extends State<ManagerHub> {
  bool _isLoading = true; 
  bool _isCreatingUser = false; 
  List<dynamic> _users = []; 
  String _gymId = ''; 
  String _gymName = 'Manager Hub'; 
  String? _gymLogo; 
  int _gymMemberMonthlyFee = 1500; 
  
  final _feeController = TextEditingController(text: '1500'); 
  final _gymNameController = TextEditingController(); 
  final _gymLogoController = TextEditingController(); 
  final _newEmailController = TextEditingController(); 
  final _newPasswordController = TextEditingController(); 
  
  String _newRole = 'member'; 
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() { 
    super.initState(); 
    _fetchManagerData(); 
  }

  Future<void> _fetchManagerData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client.from('profiles').select('gym_id, gyms(name, logo_url)').eq('id', _userId).single();
      final response = await Supabase.instance.client.from('profiles').select().neq('role', 'manager').order('role');
      setState(() { 
        if (profile['gym_id'] != null) _gymId = profile['gym_id']; 
        if (profile['gyms'] != null) { 
          _gymName = profile['gyms']['name'] ?? 'Manager Admin'; 
          _gymLogo = profile['gyms']['logo_url']; 
          _gymNameController.text = _gymName; 
          _gymLogoController.text = _gymLogo ?? ''; 
        } 
        _users = response; 
      });
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)); 
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  Future<void> _updateGymBranding() async {
    if (_gymNameController.text.trim().isEmpty) return;
    try {
      await Supabase.instance.client.from('gyms').update({
        'name': _gymNameController.text.trim(), 
        'logo_url': _gymLogoController.text.trim()
      }).eq('id', _gymId);
      
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gym Branding Updated!'), backgroundColor: Colors.green)); 
      _fetchManagerData();
    } catch (e) { 
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)); 
    }
  }

  Future<void> _createAccount() async {
    if (_newEmailController.text.isEmpty || _newPasswordController.text.length < 6) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email and 6+ character password'), backgroundColor: Colors.redAccent)); 
      return; 
    }
    
    setState(() => _isCreatingUser = true);
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success: $_newRole account created for ${_newEmailController.text}!'), backgroundColor: Colors.green)); 
      _newEmailController.clear(); 
      _newPasswordController.clear(); 
      FocusScope.of(context).unfocus();
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent)); 
    } finally { 
      if (mounted) setState(() => _isCreatingUser = false); 
    }
  }

  void _showSetFeeDialog() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
        title: const Text('Set Gym Member Fee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text('Enter the monthly rate you charge.', style: TextStyle(color: Colors.grey, fontSize: 13)), 
            const SizedBox(height: 20), 
            TextField(
              controller: _feeController, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(
                prefixText: '₹ ', 
                labelText: 'Monthly Rate', 
                filled: true, 
                fillColor: const Color(0xFF030712), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
              )
            )
          ]
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ), 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4), 
              foregroundColor: Colors.black, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ), 
            onPressed: () { 
              final newFee = int.tryParse(_feeController.text); 
              if (newFee != null && newFee > 0) { 
                setState(() => _gymMemberMonthlyFee = newFee); 
                Navigator.pop(context); 
              } 
            }, 
            child: const Text('Save Rate', style: TextStyle(fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = _users.where((u) => u['role'] == 'member').length; 
    final trainerCount = _users.where((u) => u['role'] == 'trainer').length; 
    final totalGymMRR = memberCount * _gymMemberMonthlyFee;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_gymLogo != null && _gymLogo!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6), 
                child: Image.network(_gymLogo!, height: 28, width: 28, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.shield, size: 24))
              ), 
              const SizedBox(width: 10)
            ], 
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          ]
        ), 
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF06B6D4))
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.stars, color: Color(0xFF06B6D4), size: 16), 
              label: const Text('Upgrade Pro', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const _FixlyPricingShowcaseModal())
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchManagerData), 
          IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: () => Supabase.instance.client.auth.signOut())
        ]
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFF06B6D4).withValues(alpha: 0.2), const Color(0xFF3B82F6).withValues(alpha: 0.1)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF06B6D4))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fixly Free Trial Active', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Upgrade to Premium to unlock unlimited student registrations and active WhatsApp support.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const _FixlyPricingShowcaseModal()), 
                        child: const Text('View Pro Plans', style: TextStyle(fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Members', value: '$memberCount', valueColor: const Color(0xFF06B6D4))), 
                    const SizedBox(width: 12), 
                    Expanded(child: _StatCard(title: 'Trainers', value: '$trainerCount')), 
                    const SizedBox(width: 12), 
                    Expanded(child: _StatCard(title: 'Gym Revenue', value: '₹$totalGymMRR', valueColor: Colors.purpleAccent))
                  ]
                ), 
                const SizedBox(height: 16), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), 
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sell_outlined, size: 18, color: Colors.greenAccent), 
                          const SizedBox(width: 12), 
                          Text('Member Fee: ₹$_gymMemberMonthlyFee / month', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))
                        ]
                      ), 
                      GestureDetector(
                        onTap: _showSetFeeDialog, 
                        child: const Text('Edit', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 14, fontWeight: FontWeight.bold))
                      )
                    ]
                  )
                ), 
                const SizedBox(height: 32), 
                Container(
                  padding: const EdgeInsets.all(24), 
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text('Customize Gym Branding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                      const SizedBox(height: 6), 
                      const Text('Change the name and logo that your members see.', style: TextStyle(color: Colors.grey, fontSize: 13)), 
                      const SizedBox(height: 20), 
                      TextField(
                        controller: _gymNameController, 
                        decoration: InputDecoration(
                          labelText: 'Gym Name', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 16), 
                      TextField(
                        controller: _gymLogoController, 
                        decoration: InputDecoration(
                          labelText: 'Logo Image URL', 
                          hintText: 'https://...', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 20), 
                      SizedBox(
                        width: double.infinity, 
                        height: 52, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4), 
                            foregroundColor: Colors.black, 
                            elevation: 0, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ), 
                          onPressed: _updateGymBranding, 
                          child: const Text('Save Branding', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))
                        )
                      )
                    ]
                  )
                ), 
                const SizedBox(height: 24), 
                Container(
                  padding: const EdgeInsets.all(24), 
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF334155))), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text('Register Member / Trainer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                      const SizedBox(height: 20), 
                      DropdownButtonFormField<String>(
                        initialValue: _newRole, 
                        decoration: InputDecoration(
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        ), 
                        dropdownColor: const Color(0xFF030712), 
                        items: const [
                          DropdownMenuItem(value: 'member', child: Text('Member (Student)')), 
                          DropdownMenuItem(value: 'trainer', child: Text('Trainer (Coach)'))
                        ], 
                        onChanged: (val) => setState(() => _newRole = val!)
                      ), 
                      const SizedBox(height: 16), 
                      TextField(
                        controller: _newEmailController, 
                        decoration: InputDecoration(
                          labelText: 'User Email Address', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 16), 
                      TextField(
                        controller: _newPasswordController, 
                        obscureText: true, 
                        decoration: InputDecoration(
                          labelText: 'Assigned Initial Password', 
                          filled: true, 
                          fillColor: const Color(0xFF030712), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                        )
                      ), 
                      const SizedBox(height: 20), 
                      SizedBox(
                        width: double.infinity, 
                        height: 52, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.black, 
                            elevation: 0, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ), 
                          onPressed: _isCreatingUser ? null : _createAccount, 
                          child: _isCreatingUser 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                            : const Text('Generate Credentials', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))
                        )
                      )
                    ]
                  )
                ), 
                const SizedBox(height: 32), 
                const Text('Platform Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)), 
                const SizedBox(height: 16), 
                if (_users.isEmpty) 
                  const Text('No members or trainers found.', style: TextStyle(color: Colors.grey)) 
                else 
                  ..._users.map((user) => Card(
                    color: const Color(0xFF0F172A), 
                    elevation: 0, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E293B))), 
                    margin: const EdgeInsets.only(bottom: 12), 
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF030712), 
                        child: Icon(user['role'] == 'trainer' ? Icons.sports : Icons.person, color: user['role'] == 'trainer' ? Colors.orangeAccent : const Color(0xFF06B6D4))
                      ), 
                      title: Text(user['full_name'] ?? user['email'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
                      subtitle: Text(user['role'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))
                    )
                  ))
              ]
            )
          ),
    );
  }
}

class _FixlyPricingShowcaseModal extends StatefulWidget {
  const _FixlyPricingShowcaseModal();
  @override
  State<_FixlyPricingShowcaseModal> createState() => _FixlyPricingShowcaseModalState();
}

class _FixlyPricingShowcaseModalState extends State<_FixlyPricingShowcaseModal> {
  int _selectedPlanIndex = 1;
  final List<Map<String, dynamic>> _plans = [
    {'title': '15-Day Pass', 'duration': 'Half-Month Pass', 'price': 499, 'badge': 'Quick Trial', 'desc': 'Perfect for testing platform features.'},
    {'title': '6-Month Plan', 'duration': 'Half-Year SaaS', 'price': 4999, 'badge': 'Most Popular', 'desc': 'Complete automation suite for active centres.'},
    {'title': 'Annual Pro', 'duration': '12-Month License', 'price': 8499, 'badge': 'Best Value', 'desc': 'Full priority access + unlimited expansion.'},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_selectedPlanIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.92, 
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)), 
        border: Border(top: BorderSide(color: Color(0xFF06B6D4), width: 2))
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text('Fixly Platform License', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                    Text('Next-Gen AI Gym Management', style: TextStyle(color: Colors.grey, fontSize: 11))
                  ]
                ), 
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
              ]
            )
          ), 
          const Divider(color: Color(0xFF1E293B), height: 1), 
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text('Select Your Subscription Tier:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
                  const SizedBox(height: 16), 
                  Row(
                    children: List.generate(_plans.length, (index) { 
                      final p = _plans[index]; 
                      final isSelected = _selectedPlanIndex == index; 
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlanIndex = index), 
                          child: Container(
                            margin: EdgeInsets.only(right: index == _plans.length - 1 ? 0 : 8), 
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), 
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF030712), 
                              borderRadius: BorderRadius.circular(16), 
                              border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF334155), width: isSelected ? 2 : 1)
                            ), 
                            child: Column(
                              children: [
                                Text(p['badge'], style: TextStyle(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), 
                                const SizedBox(height: 8), 
                                Text(p['title'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)), 
                                const SizedBox(height: 8), 
                                Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white))
                              ]
                            )
                          )
                        )
                      ); 
                    })
                  ), 
                  const SizedBox(height: 32), 
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(24), 
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))
                    ), 
                    child: Column(
                      children: [
                        Text('Payable for ${selectedPlan['duration']}: ₹${selectedPlan['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4))), 
                        const SizedBox(height: 6), 
                        Text(selectedPlan['desc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
                        const SizedBox(height: 24), 
                        Container(
                          width: 220, 
                          height: 260, 
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), 
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20), 
                            child: Image.asset('assets/qr.jpeg', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Text('QR Code in assets/qr.jpeg', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))))
                          )
                        ), 
                        const SizedBox(height: 24), 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), 
                          decoration: BoxDecoration(
                            color: const Color(0xFF030712), 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: const Color(0xFF334155))
                          ), 
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Text('UPI ID:', style: TextStyle(color: Colors.grey, fontSize: 13)), 
                              Text('shivnathkamble84@oksbi', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 14))
                            ]
                          )
                        )
                      ]
                    )
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}

class _AnalysisOverlay extends StatelessWidget {
  const _AnalysisOverlay();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, 
      elevation: 0, 
      child: Container(
        padding: const EdgeInsets.all(32), 
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95), 
          borderRadius: BorderRadius.circular(32), 
          border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5), width: 2)
        ), 
        child: const Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(Icons.memory, size: 72, color: Color(0xFF06B6D4)), 
            SizedBox(height: 24), 
            Text('AI Engine Processing', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), 
            SizedBox(height: 12), 
            Text('Calculating hypertrophy metrics and generating topology map...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)), 
            SizedBox(height: 28), 
            LinearProgressIndicator(color: Color(0xFF06B6D4), backgroundColor: Color(0xFF030712))
          ]
        )
      )
    );
  }
}

class _HologramResultModal extends StatefulWidget {
  const _HologramResultModal();
  @override
  State<_HologramResultModal> createState() => _HologramResultModalState();
}

class _HologramResultModalState extends State<_HologramResultModal> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    _loadLocalHologram();
  }

  Future<void> _loadLocalHologram() async {
    final String htmlContent = await rootBundle.loadString('assets/hologram.html');
    final String base64Content = base64Encode(const Utf8Encoder().convert(htmlContent));
    _controller.loadRequest(Uri.parse('data:text/html;base64,$base64Content'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, 
      decoration: const BoxDecoration(
        color: Colors.black, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)), 
        border: Border(top: BorderSide(color: Color(0xFF06B6D4), width: 2))
      ),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller), 
          const Positioned(
            top: 24, 
            left: 0, 
            right: 0, 
            child: Center(
              child: Text('3D Hologram Results', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))
            )
          ), 
          Positioned(
            bottom: 40, 
            left: 24, 
            right: 24, 
            child: Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85), 
                borderRadius: BorderRadius.circular(20)
              ), 
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text('Target: Pectorals & Deltoids', style: TextStyle(color: Colors.grey, fontSize: 11)), 
                      SizedBox(height: 4), 
                      Text('+0.5cm Projected Growth', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 14, fontWeight: FontWeight.bold))
                    ]
                  ), 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end, 
                    children: [
                      Text('Body Fat Trend', style: TextStyle(color: Colors.grey, fontSize: 11)), 
                      SizedBox(height: 4), 
                      Text('-0.4% Projected', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold))
                    ]
                  )
                ]
              )
            )
          ), 
          Positioned(
            top: 20, 
            right: 20, 
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context))
          )
        ]
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon; 
  final String title; 
  final String subtitle;
  
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});
  
  @override
  Widget build(BuildContext context) { 
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(12)
            ), 
            child: Icon(icon, color: const Color(0xFF06B6D4), size: 20)
          ), 
          const SizedBox(width: 16), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)), 
                const SizedBox(height: 4), 
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4))
              ]
            )
          )
        ]
      )
    ); 
  }
}

class _StatCard extends StatelessWidget {
  final String title; 
  final String value; 
  final Color? valueColor;
  
  const _StatCard({required this.title, required this.value, this.valueColor});
  
  @override
  Widget build(BuildContext context) { 
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12), 
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: const Color(0xFF1E293B))
      ), 
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 8), 
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: valueColor ?? Colors.white))
        ]
      )
    ); 
  }
}

class ClientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> client;
  const ClientDetailsScreen({super.key, required this.client});
  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  bool _isLoading = true; 
  Map<String, dynamic>? _dailyStats; 
  List<dynamic> _weightLogs = [];

  @override
  void initState() { 
    super.initState(); 
    _fetchClientData(); 
  }

  Future<void> _fetchClientData() async {
    setState(() { _isLoading = true; });
    try {
      final statsResponse = await Supabase.instance.client.from('daily_stats').select().eq('user_id', widget.client['id']).maybeSingle();
      final weightsResponse = await Supabase.instance.client.from('weight_logs').select().eq('user_id', widget.client['id']).order('logged_at', ascending: false).limit(1);
      setState(() { 
        _dailyStats = statsResponse; 
        _weightLogs = weightsResponse; 
      });
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)); 
    } finally { 
      if (mounted) setState(() { _isLoading = false; }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.client['full_name'] ?? widget.client['email'] ?? 'Unnamed Client'; 
    final water = _dailyStats?['water_glasses'] ?? 0; 
    final streak = _dailyStats?['streak'] ?? 0; 
    final latestWeight = _weightLogs.isNotEmpty ? _weightLogs.first['weight_kg'] : 'No data';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        backgroundColor: const Color(0xFF0F172A)
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) 
        : Padding(
            padding: const EdgeInsets.all(20.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Text('Client Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)), 
                const SizedBox(height: 20), 
                Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Streak', value: '$streak Days', valueColor: Colors.orangeAccent)), 
                    const SizedBox(width: 12), 
                    Expanded(child: _StatCard(title: 'Hydration', value: '$water/8', valueColor: Colors.blueAccent))
                  ]
                ), 
                const SizedBox(height: 16), 
                _StatCard(title: 'Latest Weight Logging', value: '$latestWeight kg', valueColor: const Color(0xFF06B6D4))
              ]
            )
          ),
    );
  }
}