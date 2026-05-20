# Flutter AI UI/UX Master System

## Vision

Create a Flutter-first AI-assisted UI/UX engineering system that eliminates:

- Random AI-generated UI
- Inconsistent spacing
- Poor typography hierarchy
- Emotionless color palettes
- Bad motion design
- Generic layouts
- Accessibility issues
- Weak interaction feedback
- Non-scalable design systems

The goal is to build a production-grade plugin + AI skill framework that enables:

- Award-winning UI quality
- Intent-driven design generation
- Psychology-based color systems
- Motion-driven interactions
- Domain-aware layouts
- Human-level polish
- Enterprise-level scalability
- Pixel-perfect consistency

---

# System Architecture

## Core Philosophy

AI should NEVER directly generate raw widgets randomly.

Instead:

AI → Intent Engine → Design System → UX Rules → Motion Rules → Components → Final UI

This creates:

- Visual consistency
- Brand coherence
- Better accessibility
- Strong emotional design
- Premium product feel

---

# Plugin Name

`flutter_ai_design_system`

Alternative names:

- `intent_ui`
- `ux_engine_flutter`
- `ai_ui_architect`
- `neuro_ui_flutter`

---

# Folder Structure

```txt
lib/
 ├── core/
 │    ├── design_tokens/
 │    ├── psychology/
 │    ├── spacing/
 │    ├── typography/
 │    ├── motion/
 │    ├── accessibility/
 │    ├── themes/
 │    └── ai_rules/
 │
 ├── widgets/
 │    ├── buttons/
 │    ├── cards/
 │    ├── navigation/
 │    ├── forms/
 │    ├── loaders/
 │    ├── onboarding/
 │    ├── ecommerce/
 │    ├── fintech/
 │    ├── health/
 │    └── saas/
 │
 ├── engines/
 │    ├── intent_engine/
 │    ├── palette_engine/
 │    ├── layout_engine/
 │    ├── motion_engine/
 │    ├── micro_interaction_engine/
 │    └── adaptive_engine/
 │
 ├── animations/
 ├── presets/
 ├── generators/
 └── skill/
      └── skill.md
```

---

# Design Intelligence Layer

## 1. Intent Engine

This is the most important system.

AI must first understand:

- Domain
- User emotion
- Screen goal
- Conversion goal
- Interaction priority
- Device context
- User attention path

Example:

```dart
final intent = UIIntent(
  domain: Domain.fintech,
  goal: Goal.trust,
  emotion: Emotion.security,
  interactionDensity: Density.medium,
  conversionPriority: Conversion.high,
);
```

The UI generated for fintech should feel:

- Stable
- Trustworthy
- Precise
- Calm
- Structured

NOT playful.

---

# Psychology-Based Color Engine

## Color Psychology Rules

### Fintech

- Deep blue
- Neutral gray
- Emerald highlights
- High trust contrast

### Health

- Soft greens
- Calm whites
- Spacious layouts
- Reduced saturation

### Luxury Ecommerce

- Rich blacks
- Gold accents
- Elegant serif typography
- Cinematic transitions

### Productivity SaaS

- Minimal palette
- Sharp spacing
- Fast interaction feedback
- Information clarity

---

# Dynamic Palette Generator

```dart
final palette = PaletteEngine.generate(
  emotion: Emotion.calm,
  brandPersonality: BrandPersonality.premium,
  accessibility: AccessibilityLevel.AAA,
);
```

Rules:

- Automatic contrast validation
- Dark/light adaptive variants
- Surface hierarchy generation
- Semantic color roles
- Motion-aware colors
- State-aware colors

---

# Typography System

## Typography Rules

AI-generated apps fail because:

- Random font sizes
- No rhythm
- No hierarchy
- Poor readability

The plugin must enforce:

```dart
AppTypography(
  displayLarge,
  displayMedium,
  headingLarge,
  headingMedium,
  bodyLarge,
  bodyMedium,
  caption,
);
```

---

# Recommended Font Strategy

## Premium Fonts

### Sans Serif

