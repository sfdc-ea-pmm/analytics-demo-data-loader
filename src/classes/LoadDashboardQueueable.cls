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

        // Dashboard create or update?
        // https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_rest.meta/bi_dev_guide_rest/bi_resources_dashboards_id.htm
        if (String.isBlank(dashboardId)) {
            // Create
        }
        else {
            // Update
        }
    }
}