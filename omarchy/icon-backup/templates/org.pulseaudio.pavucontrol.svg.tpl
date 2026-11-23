<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Volume Control</title>
  <desc>A speaker in the main color with a pale cone and three sound waves in the theme's colors, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The speaker body; one hard shadow, as Hype's slides. -->
    <rect x="96" y="196" width="120" height="120" rx="16" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="96" y="196" width="120" height="120" rx="16" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The cone. -->
    <path d="M216 196L296 156V356L216 316Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M216 196L296 156V356L216 316Z" fill="url(#main)"/>
    <path d="M216 196L296 156V356L216 316Z" fill="none" stroke="{{ icon_paper }}" stroke-width="4" opacity=".25"/>
    <!-- The knob. -->
    <circle cx="156" cy="256" r="16" fill="{{ icon_shadow }}"/>
    <circle cx="156" cy="256" r="16" fill="{{ icon_mark }}"/>
    <!-- The sound waves. -->
    <path d="M320 200Q360 256 320 312" fill="none" stroke="{{ icon_shadow }}" stroke-width="14" stroke-linecap="round" transform="translate(0 8)"/>
    <path d="M320 200Q360 256 320 312" fill="none" stroke="{{ icon_paper }}" stroke-width="14" stroke-linecap="round"/>
    <path d="M352 168Q408 256 352 344" fill="none" stroke="{{ icon_shadow }}" stroke-width="14" stroke-linecap="round" transform="translate(0 8)"/>
    <path d="M352 168Q408 256 352 344" fill="none" stroke="{{ icon_mark }}" stroke-width="14" stroke-linecap="round"/>
    <path d="M384 136Q440 256 384 376" fill="none" stroke="{{ icon_shadow }}" stroke-width="14" stroke-linecap="round" transform="translate(0 8)"/>
    <path d="M384 136Q440 256 384 376" fill="none" stroke="{{ icon_paper }}" stroke-width="14" stroke-linecap="round" opacity=".6"/>
  </g>
</svg>
