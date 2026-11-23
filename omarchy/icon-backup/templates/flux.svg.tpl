<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Flux</title>
  <desc>A phone with its screen in the main color and a chain-link badge in the highlight, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The phone; one hard shadow, as Hype's slides. -->
    <rect x="180" y="80" width="152" height="300" rx="26" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="180" y="80" width="152" height="300" rx="26" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <rect x="200" y="112" width="112" height="220" rx="14" fill="url(#main)"/>
    <rect x="224" y="348" width="64" height="8" rx="4" fill="{{ icon_paper }}"/>
    <!-- The link badge. -->
    <circle cx="376" cy="336" r="52" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <circle cx="376" cy="336" r="52" fill="url(#main)"/>
    <g transform="translate(376 336) rotate(-45)" fill="none" stroke="{{ icon_paper }}" stroke-width="8">
      <rect x="-34" y="-13" width="38" height="26" rx="13"/>
      <rect x="-4" y="-13" width="38" height="26" rx="13"/>
    </g>
  </g>
</svg>
