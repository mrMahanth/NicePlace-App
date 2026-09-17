import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/slider_model.dart';

/// A rotating image banner fetched live from the backend, with the search
/// bar floating on top of its blank top zone. Matches the 1125x375 (3:1
/// aspect ratio) asset spec:
/// - top 100/375 (~26.7%) of the image is the blank/gradient zone the
///   search bar sits over
/// - bottom 275/375 (~73.3%) is the actual marketing artwork
///
/// The search bar's own background should be passed in as transparent
/// (or semi-transparent) from the caller so the banner colors show through.
class HeroSliderBanner extends StatelessWidget {
  final List<SliderModel> sliders;
  final Widget searchBarOverlay;
  final ValueChanged<SliderModel> onSliderTap;

  const HeroSliderBanner({
    super.key,
    required this.sliders,
    required this.searchBarOverlay,
    required this.onSliderTap,
  });

  static const double _searchBarHeight = 46; // matches AnimatedHintSearchField's Container height

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sliderHeight = width / 3; // 1125:375 asset ratio = 3:1
    final topZoneHeight = sliderHeight * (100 / 375); // blank zone reserved for the search bar

    return SizedBox(
      height: sliderHeight,
      width: width,
      child: Stack(
        children: [
          if (sliders.isEmpty)
            Container(width: width, height: sliderHeight, color: Colors.grey.shade200)
          else
            CarouselSlider.builder(
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
          Positioned(
            top: (topZoneHeight - _searchBarHeight) / 2,
            left: 16,
            right: 16,
            child: searchBarOverlay,
          ),
        ],
      ),
    );
  }
}