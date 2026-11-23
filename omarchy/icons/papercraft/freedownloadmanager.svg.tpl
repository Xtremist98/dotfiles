<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Free Download Manager</title>
  <desc>A download arrow dropping into a tray, with two speed lines, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The speed lines. -->
    <g fill="{{ icon_mark }}" opacity=".55">
      <rect x="104" y="150" width="72" height="16" rx="8"/>
      <rect x="84" y="190" width="52" height="16" rx="8"/>
    </g>
    <!-- The arrow; one hard shadow. -->
    <g transform="translate(0 10)" fill="{{ icon_shadow }}">
      <rect x="236" y="96" width="40" height="150" rx="8"/>
      <path d="M176 226L256 326L336 226Z" stroke="{{ icon_shadow }}" stroke-width="12" stroke-linejoin="round"/>
    </g>
    <rect x="236" y="96" width="40" height="150" rx="8" fill="url(#main)"/>
    <path d="M176 226L256 326L336 226Z" fill="url(#main)" stroke="url(#main)" stroke-width="12" stroke-linejoin="round"/>
    <!-- The tray; one hard shadow, as Hype's slides. -->
    <rect x="96" y="300" width="320" height="120" rx="22" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="96" y="300" width="320" height="120" rx="22" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <rect x="132" y="336" width="248" height="16" rx="8" fill="{{ icon_shadow }}"/>
    <rect x="132" y="368" width="180" height="14" rx="7" fill="{{ icon_edge }}"/>
  </g>
</svg>
