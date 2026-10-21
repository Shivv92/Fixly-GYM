import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

// Your actual keys
const supabaseUrl = 'https://tjffhmeedaolhzimxfkh.supabase.co';
const supabaseKey = 'sb_publishable_cdpJ34F0Pi3v-jZCgMFiXQ_1SyRDSws';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );
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
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return FutureBuilder<String>(
            future: _getUserRole(session.user.id),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
                );
              }

              final role = roleSnapshot.data ?? 'member';

              if (role == 'manager') {
                return const ManagerHub();
              }
              if (role == 'trainer') {
                return const TrainerHub();
              }
              return const MemberDashboard();
            },
          );
        }

        return const PublicLandingScreen();
      },
    );
  }
}

class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Fixly Gym SaaS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF06B6D4).withValues(alpha: 0.3), const Color(0xFF030712)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.bolt, size: 80, color: Color(0xFF06B6D4)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next-Gen Gym Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text(
                    'An intelligent, white-label fitness ecosystem connecting members, trainers, and gym owners with real-time biometric metrics.',
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Text('Platform Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  const _FeatureRow(
                    icon: Icons.view_in_ar,
                    title: '3D AI Biometric Hologram',
                    subtitle: 'Captures physique metrics via native camera and generates interactive 3D topology tracking muscle hypertrophy over time.',
                  ),
                  const _FeatureRow(
                    icon: Icons.fitness_center,
                    title: 'Direct Coach-to-Client Engine',
                    subtitle: 'Trainers push custom split routines, sets, and reps straight to member devices with zero latency.',
                  ),
                  const _FeatureRow(
                    icon: Icons.water_drop,
                    title: 'Hydration & Weight Analytics',
                    subtitle: 'Daily glass-by-glass water accountability, daily streak counts, and bodyweight trend curves.',
                  ),
                  const _FeatureRow(
                    icon: Icons.shield,
                    title: 'Multi-Tenant Privacy & Security',
                    subtitle: 'Row-Level cloud isolation guarantees each gym completely owns and protects their member data.',
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars, color: Color(0xFF06B6D4)),
                            SizedBox(width: 8),
                            Text('SaaS Licensing Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Unlock full multi-tenant capabilities for your gym. Simple, transparent pricing.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        const _PricingTierCard(title: '15-Day Pass', price: '₹499', desc: 'Quick trial access for testing.', color: Colors.white),
                        const SizedBox(height: 8),
                        const _PricingTierCard(title: '6-Month Plan', price: '₹4,999', desc: 'Complete automation suite. (Most Popular)', color: Color(0xFF06B6D4)),
                        const SizedBox(height: 8),
                        const _PricingTierCard(title: 'Annual Pro', price: '₹8,499', desc: 'Full priority access + unlimited scaling.', color: Colors.purpleAccent),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.business),
                            label: const Text('Subscribe & Register Gym', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isSignUpMode: true)));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person),
                      label: const Text('Student / Trainer Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isSignUpMode: false)));
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool isSignUpMode;
  const LoginScreen({super.key, this.isSignUpMode = false}); // Fixed: added default value so widget_test won't crash

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email and 6+ character password'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'role': 'manager'},
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error occurred. Check internet connection.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 64, color: Color(0xFF06B6D4)),
              const SizedBox(height: 16),
              Text(
                'FIXLY GYM',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Register Your Gym on Fixly' : 'Student & Trainer Login Portal',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(_isSignUp ? 'Subscribe & Register' : 'Secure Login', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp ? 'Student/Trainer? Login Here' : 'Gym Owner? Register Your Gym Here',
                  style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final _weightController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleWorkout(String id, bool currentStatus) async {
    await Supabase.instance.client.from('workouts').update({'is_completed': !currentStatus}).eq('id', id);
    _fetchDashboardData();
  }

  Future<void> _updateWater(int change) async {
    if (_dailyStats == null) {
      return;
    }
    int newWater = ((_dailyStats!['water_glasses'] ?? 0) + change).clamp(0, 20) as int;
    await Supabase.instance.client.from('daily_stats').update({'water_glasses': newWater}).eq('id', _dailyStats!['id']);
    _fetchDashboardData();
  }

  Future<void> _logWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 20 || weight > 300) {
      return;
    }
    await Supabase.instance.client.from('weight_logs').insert({'user_id': _userId, 'weight_kg': weight});

    if (!mounted) {
      return;
    }

    _weightController.clear();
    _fetchDashboardData();
    FocusScope.of(context).unfocus();
  }

  Future<void> _launchHologramScanner() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);

    if (photo == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AnalysisOverlay(),
    );

    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HologramResultModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))));
    }

    final waterGlasses = _dailyStats?['water_glasses'] ?? 0;
    final latestWeight = _weightLogs.isNotEmpty ? _weightLogs.first['weight_kg'] : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_gymLogo != null && _gymLogo!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(_gymLogo!, height: 28, width: 28, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 24)),
              ),
              const SizedBox(width: 10),
            ],
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: () => Supabase.instance.client.auth.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155), width: 1),
                boxShadow: const [BoxShadow(color: Color(0x4006B6D4), blurRadius: 20, spreadRadius: -5)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.vrpano_outlined, size: 48, color: Color(0xFF06B6D4)),
                  const SizedBox(height: 16),
                  const Text('AI Body Scan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Map your hypertrophy progress via biometric lens.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Launch Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: _launchHologramScanner,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  if (_workouts.isEmpty)
                    const Text('No workouts assigned.', style: TextStyle(color: Colors.grey))
                  else
                    ..._workouts.map((workout) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(workout['name'],
                              style: TextStyle(
                                  color: workout['is_completed'] ? Colors.grey : Colors.white,
                                  decoration: workout['is_completed'] ? TextDecoration.lineThrough : null)),
                          subtitle: Text(workout['sets_reps'], style: const TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                              icon: Icon(workout['is_completed'] ? Icons.check_circle : Icons.circle_outlined,
                                  color: workout['is_completed'] ? const Color(0xFF06B6D4) : Colors.grey),
                              onPressed: () => _toggleWorkout(workout['id'], workout['is_completed'])),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hydration Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$waterGlasses / 8 Glasses', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _updateWater(-1)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent), onPressed: () => _updateWater(1)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Body Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(latestWeight != null ? 'Latest: $latestWeight kg' : 'No entries yet', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                      const SizedBox(width: 12),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _logWeight,
                          child: const Text('Log', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
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
    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        'sets_reps': _setsController.text.trim(),
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout assigned successfully!'), backgroundColor: Colors.green));
      _exerciseController.clear();
      _setsController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning workout: $e'), backgroundColor: Colors.redAccent));
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
                child: Image.network(_gymLogo!, height: 28, width: 28, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 24)),
              ),
              const SizedBox(width: 10),
            ],
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchMembers),
          IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: () => Supabase.instance.client.auth.signOut()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Push Custom Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMemberId,
                          decoration: InputDecoration(
                            labelText: 'Select Client',
                            filled: true,
                            fillColor: const Color(0xFF030712),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          dropdownColor: const Color(0xFF030712),
                          items: _members.map<DropdownMenuItem<String>>((member) {
                            final name = member['full_name'] ?? member['email'] ?? 'Unnamed Client';
                            return DropdownMenuItem<String>(value: member['id'], child: Text(name, style: const TextStyle(color: Colors.white)));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMemberId = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _exerciseController,
                          decoration: InputDecoration(
                            labelText: 'Exercise Name',
                            hintText: 'e.g. Romanian Deadlifts',
                            filled: true,
                            fillColor: const Color(0xFF030712),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _setsController,
                          decoration: InputDecoration(
                            labelText: 'Sets & Reps',
                            hintText: 'e.g. 4 x 10',
                            filled: true,
                            fillColor: const Color(0xFF030712),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _assignWorkout,
                            child: const Text('Assign Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Active Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (_members.isEmpty)
                    const Text('No members found.', style: TextStyle(color: Colors.grey))
                  else
                    ..._members.map((member) => Card(
                          color: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFF030712), child: Icon(Icons.person, color: Color(0xFF06B6D4))),
                            title: Text(member['full_name'] ?? member['email'] ?? 'Unnamed Client', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('ID: ${member['id'].toString().substring(0, 8)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ClientDetailsScreen(client: member)));
                            },
                          ),
                        )),
                ],
              ),
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
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await Supabase.instance.client.from('profiles').select('gym_id, gyms(name, logo_url)').eq('id', _userId).single();
      final response = await Supabase.instance.client.from('profiles').select().neq('role', 'manager').order('role');

      setState(() {
        if (profile['gym_id'] != null) {
          _gymId = profile['gym_id'];
        }
        if (profile['gyms'] != null) {
          _gymName = profile['gyms']['name'] ?? 'Manager Admin';
          _gymLogo = profile['gyms']['logo_url'];
          _gymNameController.text = _gymName;
          _gymLogoController.text = _gymLogo ?? '';
        }
        _users = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateGymBranding() async {
    if (_gymNameController.text.trim().isEmpty) {
      return;
    }
    try {
      await Supabase.instance.client.from('gyms').update({
        'name': _gymNameController.text.trim(),
        'logo_url': _gymLogoController.text.trim(),
      }).eq('id', _gymId);
      
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gym Branding Updated!'), backgroundColor: Colors.green));
      _fetchManagerData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating branding: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _createAccount() async {
    if (_newEmailController.text.isEmpty || _newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email and 6+ character password'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() {
      _isCreatingUser = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Success: $_newRole account created for ${_newEmailController.text}!'), backgroundColor: Colors.green));

      _newEmailController.clear();
      _newPasswordController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create account: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingUser = false;
        });
      }
    }
  }

  void _showSetFeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Gym Member Fee', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the monthly rate you charge your gym members to update analytics.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(prefixText: '₹ ', labelText: 'Monthly Rate', filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.black),
            onPressed: () {
              final newFee = int.tryParse(_feeController.text);
              if (newFee != null && newFee > 0) {
                setState(() {
                  _gymMemberMonthlyFee = newFee;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save Rate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                child: Image.network(_gymLogo!, height: 28, width: 28, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.shield, size: 24)),
              ),
              const SizedBox(width: 10),
            ],
            Text(_gymName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars, color: Color(0xFF06B6D4), size: 24),
            tooltip: 'Fixly Platform Plans & Features',
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const _FixlyPricingShowcaseModal()),
          ),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchManagerData),
          IconButton(icon: const Icon(Icons.logout, size: 20), onPressed: () => Supabase.instance.client.auth.signOut()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Members', value: '$memberCount', valueColor: const Color(0xFF06B6D4))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(title: 'Trainers', value: '$trainerCount')),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(title: 'Gym Revenue', value: '₹$totalGymMRR', valueColor: Colors.purpleAccent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [const Icon(Icons.sell_outlined, size: 16, color: Colors.greenAccent), const SizedBox(width: 8), Text('Member Fee: ₹$_gymMemberMonthlyFee / month', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))]),
                        GestureDetector(onTap: _showSetFeeDialog, child: const Text('Edit', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)))
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customize Gym Branding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Change the name and logo that your members see.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _gymNameController,
                          decoration: InputDecoration(labelText: 'Gym Name', filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _gymLogoController,
                          decoration: InputDecoration(labelText: 'Logo Image URL', hintText: 'https://...', filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _updateGymBranding,
                            child: const Text('Save Branding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Register Member / Trainer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _newRole,
                          decoration: InputDecoration(filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          dropdownColor: const Color(0xFF030712),
                          items: const [DropdownMenuItem(value: 'member', child: Text('Member (Student)')), DropdownMenuItem(value: 'trainer', child: Text('Trainer (Coach)'))],
                          onChanged: (val) => setState(() => _newRole = val!),
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: _newEmailController, decoration: InputDecoration(labelText: 'User Email Address', filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                        const SizedBox(height: 12),
                        TextField(controller: _newPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Assigned Initial Password', filled: true, fillColor: const Color(0xFF030712), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _isCreatingUser ? null : _createAccount,
                            child: _isCreatingUser ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('Generate Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Platform Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (_users.isEmpty)
                    const Text('No members or trainers found.', style: TextStyle(color: Colors.grey))
                  else
                    ..._users.map((user) => Card(
                          color: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF030712),
                              child: Icon(user['role'] == 'trainer' ? Icons.sports : Icons.person, color: user['role'] == 'trainer' ? Colors.orangeAccent : const Color(0xFF06B6D4)),
                            ),
                            title: Text(user['full_name'] ?? user['email'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text(user['role'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        )),
                ],
              ),
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
      decoration: const BoxDecoration(color: Color(0xFF0B1120), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Color(0xFF06B6D4), width: 2))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Fixly Platform License', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Text('Next-Gen AI Gym Management', style: TextStyle(color: Colors.grey, fontSize: 11))]),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Your Subscription Tier:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_plans.length, (index) {
                      final p = _plans[index];
                      final isSelected = _selectedPlanIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlanIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(right: index == _plans.length - 1 ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF030712), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF334155), width: isSelected ? 2 : 1)),
                            child: Column(children: [Text(p['badge'], style: TextStyle(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(p['title'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)), const SizedBox(height: 6), Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white))]),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        Text('Payable for ${selectedPlan['duration']}: ₹${selectedPlan['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4))),
                        const SizedBox(height: 4),
                        Text(selectedPlan['desc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 18),
                        Container(
                          width: 220,
                          height: 260,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/qr.jpeg', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Text('QR Code in assets/qr.jpeg', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))))),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('UPI ID:', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('shivnathkamble84@oksbi', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 13))]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5), width: 2)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, size: 64, color: Color(0xFF06B6D4)),
            SizedBox(height: 24),
            Text('AI Engine Processing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Calculating hypertrophy metrics and generating topology map...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 24),
            LinearProgressIndicator(color: Color(0xFF06B6D4), backgroundColor: Color(0xFF030712)),
          ],
        ),
      ),
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
      decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Color(0xFF06B6D4), width: 2))),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          const Positioned(top: 24, left: 0, right: 0, child: Center(child: Text('3D Hologram Results', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)))),
          Positioned(bottom: 40, left: 24, right: 24, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Target: Pectorals & Deltoids', style: TextStyle(color: Colors.grey, fontSize: 10)), Text('+0.5cm Projected Growth', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Body Fat Trend', style: TextStyle(color: Colors.grey, fontSize: 10)), Text('-0.4% Projected', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))])]))),
          Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))
        ],
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF06B6D4), size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11))]))
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor ?? Colors.white))]),
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
      setState(() { _dailyStats = statsResponse; _weightLogs = weightsResponse; });
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
      appBar: AppBar(title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), backgroundColor: const Color(0xFF0F172A)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: _StatCard(title: 'Streak', value: '$streak Days', valueColor: Colors.orangeAccent)), const SizedBox(width: 12), Expanded(child: _StatCard(title: 'Hydration', value: '$water/8', valueColor: Colors.blueAccent))]),
                  const SizedBox(height: 16),
                  _StatCard(title: 'Latest Weight Logging', value: '$latestWeight kg', valueColor: const Color(0xFF06B6D4)),
                ],
              ),
            ),
    );
  }
}