_ = require 'prelude-ls'
request = require 'request'
read = require 'read'

URL = "https://api.bitbucket.org/2.0/repositories"
USER =  process.argv[2]

console.log "Extracting data for [#{USER}]"

#pagelen
#size
#values
#   scm, website ,has_wiki, name, links, fork_policy, uuid, created_on
#   full_name, has_issues, owner, updated_on, size, type, is_private, describe
#next
#page

repo_handler = (json, lst) ->
   json.values |> _.map (item) ->
      lst.push do
         repo_name: item.name
         repo_size: item.size
         repo_uuid: item.uuid.replace(/{|}/g,"")
         repo_slug:  item.full_name.split(/\//)[1]

get_commit_handler = (repo) ->
   commit_handler = (json, lst) ->
      json.values |> _.map (item) ->
         commit = do
            hash: item.hash
            author: item.author.raw
            user_name: item.author.user?username
            user_display_name: item.author.user?display_name
            user_uuid: item.author.user?uuid
            message: item.message.replace(/\n/g,"")
            date: item.date

         commit <<< repo
         lst.push commit


getData = (url, auth, handler) ->
   new Promise (resolve, reject) ->
      lst = []
      innerf = (url,auth)->
         console.log "Fetching #{url}"
         request url, 'auth':auth ,(error, response, body) ->
            if error?
               console.log error
               reject error
            else
               jsonBody = JSON.parse body

               handler(jsonBody, lst)

               if jsonBody.next?
                  innerf(jsonBody.next, auth, handler)
               else
                  resolve(lst)

      innerf url, auth

read { prompt: 'username: ' }, (er, username) ->
   read { prompt: 'password: ', silent: true }, (er, password) ->
      auth =
         'user': username
         'pass': password
      getData "#{URL}/#{USER}", auth, repo_handler
      .then (repos) ->
         ps = []
         repos |> _.each (item) ->
            commit_handler = get_commit_handler item
            ps.push getData "#{URL}/#{USER}/#{item.repo_slug}/commits", auth, commit_handler

         Promise.all ps
         .then (commits_list) ->
            commits = commits_list |> _.flatten
            #console.log commits
            console.log commits.length
