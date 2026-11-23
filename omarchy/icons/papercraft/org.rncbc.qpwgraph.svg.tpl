<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>qpwgraph</title>
  <desc>Three patchbay nodes joined by cables in the theme's colors, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The cables; one hard shadow. -->
    <g fill="none" stroke="{{ icon_shadow }}" stroke-width="18" stroke-linecap="round" transform="translate(0 8)">
      <path d="M204 150C240 220 230 260 230 330"/>
      <path d="M308 150C272 220 282 260 282 330"/>
    </g>
    <g fill="none" stroke-width="18" stroke-linecap="round">
      <path d="M204 150C240 220 230 260 230 330" stroke="url(#main)"/>
      <path d="M308 150C272 220 282 260 282 330" stroke="{{ icon_mark }}"/>
    </g>
    <!-- The top-left node. -->
    <rect x="76" y="100" width="140" height="100" rx="18" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="100" width="140" height="100" rx="18" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <circle cx="204" cy="150" r="14" fill="{{ accent }}"/>
    <!-- The top-right node. -->
    <rect x="296" y="100" width="140" height="100" rx="18" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="296" y="100" width="140" height="100" rx="18" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <circle cx="308" cy="150" r="14" fill="{{ icon_mark }}"/>
    <!-- The bottom node, with a port for each cable. -->
    <rect x="186" y="320" width="140" height="100" rx="18" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="186" y="320" width="140" height="100" rx="18" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <circle cx="230" cy="330" r="14" fill="{{ accent }}"/>
    <circle cx="282" cy="330" r="14" fill="{{ icon_mark }}"/>
  </g>
</svg>
