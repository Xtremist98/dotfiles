<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Text Editor</title>
  <desc>A text editor window seen from the front: a dark window with a title bar, rows of text in the highlight, line numbers, a cursor in the main color, and a scrollbar, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The window; one hard shadow, as Hype's slides. -->
    <rect x="76" y="92" width="360" height="328" rx="22" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="92" width="360" height="328" rx="22" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The title bar. -->
    <rect x="76" y="144" width="360" height="3" fill="{{ icon_edge }}"/>
    <circle cx="104" cy="118" r="7" fill="{{ icon_red }}"/>
    <circle cx="124" cy="118" r="7" fill="{{ icon_orange }}"/>
    <circle cx="144" cy="118" r="7" fill="{{ icon_paper }}"/>
    <!-- The line numbers. -->
    <g fill="{{ icon_edge }}" opacity=".7">
      <rect x="100" y="172" width="16" height="8" rx="4"/>
      <rect x="100" y="204" width="16" height="8" rx="4"/>
      <rect x="100" y="236" width="16" height="8" rx="4"/>
      <rect x="100" y="268" width="16" height="8" rx="4"/>
      <rect x="100" y="300" width="16" height="8" rx="4"/>
    </g>
    <!-- The text. -->
    <g fill="{{ icon_paper }}">
      <rect x="136" y="172" width="200" height="10" rx="5"/>
      <rect x="136" y="204" width="160" height="10" rx="5" opacity=".7"/>
      <rect x="136" y="236" width="220" height="10" rx="5" opacity=".85"/>
      <rect x="136" y="268" width="120" height="10" rx="5" opacity=".55"/>
      <rect x="136" y="300" width="180" height="10" rx="5" opacity=".75"/>
    </g>
    <!-- The cursor and scrollbar. -->
    <rect x="136" y="332" width="18" height="30" rx="3" fill="url(#main)"/>
    <rect x="408" y="168" width="8" height="200" rx="4" fill="{{ icon_edge }}"/>
    <rect x="408" y="168" width="8" height="72" rx="4" fill="{{ icon_paper }}"/>
  </g>
</svg>
