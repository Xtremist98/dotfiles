<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Dolphin</title>
  <desc>A file manager window seen from the front: a dark window with a title bar, a breadcrumb, and a grid of folders, the selected folder in the main color, the rest dark with a pale sheet, and the window with a hard shadow.</desc>
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
    <rect x="76" y="144" width="360" height="3" fill="{{ icon_edge }}"/>
    <circle cx="104" cy="118" r="7" fill="{{ icon_red }}"/>
    <circle cx="124" cy="118" r="7" fill="{{ icon_orange }}"/>
    <circle cx="144" cy="118" r="7" fill="{{ icon_paper }}"/>
    <!-- The breadcrumb. -->
    <path d="M112 162L100 170L112 178" fill="none" stroke="url(#main)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="128" y="162" width="72" height="16" rx="8" fill="{{ icon_edge }}"/>
    <rect x="208" y="162" width="48" height="16" rx="8" fill="{{ icon_edge }}" opacity=".55"/>
    <rect x="264" y="162" width="40" height="16" rx="8" fill="url(#main)"/>
    <!-- The selected folder. -->
    <rect x="100" y="196" width="56" height="24" rx="7" fill="url(#main)"/>
    <rect x="100" y="212" width="140" height="80" rx="12" fill="url(#main)"/>
    <rect x="116" y="228" width="108" height="48" rx="7" fill="{{ icon_paper }}"/>
    <rect x="132" y="242" width="64" height="10" rx="5" fill="{{ icon_ink }}"/>
    <rect x="132" y="260" width="44" height="8" rx="4" fill="{{ icon_ink }}" opacity=".55"/>
    <!-- The other folders. -->
    <g fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3">
      <rect x="272" y="196" width="56" height="24" rx="7"/>
      <rect x="272" y="212" width="140" height="80" rx="12"/>
      <rect x="100" y="312" width="56" height="24" rx="7"/>
      <rect x="100" y="328" width="140" height="80" rx="12"/>
      <rect x="272" y="312" width="56" height="24" rx="7"/>
      <rect x="272" y="328" width="140" height="80" rx="12"/>
    </g>
    <g fill="{{ icon_edge }}">
      <rect x="288" y="232" width="80" height="8" rx="4"/>
      <rect x="288" y="250" width="56" height="8" rx="4"/>
      <rect x="288" y="268" width="68" height="8" rx="4"/>
      <rect x="116" y="348" width="80" height="8" rx="4"/>
      <rect x="116" y="366" width="56" height="8" rx="4"/>
      <rect x="116" y="384" width="68" height="8" rx="4"/>
    </g>
    <rect x="288" y="340" width="108" height="48" rx="7" fill="{{ icon_paper }}"/>
    <rect x="304" y="354" width="64" height="10" rx="5" fill="{{ icon_ink }}"/>
    <rect x="304" y="372" width="44" height="8" rx="4" fill="{{ icon_ink }}" opacity=".55"/>
  </g>
</svg>
