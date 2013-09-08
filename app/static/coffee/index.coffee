window.coviolations ?=
    views: {}
    models: {}

$ ->
    NProgress.start()
    NProgress.inc()

    app = window.coviolations
    waitRendering = 2

    renderFinished = =>
        NProgress.inc()
        waitRendering -= 1
        if waitRendering == 0
            NProgress.done()

    renderProjects = =>
        projectCollection = new app.models.UserProjectCollection
        projectCollection.fetch
            data:
                limit: 0
            success: (collection) =>
                if collection.meta.total_count
                    projectView = new app.views.ManageProjectsView
                        el: $('.js-enabled-projects')
                        collection: collection
                    projectView.on 'renderFinished', $.proxy renderFinished, @

                    projectView.render()
                else
                    $('.js-enabled-projects td').html 'No projects found'

    renderProjects()
    window.push.on 'project', =>
        renderProjects()

    renderTasks = =>
        taskCollection = new app.models.TaskCollection()
        taskCollection.fetch
            data:
                limit: 20
                with_violations: true
                self: true
            success: (collection) ->
                taskView = new app.views.TaskLineListView
                    el: $('.js-last-tasks')
                    collection: collection
                    showProjectName: true
                taskView.on 'renderFinished', $.proxy renderFinished, @
                taskView.render()
    renderTasks()
    window.push.on 'task', =>
        renderTasks()

    prettyPrint()
