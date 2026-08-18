const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1f010c", /* black   */
  [1] = "#b1a4b6", /* red     */
  [2] = "#e19499", /* green   */
  [3] = "#a7a8c3", /* yellow  */
  [4] = "#bea7b6", /* blue    */
  [5] = "#b1abba", /* magenta */
  [6] = "#d6c4c9", /* cyan    */
  [7] = "#dbc4bb", /* white   */

  /* 8 bright colors */
  [8]  = "#cda7b0",  /* black   */
  [9]  = "#bbafc0",  /* red     */
  [10] = "#e6a2a7", /* green   */
  [11] = "#b2b3cb", /* yellow  */
  [12] = "#c6b2c0", /* blue    */
  [13] = "#bbb6c3", /* magenta */
  [14] = "#dccbd0", /* cyan    */
  [15] = "#e0cbc4", /* white   */

  /* special colors */
  [256] = "#1f010c", /* background */
  [257] = "#f9d3dc", /* foreground */
  [258] = "#ffdde5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
