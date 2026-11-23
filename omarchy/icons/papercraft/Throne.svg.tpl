<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Throne</title>
  <desc>A crown seen from the front on a dark card: a crown in the highlight with a gem in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The card; one hard shadow, as Hype's slides. -->
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_shadow }}" transform="translate(0 10)"/>
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The crown. -->
    <path d="M128 330L152 190L200 250L256 150L312 250L360 190L384 330Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M128 330L152 190L200 250L256 150L312 250L360 190L384 330Z" fill="{{ icon_mark }}"/>
    <circle cx="256" cy="150" r="16" fill="url(#main)"/>
    <circle cx="251" cy="145" r="5" fill="{{ icon_paper }}" opacity=".55"/>
  </g>
</svg>
