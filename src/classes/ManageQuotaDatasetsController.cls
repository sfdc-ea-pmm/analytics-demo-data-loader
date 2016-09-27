public class ManageQuotaDatasetsController {
	
    public String salesApp { get; set; }
	public Id dataflowId { get; set; }
	public Id selectedRoleId { get; set; }
	public List<Id> selectedProfilesIds { get;set; }
	public Integer quotaAmount { get; set; }
    public Integer affectedCount { get; set; }
    public Boolean alsoRoleSubordinates { get; set; }
    public Boolean useOpportunityOwners { get; set; }

	public ManageQuotaDatasetsController() {
        this.alsoRoleSubordinates = false;
		this.quotaAmount = 0;
        this.useOpportunityOwners = true;
        this.affectedCount = SalesWaveQuotas.getOpportunitiesUserIds().size();
	}

    public List<SelectOption> getSalesApplications(){
        List<SelectOption> options = new List<SelectOption>();       
        List<InsightsApplication> waveApps = [SELECT DeveloperName,MasterLabel FROM InsightsApplication WHERE AppStatus = 'Completed' AND TemplateOrigin = 'sfdc_internal__Sales_Analytics' ORDER BY MasterLabel];
        for(InsightsApplication app: waveApps) {
            options.add(new SelectOption(app.DeveloperName, app.MasterLabel));
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
            DatasetAccess dsAcc = [SELECT DatasetName FROM DatasetAccess WHERE DataflowVersionId = :dfVer.Id AND AccessType = 'Write' AND DatasetName LIKE '%plain_quota%' LIMIT 1];

            SalesWaveQuotas.updateQuotaDataset(userIds, Date.today().year(), 1, 12, quotaAmount, this.salesApp, dsAcc.DatasetName);
            messages.add(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The Quota Dataset was successfully updated.'));
        }
        
        for(ApexPages.Message msg: messages) {
            ApexPages.addMessage(msg);
        }
    }
}