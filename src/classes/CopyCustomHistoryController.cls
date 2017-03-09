public with sharing class CopyCustomHistoryController {
	
	public String waveApp { get; set; }
	public Boolean testExceptionCatchBlock { get; set; }
	public String selectedObject { get; set; }	
	public Id batchProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }

	public CopyCustomHistoryController() {
		this.monitorJobExecution = false;
		this.batchProcessId = null;
		this.totalBatches = 0;
		this.batchesProcessed = 0;
		this.showJobStatistics = false;
		this.jobStatusDsc = '';
	}

	public List<SelectOption> getWaveApplications() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'None'));
        options.add(new SelectOption('ServicesWave', 'Services Wave'));
        options.add(new SelectOption('SalesWave', 'Sales Wave'));

        return options;
    }

	public List<SelectOption> getHistoryObjects() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'None'));
        
        if(!String.isBlank(this.waveApp)) {
        	
        	if (this.waveApp == 'SalesWave') {
				options.add(new SelectOption('OpportunityHistory', 'OpportunityHistory'));
				options.add(new SelectOption('OpportunityFieldHistory', 'OpportunityFieldHistory'));
			} else if (this.waveApp == 'ServicesWave') {
				options.add(new SelectOption('CaseHistory', 'CaseHistory'));
			}
        }

        return options;
    }

    public void updateWaveApp(){
    	this.selectedObject = '';
    	this.showJobStatistics = false;
    }

    public void updateSelectedObj(){
    	this.showJobStatistics = false;
    }

    public void process() {
        try {
        	this.showJobStatistics = false;
    		List<ApexPages.Message> messages = new List<ApexPages.Message>();

    		if(Test.isRunningTest() && this.testExceptionCatchBlock){
    			Double dFail = 1 / 0; // Will raise exception
    		}

    		if(String.isBlank(this.selectedObject)){
	            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are required to select an object.'));
	        }

	        if(messages.size() == 0){
    			

	        	Database.Batchable<sObject> batchProcess = null;

	        	if(this.selectedObject == 'CaseHistory'){
	        		batchProcess = new WW_CopyCaseHistory();
	        	}
	        	else if (this.selectedObject == 'OpportunityHistory') {
	        		batchProcess = new WW_CopyOpportunityHistory();	
	        	}
	        	else if (this.selectedObject == 'OpportunityFieldHistory') {
	        		batchProcess = new WW_CopyOpportunityFieldHistory();
	        	}

	        	if(batchProcess != null){

	        		// Start the batch process
	        		this.batchProcessId = Database.executeBatch(batchProcess);

					// Now monitor job execution
					this.monitorJobExecution = true;
					AsyncApexJob asyncJob = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
					this.totalBatches = asyncJob.TotalJobItems;
					this.batchesProcessed = asyncJob.JobItemsProcessed;
					this.showJobStatistics = true;
	        	}	
	        	else {
	        		messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid object selected.'));
	        	}
    		}
    		
    		for(ApexPages.Message msg: messages) {
				ApexPages.addMessage(msg);
			}
    	}
    	catch(Exception e) {
    		ApexPages.addMessages(e);
    		System.debug(e.getMessage());
    		System.debug(e.getStackTraceString());
    	}
    }

    public void monitor(){
    	if(this.monitorJobExecution && this.batchProcessId != null){
    		
    		AsyncApexJob asyncJob = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
    		this.jobStatusDsc = 'Processing';
    		if(asyncJob.Status == 'Aborted' || asyncJob.Status == 'Completed' || asyncJob.Status == 'Failed'){
    			this.monitorJobExecution = false;
    			this.batchProcessId = null;
    			this.jobStatusDsc = asyncJob.Status;
    		}

    		this.totalBatches = asyncJob.TotalJobItems;
			this.batchesProcessed = asyncJob.JobItemsProcessed;
    	}
    }
}