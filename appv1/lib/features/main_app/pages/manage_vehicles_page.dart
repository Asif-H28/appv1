import 'package:appv1/features/main_app/pages/setup_vehicle_pin_page.dart';
import 'package:flutter/material.dart';
import 'package:appv1/core/services/api_service.dart';

class ManageVehiclesPage extends StatefulWidget {
  final String orgId;
  final String coordinatorId;
  final String coordinatorName;

  const ManageVehiclesPage({
    super.key,
    required this.orgId,
    required this.coordinatorId,
    required this.coordinatorName,
  });

  @override
  State<ManageVehiclesPage> createState() => _ManageVehiclesPageState();
}

class _ManageVehiclesPageState extends State<ManageVehiclesPage> {
  bool _isLoading = true;
  List<dynamic> _vehicles = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final res = await ApiService.fetchVehicles(widget.orgId);

    if (mounted) {
      if (res['success']) {
        setState(() {
          _vehicles = res['vehicles'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load vehicles';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Vehicles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Coordinator: ${widget.coordinatorName}',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupVehiclePinPage(orgId: widget.orgId),
                ),
              );
            },
            icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
            tooltip: 'Set Transport PIN',
          ),
          IconButton(
            onPressed: _fetchVehicles,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _error.isNotEmpty
                    ? _buildErrorView()
                    : _vehicles.isEmpty
                        ? _buildEmptyView()
                        : _buildVehicleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleSheet(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }


  Widget _buildVehicleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final v = _vehicles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEDF2F7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['vehicleName'] ?? 'Unnamed Vehicle',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
                        ),
                        Text(
                          v['vehicleNumber'] ?? 'N/A',
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showVehicleSheet(vehicle: v);
                      } else if (val == 'delete') {
                        _confirmDelete(v['vehicleId']?.toString() ?? '');
                      }
                    },
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF718096)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFEDF2F7)),
              ),
              _vehicleDetailRow(Icons.person_rounded, 'Driver', v['driverName']),
              const SizedBox(height: 8),
              _vehicleDetailRow(Icons.phone_rounded, 'Phone', v['driverPhoneNumber']),
            ],
          ),
        );
      },
    );
  }

  Widget _vehicleDetailRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF718096)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF718096), fontSize: 13)),
        Text(value ?? 'N/A', style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_rounded, size: 64, color: Colors.teal.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('No vehicles assigned yet', style: TextStyle(color: Color(0xFF718096), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Click the + button to add a new vehicle', style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF4A5568))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchVehicles,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _performDelete(vehicleId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String vehicleId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    final res = await ApiService.deleteVehicle(vehicleId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.teal, behavior: SnackBarBehavior.floating));
      _fetchVehicles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  void _showVehicleSheet({Map<String, dynamic>? vehicle}) {
    final isEdit = vehicle != null;
    final vNameCtrl = TextEditingController(text: vehicle?['vehicleName']);
    final vNumCtrl = TextEditingController(text: vehicle?['vehicleNumber']);
    final dNameCtrl = TextEditingController(text: vehicle?['driverName']);
    final dPhoneCtrl = TextEditingController(text: vehicle?['driverPhoneNumber']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Vehicle' : 'Vehicle Details',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      Text(
                        isEdit ? 'Update technical specifications' : 'Enter technical specifications',
                        style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF718096)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              _sheetLabel('Vehicle Name'),
              _sheetField(vNameCtrl, 'e.g. Heavy Duty Transport A1'),
              _sheetLabel('Vehicle Number'),
              _sheetField(vNumCtrl, 'e.g. ABC-1234-XY'),
              _sheetLabel('Driver Name'),
              _sheetField(dNameCtrl, 'e.g. John Doe'),
              _sheetLabel('Driver Phone Number'),
              _sheetField(dPhoneCtrl, '+1 (555) 000-0000', icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Updated tracking data will be applied immediately to maintenance and fuel reports.' : 'By adding this vehicle, it will be automatically tracked for maintenance intervals and fuel consumption reporting.',
                        style: const TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  if (vNameCtrl.text.isEmpty || vNumCtrl.text.isEmpty || dNameCtrl.text.isEmpty || dPhoneCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }

                  Navigator.pop(sheetContext); // Close sheet
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogCtx) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  );

                  final Map<String, dynamic> res;
                  if (isEdit) {
                    res = await ApiService.updateVehicle(
                      vehicleId: vehicle['vehicleId']?.toString() ?? '',
                      vehicleName: vNameCtrl.text,
                      vehicleNumber: vNumCtrl.text,
                      driverName: dNameCtrl.text,
                      driverPhoneNumber: dPhoneCtrl.text,
                    );
                  } else {
                    res = await ApiService.createVehicle(
                      orgId: widget.orgId,
                      coordinatorId: widget.coordinatorId,
                      vehicleName: vNameCtrl.text,
                      vehicleNumber: vNumCtrl.text,
                      driverName: dNameCtrl.text,
                      driverPhoneNumber: dPhoneCtrl.text,
                    );
                  }

                  if (!mounted) return;
                  Navigator.pop(context); // Close loading dialog using state context

                  if (res['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.teal, behavior: SnackBarBehavior.floating));
                    _fetchVehicles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                  }
                },
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(isEdit ? 'Update Vehicle' : 'Save Vehicle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF4A5568),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568))),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFFCBD5E0)) : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
