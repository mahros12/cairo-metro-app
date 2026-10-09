import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestWidget extends StatelessWidget
{
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RouteController());
    return Text('test');
  }
}