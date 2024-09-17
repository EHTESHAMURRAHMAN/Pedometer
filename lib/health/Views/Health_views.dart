import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HealthView extends StatelessWidget {
  const HealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xff0d1a38),
          statusBarIconBrightness: Brightness.light,
        ),
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/main.png'), fit: BoxFit.cover),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                height: MediaQuery.of(context).size.height / 16,
                width: MediaQuery.of(context).size.width / 2.9,
                child: const Center(
                    child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                )),
              ),
            ),
            SizedBox(
              height: 5,
            )
          ],
        ),
      ),
    );
  }
}
