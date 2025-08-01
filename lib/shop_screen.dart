import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/shop_service.dart';
import 'services/coin_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopItem? selectedItem;
  ShopItem? buyPreviewItem;
  int userCoins = 0;
  bool showOwnedItems = false; // Toggle between Buy and Owned
  bool isLoading = true;
  String currentWornItem = 'MyCharacter';
  List<ShopItem> shopItems = [];

  final ShopService _shopService = ShopService();
  final CoinService _coinService = CoinService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeShop();
  }

  Future<void> _initializeShop() async {
    try {
      // Initialize user shop data if needed
      await _shopService.initializeUserShopData();

      // Load shop items and user data
      await _loadShopData();

      // Start listening to coin changes
      _startCoinListener();

      // Start listening to shop data changes
      _startShopDataListener();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error initializing shop: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadShopData() async {
    try {
      // Load shop items with ownership status
      final items = await _shopService.getShopItems();

      // Load current coin balance
      final coins = await _coinService.getCurrentUserCoins();

      // Load current worn item
      final wornItem = await _shopService.getCurrentWornItem();

      setState(() {
        shopItems = items;
        userCoins = coins;
        currentWornItem = wornItem;

        // Set the current worn item as selected by default
        selectedItem = items.firstWhere(
          (item) => item.id == wornItem,
          orElse: () => items.first,
        );
      });
    } catch (e) {
      print('❌ Error loading shop data: $e');
    }
  }

  void _startCoinListener() {
    _coinService.getCurrentUserCoinsStream().listen((coins) {
      if (mounted) {
        setState(() {
          userCoins = coins;
        });
      }
    });
  }

  void _startShopDataListener() {
    _shopService.getShopDataStream().listen((shopData) async {
      if (mounted) {
        // Reload shop items to reflect ownership changes
        final items = await _shopService.getShopItems();
        final wornItem = shopData['currentCharacter'] as String;

        setState(() {
          shopItems = items;
          currentWornItem = wornItem;

          // Update selected item if it's the worn item
          if (selectedItem?.id != wornItem) {
            selectedItem = items.firstWhere(
              (item) => item.id == wornItem,
              orElse: () => items.first,
            );
          }
        });
      }
    });
  }

  void handleItemSelect(ShopItem item) {
    setState(() {
      selectedItem = item;
    });
  }

  Future<void> handleBuyClick(ShopItem item) async {
    if (item.isOwned) {
      // If already owned, wear it instead
      await _wearItem(item);
    } else {
      // Show buy preview
      setState(() {
        buyPreviewItem = item;
        selectedItem = item;
      });
    }
  }

  Future<void> _buyItem(ShopItem item) async {
    try {
      final success = await _shopService.buyItem(item.id);

      if (success) {
        // Close buy preview
        closeBuyPreview();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully bought ${item.name}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reload shop data to reflect changes
        await _loadShopData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to buy item. Check your coins!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error buying item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _wearItem(ShopItem item) async {
    try {
      final success = await _shopService.wearItem(item.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Now wearing ${item.name}!'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reload shop data to reflect changes
        await _loadShopData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to wear item!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error wearing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void closeBuyPreview() {
    setState(() {
      buyPreviewItem = null;
    });
  }

  List<ShopItem> getFilteredItems() {
    return shopItems.where((item) => item.isOwned == showOwnedItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Always show the current worn item in preview, regardless of selection
    final displayItem = buyPreviewItem ??
        selectedItem ??
        shopItems.firstWhere(
          (item) => item.id == currentWornItem,
          orElse: () => shopItems.first,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shop',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(color: const Color(0xFFF5E9B9), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Coin image
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/coin.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userCoins.toString(),
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top 55% - Item Preview Display
          Expanded(
            flex: 55,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _buildItemPreview(displayItem),
              ),
            ),
          ),

          // Bottom 45% - Shop Items Carousel or Buy Preview
          Expanded(
            flex: 45,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: buyPreviewItem == null
                  ? _buildShopSection()
                  : _buildBuyPreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPreview(ShopItem item) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: RepaintBoundary(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AbsorbPointer(
              child: ModelViewer(
                key: ValueKey('preview_${item.id}'),
                src: item.glbFilePath,
                alt: "A 3D model of ${item.name}",
                autoRotate: false,
                cameraControls: false,
                backgroundColor: Colors.transparent,
                cameraOrbit: "0deg 75deg 100%",
                minCameraOrbit: "0deg 75deg 100%",
                maxCameraOrbit: "0deg 75deg 100%",
                interactionPrompt: InteractionPrompt.none,
                disableTap: true,
                autoPlay: true,
                disableZoom: true,
                disablePan: true,
                minFieldOfView: "45deg",
                maxFieldOfView: "45deg",
                fieldOfView: "45deg",
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSection() {
    final filteredItems = getFilteredItems();

    return Column(
      children: [
        // Toggle Switch - 15% of the 45% section
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                // Buy Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showOwnedItems = false;
                        selectedItem = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            !showOwnedItems ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: !showOwnedItems
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Buy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !showOwnedItems
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Owned Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showOwnedItems = true;
                        selectedItem = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            showOwnedItems ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: showOwnedItems
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Owned',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: showOwnedItems
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Shop Items Carousel - 85% of the 45% section
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        showOwnedItems ? Icons.inventory : Icons.shopping_bag,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        showOwnedItems
                            ? 'No owned items yet'
                            : 'No items available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildShopItemsCarousel(filteredItems),
        ),
      ],
    );
  }

  Widget _buildShopItemsCarousel(List<ShopItem> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem?.id == item.id;
          final isWorn = item.isWorn;

          return Container(
            width: 160,
            height: 120,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => handleItemSelect(item),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWorn
                        ? Colors.green
                        : isSelected
                            ? Colors.orange
                            : Colors.grey[300]!,
                    width: isWorn || isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Item Image
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Image.asset(
                                    item.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // Worn indicator
                            if (isWorn)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Item Info
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!showOwnedItems) // Only show price for purchasable items
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on,
                                          size: 10, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        item.price.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                GestureDetector(
                                  onTap: () => handleBuyClick(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.isOwned
                                          ? Colors.green
                                          : Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.isOwned ? 'Wear' : 'Buy',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyPreview() {
    if (buyPreviewItem == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: closeBuyPreview,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14),
              ),
            ),
          ),

          // Item Preview
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    buyPreviewItem!.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Item Details
          Text(
            buyPreviewItem!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            buyPreviewItem!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Buy Button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _buyItem(buyPreviewItem!),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: userCoins >= buyPreviewItem!.price
                      ? Colors.black
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userCoins >= buyPreviewItem!.price
                          ? 'Buy'
                          : 'Not enough coins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: userCoins >= buyPreviewItem!.price
                            ? Colors.white
                            : Colors.grey[500],
                      ),
                    ),
                    if (userCoins >= buyPreviewItem!.price)
                      Row(
                        children: [
                          const Icon(Icons.monetization_on,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${buyPreviewItem!.price}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
