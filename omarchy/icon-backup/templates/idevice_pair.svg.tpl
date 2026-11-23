<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>idevice pair</title>
  <desc>A phone with its screen in the highlight, a cable at its foot, and a pairing check in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The phone; one hard shadow, as Hype's slides. -->
    <rect x="176" y="64" width="160" height="320" rx="28" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="176" y="64" width="160" height="320" rx="28" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <rect x="196" y="96" width="120" height="240" rx="14" fill="{{ icon_mark }}"/>
    <rect x="224" y="352" width="64" height="8" rx="4" fill="{{ icon_paper }}"/>
    <!-- The cable. -->
    <path d="M256 384V440H340" fill="none" stroke="{{ icon_shadow }}" stroke-width="16" stroke-linecap="round" transform="translate(0 8)"/>
    <path d="M256 384V440H340" fill="none" stroke="{{ icon_paper }}" stroke-width="16" stroke-linecap="round"/>
    <rect x="340" y="428" width="44" height="24" rx="6" fill="{{ icon_mark }}"/>
    <!-- The pairing check. -->
    <circle cx="360" cy="120" r="46" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <circle cx="360" cy="120" r="46" fill="url(#main)"/>
    <path d="M338 120L354 136L384 104" fill="none" stroke="{{ icon_paper }}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
</svg>
