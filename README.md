## Application flow

1. Webhooks are caught from a marketing service
2. The inner billing email address is saved to a postgres table.
3. Users get their confirmation email which has a discord OAuth2 authorize URL.
4. The authorization callback is caught by the web app, and the OAuth2 flow is completed
5. The returned Bearer token is resolved via `GET /users/@me` and a query to check if we already have their email on file
6. If we do, perform `PUT /guilds/{gid}/members/{uid}` to add them to the guild.

## Contributors

- [z64](https://github.com/z64) Zac Nowicki - creator, maintainer
