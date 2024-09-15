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
    details: Wrapper around roblox's AnalyticsService with a better api
    link: /log-analytics
  - title: Rbx Safe Conn
    details: Connects to events where you'd want to probably also iterate over an array and call the same callback on every array item
    link: /rbx-safe-conn
  - title: Safe Teleport
    details: TeleportAsync wrapper that makes teleporting simple
    link: /safe-teleport
  - title: Rbx Deeplink
    details: Small utility with basic functions for dealing with roblox deeplinks
    link: /rbx-deeplink
  - title: Player Zone
    details: Fast module for detecting players in rectangular zones
    link: /player-zone
  - title: Linked list
    details: Doubly-linked list implementation in luau
    link: /linked-list
  - title: Pages Util
    details: Utility for dealing with roblox page instances easily
    link: /pages-util
  - title: Text Chat
    details: Utility that makes it easier to work with TextChatService
    link: /text-chat
  - title: Character
    details: Utility for getting better types with player characters in roblox
    link: /character
  - title: Connector
    details: Utility for handling event callbacks
    link: /connector
  - title: Leventine
    details: Fast levenstein distance library for luau
    link: /leventine
  - title: Ratelimit
    details: Object for handling ratelimits intuitively
    link: /ratelimit
  - title: RbxThumb
    details: Utility for making roblox thumbnail urls
    link: /rbx-thumb
  - title: Is Empty
    details: Checks if a given table is empty
    link: /is-empty
  - title: Observer
    details: n/a
    link: /observer
  - title: Grouper
    details: Module for getting accurate group ranks for players on the server, and detecting rank changes
    link: /grouper
  - title: Retryer
    details: Utility for easily retrying functions
    link: /retryer
  - title: Random
    details: Pure luau version of roblox's Random object
    link: /random
  - title: Cross
    details: Utility for dealing with cross runtime shenanigans, covering the bear necessities
    link: /cross
  - title: Race
    details: Runs several functions at once, and returns the result of the function that completes first
    link: /race
  - title: Url
    details: Small utility with basic functions handling url queries and encoding/decoding urls
    link: /url
---
