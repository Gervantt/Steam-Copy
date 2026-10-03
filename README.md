# GameVault — Game Detail Screen

Lab work #5: an adaptive e-commerce item detail screen built with Flutter.

The screen shows the page of Hollow Knight in the fictional GameVault store:

- cover image with back button, bookmark button and discount badge (Stack + Positioned)
- title, developer, star rating and price with old price (Row)
- genre tags that wrap to new lines (Wrap)
- short description
- sticky bottom bar with price and a full-width "Add to Cart" button (Expanded)

The layout has no RenderFlex overflow on small and large screens. On wide screens the content is limited to 700 px and centered.

## Run

```bash
flutter pub get
flutter run
```
