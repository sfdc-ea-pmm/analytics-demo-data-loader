public class ManageQuotaDatasetsController {
	
    public String salesApp { get; set; }
	public Id dataflowId { get; set; }
	public Id selectedRoleId { get; set; }
	public List<Id> selectedProfilesIds { get;set; }
	public Integer quotaAmount { get; set; }
    public Integer affectedCount { get; set; }
    public Boolean alsoRoleSubordinates { get; set; }
    public Boolean useOpportunityOwners { get; set; }
    public Boolean firstLoad { get; set; }
    public List<WaveFolder> salesWaveFolders { get; set; }

	public ManageQuotaDatasetsController() {
        this.alsoRoleSubordinates = false;
		this.quotaAmount = 0;
        this.useOpportunityOwners = true;
        this.affectedCount = SalesWaveQuotas.getOpportunitiesUserIds().size();
        this.firstLoad = true;
        this.salesWaveFolders = new List<WaveFolder>();
	}

    /*
    // HTTP Callout to retrieve Sales Apps
    public String getWaveFoldersJSON(){
        HttpRequest req = new HttpRequest();
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url =  salesforceHost + '/services/data/v38.0/wave/folders';
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setMethod('GET');

        Http httpMgr = new Http();
        HTTPResponse res = httpMgr.send(req);

        return res.getBody();
    }

    public List<SelectOption> getSalesApplications(){
        List<SelectOption> options = new List<SelectOption>();
        
        if(this.firstLoad){
            
            String jsonFolders = this.getWaveFoldersJSON();
            WaveFoldersResponse foldersResponse = (WaveFoldersResponse)JSON.deserialize(jsonFolders, WaveFoldersResponse.class);
            
            for(WaveFolder folder : foldersResponse.folders){
                if(folder.applicationStatus.toLowerCase() == 'completedstatus' && folder.templateSourceId == 'sfdc_internal__Sales_Analytics'){
                    this.salesWaveFolders.add(folder);
                }
            }

            this.firstLoad = false;
        }
                
        for(WaveFolder folder : this.salesWaveFolders){
            options.add(new SelectOption(folder.name, folder.label.unescapeHtml4()));
        }

        return options;
    }*/

    public List<SelectOption> getSalesApplications(){
        List<SelectOption> options = new List<SelectOption>();
        
        if(this.firstLoad){

            for(List<Folder> folders: [SELECT DeveloperName, Name FROM Folder WHERE Type = 'Insights' AND DeveloperName NOT IN('SharedApp', 'WAVE_PUBLIC_DATAFLOWS')]) {
                for(Folder f: folders) {
                    WaveFolder wf = new WaveFolder();
                    wf.name = f.DeveloperName;
                    wf.label = f.Name;
                    this.salesWaveFolders.add(wf);
                }
            }
            
            this.firstLoad = false;
        }
                
        for(WaveFolder folder : this.salesWaveFolders){
            options.add(new SelectOption(folder.name, folder.label.unescapeHtml4()));
        }

        return options;
    }

	public List<SelectOption> getDataflows() {

        List<SelectOption> options = new List<SelectOption>();
        List<Dataflow> dataflows = [SELECT Id,MasterLabel FROM Dataflow WHERE DataflowType = 'User' AND State = 'Active'];

        for(Dataflow df: dataflows) {
        	options.add(new SelectOption(df.Id, df.MasterLabel));
        }

        return options;
    }

	public List<SelectOption> getRoles() {

        List<SelectOption> options = new List<SelectOption>();
        List<UserRole> roles = RoleUtils.getUserRoles();

        options.add(new SelectOption('', 'None'));
        for(UserRole role: roles) {
        	options.add(new SelectOption(role.Id, role.Name));
        }

        return options;
    }

    public List<SelectOption> getProfiles() {

        List<SelectOption> options = new List<SelectOption>();
        List<Profile> profiles = ProfileUtils.getProfiles();

        for(Profile prof: profiles) {
        	options.add(new SelectOption(prof.Id, prof.Name));
        }

        return options;
    }

    public void handleAffected() {
        this.affectedCount = 0;

        if(this.useOpportunityOwners) {
            this.affectedCount = SalesWaveQuotas.getOpportunitiesUserIds().size();
        } 
        else {
            // Roles
            if(selectedRoleId != null) {
                if(this.alsoRoleSubordinates){
                    this.affectedCount = RoleUtils.getRoleSubordinateUsersIds(selectedRoleId, true).size();
                }
                else {
                    this.affectedCount = RoleUtils.getRoleUsersIds(selectedRoleId).size();
                }
            }

            // Profiles
            if(selectedProfilesIds != null && selectedProfilesIds.size() > 0) {
                this.affectedCount += ProfileUtils.getProfilesSetUsersIds(selectedProfilesIds).size();
            }   
        }
    }

	public void save() {
        List<ApexPages.Message> messages = new List<ApexPages.Message>();
        if(this.affectedCount == 0){
            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'There will be no users affected by this operation.'));
        }
        if(this.quotaAmount <= 0){
            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quota Amount must be non-zero.'));
        }

        if(messages.size() == 0){
            
            List<Id> userIds = new List<Id>();
            
            if(this.useOpportunityOwners) {
                userIds.addAll(SalesWaveQuotas.getOpportunitiesUserIds());
            } 
            else {
                Set<Id> setIds = new Set<Id>();
                // Roles
                if(selectedRoleId != null) {
                    if(this.alsoRoleSubordinates){
                        setIds.addAll(RoleUtils.getRoleSubordinateUsersIds(selectedRoleId, true));
                    }
                    else {
                        setIds.addAll(RoleUtils.getRoleUsersIds(selectedRoleId));
                    }
                }

                // Profiles
                if(selectedProfilesIds != null && selectedProfilesIds.size() > 0) {
                    setIds.addAll(ProfileUtils.getProfilesSetUsersIds(selectedProfilesIds));
                }

                userIds.addAll(setIds);    
            }

            Dataflow dfSel = [SELECT Id FROM Dataflow WHERE DeveloperName = :this.salesApp];
            DataflowVersion dfVer = [SELECT Id FROM DataflowVersion WHERE DataflowId = :dfSel.Id ORDER BY CreatedDate DESC LIMIT 1];
            
            List<DatasetAccess> datasetAccesses = [SELECT DatasetName FROM DatasetAccess WHERE DataflowVersionId = :dfVer.Id AND AccessType = 'Write' AND DatasetName LIKE '%plain_quota%' LIMIT 1];
            if(datasetAccesses.size() > 0) {
                
                DatasetAccess dsAcc = datasetAccesses.get(0);

                SalesWaveQuotas.updateQuotaDataset(userIds, Date.today().year(), 1, 12, quotaAmount, this.salesApp, dsAcc.DatasetName);
                messages.add(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The Quota Dataset was successfully updated.'));
            }
            else {
                messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'The application you selected is not a Sales Wave application.'));
            }
        }
        
        for(ApexPages.Message msg: messages) {
            ApexPages.addMessage(msg);
        }
    }
}