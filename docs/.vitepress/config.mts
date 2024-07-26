import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
	title: "rbxlibs",
	description: "A collection of libraries & utilitys for luau and roblox",
	appearance: "force-auto",
	lastUpdated: true,
	cleanUrls: true,
	lang: 'en-US',

	markdown: {
	theme: {
		light: "catppuccin-latte",
		dark: "catppuccin-frappe"
	}
	},
	themeConfig: {
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
			text: 'Libraries',
			items: [
				{ text: 'Character', link: '/character' },
				{ text: 'Grouper', link: '/grouper' },
				{ text: 'Is Empty', link: '/is-empty' },
				{ text: 'Leventine', link: '/leventine' },
				{ text: 'Linked List', link: '/linked-list' },
				{ text: 'Log Analytics', link: '/log-analytics' },
				{ text: 'Observer', link: '/observer' },
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
