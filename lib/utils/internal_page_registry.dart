import 'package:flutter/material.dart';
import '../screens/post_property_type_screen.dart';

/// Maps each Slider's `internal_page_app_screen_key` (set by the admin in
/// the InternalPage model) to an actual Flutter screen.
///
/// Whenever you build a new page in the app that should be reachable from
/// a slider (e.g. "Why Choose Us", "About Us"), add one line here whose key
/// EXACTLY matches the `app_screen_key` your admin will type into that
/// InternalPage's admin form. Coordinate the key spelling with whoever
/// manages the backend admin panel - a typo on either side means the link
/// silently falls through to "not supported yet".
///
/// Example, once you build a WhyChooseUsScreen:
/// 'why_choose_us': (context) => const WhyChooseUsScreen(),
final Map<String, WidgetBuilder> internalPageRegistry = {
  // Add entries here as you build each page.
  'post_property': (context) => const PostPropertyTypeScreen(),
};