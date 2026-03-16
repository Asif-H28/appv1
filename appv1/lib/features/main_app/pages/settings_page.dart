import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notifications'),
                trailing: Switch(value: true, onChanged: (val) {}),
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                trailing: Text('English'),
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                textColor: AppColors.error,
                onTap: () {
                  // TODO: Clear SharedPreferences + API logout
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