- Inter
- Satoshi
- SF Pro
- Manrope
- General Sans

### Serif

- Playfair Display
- Cormorant
- Lora

### Monospace

- JetBrains Mono
- IBM Plex Mono

---

# Adaptive Spacing System

## Never Hardcode Spacing

Bad:

```dart
SizedBox(height: 17)
```

Correct:

```dart
context.space.md
```

Spacing scale:

```dart
4, 8, 12, 16, 20, 24, 32, 40, 48, 64
```

---

# Motion Design Engine

## Most Flutter Apps Lack Motion Intelligence

Motion should communicate:

- Feedback
- Hierarchy
- Navigation direction
- State changes
- Delight
- Brand personality

---

# Motion Rules

## Premium Motion Standards

### Fast UI feedback

50–150ms

### Navigation transitions

300–500ms

### Hero cinematic transitions

600–900ms

### Micro interactions

120–220ms

---

# Motion Packages

## Essential Flutter Animation Packages

### Core

- animations
- flutter_animate
- simple_animations
- rive
- lottie
- spring
- animated_text_kit

### Advanced

- flutter_glow
- glassmorphism
- shimmer
- mesh_gradient
- liquid_swipe
- smooth_page_indicator

### 3D / Visual

- flutter_cube
- model_viewer_plus
- vector_graphics

---

# Micro Interaction System

## Premium Interaction Behaviors

### Buttons

- Press depth
- Scale feedback
- Ripple control
- Haptic feedback
- Magnetic hover

### Cards

- Elevation transitions
- Mouse parallax
- Tilt effect
- Soft shadow animation

### Inputs

- Focus glow
- Validation transitions
- Animated helper text
- Error shake

---

# AI UI Rules

## Rule 1

Never generate more than:

- 2 primary colors
- 1 accent color
- 2 font families

---

## Rule 2

Every screen must define:

- Primary action
- Secondary action
- Reading flow
- Visual anchor
- Motion hierarchy

---

## Rule 3

Every page must pass:

- Accessibility
- Contrast
- Touch target size
- Layout consistency
- Typography rhythm

---

## Rule 4

Avoid visual noise.

AI must reduce:

- Unnecessary borders
- Excess shadows
- Random gradients
- Over-animation
- Over-rounded corners

---

# Layout Intelligence Engine

## Layout Rules

### Dashboard

- Structured grid
- Information hierarchy
- Dense but breathable

### Social App

- Gesture-first
- Thumb-zone optimized
- Infinite scrolling performance

### Ecommerce

- Product focus
- Visual storytelling
- Fast checkout path

### SaaS

- Clarity-first
- Functional spacing
- Data readability

---

# Responsive Intelligence

## AI Should Understand Device Context

### Mobile

- Thumb-friendly
- Bottom interaction priority

### Tablet

- Split layouts
- Hybrid navigation

### Desktop

- Multi-column
- Hover interactions
- Keyboard optimization

---

# Recommended Flutter Packages

## UI Foundation

- flutter_screenutil
- responsive_framework
- flex_color_scheme
- google_fonts
- theme_tailor

## State Management

- riverpod
- flutter_bloc
- provider

## Routing

- go_router
- auto_route

## Motion

- flutter_animate
- rive
- lottie

## Glass / Modern UI

- glassmorphism_ui
- mesh_gradient
- blurred

## SVG / Graphics

- flutter_svg
- vector_graphics

## Performance

- cached_network_image
- flutter_native_splash

---

# Material 3 + Custom Design Hybrid

Do NOT fully depend on raw Material widgets.

Correct approach:

```txt
Material Foundation
        +
Custom Brand Layer
        +
Interaction Layer
        +
Motion Layer
        +
Psychology Layer
```

---

# AI Prompting Rules for Flutter UI

## BAD Prompt

"Create a login screen"

---

## GOOD Prompt

"Create a premium fintech login screen using Material 3 with deep trust psychology, soft motion transitions, AAA accessibility, adaptive spacing system, floating glass card, subtle blur layers, biometric login emphasis, and frictionless onboarding UX."

---

# skill.md

