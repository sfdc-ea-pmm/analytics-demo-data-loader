public with sharing class LoadDashboardQueueable implements Queueable, Database.AllowsCallouts {
    
    private Double apiVersion;
    private String sessionId;
    private String folderId;
    private WaveApplicationDashboard dashboardToLoad;
    private Map<String, WaveApplicationDataset> datasetsMap;

    public LoadDashboardQueueable(WaveApplicationDashboard dashboard, Map<String, WaveApplicationDataset> datasetsMap, String folderId, Double apiVersion, String sessionId) {
        this.dashboardToLoad = dashboard;
		this.sessionId = sessionId;
        this.apiVersion = apiVersion;
        this.folderId = folderId;
        this.datasetsMap = datasetsMap;
    }

    public void execute(QueueableContext context) {
        // Find if there exists dashboard
        List<Lens> lstDashboards = [SELECT Id, FolderId FROM Lens WHERE Type = 'dashboard' AND DeveloperName = :this.dashboardToLoad.name AND IsDeleted = false];
        String dashboardId = '';
        String dashNameCandidate = this.dashboardToLoad.name;

        if (lstDashboards.size() > 0) {
            // Create new one with distinct name, or overwrite exising?
            Lens orgDashboard = lstDashboards.get(0);
            
            if (!orgDashboard.FolderId.equals(this.folderId)) {
                // Same dashboard name exists in another analytics app, need to find new name
                List<String> dashboardNames = new List<String>();
                
                for (Lens l: [SELECT DeveloperName FROM Lens WHERE Type = 'dashboard' AND IsDeleted = false]) {
                    dashboardNames.add(l.DeveloperName);
                }

                Integer iSuffix = 0;                
                while(dashboardNames.contains(dashNameCandidate)){
                    iSuffix++;
                    dashNameCandidate = this.dashboardToLoad.name + iSuffix;
                }
            }
            else {
                dashboardId = orgDashboard.Id;
            }
        }

        // Get the dashboard json template. How to generate it? From Chrome's debugger console, network tab to see what is sent when you save a dashboard
        HttpResponse resJson = WaveConfiguratorUtils.httpGetCallout(this.dashboardToLoad.jsonUrl);
        String dashboardJsonToSend = resJson.getBody();
        dashboardJsonToSend = dashboardJsonToSend.replace('{#FolderId}', this.folderId);
        dashboardJsonToSend = dashboardJsonToSend.replace('{#DashboardName}', dashNameCandidate);
        for (String datasetName : this.dashboardToLoad.referencedDatasets) {
            if (this.datasetsMap.containsKey(datasetName)) {
                WaveApplicationDataset ds = this.datasetsMap.get(datasetName);
                dashboardJsonToSend = dashboardJsonToSend.replace('{#' + datasetName + '}', ds.nameToSave);
            }
        }
        
        // Dashboard create or update?
        // https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_rest.meta/bi_dev_guide_rest/bi_resources_dashboards_id.htm
        HTTPResponse res = null;
        if (String.isBlank(dashboardId)) {
            // Create
            res = WaveConfiguratorUtils.httpCallout('/services/data/v' + apiVersion + '/wave/dashboards', 'POST', true, dashboardJsonToSend);
        }
        else {
            // Update
            res = WaveConfiguratorUtils.httpCallout('/services/data/v' + apiVersion + '/wave/dashboards/' + dashboardId + '?_HttpMethod=PATCH', 'POST', true, dashboardJsonToSend);
        }

        if(!WaveConfiguratorUtils.checkStatus(res)){
            if(res.getBody().containsIgnoreCase('errorCode')){
                List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
                throw new WaveConfiguratorException('There was an error in the attempt to save the: ' + dashNameCandidate + ' dashboard. Cause: ' + r.get(0).message + '.');
            }
            throw new WaveConfiguratorException('There was an error in the attempt to save the: ' + dashNameCandidate + ' dashboard.');
        }
    }
}