---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: Luauberries
  text: A collection of libraries for luau and other runtimes
  actions:
    - theme: brand
      text: Get started
      link: /installing
    - theme: alt
      text: API
      link: /safe-teleport

features:
  - title: Log Analytics
    details: n/a
    link: /log-analytics.md
  - title: Safe Teleport
    details: TeleportService:TeleportAsync wrapper that makes teleporting simple
    link: /safe-teleport.md
  - title: Rbx Safe Conn
    details: Connects to events where you'd want to probably also iterate over an array and call the same callback on every array item
    link: /rbx-safe-conn.md
  - title: Rbx Deeplink
    details: Small utility with basic functions for dealing with roblox deeplinks
    link: /rbx-deeplink.md
  - title: Linked List
    details: A doubly-linked list implementation in luau
    link: /linked-list.md
  - title: Player Zone
    details: Fast module for detecting players in rectangular zones
    link: /player-zone.md
  - title: Pages Util
    details: Utility for dealing with roblox pages instances easily
    link: /pages-util.md
  - title: Ratelimit
    details: Object for handling ratelimits intuitively
    link: /ratelimit.md
  - title: Rbx Thumb
    details: n/a
    link: /rbx-thumb.md
  - title: Text Chat
    details: Utility that makes it easier to work with TextChatService
    link: /text-chat.md
  - title: Character
    details: Utility for getting better types with player characters in roblox
    link: /character.md
  - title: Connector
    details: Utility for handling event callbacks
    link: /connector.md
  - title: Leventine
    details: A fast levenstein distance library for luau, based on fastest-levenstein and fzy-lua
    link: /leventine.md
  - title: Observer
    details: Simple observer library for roblox
    link: /observer.md
  - title: Is Empty
    details: Checks if a given table is empty
    link: /is-empty.md
  - title: Grouper
    details: Module for getting accurate group ranks for players on the server, and detecting rank changes
    link: /grouper.md
  - title: Retryer
    details: Utility for easily retrying functions
    link: /retryer.md
  - title: Random
    details: Pure luau version of robloxs random class
    link: /random.md
  - title: Cross
    details: Utility for dealing with cross runtime shenanigans, covering the bear necessities
    link: /cross.md
  - title: Race
    details: Runs several functions at once, and returns the result of the function that completes first
    link: /race.md
  - title: Url
    details: Small utility with basic functions handling url queries and encoding/decoding urls
    link: /url.md
---