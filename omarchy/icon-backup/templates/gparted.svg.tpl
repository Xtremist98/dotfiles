<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>GParted</title>
  <desc>A hard drive seen from the front with its partition bar split into four pieces in the theme's colors, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The case; one hard shadow, as Hype's slides. -->
    <rect x="76" y="120" width="360" height="272" rx="24" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="120" width="360" height="272" rx="24" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The slot at the top. -->
    <rect x="108" y="156" width="296" height="24" rx="12" fill="{{ icon_shadow }}"/>
    <!-- The partition bar: four pieces, each its own color. -->
    <rect x="108" y="212" width="296" height="72" rx="12" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <rect x="108" y="212" width="296" height="72" rx="12" fill="{{ icon_paper }}"/>
    <path d="M108 224Q108 212 120 212H208V284H120Q108 284 108 272Z" fill="url(#main)"/>
    <rect x="208" y="212" width="80" height="72" fill="{{ icon_mark }}"/>
    <rect x="288" y="212" width="60" height="72" fill="{{ icon_red }}"/>
    <path d="M348 212H392Q404 212 404 224V272Q404 284 392 284H348Z" fill="{{ icon_orange }}"/>
    <g stroke="{{ icon_shadow }}" stroke-width="4" opacity=".35">
      <path d="M208 212V284M288 212V284M348 212V284"/>
    </g>
    <!-- The label and the spindle. -->
    <rect x="108" y="316" width="128" height="14" rx="7" fill="{{ icon_ink }}"/>
    <rect x="108" y="344" width="88" height="14" rx="7" fill="{{ icon_ink }}" opacity=".55"/>
    <circle cx="372" cy="336" r="22" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <circle cx="372" cy="336" r="22" fill="{{ icon_mark }}"/>
    <circle cx="372" cy="336" r="8" fill="{{ icon_shadow }}" opacity=".35"/>
  </g>
</svg>
