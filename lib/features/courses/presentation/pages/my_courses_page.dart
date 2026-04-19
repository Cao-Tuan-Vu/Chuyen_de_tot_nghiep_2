// Page: My Courses + Course Catalog
// Shows courses the current user is enrolled in and a catalog to register new courses.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({Key? key}) : super(key: key);

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<Map<String, dynamic>> _myCourses = [];
  String _userId = '';

  @override
  void initState() {
	super.initState();
	_loadUserAndCourses();
  }

  Future<void> _loadUserAndCourses() async {
	setState(() => _loading = true);

	final firebaseUser = FirebaseAuth.instance.currentUser;
	if (firebaseUser == null) {
	  print('❌ [LOAD] No user signed in');
	  setState(() {
		_userId = '';
		_myCourses = [];
		_loading = false;
	  });
	  return;
	}

	_userId = firebaseUser.uid;
	print('📚 [LOAD] Loading courses for user: $_userId');

	try {
	  final userSnap = await db.child('users/$_userId').get();
	  print('📚 [LOAD] User snapshot exists: ${userSnap.exists}');
	  
	  final enrolled = <String>[];
	  if (userSnap.exists) {
		final data = userSnap.value;
		print('📚 [LOAD] User data: $data');
		
		if (data is Map) {
		  final map = Map<String, dynamic>.from(data);
		  if (map.containsKey('enrolledCourses')) {
			final raw = map['enrolledCourses'];
			print('📚 [LOAD] enrolledCourses raw value: $raw');
			print('📚 [LOAD] enrolledCourses type: ${raw.runtimeType}');
			
			if (raw is Map) {
			  enrolled.addAll(raw.keys.map((k) => k.toString()));
			  print('📚 [LOAD] Found ${enrolled.length} courses (Map type)');
			} else if (raw is List) {
			  for (var v in raw) {
				if (v != null) enrolled.add(v.toString());
			  }
			  print('📚 [LOAD] Found ${enrolled.length} courses (List type)');
			}
		  } else {
			print('⚠️ [LOAD] No enrolledCourses field found');
		  }
		}
	  } else {
		print('⚠️ [LOAD] User data not found in Firebase');
	  }

	print('📚 [LOAD] Total enrolled courses: ${enrolled.length}');

	final coursesSnap = await db.child('courses').get();
	print('📚 [LOAD] Courses snapshot exists: ${coursesSnap.exists}');
	
	final courses = <Map<String, dynamic>>[];
	if (coursesSnap.exists && coursesSnap.value is Map) {
	  final all = Map<String, dynamic>.from(coursesSnap.value as Map);
	  print('📚 [LOAD] Total courses in database: ${all.length}');
	  
	  for (final id in enrolled) {
		if (all.containsKey(id)) {
		  final c = Map<String, dynamic>.from(all[id] as Map);
		  c['id'] = id;
		  courses.add(c);
		  print('✅ [LOAD] Added course: $id - ${c['title']}');
		} else {
		  print('⚠️ [LOAD] Course not found: $id');
		}
	  }
	}

	print('📚 [LOAD] Final loaded courses: ${courses.length}');
	setState(() {
	  _myCourses = courses;
	  _loading = false;
	});
	} catch (e) {
	  print('❌ [LOAD] Error loading courses: $e');
	  print('❌ [LOAD] Error type: ${e.runtimeType}');
	  setState(() => _loading = false);
	}
  }

  void _openCatalog() async {
	if (_userId.isEmpty) {
	  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
		content: Text('Vui lòng đăng nhập để đăng ký khóa học.'),
	  ));
	  return;
	}

	await Navigator.of(context).push(MaterialPageRoute(
	  builder: (_) => CourseCatalogPage(userId: _userId),
	));
	// reload after returning from catalog
	await _loadUserAndCourses();
  }

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  appBar: AppBar(title: const Text('Khóa học của tôi')),
	  body: _loading
		  ? const Center(child: CircularProgressIndicator())
		  : (FirebaseAuth.instance.currentUser == null)
			  ? Center(
				  child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
					  const Text('Vui lòng đăng nhập để xem khóa học của bạn.'),
					  const SizedBox(height: 12),
					  ElevatedButton(
						onPressed: () {
						  // let app routing handle login; user can navigate to profile/login page
						},
						child: const Text('Đăng nhập'),
					  )
					],
				  ),
				)
			  : (_myCourses.isEmpty
				  ? const Center(child: Text('Bạn chưa đăng ký khóa học nào.'))
				  : ListView.builder(
					  itemCount: _myCourses.length,
					  itemBuilder: (ctx, i) {
						final c = _myCourses[i];
						return Card(
						  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
						  child: ListTile(
							title: Text(c['title'] ?? c['id'] ?? ''),
							subtitle: Text(c['desc'] ?? ''),
							trailing: Text(c['level'] ?? ''),
							onTap: () {
							  // open lesson list or course detail - integrate with your app routing
							},
						  ),
						);
					  },
					)),
	  floatingActionButton: FloatingActionButton.extended(
		onPressed: _openCatalog,
		icon: const Icon(Icons.add),
		label: const Text('Đăng ký'),
	  ),
	);
  }
}

