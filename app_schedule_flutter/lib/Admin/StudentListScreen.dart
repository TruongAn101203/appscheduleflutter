import 'package:app_schedule_flutter/Admin/StudentForm.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> studentList = []; // List to store student maps
  List<Map<String, dynamic>> classList = []; // List to store classes

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch students and classes
  }

  // Fetch both student and class data
  Future<void> _fetchData() async {
    final studentData = await FirebaseDatabase.instance.ref('students').get();

    if (studentData.exists) {
      setState(() {
        // Kiểm tra nếu dữ liệu là List
        if (studentData.value is List) {
          // Lọc các phần tử null và chuyển đổi thành Map<String, dynamic>
          studentList = List<Map<String, dynamic>>.from(
              (studentData.value as List)
                  .where((e) => e != null) // Lọc các phần tử null
                  .map((e) => Map<String, dynamic>.from(e))
          );
        }
      });
    } else {
      setState(() {
        studentList = [];
      });
    }
  }

  // Show student form when adding or editing a student
  void _showStudentForm({Map<String, dynamic>? student}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StudentForm(
          student: student != null ? student : null, // Truyền thông tin sinh viên nếu có
          onSave: (stuid, studentData) async {
            // Hàm onSave xử lý thêm hoặc cập nhật dữ liệu sinh viên
            final studentDataRef = FirebaseDatabase.instance.ref('students');
            final snapshot = await studentDataRef.get();

            List<dynamic> students = [];
            if (snapshot.exists) {
              if (snapshot.value is List) {
                students = (snapshot.value as List).whereType<Map<String, dynamic>>().toList();
              } else if (snapshot.value is Map) {
                students = (snapshot.value as Map).values.map((item) {
                  return Map<String, dynamic>.from(item);
                }).toList();
              }
            }

            if (stuid == 0 || stuid == null) {
              // Nếu là sinh viên mới (stuid chưa tồn tại), thêm vào danh sách
              students.add(studentData);
            } else {
              // Nếu đã tồn tại stuid, cập nhật dữ liệu
              final index = students.indexWhere((s) => s['stuid'] == stuid);
              if (index != -1) {
                students[index] = studentData;
              }
            }

            // Cập nhật lại dữ liệu trên Firebase
            await studentDataRef.set(students);

            // Reload danh sách sinh viên
            _fetchData();
          },
          classList: classList, // Truyền danh sách lớp hiện tại
        );
      },
    );
  }

  // Save or update student
  void _saveStudent(int? stuid, Map<String, dynamic> studentData) async {
    final studentDataRef = FirebaseDatabase.instance.ref('students');
    final snapshot = await studentDataRef.get();
    List<Map<String, dynamic>> students = [];

    if (snapshot.exists) {
      if (snapshot.value is List) {
        students = (snapshot.value as List).whereType<Map<String, dynamic>>().toList();
      } else if (snapshot.value is Map) {
        students = (snapshot.value as Map).values.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      }
    }

    if (stuid == null || stuid == 0) {
      // Add new student to the list
      students.add(studentData); // Add new student data to the list
    } else {
      // Update existing student
      students[stuid] = studentData; // Update the student in the list
    }

    // Save the updated student list to Firebase (still keeping it as a List)
    await studentDataRef.set(students);

    // After saving, reload the student list
    _fetchData();
  }

  // Delete student with confirmation
  void _deleteStudent(int stuid) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có muốn xóa sinh viên này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xóa'),
              onPressed: () async {
                final studentDataRef = FirebaseDatabase.instance.ref('students');
                final snapshot = await studentDataRef.get();

                // Thêm print debug
                print("Attempting to delete student with ID: $stuid");

                if (snapshot.exists) {
                  List<dynamic> students = [];

                  if (snapshot.value is List) {
                    students = List.from(snapshot.value as List);
                  } else if (snapshot.value is Map) {
                    students = (snapshot.value as Map).values.toList();
                  }

                  // Thêm print debug
                  print("Current students in database: ${students.map((s) => s['stuid']).toList()}");

                  // Đảm bảo so sánh cùng kiểu dữ liệu
                  final studentToDeleteIndex = students.indexWhere(
                          (student) => int.parse(student['stuid'].toString()) == stuid
                  );

                  print("Found student at index: $studentToDeleteIndex");

                  if (studentToDeleteIndex != -1) {
                    // Xóa sinh viên
                    students.removeAt(studentToDeleteIndex);
                    await studentDataRef.set(students);

                    setState(() {
                      studentList.removeWhere(
                              (student) => int.parse(student['stuid'].toString()) == stuid
                      );
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xóa sinh viên thành công'))
                    );
                  } else {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không tìm thấy sinh viên'))
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không tìm thấy dữ liệu'))
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách sinh viên",
        style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto'
        ),
      ),
      backgroundColor: Color.fromARGB(255, 6, 138, 246), // Blue AppBar
      elevation: 4.0,
      centerTitle:true,

      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 25, color: Colors.white,),
        onPressed: (){
          Navigator.pop(context);
        },
      ), // Blue app bar
      ),
      body: ListView.builder(
        itemCount: studentList.length,
        itemBuilder: (context, index) {
          final student = studentList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(15),
              title: Text(
                student['stuname'] ?? 'Không có tên',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                student['gmail'] ?? 'Không có Email',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showStudentForm(student: student), // Show form to edit
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStudent(student['stuid']), // Delete student with confirmation
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentForm(), // Show form to add a new student
        child: Icon(Icons.add),
        backgroundColor: Colors.blue, // Blue FAB
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
