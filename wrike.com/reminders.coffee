->
    start = (utilities) ->
        googleConnect()

    googleConnect = ->
        cfg = {
            id: '181733347279'
            apiKey: 'AIzaSyCLQdexpRph5rbV4L3V_9i0rXRRNiib304'
            scope: 'https://www.googleapis.com/auth/calendar'
        }

        $('body').append '<script src="https://apis.google.com/js/client.js?onload=handleClientLoad"></script>'

        window.handleClientLoad = ->
            gapi.client.setApiKey cfg.apiKey
            window.setTimeout checkAuth, 1

        checkAuth = ->
            gapi.auth.authorize {client_id: cfg.id, scope: cfg.scope, immediate: true}, handleAuthResult

        handleAuthResult = ->
            alert 1

    {start}
