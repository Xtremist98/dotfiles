<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Vesktop</title>
  <desc>A game controller seen from the front on a dark card, the controller in the highlight with dark eyes and a smile, each piece with a hard shadow.</desc>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The card; one hard shadow, as Hype's slides. -->
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_shadow }}" transform="translate(0 10)"/>
    <rect x="88" y="88" width="336" height="336" rx="56" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The controller; one hard shadow. -->
    <path d="M136 240Q136 192 184 192H328Q376 192 376 240L392 320Q398 360 360 360Q336 360 320 336L296 304H216L192 336Q176 360 152 360Q114 360 120 320Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M136 240Q136 192 184 192H328Q376 192 376 240L392 320Q398 360 360 360Q336 360 320 336L296 304H216L192 336Q176 360 152 360Q114 360 120 320Z" fill="{{ icon_mark }}"/>
    <!-- The eyes and smile. -->
    <circle cx="208" cy="250" r="14" fill="{{ icon_body }}"/>
    <circle cx="304" cy="250" r="14" fill="{{ icon_body }}"/>
    <path d="M232 292Q256 308 280 292" fill="none" stroke="{{ icon_body }}" stroke-width="8" stroke-linecap="round"/>
  </g>
</svg>
