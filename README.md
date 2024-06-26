# immich-duplicates

Find image and video duplicates in Immich.

1. Install [findimagedupes](https://gitlab.com/opennota/findimagedupes).
   Alternatively, you may use docker as outlined in the next step.

1. Run `findimagedupes` against your Immich thumbnails directory scanning the
   large previews. These can be either WebP or JPEG files, depending on your
   Immich settings.

   ```sh
   $ "$HOME/go/bin/findimagedupes" --prune \
                                   --fingerprints dupes.db \
                                   --prune \
                                   --no-compare \
                                   --recurse \
                                   --exclude '-[0-9A-Fa-f]{12}\.webp$' \
                                   --exclude '-thumbnail\.(webp|jpeg)$' \
                                   /path/to/immich/thumbs/<your user ID>
   ```

   Or, if you don't want to compile `findimagedupes` yourself:

   ```sh
   $ docker container run \
                      --rm \
                      --volume /path/to/immich/thumbs/:/thumbs/ \
                      --volume "$PWD:/output/" \
                      ghcr.io/agross/immich-duplicates-findimagedupes \
                      --prune \
                      --fingerprints /output/dupes.db \
                      --recurse \
                      --no-compare \
                      --exclude '-[0-9A-Fa-f]{12}\.webp$' \
                      --exclude '-thumbnail\.(webp|jpeg)$' \
                      /thumbs/<your user ID>
   ```

   In case you're wondering what the `--exclude` parameters mean:

   * `-[0-9A-Fa-f]{12}\.webp$` excludes thumbnails created by Immich < 1.102
     that were always in WebP format
   * `-thumbnail\.(webp|jpeg)$` excludes thumbnails created by Immich >=
     [1.102](https://github.com/immich-app/immich/releases/tag/v1.102.0) that
     can be either JPEG or WebP and always have the `-thumbnail` suffix

1. The resulting `dupes.db` is a SQLite database. Group the duplicates as a
   JSON document using the provided Ruby script.

   <a id="hamming"></a>You can control the required similarity of the perceptive hashes
   by specifying an optional parameter setting the
   [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance), i.e. the
   number of bits that may differ for two hashes to be considered equal. The
   default value is `0` (hashes must be equal).

   ```sh
   # Optional last argument: allow up to 5 bits to differ.
   $ docker container run \
                      --rm \
                      --volume /path/containing/dupes.db/:/app/data/ \
                      ghcr.io/agross/immich-duplicates-grouper \
                      5
   Hamming distance = 5
   42 duplicate groups
   ```

   In `/path/containing/dupes.db/` you will now find a `dupes.json` file.
   Its contents will later be required to be pasted into the duplicate browser.

1. Generate an API key for your account on the Immich web UI and save it.

1. Configure the Immich server to accept API calls from foreign domains (CORS).

   **If don’t know how to do it, continue with the next step.**

   Depending in your web server the setup will differ a bit.

   * For **nginx**, add the following lines to the `location` serving `/api`.

     ```conf
     if ($request_method = 'OPTIONS') {
       add_header 'Access-Control-Allow-Origin' '*';
       add_header 'Access-Control-Allow-Methods' 'GET, PUT, POST, DELETE, OPTIONS';
       add_header 'Access-Control-Allow-Headers' 'X-Api-Key, User-Agent, Content-Type';
       add_header 'Access-Control-Max-Age' 1728000; # 20 days
       add_header 'Content-Type' 'text/plain; charset=utf-8';
       add_header 'Content-Length' 0;
       return 204;
     }

     # This needs to be set in the location block.
     add_header 'Access-Control-Allow-Origin' '*' always;
     ```

   * For **Traefik**, add the CORS middleware to the router serving Immich.

     ```conf
     traefik.http.routers.immich.middlewares=immich-cors

     traefik.http.middlewares.immich-cors.headers.accessControlAllowOriginList=*
     traefik.http.middlewares.immich-cors.headers.accessControlAllowMethods=GET, PUT, POST, DELETE, OPTIONS
     traefik.http.middlewares.immich-cors.headers.accessControlAllowHeaders=X-Api-Key, User-Agent, Content-Type
     traefik.http.middlewares.immich-cors.headers.accessControlMaxAge=1728000
     ```

1. Run the docker image for the duplicate browser.

   ```sh
   $ docker container run --rm --publish 8080:80 ghcr.io/agross/immich-duplicates-browser
   ```

   <a name="proxy"></a>
   **If you did not enable CORS in the previous step, you need add an additional
   argument to the command above. The API endpoint URL you enter on the setup
   screen needs to change to `http://localhost:8080/api`.**

   The additional argument `--env IMMICH_URL=https://immich.example.com` must be
   set to the base address of your Immich installation. For example:

   ```sh
   $ docker container run \
                      --env IMMICH_URL=https://immich.example.com \
                      --rm \
                      --publish 8080:80 \
                      ghcr.io/agross/immich-duplicates-browser
   ```

1. Navigate to [http://localhost:8080](http://localhost:8080).
1. On the setup screen, paste your Immich data.

   * API endpoint URL, e.g. `https://immich.example.com/api`
     (or `http://localhost:8080/api`, see [above](#proxy))
   * Immich base URL, e.g. `https://immich.example.com`, only required if the
     [proxy](#proxy) is used
   * API key generated above
   * The contents of the `dupes.json` file generated above

1. If everything works you should see something like this:

   ![Sample screenshot](img/sample.png)

1. All data (API key, endpoint URL, base URL, duplicate groups) is stored locally in your
   browser.

   * If you follow the instructions above, duplicates will be determined by
     their downsized (but still large) JPEG thumbnail. Videos will also be
     considered, but only by their thumbnail image (= 1 frame of the video).
   * For each thumbnail a perceptive hash will be computed. Images with the same
     perceptive hash would be considered the same by the human eye.
   * The perceptive hashes are compared using strict equality by default. You
     may allow deviation from strict equality by e.g. by allowing the Hamming
     distance of two hash values to be `> 0`. Use the optional argument of the
     [grouper](#hamming).
   * The best duplicate (with the green border, displayed first) is determined
     by file size only. I accept pull requests!
   * If you click "Keep best asset" for the currently displayed group:
     * The best asset will be added to all albums of the group's other
       ("non-best") assets
     * The best asset will become a favorite if any asset in the group is a
       favorite
     * All "non-best" assets will be deleted (i.e. moved to Immich's Trash if
       you have that feature enabled)
     * The group's information will be purged from your browser
   * If you ignore a duplicate group the group's information will be purged from
     your browser

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur) + [TypeScript Vue Plugin (Volar)](https://marketplace.visualstudio.com/items?itemName=Vue.vscode-typescript-vue-plugin).

## Type Support for `.vue` Imports in TS

TypeScript cannot handle type information for `.vue` imports by default, so we replace the `tsc` CLI with `vue-tsc` for type checking. In editors, we need [TypeScript Vue Plugin (Volar)](https://marketplace.visualstudio.com/items?itemName=Vue.vscode-typescript-vue-plugin) to make the TypeScript language service aware of `.vue` types.

If the standalone TypeScript plugin doesn't feel fast enough to you, Volar has also implemented a [Take Over Mode](https://github.com/johnsoncodehk/volar/discussions/471#discussioncomment-1361669) that is more performant. You can enable it by the following steps:

1. Disable the built-in TypeScript Extension
    1) Run `Extensions: Show Built-in Extensions` from VSCode's command palette
    2) Find `TypeScript and JavaScript Language Features`, right click and select `Disable (Workspace)`
2. Reload the VSCode window by running `Developer: Reload Window` from the command palette.

## Customize configuration

See [Vite Configuration Reference](https://vitejs.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Type-Check, Compile and Minify for Production

```sh
npm run build
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```
