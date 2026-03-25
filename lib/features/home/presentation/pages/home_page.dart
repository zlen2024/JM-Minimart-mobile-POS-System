import 'package:flutter/material.dart';
import '../../../../features/iot/presentation/pages/ble_setup_page.dart';
import '../../../../features/iot/presentation/pages/iot_control_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('POS Dashboard')),
    const Center(child: Text('Inventory Dashboard')),
    const Center(child: Text('Reports Dashboard')),
    const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IoTNavigationButton(
            title: "IoT BLE Provisioning",
            page: BLEProvisioningPage(),
            icon: Icons.bluetooth,
          ),
          SizedBox(height: 20),
          IoTNavigationButton(
            title: "IoT Control Dashboard",
            page: IoTControlPage(),
            icon: Icons.dashboard_customize,
          ),
        ],
      ),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JM Mini Mart'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors),
            label: 'IoT Devices',
          ),
        ],
      ),
    );
  }
}

class IoTNavigationButton extends StatelessWidget {
  final String title;
  final Widget page;
  final IconData icon;

  const IoTNavigationButton({
    required this.title,
    required this.page,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 16),
      ),
      icon: Icon(icon),
      label: Text(title),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
