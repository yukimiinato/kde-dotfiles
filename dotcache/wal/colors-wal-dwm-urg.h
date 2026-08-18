static const char norm_fg[] = "#e0cbc4";
static const char norm_bg[] = "#1f010c";
static const char norm_border[] = "#cda7b0";

static const char sel_fg[] = "#e0cbc4";
static const char sel_bg[] = "#e19499";
static const char sel_border[] = "#e0cbc4";

static const char urg_fg[] = "#e0cbc4";
static const char urg_bg[] = "#b1a4b6";
static const char urg_border[] = "#b1a4b6";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
