module.exports = (grunt) ->

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-compress'
    grunt.loadNpmTasks 'grunt-contrib-uglify'
    grunt.loadNpmTasks 'grunt-contrib-clean'

    grunt.initConfig
        coffee:
            compile:
                options:
                    bare: true
                files:
                    'js/options.js':    ['src/options-object.coffee', 'src/options-interface.coffee', 'src/options.coffee']
                    'js/background.js': 'src/background.coffee'

        watch:
            files: 'src/**/*.coffee'
            tasks: ['coffee', 'uglify']

        compress:
            main:
                options:
                    archive: 'feedly-pooqer.zip'
                src: [
                    'options.html'
                    'manifest.json'
                    'img/**/*'
                    'js/**/*.min.js'
                    '_locales/**/*'
                ]

        uglify:
            feedly_pooqer:
                files:
                    'js/options.min.js':    ['js/options.js']
                    'js/background.min.js': ['js/background.js']

        clean: ['js/**/*', '*.zip']

    grunt.registerTask 'default', ['coffee', 'uglify', 'watch']
    grunt.registerTask 'bundle',  ['clean', 'coffee', 'uglify', 'compress']
