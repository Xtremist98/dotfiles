<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Ark</title>
  <desc>An archive box with a zipper down its front and a pull in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The box; one hard shadow, as Hype's slides. -->
    <rect x="96" y="120" width="320" height="280" rx="20" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="96" y="120" width="320" height="280" rx="20" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The lid. -->
    <rect x="84" y="84" width="344" height="72" rx="18" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="84" y="84" width="344" height="72" rx="18" fill="{{ icon_paper }}"/>
    <rect x="84" y="84" width="344" height="72" rx="18" fill="none" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The zipper strip. -->
    <rect x="240" y="120" width="32" height="280" fill="{{ icon_shadow }}"/>
    <g fill="{{ icon_mark }}">
      <rect x="220" y="136" width="24" height="10" rx="5"/>
      <rect x="268" y="154" width="24" height="10" rx="5"/>
      <rect x="220" y="172" width="24" height="10" rx="5"/>
      <rect x="268" y="190" width="24" height="10" rx="5"/>
      <rect x="220" y="208" width="24" height="10" rx="5"/>
      <rect x="268" y="226" width="24" height="10" rx="5"/>
      <rect x="220" y="244" width="24" height="10" rx="5"/>
      <rect x="268" y="262" width="24" height="10" rx="5"/>
      <rect x="220" y="280" width="24" height="10" rx="5"/>
      <rect x="268" y="298" width="24" height="10" rx="5"/>
      <rect x="220" y="316" width="24" height="10" rx="5"/>
    </g>
    <!-- The pull. -->
    <rect x="232" y="340" width="48" height="24" rx="8" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <rect x="232" y="340" width="48" height="24" rx="8" fill="url(#main)"/>
    <circle cx="256" cy="382" r="14" fill="none" stroke="{{ icon_shadow }}" stroke-width="8" transform="translate(0 6)"/>
    <circle cx="256" cy="382" r="14" fill="none" stroke="{{ icon_mark }}" stroke-width="8"/>
  </g>
</svg>
