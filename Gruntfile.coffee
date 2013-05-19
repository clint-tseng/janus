module.exports = (grunt) ->

  # build config
  grunt.initConfig(
    clean:
      lib:
        src: 'lib/**'

    coffee:
      compile:
        expand: true
        cwd: 'src/'
        src: [ '**/*.coffee', '**/*.coffee.md' ]
        dest: 'lib/'
        ext: '.js'

    copy:
      js:
        expand: true
        cwd: 'src/'
        src: '**/*.js'
        dest: 'lib/'

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'spec'

      all:
        src: 'test/**/*.coffee'

    docco:
      build:
        cwd: 'src/'
        src: '**/*.coffee'
        dest: 'docs/'
  )

  # load plugins
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-docco')
  grunt.loadNpmTasks('grunt-simple-mocha')

  # tasks
  grunt.registerTask('default', [ 'clean:lib', 'coffee:compile', 'copy:js' ])
  grunt.registerTask('test', [ 'default', 'simplemocha:all' ])
  grunt.registerTask('docs', [ 'docco:build' ])

