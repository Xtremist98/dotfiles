<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Task Manager</title>
  <desc>A monitor seen from the front with a pulse in the main color and a row of bars, on a stand, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The monitor; one hard shadow, as Hype's slides. -->
    <rect x="76" y="96" width="360" height="280" rx="22" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="96" width="360" height="280" rx="22" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <rect x="96" y="116" width="320" height="240" rx="12" fill="{{ icon_shadow }}"/>
    <!-- The pulse. -->
    <path d="M120 260L170 260L200 200L240 300L280 230L320 260L392 260" fill="none" stroke="{{ icon_shadow }}" stroke-width="14" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 8)"/>
    <path d="M120 260L170 260L200 200L240 300L280 230L320 260L392 260" fill="none" stroke="url(#main)" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- The bars. -->
    <g>
      <rect x="120" y="300" width="40" height="40" rx="6" fill="{{ icon_mark }}"/>
      <rect x="176" y="280" width="40" height="60" rx="6" fill="{{ icon_paper }}"/>
      <rect x="232" y="310" width="40" height="30" rx="6" fill="{{ icon_orange }}"/>
      <rect x="288" y="292" width="40" height="48" rx="6" fill="{{ icon_red }}"/>
    </g>
    <!-- The stand. -->
    <rect x="236" y="376" width="40" height="36" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <rect x="236" y="376" width="40" height="36" fill="{{ icon_paper }}"/>
    <rect x="176" y="412" width="160" height="20" rx="10" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <rect x="176" y="412" width="160" height="20" rx="10" fill="{{ icon_paper }}"/>
  </g>
</svg>
