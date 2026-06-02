'use strict'
const path = require('path')

module.exports = {
  pagesDir: null,
  widgetsDir: path.join(__dirname, 'widgets'),
  serverDir: path.join(__dirname, 'server'),
  pagesMountPath: 'arc-cookie-bar',
  version: require('../package.json').version,
}
