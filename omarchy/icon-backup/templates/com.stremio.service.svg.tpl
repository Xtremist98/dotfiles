<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Stremio Service</title>
  <desc>A screen in the highlight with a pale play button and a small gear in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The screen; one hard shadow, as Hype's slides. -->
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_shadow }}" transform="translate(0 10)"/>
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_mark }}"/>
    <rect x="112" y="112" width="288" height="288" rx="40" fill="{{ icon_body }}"/>
    <!-- The play button. -->
    <path d="M220 176L336 256L220 336Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M220 176L336 256L220 336Z" fill="{{ icon_paper }}"/>
    <!-- The service gear. -->
    <g transform="translate(380 380)" fill="{{ accent }}">
      <circle r="34"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(45)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(90)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(135)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(180)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(225)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(270)"/>
      <rect x="-8" y="-46" width="16" height="20" rx="4" transform="rotate(315)"/>
    </g>
    <circle cx="380" cy="380" r="14" fill="{{ icon_body }}"/>
  </g>
</svg>
