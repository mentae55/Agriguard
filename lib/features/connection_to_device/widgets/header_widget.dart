import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/core.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: primaryColor, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiFi Setup',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: blackColor,
                    ),
                  ),
                  Text(
                    'Connect AgriGuard to your network',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'AbhayaLibre',
                      fontWeight: FontWeight.w600,
                      color: grayColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(9),
              child: SvgPicture.asset('assets/app_images/icons/logo.svg'),
            ),
          ],
        ),
      );
    }
  }

