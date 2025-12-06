// @ts-check
import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
	site: 'https://byte-converter.netlify.app',
	integrations: [
		starlight({
			title: 'Byte Converter',
			logo: {
				src: './public/logo.svg',
			},
			customCss: [
				'./src/styles/custom.css',
			],
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/ArunPrakashG/byte_converter' }],
			sidebar: [
				{
					label: 'Guides',
					items: [
						{ label: 'Getting Started', slug: 'guides/getting-started' },
						{ label: 'Usage', slug: 'guides/usage' },
						{ label: 'Formatting', slug: 'guides/formatting' },
						{ label: 'Parsing', slug: 'guides/parsing' },
						{ label: 'Data Rate', slug: 'guides/data-rate' },
						{ label: 'BigInt', slug: 'guides/bigint' },
						{ label: 'Extensions', slug: 'guides/extensions' },
						{ label: 'Utilities', slug: 'guides/utilities' },
						{ label: 'Recipes', slug: 'guides/recipes' },
						{ label: 'Edge Cases', slug: 'guides/edge-cases' },
						{ label: 'Benchmarks', slug: 'guides/benchmarks' },
						{ label: 'Troubleshooting', slug: 'guides/troubleshooting' },
						{ label: 'FAQ', slug: 'guides/faq' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'API Reference', slug: 'reference/api' },
						{ label: 'Changelog', slug: 'reference/changelog' },
					],
				},
			],
		}),
	],
});
