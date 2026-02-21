import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final Color primaryGreen = const Color(0xFF006B4D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(
              child: _searchController.text.isEmpty 
                ? _buildRecentSearches() 
                : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Search inventory, transactions...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final history = ["Golden Penny Beans", "Electricity bill", "Tomatoes"];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        ...history.map((item) => ListTile(
          leading: const Icon(Icons.history, size: 18),
          title: Text(item),
          onTap: () => _searchController.text = item,
        )),
      ],
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _resultCategory("Inventory Items"),
        _resultItem("Golden Penny Beans", "Grains • 20 Units", Icons.inventory_2_outlined, '/inventory'),
        const SizedBox(height: 20),
        _resultCategory("Financial Transactions"),
        _resultItem("Electricity Payment", "Expense • ₦10,000", Icons.bolt, '/transactions'),
      ],
    );
  }

  Widget _resultCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
    );
  }

  Widget _resultItem(String title, String sub, IconData icon, String route) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: Icon(icon, color: primaryGreen, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () => context.push(route),
    );
  }
}