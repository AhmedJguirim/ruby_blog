module.exports = {
    content: [
      './app/helpers/**/*.rb',
      './app/javascript/**/*.js',
      './app/views/**/*',
    ],
    theme: {
      extend: {
        colors: {
          'primary': '#FFA726',
          'secondary': '#1A365D',
          'txtblk': '#1C1D21',
          'txtwht': '#D3F8E2',
          'danger': '#92140C',
        },
        fontFamily: {
          'heading': ['Georgia', 'Times New Roman', 'serif'],
          'body': ['Inter var', 'Helvetica', 'sans-serif'],
          'code': ['Courier New', 'Courier', 'monospace'],
          'accent': ['Trebuchet MS', 'sans-serif'],
        },
      },
    },
    plugins: [
      require('flowbite/plugin')
    ],
  }