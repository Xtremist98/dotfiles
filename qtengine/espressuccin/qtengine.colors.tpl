# KDE color scheme that qtengine turns into the Qt palette. Explicit normal
# and inactive groups keep inherited kdeglobals colours out. KColorScheme
# selects an Inactive subgroup instead of falling back to the normal group.
#
# Content (lists, text fields, editors, buttons) sits on background, the color
# the theme's hues are drawn against in the terminal, and the window chrome
# around it on dark_background. Selected text uses the background on the
# accent, which holds its contrast across the themes where the foreground does
# not.

[General]
ColorScheme=Omarchy
Name=Omarchy

[KDE]
contrast=0

[ColorEffects:Disabled]
Enable=true
IntensityEffect=0
ColorEffect=0
ContrastEffect=1
ContrastAmount=0.55

[ColorEffects:Inactive]
Enable=false
ChangeSelectionColor=false

[Colors:Window]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Window][Inactive]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:View]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 4% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ selection_rgb }}
DecorationHover={{ selection_rgb }}

[Colors:View][Inactive]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 4% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ selection_rgb }}
DecorationHover={{ selection_rgb }}

[Colors:Button]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 6% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Button][Inactive]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 6% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Selection]
BackgroundNormal={{ selection_rgb }}
BackgroundAlternate={{ mix_rgb selection foreground 10% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ muted_rgb }}
ForegroundActive={{ foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Selection][Inactive]
BackgroundNormal={{ selection_rgb }}
BackgroundAlternate={{ mix_rgb selection foreground 10% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ muted_rgb }}
ForegroundActive={{ foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Tooltip]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Tooltip][Inactive]
BackgroundNormal={{ background_rgb }}
BackgroundAlternate={{ mix_rgb background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Header]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Header][Inactive]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Complementary]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}

[Colors:Complementary][Inactive]
BackgroundNormal={{ dark_background_rgb }}
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
ForegroundNormal={{ foreground_rgb }}
ForegroundInactive={{ mix_rgb foreground dark_background 34% }}
ForegroundActive={{ accent_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundVisited={{ magenta_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundPositive={{ green_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
