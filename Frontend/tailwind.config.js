export default {
  darkMode: ['class'],
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        background: 'hsl(222.2 84% 4.9%)',
        foreground: 'hsl(210 40% 98%)',

        card: 'hsl(222.2 84% 4.9%)',
        'card-foreground': 'hsl(210 40% 98%)',

        popover: 'hsl(222.2 84% 4.9%)',
        'popover-foreground': 'hsl(210 40% 98%)',

        primary: 'hsl(262.1 83.3% 57.8%)',
        'primary-foreground': 'hsl(210 40% 98%)',

        secondary: 'hsl(217.2 32.6% 17.5%)',
        'secondary-foreground': 'hsl(210 40% 98%)',

        muted: 'hsl(217.2 32.6% 17.5%)',
        'muted-foreground': 'hsl(215 20.2% 65.1%)',

        accent: 'hsl(217.2 32.6% 17.5%)',
        'accent-foreground': 'hsl(210 40% 98%)',

        border: 'hsl(217.2 32.6% 17.5%)',
        input: 'hsl(217.2 32.6% 17.5%)',
        ring: 'hsl(262.1 83.3% 57.8%)',
      },
      borderRadius: {
        lg: '0.75rem',
        md: '0.5rem',
        sm: '0.375rem',
      },
    },
  },
  plugins: [],
}