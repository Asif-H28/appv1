import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'John Doe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Student',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              SizedBox(height: 30),
              Card(
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text('john@example.com'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.school),
                  title: Text('Class'),
                  subtitle: Text('10A'),
                ),
              ),
              // TODO: Load from API
            ],
          ),
        ),
      ),
    );
  }
}
