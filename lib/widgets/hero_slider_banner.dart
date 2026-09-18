import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/slider_model.dart';

/// A plain rotating image carousel, shown below the search bar (no overlay).
/// Aspect ratio: 16:9. Recommended asset sizes (any of these):
/// - 1280x720 (HD)
/// - 1920x1080 (Full HD - most common)
/// - 2560x1440 (2K)
/// - 3840x2160 (4K)
class HeroSliderBanner extends StatelessWidget {
  final List<SliderModel> sliders;
  final ValueChanged<SliderModel> onSliderTap;

  const HeroSliderBanner({
    super.key,
    required this.sliders,
    required this.onSliderTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sliderHeight = width * 9 / 16; // 16:9 aspect ratio

    return SizedBox(
      height: sliderHeight,
      width: width,
      child: sliders.isEmpty
          ? Container(width: width, height: sliderHeight, color: Colors.grey.shade200)
          : CarouselSlider.builder(
              itemCount: sliders.length,
              itemBuilder: (context, index, realIndex) {
                final slider = sliders[index];
                final imageUrl = slider.displayImageUrl;
                return GestureDetector(
                  onTap: () => onSliderTap(slider),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: width,
                          height: sliderHeight,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        )
                      : Container(width: width, height: sliderHeight, color: Colors.grey.shade200),
                );
              },
              options: CarouselOptions(
                height: sliderHeight,
                viewportFraction: 1.0,
                autoPlay: sliders.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                enableInfiniteScroll: sliders.length > 1,
              ),
            ),
    );
  }
}