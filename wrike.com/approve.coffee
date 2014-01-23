->
    utils = null
    approver = null

    states = {
        'initial': {
            triggers: {
                'Send for approval': 'onApproval'
            }
        },
        'onApproval': {
            triggers: {
                'Approve': 'accepted',
                'Decline': 'declined'
            },
            titleTag: 'To Approve',
            author: true
        },  
        'accepted': {
            titleTag: 'Approved',
            owner: true
        },
        'declined': {
            triggers: {
                'Send for approval': 'onApproval'
            },  
            titleTag: 'Declined',
            owner: true
        }
    }

    class WrikeTaskFilters
        filter: 'All'
        flagTemplate = '<a class="wrike-button-checkbox x-btn-noicon" href="#"></a>';

        renderFlags: ->
            containerId = 'wrike-taist-approval-filters'
            if $('#' + containerId).length
                return
            originalFlags = $('.type-selector')
            flags = originalFlags.clone()
            flags.attr 'id', containerId
            flagsContainer = flags.find('.x-column').empty()
            originalFlags.after flags
            self = @
            for _, state of states
                flag = $(flagTemplate)
                flag.text state.titleTag or 'All'
                flagsContainer.append flag
                if @filter is flag.text()
                    flag.addClass('x-btn-pressed')
                flag.on 'click', ->
                    flagsContainer.find('a').removeClass('x-btn-pressed');
                    $(@).addClass('x-btn-pressed')
                    self.filter = $(@).text()
                    self.filterTasks()
                    false

        filterTasks: ->
            $('.stream-task-entry').each (i, element) =>
                elm = $ element
                if @filter is 'All'
                    elm.removeClass 'wrike-taist-hidden'
                else
                    taskTitle = elm.find('span').text()
                    if taskTitle.match '\\[' + @filter + '\\]'
                        elm.removeClass 'wrike-taist-hidden'
                    else
                        elm.addClass 'wrike-taist-hidden'
            


    class WrikeTaskApprover
        buttonTemplate: '<a class="wspace-task-settings-button"></a>'

        setTask: (task) ->
            if @task is task
                return;
            @task = task
            @title = $('.wspace-task-widgets-title-view').find('textarea')
            @state = @stateFromTitle()

            # Have to remove the toolbar as view init event is being emmitted
            # multiple times from the stream view
            $('#wrike-taist-toolbar').remove()
            originalToolbar = $ '.wspace-task-settings-bar'
            @toolbar = originalToolbar.clone()
            @toolbar.attr 'id', 'wrike-taist-toolbar'
            @toolbar.empty()
            originalToolbar.after @toolbar

            roles = taistWrike.myTaskRoles(task)
            if roles.owner and states[@state].owner or roles.author and states[@state].author
                @renderControls()

        stateFromTitle: ->
            m = @title.val().match /^\[(.+)\].*/
            if not m?[1]
                return 'initial'
            for stateName, state of states
                if state.titleTag is m[1]
                    return stateName

        renderControls: ->
            mOver = ->
                $(@).addClass 'x-btn-over'
            mOut = ->
                $(@).removeClass 'x-btn-over'
            for buttonTitle, nextState of states[@state].triggers
                do(buttonTitle, nextState) =>
                    button = $(@buttonTemplate)
                    button.text buttonTitle
                    button.hover mOver, mOut
                    button.on 'click', =>
                        @toolbar.empty()
                        @applyState nextState
                        @renderControls()
                        false
                    @toolbar.append button
                

        applyState: (newState) ->
            newPrefix = '[' + states[newState].titleTag + '] '
            if @state is 'initial'
                @title.val(newPrefix + @title.val())
            else
                @title.val(@title.val().replace(/^\[.+\]\s/, newPrefix))

            # Sequence for auto-saving modified ticket title
            @title.focus()
            $.event.trigger {type: 'keypress', which: 13 }
            @title.blur()

            @state = newState

    approver = new WrikeTaskApprover()
    filters = new WrikeTaskFilters()

    start = (utilities) ->
        utils = utilities

        style = $ '<style> .wrike-taist-hidden {display: none;} </style>'
        $('html > head').append(style)

        taistWrike.onTaskViewRender (task) ->
            if not task
                return;
            approver.setTask task

        taistWrike.onStreamView ->
            filters.renderFlags()
            filters.filterTasks()

        if window.location.hash.match(/stream/)
            filters.renderFlags()
            filters.filterTasks()

    taistWrike =
        me: -> $wrike.user.getUid()

        myTaskRoles: (task) ->
            {
                owner: task.data['responsibleList'].indexOf(@me()) >= 0
                author: (task.get 'author') is @me()
            }

        onTaskViewRender: (callback) ->
            listenerName = 'load'
            listenersInPrototype = $wspace.task.View.prototype.xlisteners

            utils.aspect.after listenersInPrototype, listenerName, (view, task) ->
                if task?
                    task.load (loadedTask) ->
                        callback loadedTask, view
                else
                    return callback null, view

            currentTaskView = window.Ext.ComponentMgr.get ($('.wspace-task-view').attr 'id')
            currentTask = currentTaskView?['record']

            if currentTask? and currentTaskView?
                enhancedListener = listenersInPrototype[listenerName]
                currentViewListeners = currentTaskView.events[listenerName].listeners[0]
                currentViewListeners.fn = currentViewListeners.fireFn = enhancedListener

                callback currentTask, currentTaskView

        onTaskChange: (callback) ->
            utils.aspect.after Wrike.Task, 'getChanges', (-> callback @)

        onStreamView: (callback) ->
            utils.aspect.before XMLHttpRequest, 'open', (requestMethod, requestUrl) =>
                if requestUrl is 'https://www.wrike.com/ui/as_append3'
                    callback()

    return {start}