```md
# Flutter AI UI/UX Expert Skill

You are a senior Flutter UI/UX architect with expertise in:

- Design systems
- Motion design
- Human psychology
- Product UX
- Accessibility
- Material 3
- Cupertino design
- Micro interactions
- Responsive systems
- Premium animations
- Visual hierarchy
- Typography systems
- AI-assisted UI generation

Your goal is to generate:

- Production-ready Flutter UI
- Pixel-perfect layouts
- Emotionally intelligent interfaces
- Domain-aware UX
- High conversion interfaces
- Premium interaction systems

---

# Core Rules

## Never generate random UI.

Always identify:

- App domain
- User intent
- Emotional goal
- Conversion goal
- Device type
- Accessibility level

before generating widgets.

---

# Design Principles

## Spacing

Use consistent spacing scale:

4, 8, 12, 16, 20, 24, 32, 40, 48, 64

Never hardcode random spacing.

---

## Typography

Always maintain:

- Strong hierarchy
- Readability
- Consistent rhythm
- Responsive scaling

---

## Colors

Use psychology-driven palettes.

Examples:

- Fintech → trust and security
- Health → calm and safety
- Luxury → elegance and depth
- SaaS → clarity and efficiency

Always ensure:

- WCAG accessibility
- Proper contrast
- Surface hierarchy

---

## Motion

Motion must communicate:

- Feedback
- Navigation
- State changes
- Delight

Avoid unnecessary animation.

---

## Micro Interactions

Every interactive component should include:

- Press feedback
- Hover behavior
- Focus states
- Transition states
- Loading states
- Error states

---

# Architecture Rules

Use:

- Clean architecture
- Modular widgets
- Reusable design tokens
- Theme extensions
- Adaptive layouts

Avoid:

- Giant widget trees
- Hardcoded values
- Inline styling everywhere
- Unstructured themes

---

# Preferred Flutter Stack

## UI

- Material 3
- Custom Theme Extensions
- FlexColorScheme
- Google Fonts

## State

- Riverpod

## Routing

- go_router

## Motion

- flutter_animate
- rive
- lottie

## Responsive

- responsive_framework
- flutter_screenutil

---

# Screen Generation Checklist

Before finalizing any UI:

- Is the visual hierarchy clear?
- Is spacing consistent?
- Is accessibility respected?
- Does motion feel premium?
- Is the UI emotionally aligned?
- Is there a clear primary action?
- Are touch targets usable?
- Is typography readable?
- Is the design scalable?

---

# Premium UI Behaviors

Always prefer:

- Soft shadows
- Layered surfaces
- Smooth motion
- Adaptive spacing
- Intentional color systems
- Context-aware layouts
- Reduced cognitive load

Avoid:

- Random gradients
- Excess glow
- Overcrowded screens
- Generic templates
- Excessive text
- Over-animation

---

# Expert-Level UX Expectations

Generated UI should feel comparable to:

- Stripe
- Linear
- Notion
- Airbnb
- Apple
- Tesla
- Revolut
- Headspace
- Spotify

without copying them directly.

---

# Output Standards

All generated Flutter code must:

- Be production-ready
- Be modular
- Support dark mode
- Support responsiveness
- Include loading/error states
- Include motion behaviors
- Follow Material 3 principles
- Include semantic naming
- Be scalable for enterprise apps

```

---

# Advanced Features

## AI Design Critic

Create an internal analyzer:

```dart
UIDesignCritic.analyze(screen)
```

Checks:

- Spacing rhythm
- Accessibility
- Color harmony
- Layout density
- Interaction clarity
- Motion consistency

---

# Design Tokens

## Essential Tokens

```dart
class AppTokens {
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;

  static const animationFast = 150;
  static const animationMedium = 300;
  static const animationSlow = 600;
}
```

---

# Enterprise-Level UI Principles

## Great UI feels:

- Predictable
- Smooth
- Intentional
- Emotionally aligned
- Visually calm
- Fast
- Intelligent

---

# Golden Rule

Do not build screens.

Build experiences.

Every pixel must communicate purpose.

