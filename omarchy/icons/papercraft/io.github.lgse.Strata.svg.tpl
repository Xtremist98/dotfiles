<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Strata</title>
  <desc>Three strata stacked in an isometric view, the top in the main color, the middle in the highlight, and the bottom in the body, each with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The bottom stratum. -->
    <path d="M92 300L256 220L420 300L256 380Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M92 300L256 220L420 300L256 380Z" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <path d="M92 300V340L256 420L256 380Z" fill="{{ icon_shadow }}" opacity=".8"/>
    <path d="M420 300V340L256 420L256 380Z" fill="{{ icon_shadow }}" opacity=".55"/>
    <!-- The middle stratum. -->
    <path d="M92 220L256 140L420 220L256 300Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M92 220L256 140L420 220L256 300Z" fill="{{ icon_mark }}"/>
    <path d="M92 220V260L256 340L256 300Z" fill="{{ icon_shadow }}" opacity=".65"/>
    <path d="M420 220V260L256 340L256 300Z" fill="{{ icon_shadow }}" opacity=".45"/>
    <!-- The top stratum. -->
    <path d="M92 140L256 60L420 140L256 220Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M92 140L256 60L420 140L256 220Z" fill="url(#main)"/>
    <path d="M92 140V180L256 260L256 220Z" fill="{{ icon_shadow }}" opacity=".55"/>
    <path d="M420 140V180L256 260L256 220Z" fill="{{ icon_shadow }}" opacity=".35"/>
    <path d="M92 140L256 60L420 140L256 220Z" fill="none" stroke="{{ icon_paper }}" stroke-width="4" opacity=".3"/>
  </g>
</svg>
