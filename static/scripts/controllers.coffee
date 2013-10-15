define [
    'angular'
    'underscore'
    'underscoreString'
    'plottings'
    'angles'
    'angularBootstrap'
    'ngInfiniteScroll'
    'ngprogress'
    'models'
    'services'
    'directives'
], (angular, _, _s, plottings) ->
    _.mixin _s.exports()

    module = angular.module 'coviolations.controllers', [
        'angles'
        'ui.bootstrap'
        'infinite-scroll'
        'ngProgress'
        'coviolations.models'
        'coviolations.services'
        'coviolations.directives'
    ]

    IndexCtrl = ($scope, favicoService) ->
        ### Index page controller ###
        if window.isAuthenticated
            window.location = '#'

        favicoService.badge(0)
        $scope.successColor = "#5cb85c"
        $scope.failedColor = "#d9534f"
        $scope.chartData =
            [
                    value: window.successTasks
                    color: $scope.successColor
                ,
                    value: window.failedTasks
                    color: $scope.failedColor
            ]
        $scope.chartOptions =
            animation:false
        $scope.successPercent = window.successTasks
        $scope.failedPercent = window.failedTasks
    module.controller 'IndexCtrl', [
        '$scope', 'favicoService', IndexCtrl,
    ]

    DashboardCtrl = ($scope, $http, ngProgress, favicoService, Tasks) ->
        ### Dashboard controller ###
        if not window.isAuthenticated
            window.location = '#'

        ngProgress.start()
        $http.get(
            '/api/v1/projects/project/?limit=0&with_success_percent=true&with_last_task=true'
        ).success (data) =>
            $scope.projects = data.objects
            failedTasks = 0
            _.each $scope.projects, (project) =>
                plot = new plottings.SuccessPercentPlot project
                project.chart = plot.createChartObject()
                if project.last_task and project.last_task.status == 2
                    failedTasks += 1
            favicoService.badge(failedTasks)
            ngProgress.complete()

        $scope.tasks = new Tasks 20,
            withViolations: true
            self: true
        $scope.tasks.load()
    module.controller 'DashboardCtrl', [
        '$scope', '$http', 'ngProgress', 'favicoService', 'Tasks', DashboardCtrl,
    ]

    ManageCtrl = ($scope, $http, ngProgress, favicoService) ->
        ### Manage projects page controller ###
        if not window.isAuthenticated
            window.location = '#'

        favicoService.badge(0)
        ngProgress.start()
        $scope.loading = true
        $http.get('/api/v1/projects/project/?fetch=true&limit=0').success (data) =>
            $scope.projects = data.objects
            $scope.loading = false
            $scope.$watch 'projects', (newProjects, oldProjects) =>
                _.each newProjects, (project, num) =>
                    if project.is_enabled != oldProjects[num].is_enabled
                        $http.put(project.resource_uri, project)
            , true

            ngProgress.complete()
    module.controller 'ManageCtrl', [
        '$scope', '$http', 'ngProgress', 'favicoService', ManageCtrl,
    ]

    ProjectCtrl = (
            $scope, $http, $routeParams, $modal,
            ngProgress, favicoService, Tasks
    ) ->
        ### Single project page controller ###
        favicoService.badge(0)
        ngProgress.start()
        projectName = _.sprintf '%s/%s', $routeParams['owner'], $routeParams['name']
        projectUrl = _.sprintf '/api/v1/projects/project/%s/', projectName

        loadProject = =>
            $http.get(projectUrl).success (data) =>
                $scope.project = data
                if not $scope.branches
                    $scope.branches = data.branches
                $scope.branch = $scope.project.default_branch
                ngProgress.complete()
        loadProject()

        $scope.$watch 'branch', (branch) =>
            $scope.tasks = new Tasks 20,
                withViolations: true
                project: projectName
                branch: branch
            $scope.tasks.load =>
                plotData = new plottings.PlotData $scope.tasks.items
                plotData.normalise()
                $scope.charts = plotData.createChartObjects()

        $scope.toggleBadgeHelp = =>
            $scope.showBadgeHelp =
                if $scope.showBadgeHelp then false else true

        $scope.regenerateToken = =>
            $scope.project.token = ''
            $http.put(projectUrl, $scope.project).success =>
                loadProject()

        $scope.showSettings = =>
            $modal.open
                templateUrl: '/static/views/project_settings.html'
                controller: ProjectSettingsCtrl
                resolve:
                    $http: => $http
                    project: => $scope.project

        $scope.domain = window.domain
    module.controller 'ProjectCtrl', [
        '$scope', '$http', '$routeParams', '$modal', 'ngProgress',
        'favicoService', 'Tasks', ProjectCtrl,
    ]

    ProjectSettingsCtrl = ($scope, $modalInstance, $http, project) ->
        $scope.project = project
        $scope.close = =>
            $modalInstance.close()
        $scope.$watch 'project', =>
            $http.put($scope.project.resource_uri, $scope.project)
        , true

    TaskCtrl = ($scope, $http, $routeParams, ngProgress, favicoService) ->
        ### Single task controller ###
        ngProgress.start()
        taskUrl = _.sprintf '/api/v1/tasks/task/%s/', $routeParams['pk']

        $http.get(taskUrl).success (data) =>
            $scope.task = data
            failed = (_.filter data.violations, (violation) -> violation.status == 2).length
            favicoService.badge failed

            projectUrl = _.sprintf '/api/v1/projects/project/%s/', data['project']
            $http.get(projectUrl).success (project) =>
                $scope.project = project
                ngProgress.complete()
    module.controller 'TaskCtrl', [
        '$scope', '$http', '$routeParams', 'ngProgress',
        'favicoService', TaskCtrl,
    ]


    IndexCtrl: IndexCtrl
    DashboardCtrl: DashboardCtrl
    ManageCtrl: ManageCtrl
    ProjectCtrl: ProjectCtrl
    ProjectSettingsCtrl: ProjectSettingsCtrl
    TaskCtrl: TaskCtrl
