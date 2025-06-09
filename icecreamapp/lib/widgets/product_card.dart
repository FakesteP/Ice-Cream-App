import 'package:flutter/material.dart';
import 'package:icecreamapp/models/product_model.dart';
import 'package:icecreamapp/pages/product_detail_page.dart';
import 'package:icecreamapp/services/currency_service.dart'; // Untuk format harga
import 'package:intl/intl.dart';


class ProductCard extends StatelessWidget {
  final Product product;
  final CurrencyService _currencyService = CurrencyService(); // Jika ingin format harga

  ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Menggunakan NumberFormat untuk IDR secara default jika CurrencyService tidak digunakan di sini
    final priceString = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Add debugging to check product data
          print('🛒 ProductCard tapped:');
          print('  - Product ID: ${product.id}');
          print('  - Product Name: ${product.name}');
          print('  - Product Price: ${product.price}');
          print('  - Product Price Type: ${product.price.runtimeType}');
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.icecream_outlined, size: 50, color: Colors.grey[400]),
                        ),
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.pink[100],
                        child: Icon(Icons.icecream, size: 60, color: Colors.pink[300]),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // SizedBox(height: 4),
                    // Text(
                    //   product.description ?? 'No description available.',
                    //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // SizedBox(height: 6),
                    Text(
                      priceString,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}