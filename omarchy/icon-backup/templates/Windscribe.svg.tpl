<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Windscribe</title>
  <desc>A shield seen from the front: a dark shield with three wind lines in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The shield; one hard shadow, as Hype's slides. -->
    <path d="M256 72L392 120V256Q392 360 256 424Q120 360 120 256V120Z" fill="{{ icon_shadow }}" transform="translate(0 10)"/>
    <path d="M256 72L392 120V256Q392 360 256 424Q120 360 120 256V120Z" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <path d="M256 100L364 138V256Q364 340 256 392Q148 340 148 256V138Z" fill="none" stroke="{{ icon_edge }}" stroke-width="4" opacity=".35"/>
    <!-- The wind. -->
    <g fill="none" stroke="url(#main)" stroke-width="16" stroke-linecap="round">
      <path d="M176 208Q256 172 336 208"/>
      <path d="M152 264Q256 228 360 264"/>
      <path d="M176 320Q256 284 336 320"/>
    </g>
  </g>
</svg>
