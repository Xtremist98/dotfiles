<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Konsole</title>
  <desc>A terminal window with a title bar, a prompt in the main color and a cursor in the highlight, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The window; one hard shadow, as Hype's slides. -->
    <rect x="76" y="92" width="360" height="328" rx="22" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="76" y="92" width="360" height="328" rx="22" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The title bar. -->
    <path d="M76 114Q76 92 98 92H414Q436 92 436 114V144H76Z" fill="{{ icon_mark }}"/>
    <circle cx="108" cy="118" r="8" fill="{{ icon_red }}"/>
    <circle cx="132" cy="118" r="8" fill="{{ icon_orange }}"/>
    <circle cx="156" cy="118" r="8" fill="{{ icon_paper }}"/>
    <!-- The prompt. -->
    <path d="M140 208L220 264L140 320" fill="none" stroke="{{ icon_shadow }}" stroke-width="36" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 8)"/>
    <path d="M140 208L220 264L140 320" fill="none" stroke="url(#main)" stroke-width="36" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- The cursor. -->
    <rect x="280" y="218" width="36" height="100" rx="18" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="280" y="218" width="36" height="100" rx="18" fill="{{ icon_mark }}"/>
    <rect x="294" y="242" width="8" height="52" rx="4" fill="{{ icon_shadow }}" opacity=".35"/>
  </g>
</svg>
