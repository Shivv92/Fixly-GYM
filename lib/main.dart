import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
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
      title: 'Fixly Gym',
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
              
              if (role == 'manager') return const ManagerHub();
              if (role == 'trainer') return const TrainerHub(); 
              return const MemberDashboard(); 
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'role': 'member'},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Logging in...'), backgroundColor: Colors.green),
          );
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error occurred'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 64, color: Color(0xFF06B6D4)),
              const SizedBox(height: 16),
              Text(
                'FIXLY GYM',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
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
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : Text(_isSignUp ? 'Create Account' : 'Access Dashboard', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up',
                  style: const TextStyle(color: Color(0xFF06B6D4)),
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
  late final WebViewController _controller;
  final _weightController = TextEditingController();
  
  bool _isLoading = true;
  List<dynamic> _workouts = [];
  Map<String, dynamic>? _dailyStats;
  List<dynamic> _weightLogs = [];
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    _loadLocalHologram();
    _fetchDashboardData();
  }

  Future<void> _loadLocalHologram() async {
    final String htmlContent = await rootBundle.loadString('assets/hologram.html');
    final String base64Content = base64Encode(const Utf8Encoder().convert(htmlContent));
    _controller.loadRequest(Uri.parse('data:text/html;base64,$base64Content'));
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final statsResponse = await Supabase.instance.client
          .from('daily_stats')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      
      final workoutsResponse = await Supabase.instance.client
          .from('workouts')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: true);

      final weightsResponse = await Supabase.instance.client
          .from('weight_logs')
          .select()
          .eq('user_id', _userId)
          .order('logged_at', ascending: false)
          .limit(1);

      setState(() {
        _dailyStats = statsResponse;
        _workouts = workoutsResponse;
        _weightLogs = weightsResponse;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWorkout(String id, bool currentStatus) async {
    await Supabase.instance.client
        .from('workouts')
        .update({'is_completed': !currentStatus})
        .eq('id', id);
    _fetchDashboardData();
  }

  Future<void> _updateWater(int change) async {
    if (_dailyStats == null) return;
    int currentWater = _dailyStats!['water_glasses'] ?? 0;
    int newWater = (currentWater + change).clamp(0, 20);
    
    await Supabase.instance.client
        .from('daily_stats')
        .update({'water_glasses': newWater})
        .eq('id', _dailyStats!['id']);
    _fetchDashboardData();
  }

  Future<void> _logWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 20 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight between 20 and 300 kg'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    await Supabase.instance.client.from('weight_logs').insert({
      'user_id': _userId,
      'weight_kg': weight,
    });
    
    if (!mounted) return;
    
    _weightController.clear();
    _fetchDashboardData();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
      );
    }

    final waterGlasses = _dailyStats?['water_glasses'] ?? 0;
    final latestWeight = _weightLogs.isNotEmpty ? _weightLogs.first['weight_kg'] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elite Fitness Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Body Scan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155), width: 1),
                boxShadow: const [BoxShadow(color: Color(0x4006B6D4), blurRadius: 20, spreadRadius: -5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: WebViewWidget(controller: _controller),
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
                      title: Text(
                        workout['name'],
                        style: TextStyle(
                          color: workout['is_completed'] ? Colors.grey : Colors.white,
                          decoration: workout['is_completed'] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(workout['sets_reps'], style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: Icon(
                          workout['is_completed'] ? Icons.check_circle : Icons.circle_outlined,
                          color: workout['is_completed'] ? const Color(0xFF06B6D4) : Colors.grey,
                        ),
                        onPressed: () => _toggleWorkout(workout['id'], workout['is_completed']),
                      ),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () => _updateWater(-1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                            onPressed: () => _updateWater(1),
                          ),
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
                  Text(
                    latestWeight != null ? 'Latest: $latestWeight kg' : 'No entries yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _logWeight,
                        child: const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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
  List<dynamic> _members = [];
  String? _selectedMemberId;
  
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'member');
          
      setState(() {
        _members = response;
        if (_members.isNotEmpty) {
          _selectedMemberId = _members.first['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignWorkout() async {
    if (_selectedMemberId == null || _exerciseController.text.isEmpty || _setsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('workouts').insert({
        'user_id': _selectedMemberId,
        'name': _exerciseController.text.trim(),
        'sets_reps': _setsController.text.trim(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout assigned successfully!'), backgroundColor: Colors.green),
      );
      
      _exerciseController.clear();
      _setsController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning workout: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchMembers,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
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
                          return DropdownMenuItem<String>(
                            value: member['id'],
                            child: Text(name, style: const TextStyle(color: Colors.white)),
                          );
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
                          hintText: 'e.g. Bulgarian Split Squats',
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
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF030712),
                        child: Icon(Icons.person, color: Color(0xFF06B6D4)),
                      ),
                      title: Text(member['full_name'] ?? member['email'] ?? 'Unnamed Client', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('ID: ${member['id'].toString().substring(0, 8)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailsScreen(client: member),
                          ),
                        );
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
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .neq('role', 'manager') 
          .order('role');
          
      setState(() {
        _users = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = _users.where((u) => u['role'] == 'member').length;
    final trainerCount = _users.where((u) => u['role'] == 'trainer').length;
    final mrr = memberCount * 1499; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
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
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Trainers', value: '$trainerCount')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'MRR', value: '₹$mrr', valueColor: Colors.purpleAccent)),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('Platform Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                
                if (_users.isEmpty)
                  const Text('No users found on platform.', style: TextStyle(color: Colors.grey))
                else
                  ..._users.map((user) => Card(
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF030712),
                        child: Icon(
                          user['role'] == 'trainer' ? Icons.sports : Icons.person,
                          color: user['role'] == 'trainer' ? Colors.orangeAccent : const Color(0xFF06B6D4)
                        ),
                      ),
                      title: Text(user['full_name'] ?? user['email'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(user['role'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Admin editing restricted in demo.')),
                          );
                        },
                      ),
                    ),
                  )),
              ],
            ),
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
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: valueColor ?? Colors.white)),
        ],
      ),
    );
  }
}

/// The new Client Details Screen for Trainers
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
    setState(() => _isLoading = true);
    try {
      final statsResponse = await Supabase.instance.client
          .from('daily_stats')
          .select()
          .eq('user_id', widget.client['id'])
          .maybeSingle();

      final weightsResponse = await Supabase.instance.client
          .from('weight_logs')
          .select()
          .eq('user_id', widget.client['id'])
          .order('logged_at', ascending: false)
          .limit(1);

      setState(() {
        _dailyStats = statsResponse;
        _weightLogs = weightsResponse;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading client data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Streak', value: '$streak Days', valueColor: Colors.orangeAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Hydration', value: '$water/8', valueColor: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatCard(title: 'Latest Weight Logging', value: '$latestWeight kg', valueColor: const Color(0xFF06B6D4)),
                ],
              ),
            ),
    );
  }
}