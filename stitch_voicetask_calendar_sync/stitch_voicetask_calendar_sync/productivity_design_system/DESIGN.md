---
name: Productivity Design System
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#47464f'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#787680'
  outline-variant: '#c8c5d0'
  surface-tint: '#5b598c'
  primary: '#070235'
  on-primary: '#ffffff'
  primary-container: '#1e1b4b'
  on-primary-container: '#8683ba'
  inverse-primary: '#c4c1fb'
  secondary: '#712ae2'
  on-secondary: '#ffffff'
  secondary-container: '#8a4cfc'
  on-secondary-container: '#fffbff'
  tertiary: '#000a22'
  on-tertiary: '#ffffff'
  tertiary-container: '#00204d'
  on-tertiary-container: '#4086fa'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e3dfff'
  primary-fixed-dim: '#c4c1fb'
  on-primary-fixed: '#181445'
  on-primary-fixed-variant: '#444173'
  secondary-fixed: '#eaddff'
  secondary-fixed-dim: '#d2bbff'
  on-secondary-fixed: '#25005a'
  on-secondary-fixed-variant: '#5a00c6'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  h1:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  h3:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: '0'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
    letterSpacing: '0'
  label-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: 0.02em
  label-xs:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  margin-page: 32px
  gutter: 24px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system focuses on cognitive clarity and frictionless task management. It adopts a **Minimalist-Corporate** hybrid aesthetic, prioritizing negative space to reduce mental fatigue. The brand personality is professional yet innovative, positioning itself as a silent partner in the user's workflow. 

Visual depth is achieved through layering rather than decoration. The interface should feel expansive, utilizing "Crisp White" as the primary canvas to allow "Deep Indigo" elements to signify importance and "Electric Violet" to draw immediate focus to the voice-driven capabilities.

## Colors
The palette is rooted in a professional "Deep Indigo" (#1E1B4B) for high-level navigation and primary actions. "Crisp Whites" and "Soft Grays" form the structural foundation, ensuring the UI remains airy. 

The "Electric Violet" (#8B5CF6) is reserved exclusively for the voice interface and AI-driven features, creating a distinct visual "mode" for the user. Neutral tones are strictly cool-skewed to maintain the sleek, modern professional tone.

## Typography
**Inter** is the sole typeface, utilized for its exceptional readability and neutral, systematic feel. Information hierarchy is established through aggressive weight variance and tight letter-spacing on larger headings.

- Use **Bold/700** for primary page headers.
- Use **Medium/500** for interactive labels to differentiate them from static body text.
- Maintain ample line-height (1.5+) for body text to ensure readability during long-form task descriptions.

## Layout & Spacing
The system uses a **12-column fluid grid** for desktop and a single-column fluid layout for mobile, with a focus on generous internal padding. 

Margins and gutters follow an 8px rhythmic scale. Spacing is used as a tool for grouping: elements within a card use `stack-sm`, while distinct sections of the application are separated by `stack-lg`. Use "Safe Areas" around the voice activation trigger to ensure it remains the focal point of the lower-third of the screen.

## Elevation & Depth
Depth is communicated through **Ambient Shadows** and a **Tonal Layering** system.
- **Level 0 (Base):** Crisp White (#FFFFFF) background.
- **Level 1 (Cards):** Soft Gray (#F9FAFB) surface with a subtle 1px border (#E5E7EB).
- **Level 2 (Active/Floating):** High-diffusion shadows using Indigo-tinted blacks at 4% opacity. 

Shadows should feel like light passing through glass rather than heavy silhouettes. Avoid harsh outlines; use 1px borders in a slightly darker neutral shade to define boundaries on white backgrounds.

## Shapes
This design system utilizes a high degree of roundedness to evoke a friendly, modern, and high-end feel.
- **Base Components:** 16px (1rem) for standard buttons and input fields.
- **Containers/Cards:** 24px (1.5rem) for main content areas and dashboard widgets.
- **Voice Trigger:** Fully rounded (pill-shaped) to distinguish it from rectangular productivity elements.

## Components

### Buttons & Inputs
- **Primary Action:** Deep Indigo background with white text. 16px corner radius.
- **Voice Action:** Electric Violet background. Must include a pulse animation or glowing ambient shadow when active.
- **Inputs:** Soft Gray background, 1px border. On focus, the border transitions to Deep Indigo with a 2px outer glow.

### Cards & Lists
- **Cards:** White background with a 24px corner radius and a Level 2 ambient shadow.
- **List Items:** Separated by whitespace rather than lines. Hover states should trigger a Soft Gray background transition.

### Navigation & Feedback
- **Active States:** Indicated by a 4px vertical Indigo pill next to the menu item.
- **Iconography:** Use "Linear" style icons with a 2px stroke weight. Icons should be monochrome (Deep Indigo) except when associated with the Voice feature (Electric Violet).
- **Chips:** Small, 100px radius pills used for status tags (e.g., "In Progress", "High Priority") using de-saturated versions of the primary palette.