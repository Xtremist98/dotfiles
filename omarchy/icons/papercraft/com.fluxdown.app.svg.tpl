<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>FluxDown</title>
  <desc>A download window seen from the front: a dark card with a download arrow in the main color and a progress bar in the highlight, each piece with a hard shadow.</desc>
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
    <!-- The download arrow. -->
    <rect x="240" y="128" width="32" height="112" rx="8" fill="url(#main)"/>
    <path d="M196 224L256 312L316 224Z" fill="url(#main)"/>
    <!-- The progress bar. -->
    <rect x="128" y="356" width="256" height="18" rx="9" fill="{{ icon_edge }}"/>
    <rect x="128" y="356" width="160" height="18" rx="9" fill="{{ icon_paper }}"/>
  </g>
</svg>
