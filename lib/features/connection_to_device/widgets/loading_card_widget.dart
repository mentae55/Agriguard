import 'package:flutter/material.dart';

import '../../../core/core.dart';

class LoadingCardWidget extends StatelessWidget {
  const LoadingCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size =MediaQuery.of(context).size.height;
    return
        Column(
          children: [
            SizedBox(height: size*0.2,),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 20,vertical: 20),
              child: Container(
                width: double.infinity,
                height: size*0.25,
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
                    const SizedBox(height: 12),
                    Text(
                      'Scanning for WiFi networks...',
                      style: TextStyle(
                        color: grayColor,
                        fontSize: 14,
                        fontFamily: 'AbhayaLibre',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                  ),
            ),
          ],
        );
  }
}
