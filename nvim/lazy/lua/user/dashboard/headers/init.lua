local render_cats = require("user.dashboard.renderers.cats")

return {
  { text = require("user.dashboard.headers.duo-cats"), render = render_cats },
  { text = require("user.dashboard.headers.magic-cat"), render = render_cats },
}
