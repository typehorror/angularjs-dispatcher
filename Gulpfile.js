var gulp = require("gulp");
var gutil = require("gulp-util");
var concat = require("gulp-concat");
var coffee = require("gulp-coffee");
var uglify = require("gulp-uglify");
var rename = require("gulp-rename");

gulp.task("compile-coffee", function() {
  gulp.src(["src/dispatcher.coffee", "src/**/*.coffee"])
    .pipe(
      coffee({bare:true})               // Compile coffeescript
        .on("error", gutil.log)
    )
    .pipe(concat("dispatcher.js"))      // Combine into 1 file
    .pipe(gulp.dest("dist"))            // Write non-minified to disk
    .pipe(uglify())                     // Minify
    .pipe(rename({extname: ".min.js"})) // Rename to dispatcher.min.js
    .pipe(gulp.dest("dist"))            // Write minified to disk
});

gulp.task("default", function() {
  gulp.start("compile-coffee");
});
