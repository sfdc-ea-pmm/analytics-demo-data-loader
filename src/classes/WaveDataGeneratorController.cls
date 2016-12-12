public with sharing class WaveDataGeneratorController {

	public String waveApp { get; set; }
	public Boolean testExceptionCatchBlock { get; set; }
	public String selectedObject { get; set; }
	public String dataUrl { get; set; }
	public Boolean showHelp { get; set; }
	public String helpText { get; set; }
	public Boolean validSchema { get; set; }
	public String validationMessage { get; set; }
	public Id batchProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }
	
	public WaveDataGeneratorController() {
		this.showHelp = false;
		this.helpText = 'Click for help';
		this.validSchema = false;
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

	public List<SelectOption> getOrgObjects() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'None'));
        
        if(!String.isBlank(this.waveApp)) {
        	// Default ones
			options.add(new SelectOption('User', 'User'));

			if (this.waveApp == 'SalesWave') {
				options.add(new SelectOption('Account', 'Account'));
				options.add(new SelectOption('Opportunity', 'Opportunity'));
			} else if (this.waveApp == 'ServicesWave') {
				options.add(new SelectOption('Case', 'Case'));
			}

			options.add(new SelectOption('Task', 'Task'));
			options.add(new SelectOption('Event', 'Event'));
        }

        return options;
    }

    public void help(){
    	this.showHelp = !this.showHelp;
    	if(this.showHelp){
    		this.helpText = 'Hide help';
    	}
    	else {
    		this.helpText = 'Click for help';
    	}
    }

    public void updateWaveApp(){
    	this.selectedObject = '';
    	this.dataUrl = '';
    	this.validationMessage = '';
    	this.showJobStatistics = false;
    }

    public void updateSelectedObj(){

    	this.dataUrl = '';
    	this.validationMessage = '';
    	this.showJobStatistics = false;

        Boolean changed = false;

        // Default URLs
        if(this.selectedObject == 'User'){
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/283bc870/download?count=20&key=ad4356a0';
            changed = true;
        }
        else if (this.selectedObject == 'Account') {
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/e7369170/download?count=100&key=ad4356a0';
            changed = true;
        }
        else if (this.selectedObject == 'Opportunity') {
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/1f197d90/download?count=100&key=ad4356a0';
            changed = true;
        }
        else if (this.selectedObject == 'Case') {
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/faf959e0/download?count=500&key=ad4356a0';
            changed = true;
        }
        else if (this.selectedObject == 'Task') {
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/08b5e490/download?count=100&key=ad4356a0';
            changed = true;
        }
        else if (this.selectedObject == 'Event') {
            this.dataUrl = 'https://sfdc-mockaroo.herokuapp.com/d73ca970/download?count=100&key=ad4356a0';            
            changed = true;
        }

        if(changed && !Test.isRunningTest()){
            this.validateSchema();
        }
    }

    public void validateSchema(){
    	
    	this.validationMessage = '';
        this.dataUrl = (this.dataUrl == null ? '' : this.dataUrl.trim());

    	if(String.isBlank(this.dataUrl)){
            this.validSchema = false;
        }
    	else {
    		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    		this.validationMessage = iMockHelper.validateDataURL(this.dataUrl);
    		if(String.isBlank(this.validationMessage)){
    			
    			// Now validate data schema against sObject's schema
    			List<String> dataFields = iMockHelper.getSchemaFieldNames(this.dataUrl);

    			if(dataFields.size() > 0){

    				// Retrieve sObject's schema
    				Map<String, Schema.DisplayType> schemaMapping = new Map<String, Schema.DisplayType>();
    				SObjectType objectType = Schema.getGlobalDescribe().get(this.selectedObject);
    				Map<String, Schema.SObjectField> objectFields = objectType.getDescribe().fields.getMap();

    				List<String> requiredFields = new List<String>();
    				for (String s: objectFields.keySet()) {
						
						Schema.DescribeFieldResult dfr = objectFields.get(s).getDescribe();
						if(!dfr.isNillable() && !dfr.isDefaultedOnCreate() && dfr.getName() != 'ProfileId' && dfr.getName() != 'OwnerId' && dfr.getName() != 'CaseId' && dfr.getName() != 'BusinessHoursId'){
							// It is required
							requiredFields.add(dfr.getName());
						}
					}

					// We build this map to speed up searches
					Map<String, String> fieldTable = new Map<String, String>();
					for(String mockarooField: dataFields) {
						fieldTable.put(mockarooField, mockarooField);
					}

					// Now we have the fields that salesforce requires. We have to remove those that 
					// will be managed as external ids and smart lookups			 
					if(this.selectedObject == 'User'){
    					// Add the mockaroo ones
    					requiredFields.add('Profile.Name');
    					requiredFields.add('External_Id__c');
    				}
    				else if (this.selectedObject == 'Account') {
    					// Add the mockaroo ones
    					requiredFields.add('External_Id__c');
    					requiredFields.add('Owner.External_Id__c');
    				}
    				else if (this.selectedObject == 'Case') {
    					requiredFields.add('External_Id__c');
    					requiredFields.add('Owner.External_Id__c');
    					requiredFields.add('BusinessHours.Name');
    				}
    				else if (this.selectedObject == 'Opportunity' || this.selectedObject == 'Task' || this.selectedObject == 'Event') {
    					requiredFields.add('Owner.External_Id__c');	
    				}

					// All required fields must be present in mockaroo schema
					List<String> missingFields = new List<String>();
					for(String reqField: requiredFields) {
						if(!fieldTable.containsKey(reqField)){
							System.debug(reqField);
							missingFields.add(reqField);
						}
					}

					if(missingFields.size() > 0){
						this.validSchema = false;
						this.validationMessage = 'Invalid Mockaroo data schema. The following fields are required by the selected object: ' + String.join(missingFields, ', ');
					}
					else {
						this.validSchema = true;
						this.validationMessage = 'The Mockaroo data schema is correct. You can proceed to generate data.';	
					}    				
    			}
    			else {
    				this.validSchema = false;
    				this.validationMessage = 'Invalid Mockaroo data schema. No fields were retrieved.';
    			}
    		}
    		else {
    			this.validSchema = false;
    		}
    	}
    }
    
    public void save() {
        try {
        	this.showJobStatistics = false;
    		List<ApexPages.Message> messages = new List<ApexPages.Message>();

    		if(Test.isRunningTest() && this.testExceptionCatchBlock){
    			Double dFail = 1 / 0; // Will raise exception
    		}

    		if(String.isBlank(this.selectedObject)){
	            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are required to select an object.'));
	        }

	        if(String.isBlank(this.dataUrl)){
	            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are required to enter a data URL.'));
	        }

    		if(messages.size() == 0){
    			IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    			List<List<String>> csvData = iMockHelper.getData(this.dataUrl, false);

    			if(csvData.size() > 0){
    				// Will extract headers
    				List<String> headers = csvData.remove(0);
    				Map<Integer, String> fieldPositions = new Map<Integer, String>();
    				
    				for(Integer i = 0; i < headers.size(); i++) {
    					fieldPositions.put(i, headers[i]);
    				}

    				// Start the batch process
    				CsvDataImportBatch batchProcess = new CsvDataImportBatch(Schema.getGlobalDescribe().get(this.selectedObject), csvData, fieldPositions);
    				this.batchProcessId = Database.executeBatch(batchProcess);

    				// Now monitor job execution
    				this.monitorJobExecution = true;
    				AsyncApexJob asyncJob = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
    				this.totalBatches = asyncJob.TotalJobItems;
					this.batchesProcessed = asyncJob.JobItemsProcessed;
					this.showJobStatistics = true;
    			}
    			else {
    				// No data rows retrieved
					messages.add(new ApexPages.Message(ApexPages.Severity.WARNING, 'No data to process.'));
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