class CourseCatalogPage extends StatefulWidget {
  final String userId;
  const CourseCatalogPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final db = FirebaseDatabase.instance.ref();
  Map<String, dynamic> _courses = {};
  final Set<String> _enrolled = {};
  bool _loading = true;

  @override
  void initState() {
	super.initState();
	_loadCatalog();
  }

  Future<void> _loadCatalog() async {
	setState(() => _loading = true);
	final snap = await db.child('courses').get();
	final userSnap = await db.child('users/${widget.userId}').get();

	_enrolled.clear();
	if (userSnap.exists) {
	  final data = userSnap.value;
	  if (data is Map && data.containsKey('enrolledCourses')) {
		final raw = data['enrolledCourses'];
		if (raw is Map) {
		  _enrolled.addAll(raw.keys.map((k) => k.toString()));
		} else if (raw is List) {
		  for (var v in raw) {
			if (v != null) _enrolled.add(v.toString());
		  }
		}
	  }
	}

	if (snap.exists && snap.value is Map) {
	  _courses = Map<String, dynamic>.from(snap.value as Map);
	} else {
	  _courses = {};
	}

	setState(() => _loading = false);
  }

  Future<void> _toggleEnroll(String courseId) async {
	if (widget.userId.isEmpty) {
	  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập.')));
	  return;
	}
	
	print('📚 [ENROLLMENT] Starting enrollment process for course: $courseId');
	print('📚 [ENROLLMENT] User ID: ${widget.userId}');
	
	final userCourseRef = db.child('users/${widget.userId}/enrolledCourses/$courseId');
	final isEnrolled = _enrolled.contains(courseId);
	
	try {
	  if (isEnrolled) {
		print('📚 [ENROLLMENT] Removing enrollment...');
		await userCourseRef.remove();
		_enrolled.remove(courseId);
		print('✅ [ENROLLMENT] Removed successfully');
		if (mounted) {
		  ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
			  content: Text('Hủy đăng ký khóa học thành công'),
			  duration: Duration(seconds: 2),
			  backgroundColor: Colors.orange,
			),
		  );
		}
	  } else {
		print('📚 [ENROLLMENT] Adding enrollment...');
		final enrollmentData = {
		  'enrolledAt': DateTime.now().toIso8601String(),
		  'status': 'active',
		};
		print('📚 [ENROLLMENT] Data to save: $enrollmentData');
		
		await userCourseRef.set(enrollmentData);
		
		// Verify the data was written
		final verification = await userCourseRef.get();
		print('📚 [ENROLLMENT] Verification - Data exists: ${verification.exists}');
		print('📚 [ENROLLMENT] Verification - Data value: ${verification.value}');
		
		_enrolled.add(courseId);
		print('✅ [ENROLLMENT] Added successfully');
		if (mounted) {
		  ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
			  content: Text('Đăng ký khóa học thành công!'),
			  duration: Duration(seconds: 2),
			  backgroundColor: Colors.green,
			),
		  );
		}
	  }
	  setState(() {});
	} catch (e) {
	  print('❌ [ENROLLMENT] Error: $e');
	  print('❌ [ENROLLMENT] Error type: ${e.runtimeType}');
	  if (mounted) {
		ScaffoldMessenger.of(context).showSnackBar(
		  SnackBar(
			content: Text('Lỗi: ${e.toString()}'),
			duration: const Duration(seconds: 3),
			backgroundColor: Colors.red,
		  ),
		);
	  }
	}
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Khám phá khóa học',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final id = _courses.keys.elementAt(index);
                    final c = Map<String, dynamic>.from(_courses[id] as Map);
                    final enrolled = _enrolled.contains(id);
                    return _CatalogCard(
                      id: id,
                      title: c['title'] ?? id,
                      desc: c['desc'] ?? '',
                      level: c['level'] ?? 'Cơ bản',
                      enrolled: enrolled,
                      onToggle: () => _toggleEnroll(id),
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Không tìm thấy khóa học nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final String id;
  final String title;
  final String desc;
  final String level;
  final bool enrolled;
  final VoidCallback onToggle;
  final bool isDarkMode;

  const _CatalogCard({
    required this.id,
    required this.title,
    required this.desc,
    required this.level,
    required this.enrolled,
    required this.onToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: enrolled
                      ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                      : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.school_rounded, size: 40, color: Colors.white),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enrolled ? Colors.transparent : const Color(0xFF6366F1),
                      foregroundColor: enrolled ? (isDarkMode ? Colors.white70 : Colors.black54) : Colors.white,
                      elevation: enrolled ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: enrolled ? const BorderSide(color: Colors.grey) : BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      enrolled ? 'Hủy đăng ký' : 'Đăng ký học',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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


