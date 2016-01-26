_ = require 'prelude-ls'
request = require 'request'
read = require 'read'
fs = require 'fs'

URL = "https://api.bitbucket.org/2.0/repositories"
USER =  process.argv[2]
console.log "Extracting data for [#{USER}]"
USER_URL = "#{URL}/#{USER}"


#pagelen
#size
#values
#   scm, website ,has_wiki, name, links, fork_policy, uuid, created_on
#   full_name, has_issues, owner, updated_on, size, type, is_private, describe
#next
#page

get_repo_handler =  ->
   type: "repo"
   handle: (json) ->
      lst = []
      json.values |> _.map (item) ->
         lst.push do
            repo_name: item.name
            repo_size: item.size
            repo_uuid: item.uuid.replace(/{|}/g,"")
            repo_slug:  item.full_name.split(/\//)[1]
      lst

get_commit_handler = (cache) ->
   type: "commit"
   handle: (json) ->
      lst = []
      json.values |> _.map (item) ->
         commit = do
            hash: item.hash
            author: item.author.raw
            user_name: item.author.user?username
            user_display_name: item.author.user?display_name
            user_uuid: item.author.user?uuid
            message: item.message.replace(/\n/g,"")
            date: item.date
            repo_name: item.repository.name
            repo_size: item.repository.size
            repo_uuid: item.repository.uuid.replace(/{|}/g,"")
            repo_slug:  item.repository.full_name.split(/\//)[1]

         lst.push commit
      lst

callCount = 0
getData = (url, auth, cache, handler) ->
   new Promise (resolve, reject) ->
      callCount :=  callCount + 1
      console.log "[#{callCount}] [#{handler.type}] Fetching #{url} "
      request url, 'auth':auth ,(error, response, body) ->
         if error?
            console.log error
            reject error
         else
            jsonBody = JSON.parse body

            if jsonBody.error?
               console.log jsonBody.error
               reject jsonBody.error
            else
               url |> removeFromCache cache

               if jsonBody.next?
                  jsonBody.next |> addToCache cache, handler.type

               resolve handler.handle(jsonBody)

readCache = ->
   new Promise (resolve, reject) ->
      fs.readFile "./.cache", (err,data) ->
         if err? && err.code != 'ENOENT'
            reject err
         else if err? && err.code == 'ENOENT'
            console.log "Empty cache"
            resolve []
         else
            data = JSON.parse(data)
            console.log "Using [#{data.length}] item"
            resolve data

saveCache = (cache) ->
   new Promise (resolve, reject) ->
      if cache.length > 0
         console.log "Saving cache [#{cache.length}]"
         fs.writeFile "./.cache", JSON.stringify(cache) , (err) ->
            if err?
               reject err
            else
               resolve!
      else
         fs.exists "./.cache", (exists) ->
            if exists
               console.log "Deleting cache"
               fs.unlink "./.cache", (err) ->
                  if err?
                     reject err
                  else
                     resolve!

processCache = (auth, cache) ->
   new Promise (resolve, reject) ->
      process = ->
         if cache.length == 0
            resolve!
         else
            item = cache[0]
            switch item.type
            | 'repo' =>
               getData item.url, auth, cache, get_repo_handler!
               .then (repos) ->
                  repos |> _.each (item) ->
                     "#{USER_URL}/#{item.repo_slug}/commits" |> addToCache cache, "commit"

                  lines = repos |> _.map (repo) ->
                     (repo |> _.values).join()
                  str = lines.join("\n")
                  fs.appendFile "./repos.csv", str, (err) ->
                     if err?
                        console.log err
                     else
                        process!

            | 'commit' =>
               getData item.url, auth, cache, get_commit_handler!
               .then (commits)->

                  lines = commits |> _.map (commit) ->
                     (commit |> _.values).join()
                  str = lines.join("\n")
                  fs.appendFile "./commits.csv", str, (err) ->
                     if err?
                        console.log err
                     else
                        process!

            | otherwise =>
                  console.log "Cache type error"
                  process!

      process!

removeFromCache = (cache, url) -->
   index = cache |> _.find-index (item) ->
      item.url == url

   if index != -1
      cache.splice index, 1

addToCache = (cache, type, url) -->
   cache.push { url:url, type:type }

readCache!
.then (cache) ->
   read { prompt: 'username: ' }, (er, username) ->
      read { prompt: 'password: ', silent: true }, (er, password) ->
         auth = { 'user': username, 'pass': password}

         # If the cache is empty then prime it with the initial url
         #
         if cache.length == 0
            USER_URL |> addToCache cache, "repo"


         processCache auth, cache
         .then (count) ->
            console.log 'The end...'
            saveCache cache
         .catch (error) ->
            console.log 'Some error ...'
            saveCache cache
