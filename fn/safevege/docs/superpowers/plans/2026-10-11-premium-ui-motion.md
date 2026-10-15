# SafeVege Premium UI and Motion Plan

## Goal

Refine the visual system across guest, shop, and admin screens so the app feels cohesive, polished, and comfortable on mobile and desktop. Add brief, purposeful micro-animations while preserving screen behavior, API calls, and the existing Flutter/PHP/MySQL stack.

## Design direction

- Keep SafeVege's green identity, using deep evergreen for primary actions, a restrained leaf-green accent, warm neutral backgrounds, clear white surfaces, and quiet borders/shadows.
- Make shared typography, card, input, button, badge, and navigation styling consistent through the app theme and reusable widgets.
- Use short eased motion for press feedback, selected states, page routes, and content entrances. Keep motion subtle, avoid layout-changing animation, and honor the operating-system reduced-motion setting.

## Implementation phases

1. Audit the current theme, shared widgets, screen navigation, and existing Flutter tests.
2. Add motion/design tokens and tests for reduced-motion behavior before changing the shared animation widgets.
3. Refine the global Material theme, reusable interactive components, and navigation transitions so the changes reach all roles and routes.
4. Check key guest, shop, and admin screens at mobile and desktop widths, then run Flutter tests, analysis, and a debug build.

## Acceptance criteria

- Guest, shop, and admin screens share the updated color, typography, surface, and interaction language.
- Press and route feedback feels quick and restrained; reduced-motion settings remove nonessential movement.
- Existing workflows and API behavior remain unchanged.
- Flutter tests, static analysis, and debug build succeed.
