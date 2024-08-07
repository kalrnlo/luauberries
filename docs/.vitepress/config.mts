import { defineConfig } from 'vitepress'

    /**
import fs from 'fs'

export type SidebarItem = {
    text?: string
    link?: string
    items?: SidebarItem[]
    collapsed?: boolean
    base?: string
    docFooterText?: string
    rel?: string
    target?: string
  }

const sidebar = new Array

const sidebar_library_section = {
	items: [] as unknown as [SidebarItem],
	text: 'Libraries',
}
const sidebar_libs = sidebar_library_section.items

const dir = fs.readdirSync("./docs", {
	withFileTypes: true,
	recursive: false,
	encoding: "utf8"
})

for (let index = 0; index < dir.length; index++) {
	const element = dir[index];
	
	if (element.name.endsWith(".md") && !(element.name === "index.md")) {
		sidebar_libs.push({

		})
	} else if (element.isDirectory() && !(element.name === ".vitepress" || element.name === "public")) {

	}
}
*/

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
		lastUpdated: {
			text: 'Last edit',
			formatOptions: {
			  dateStyle: 'short',
			  timeStyle: 'short',
			  forceLocale: true,
			}
		  },

		logo: "/rbxlibs_logo_small.svg",
		editLink: {
			pattern: 'https://github.com/kalrnlo/rbxlibs/edit/main/docs/:path'
		},
		search: {
			provider: 'local',
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
					{ text: 'Cross', link: '/cross' },
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
