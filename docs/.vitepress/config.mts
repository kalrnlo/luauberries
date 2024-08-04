import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
	title: "rbxlibs",
	description: "A collection of libraries for luau and roblox",
	lastUpdated: true,
	cleanUrls: true,
	lang: 'en-US',

	head: [
		['link', { rel: 'icon', href: '/rbxlibs_logo.svg' }]
	],

	markdown: {
		theme: {
			light: "catppuccin-latte",
			dark: "catppuccin-frappe"
		}
	},
	themeConfig: {
		logo: "/rbxlibs_logo_small.svg",
		editLink: {
			pattern: 'https://github.com/kalrnlo/rbxlibs/edit/main/docs/:path'
		},
		search: {
			provider: 'local'
		},

		// https://vitepress.dev/reference/default-theme-config
		socialLinks: [
			{ icon: 'github', link: 'https://github.com/kalrnlo/rbxlibs' },
			{ icon: 'discord', link: 'https://discord.gg/mchCdAFPWU' },
		],
		nav: [
			{ text: 'Donate', link: 'https://buymeacoffee.com/kalrnlo' },
		],

		sidebar: [
			{
				text: "Getting Started",
				items: [
					{ text: "Installing", link: "/installing" }
				]
			},
			{
				text: 'Libraries',
				items: [
					{ text: 'Character', link: '/character' },
					{ text: 'Grouper', link: '/grouper' },
					{ text: 'Is Empty', link: '/is-empty' },
					{ text: 'Leventine', link: '/leventine' },
					{ text: 'Linked List', link: '/linked-list' },
					{ text: 'Log Analytics', link: '/log-analytics' },
					{ text: 'Observer', link: '/observer' },
					{ text: 'Pages Util', link: '/pages-util' },
					{ text: 'Player Zone', link: '/player-zone' },
					{ text: 'Race', link: '/race' },
					{ text: 'Random', link: '/random' },
					{ text: 'Ratelimit', link: '/ratelimit' },
					{ text: 'RbxThumb', link: '/rbx-thumb' },
					{ text: 'Retryer', link: '/retryer' },
					{ text: 'Safe Teleport', link: '/safe-teleport' },
					{ text: 'Text Chat', link: '/text-chat' },
					{ text: 'Url', link: '/url' },
				]
			}
		],
	}
})
