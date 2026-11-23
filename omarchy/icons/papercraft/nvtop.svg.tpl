<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>nvtop</title>
  <desc>A graphics card seen from the front: a dark card with a fan in the highlight, a pulse in the main color, and a gold connector, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The card; one hard shadow, as Hype's slides. -->
    <rect x="76" y="150" width="360" height="220" rx="22" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="150" width="360" height="220" rx="22" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The heatsink fins. -->
    <g fill="{{ icon_edge }}">
      <rect x="276" y="172" width="8" height="44" rx="4"/>
      <rect x="296" y="172" width="8" height="44" rx="4"/>
      <rect x="316" y="172" width="8" height="44" rx="4"/>
      <rect x="336" y="172" width="8" height="44" rx="4"/>
      <rect x="356" y="172" width="8" height="44" rx="4"/>
      <rect x="376" y="172" width="8" height="44" rx="4"/>
    </g>
    <!-- The fan. -->
    <circle cx="180" cy="260" r="66" fill="{{ icon_shadow }}"/>
    <circle cx="180" cy="260" r="60" fill="{{ icon_mark }}"/>
    <g transform="translate(180 260)" fill="{{ icon_body }}">
      <path d="M0-50Q32-22 0 0Q-32-22 0-50Z"/>
      <path d="M0-50Q32-22 0 0Q-32-22 0-50Z" transform="rotate(90)"/>
      <path d="M0-50Q32-22 0 0Q-32-22 0-50Z" transform="rotate(180)"/>
      <path d="M0-50Q32-22 0 0Q-32-22 0-50Z" transform="rotate(270)"/>
    </g>
    <circle cx="180" cy="260" r="14" fill="{{ icon_paper }}"/>
    <!-- The pulse. -->
    <path d="M280 300L310 260L340 290L370 230L400 270" fill="none" stroke="{{ icon_shadow }}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 8)"/>
    <path d="M280 300L310 260L340 290L370 230L400 270" fill="none" stroke="url(#main)" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- The PCIe connector. -->
    <g fill="{{ icon_orange }}">
      <rect x="120" y="356" width="24" height="14" rx="4"/>
      <rect x="156" y="356" width="24" height="14" rx="4"/>
      <rect x="192" y="356" width="24" height="14" rx="4"/>
      <rect x="228" y="356" width="24" height="14" rx="4"/>
      <rect x="264" y="356" width="24" height="14" rx="4"/>
    </g>
  </g>
</svg>
