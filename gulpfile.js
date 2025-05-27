import { src, dest, watch, series} from 'gulp'

import * as dartSass from 'sass'
import gulpSass from 'gulp-sass'

const sass = gulpSass(dartSass)

export function css( done ){
    src('src/scss/app.scss')
    .pipe( sass().on('error', sass.logError) )
    .pipe( dest('build/css'))

    done()
}

export function js(done){
    src('src/js/app.js')
        .pipe(dest('build/js'));

        done();
}

export function dev(){
    watch('src/scss/**/*.scss', css)
    watch('src/js/**/*.js', js)
}
// ✅ Esta es la tarea que Netlify necesita
export const build = series(css, js)