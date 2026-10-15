# SafeVege UX and Functionality Improvements

## Goal

Make the Flutter prototype easier to evaluate and more honest about what works today. Keep the existing Flutter, PHP, MySQL, and Longdo stack. Keep the Flutter app on local mock data; do not connect it to the PHP API in this pass.

## Work plan

1. **Guest discovery and map**
   - Open the guest experience on the real Longdo map, with the current shop list available from the existing Home tab.
   - Replace unsupported absolute safety claims and mark guest/shop/admin sample data as demo data.
   - Remove the Longdo API key default from source and keep the environment configuration path.
2. **Routing**
   - Remove the hard-coded Chiang Rai origin, estimated travel times, invented turn instructions, and in-app “live navigation” simulation.
   - Request the device's current location with permission, explain denial/unavailability, and allow a manual origin pick on the Longdo map.
   - Draw/clear the route only through documented Longdo Map Route commands.
3. **Shop and admin workflows**
   - Start inspection requests with blank vegetable rows and validate names before sending.
   - Start result entry with no preselected outcomes, canned findings, or fake certificate; require each result before completion.
   - Use the system file picker for certificate selection, validate allowed file types and size, and state that local selection is not a real upload.
   - Make shop/admin access visibly demo-only and remove prefilled credentials while retaining quick demo entry for testing.
4. **Verification**
   - Add focused widget/unit coverage for map-first navigation, demo-mode messaging, blank result defaults/validation, and Longdo route command payloads.
   - Run Flutter tests, analyzer, and web build; inspect the updated primary flows for layout regressions.

## Boundaries

- No Flutter-to-PHP API integration in this pass.
- Do not claim that a locally selected certificate is uploaded or published.
- Do not fabricate route distance, ETA, or turn-by-turn guidance when the supported Longdo SDK surface does not provide it.
- A live map and device location still require a valid Longdo key and runtime platform permissions.

## Completed

- Guest landing opens on the real Longdo map; nearby search uses device coordinates, and routes use Longdo Route commands.
- Demo data and account flows are labeled; mock result forms start blank, validate every vegetable, and keep selected files local.
- Certificate previews are shown only when the request has a passing item and certificate metadata. They list passing vegetables only; download and share are not presented as working actions.
- The Flutter app still does not connect to the PHP API or MySQL.
- Verification: `flutter analyze` passed, all 19 Flutter tests passed, and `flutter build web --dart-define-from-file=env/local.json` succeeded.
