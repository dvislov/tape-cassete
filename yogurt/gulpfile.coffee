fs = require 'fs'
streamqueue = require 'streamqueue'
gulp = require 'gulp'
yaml = require 'js-yaml'
connect = require('gulp-connect-multi')()
plugins = require('gulp-load-plugins')()

config = yaml.load(fs.readFileSync("config.yml", "utf8"))

gulp.task 'connect', connect.server(
  root: [config.webserver.root_path]
  port: config.webserver.port
  livereload: true
  open:
    browser: 'Google Chrome'
)


# Templates compilation

gulp.task 'jade', ->
  gulp.src config.paths.jade.src
    .pipe plugins.plumber()
    .pipe plugins.jade
      pretty: true
    .pipe plugins.duration('jade templates compile')
    .pipe gulp.dest config.paths.jade.develop_compile

    .pipe connect.reload()


# Styles compilation

gulp.task 'stylus', ->

  streamqueue objectMode: true,
    gulp.src config.paths.vendor.css.src
    gulp.src config.paths.stylus.src
      .pipe plugins.stylus()
      .pipe plugins.autoprefixer()

  .pipe plugins.duration('stylus compilation')
  .pipe plugins.plumber()

  .pipe plugins.concat('application.css')
  .pipe gulp.dest config.paths.stylus.develop_compile

  .pipe connect.reload()


# Compile images sprite
spritesmith = require 'gulp.spritesmith'
# TODO: make this require from gulp-load-plugins

gulp.task 'sprite', ->
  spriteData = gulp.src(config.paths.sprite.src).pipe(plugins.plumber())
    .pipe plugins.duration('sprite develop compilation')
    .pipe plugins.plumber()
    .pipe(spritesmith(
      imgName: 'sprite.png'
      cssName: 'sprite.styl'
      imgPath: '../images/sprite.png'
      cssFormat: 'stylus'
      padding: 10
      algorithm: 'binary-tree'
    ))

  spriteData.img
    .pipe plugins.plumber()
    .pipe plugins.duration('sprite images compilation')
    .pipe gulp.dest config.paths.sprite.develop_compile_images
  spriteData.css
    .pipe plugins.plumber()
    .pipe plugins.duration('sprite styles compilation')
    .pipe gulp.dest config.paths.sprite.develop_compile_styles
  return


# CoffeeScript

gulp.task 'coffee', ->
  gulp.src config.paths.coffee.src
  .pipe plugins.coffee()
  .pipe plugins.plumber()
  .pipe plugins.duration('coffeescript compilation')
  .pipe gulp.dest config.paths.coffee.dest
  .pipe connect.reload()


# Copy static assets
gulp.task 'fonts-assets', ->
  gulp.src config.paths.fonts.src
    .pipe plugins.syncFiles
      name: 'fonts'
      src: config.paths.fonts.src
      dest: config.paths.fonts.dest

    .pipe plugins.plumber()
    .pipe plugins.duration('Fonts assets sync')

    .pipe gulp.dest config.paths.fonts.dest

gulp.task 'images-assets', ->
  gulp.src config.paths.images.src
    .pipe plugins.syncFiles
      name: 'images'
      src: config.paths.images.src
      dest: config.paths.images.dest

    .pipe plugins.plumber()
    .pipe plugins.duration('Images assets sync')

    .pipe gulp.dest config.paths.images.dest

# Watchers

gulp.task 'watch', ->
  gulp.watch config.paths.jade.src, ['jade']
  gulp.watch config.paths.jade.src_shared, ['jade']

  gulp.watch config.paths.stylus.base, ['stylus']
  gulp.watch config.paths.sprite.src, ['sprite', 'stylus']
  gulp.watch config.paths.vendor.css.src, ['stylus']

  gulp.watch config.paths.coffee.watch, ['coffee']

  gulp.watch config.paths.fonts.src, ['fonts-assets']
  gulp.watch config.paths.images.src, ['images-assets']
  return


gulp.task 'default', [
  'connect'
  'watch'
]
