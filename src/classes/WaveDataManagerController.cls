public with sharing class WaveDataManagerController {
	
	public String Host {get;set;}
	public String RemoteSiteName { get { return 'WaveDataManager_mdapi'; } }
	public String MetadataResponse {get;set;}
	public Boolean MetadataConnectionWarning {get;set;}
	public String MetadataApiException {get;set;}
	public String selectedWaveApp { get; set; }
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }
	public String warningMessage  { get; set; }
	public Id batchProcessId { get; set; }
	public Id queueProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }
	public List<String> processingLog { get; set; }
	public Integer currentNodeIndex { get; set; }
	public Integer currentTimeShiftingNodeIndex { get; set; }
	public String currentObjectProcessing { get; set; }
	public List<WaveApplicationObject> objectsNodes { get; set; }
	public List<Edgemart> edgemarts { get; set; }
	public boolean disabledButton { get; set; }
	private WaveMetadata metadata;
	private Map<String, String> appDescriptions; // <appName, appDesc>
	private Map<String, Integer> appIndexes; // <appName, appIndex in this.metadata.waveApplications>
	private Map<String, String> edgemartNamesToSave; // <edgemart name as it comes from JSON, unique edgemart name to store>
	private Map<String, String> dashboardsIdsByName;
	public String folderName { get; set; }
	public String folderLabel { get; set; }
	public String folderId { get; set; }
	public String dataflowName { get; set; }
	public String dataflowLabel { get; set; }
	public String emailAddress { get; set; }
	public List<WaveApplicationRow> applicationRows;
	public WaveMetadataApplication selectedAppMetadata { get; set; }
	public String dataflowDefinitionJson { get; set; }
	public GenericAppConfiguration genericAppConfiguration { get; set; }
	public static final String genericAppConfigurationFileName = 'SEADemoDataLoaderConfig';
	public Boolean pageRendered { get; set; }
	public WaveConfiguratorUtils utils;
	public List<WaveTimeShiftingItem> timeShiftingItems { get; set; }
	public Boolean enableTimeShiftingCheck { get; set; }
	public Boolean enableObjectProcessingCheck { get; set; }
	public String selectedInstallationProcess { get; set; }
	public List<List<SF_MetadataUtils.CustomFieldSpecification>> objectsAndFieldsMatrix;
	public Integer currentObjectIndex;
	public Integer currentFieldIndex;
	public Boolean processingObjectsAndFieldsMetadata { get; set; }
	public Boolean processingEdgemarts { get; set; }
	public Map<String, Boolean> edgeMartsChecked;
	public List<List<SF_MetadataUtils.RecordTypeSpecification>> objectsRecordTypesMatrix;
	public Integer currentRecordTypeIndex;
	public Boolean processingRecordTypes { get; set; }

	// Secuence control
	public String installationStep { get; set; }

	public WaveDataManagerController() {
		this.objectsNodes = new List<WaveApplicationObject>();
		this.timeShiftingItems = new List<WaveTimeShiftingItem>();
		this.processingLog = new List<String>();
		this.appDescriptions = new Map<String, String>();
		this.appIndexes = new Map<String, Integer>();
		this.emailAddress = UserInfo.getUserEmail();
		this.utils = new WaveConfiguratorUtils();
		this.objectsAndFieldsMatrix = new List<List<SF_MetadataUtils.CustomFieldSpecification>>();
		this.objectsRecordTypesMatrix = new List<List<SF_MetadataUtils.RecordTypeSpecification>>();
		this.MetadataResponse = '';
		this.installationStep = '';
		this.enableTimeShiftingCheck = false;
		this.enableObjectProcessingCheck = false;
		this.processingObjectsAndFieldsMetadata = false;
		this.processingEdgemarts = false;
		this.edgeMartsChecked = new Map<String, Boolean>();
		this.selectedInstallationProcess = 'fullInstallation';
	}

	public PageReference pageLoad()
	{
		// Get Host Domain
		Host = ApexPages.currentPage().getHeaders().get('Host');
		
		try{

			//Get App Configuration File
			this.genericAppConfiguration = utils.getAppConfiguration(genericAppConfigurationFileName);
			this.pageRendered = true;

			// Attempt to connect to the Metadata API
			MetadataConnectionWarning = false;
			if(!Test.isRunningTest() && !SF_MetadataUtils.checkMetadataAPIConnection())
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Unable to connect to the Salesforce Metadata API.'));
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'A Remote Site Setting must be created in your org before you can use this tool.'));
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Press the Create Remote Site Setting button to perform this step or refer to the post install step below to perform this manually.'));
				MetadataConnectionWarning = true;
				MetadataApiException = '';
				/*if(RollupService.LastMetadataAPIConnectionException!=null)
					MetadataApiException = RollupService.LastMetadataAPIConnectionException.getMessage();*/
			}

			if(applicationRows == null){
				applicationRows = WaveConfiguratorUtils.getWaveApplications(this.genericAppConfiguration.baseUrl + this.genericAppConfiguration.waveApplicationsUrl);			
				if(this.applicationRows != null){
					Integer index = 0;
		        	for(WaveApplicationRow genericApp: this.applicationRows) {
						this.appIndexes.put(genericApp.Name, index);
						this.appDescriptions.put(genericApp.Name, genericApp.Description);
						index++;
					}
		        }
			}

		} 
		catch(WaveConfiguratorException ex){
			this.errorMessage = ex.getMessage();
		}

		return null;
	}

	public List<SelectOption> getWaveApps() {
        
        List<SelectOption> options = new List<SelectOption>();

        if(this.applicationRows != null){
        	for(WaveApplicationRow genericApp: this.applicationRows) {
				options.add(new SelectOption(genericApp.Name, genericApp.Label));
			}
        }

        return options;
    }

    public PageReference waveAppSelected(){

    	this.folderName = this.selectedWaveApp;

    	Integer appIndex = this.appIndexes.get(this.selectedWaveApp);
		WaveApplicationRow appRow = this.applicationRows.get(appIndex);
    	this.folderLabel = appRow.Label;
    	
    	return null;
    }


    public String getAppDescription(){
    	
    	String dsc = 'No description available.';

    	if(!String.isBlank(this.selectedWaveApp) && this.appDescriptions.containsKey(this.selectedWaveApp)){
    		dsc =  this.appDescriptions.get(this.selectedWaveApp);
    	}
    	
    	return dsc;
    }

	public void resetMessages(){
		this.errorMessage = '';
		this.successMessage = '';
		this.warningMessage = '';
		this.jobStatusDsc = '';
		this.processingLog.clear();
	}

	public List<WaveApplicationObject> getObjectsToProcess(WaveMetadataApplicationObject wmaObj){
		List<WaveApplicationObject> listToProcess = new List<WaveApplicationObject>();
		WaveApplicationObject rootObj = new WaveApplicationObject();
		rootObj.name = wmaObj.name;
		rootObj.url = this.genericAppConfiguration.baseUrl + wmaObj.url;
		rootObj.additionalDataFiles = wmaObj.additionalDataFiles;
		listToProcess.add(rootObj);

		// We process the fields metadata
		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    	List<List<String>> csvMetadata = iMockHelper.getData(this.genericAppConfiguration.baseUrl + wmaObj.metadataUrl, false);
    	
    	if(csvMetadata.size() > 0){
			// Will extract headers
			List<String> headers = csvMetadata.remove(0);
			Map<String, Integer> fieldPositions = new Map<String, Integer>();
			
			for(Integer i = 0; i < headers.size(); i++) {
				fieldPositions.put(headers.get(i), i);
			}

			// For each row of data in the CSV
			rootObj.fields = new List<WaveApplicationObjectField>();

			for(List<String> metadataRow: csvMetadata) {

				WaveApplicationObjectField fieldMetadata = new WaveApplicationObjectField();
				fieldMetadata.Label = metadataRow.get(fieldPositions.get('Label')).trim();
				fieldMetadata.Name = metadataRow.get(fieldPositions.get('Name')).trim();
				fieldMetadata.Type = metadataRow.get(fieldPositions.get('Type')).trim();
				fieldMetadata.ReferenceTo = metadataRow.get(fieldPositions.get('ReferenceTo')).trim();
				fieldMetadata.Length = Integer.valueOf(metadataRow.get(fieldPositions.get('Length')));
				fieldMetadata.Precision = Integer.valueOf(metadataRow.get(fieldPositions.get('Precision')));
				fieldMetadata.Scale = Integer.valueOf(metadataRow.get(fieldPositions.get('Scale')));
				fieldMetadata.IsExternalId = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsExternalId')));
				fieldMetadata.IsRequired = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsRequired')));
				fieldMetadata.DefaultValue = metadataRow.get(fieldPositions.get('DefaultValue')).trim();

				rootObj.fields.add(fieldMetadata);
			}
		}

		// We process the relations
		rootObj.relations = new List<WaveApplicationObjectRelation>();
		if(wmaObj.relations != null){			
			for(WaveMetadataApplicationObjectRelation relObj: wmaObj.relations) {
				WaveApplicationObjectRelation rel = new WaveApplicationObjectRelation();
				rel.csvColumnName = relObj.csvColumnName;
				rel.targetSObject = relObj.targetSObject;
				rel.targetSObjectLookupField = relObj.targetSObjectLookupField;
				rel.foreignKeyField = relObj.foreignKeyField;

				rootObj.relations.add(rel);
			}
		}

		// Replicate for each adittional data CSV file

		// We process the children
		if(wmaObj.children != null) {
			// Now the children objects
			for(WaveMetadataApplicationObject chObj: wmaObj.children) {
				List<WaveApplicationObject> childrenObjs = getObjectsToProcess(chObj);
				listToProcess.addAll(childrenObjs);
			}
		}

		return listToProcess;
	}

	private void processCurrentObjectLoadNode(){
		
		try{
			WaveApplicationObject currentNode = this.objectsNodes.get(this.currentNodeIndex);
			this.logMessage('Loading records for ' + currentNode.name + ' object...');
            System.debug('Current Node Url: ' + currentNode.url);
			HttpResponse res = WaveConfiguratorUtils.httpGetCallout(currentNode.url);
			String csvDataWithHeaders = res.getBody();
			
			// We search for \n
			Integer indexOfLF = csvDataWithHeaders.indexOf('\n');
			if(indexOfLF != -1){
				
				String headersLine = csvDataWithHeaders.substring(0, indexOfLF);
				System.debug('Headers: ' + headersLine);
				
				// We search for \r
				if(headersLine.indexOf('\r') != -1){
					headersLine = headersLine.replace('\r', '');
				}

				List<String> headers = headersLine.split(',');

				currentNode.fieldPositions = new Map<Integer, String>();
					
				for(Integer i = 0; i < headers.size(); i++) {
					currentNode.fieldPositions.put(i, headers[i]);
				}

				String csvData = csvDataWithHeaders.substringAfter('\n');
				if(currentNode.url == 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/data/PricebookEntry.csv'){
					System.debug(csvData);
				}

				if(csvData.length() > 0){

					this.currentObjectProcessing = currentNode.name;					

					// Start the batch process
					CsvDataImportBatch batchProcess = new CsvDataImportBatch(Schema.getGlobalDescribe().get(currentNode.name), csvData, currentNode.fieldPositions, currentNode.relations);
					this.batchProcessId = Database.executeBatch(batchProcess, this.genericAppConfiguration.objectLoadingBatchSize);
					this.enableObjectProcessingCheck = true;

					// Now monitor job execution
					this.monitorJobExecution = true;
					AsyncApexJob asyncJob = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];			
					this.totalBatches = asyncJob.TotalJobItems;
					this.batchesProcessed = asyncJob.JobItemsProcessed;
					this.showJobStatistics = true;
				}
			}	
		} catch(Exception e){
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.enableObjectProcessingCheck = false;
			this.disabledButton = false;
			this.errorMessage = e.getMessage();
		}	
	}


	private void processTimeShiftingObjects(){
		
		if(this.timeShiftingItems.size() > 0){
			WaveTimeShiftingItem currentNode = this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex);

			this.logMessage('Loading ' + currentNode.fieldsToTimeShift.size() + ' fields for time shifting for ' + currentNode.objectTypeName + ' object...');

			// Start the batch process
			TimeShiftingBatch batchProcess = new TimeShiftingBatch(currentNode.objectTypeName, currentNode.fieldsToTimeShift, currentNode.appType);
			this.batchProcessId = Database.executeBatch(batchProcess, this.genericAppConfiguration.timeShiftingBatchSize);

		} 
		else{
			this.logMessage('There are no fields for time shifting.');
			this.finishTimeShiftingProcess();			
		}

	}

	private void finishTimeShiftingProcess(){
		this.disabledButton = false;
		this.currentTimeShiftingNodeIndex = 0;
		this.timeShiftingItems.clear();
		this.logMessage('Done.');

		if(this.selectedInstallationProcess == 'timeShifting'){
			this.successMessage = 'The Time Shifting process has finished successfully.';
			WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Time Shifting completed successfully', 'The Time Shifting process of your SDO data has finished successfully.');
		}
	}

	public PageReference checkObjectLoadingStatus(){
		
		try{
			if(!String.isBlank(this.batchProcessId)){

				WaveApplicationObject currentNode = this.objectsNodes.get(this.currentNodeIndex);
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
				
				if(lstJobs.size() > 0){

					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'The process was interrupted due to errors while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object. See logs for details.';
							this.currentNodeIndex = 0;
							currentNode.currentDataIndex = 0;
							this.objectsNodes.clear();
							this.jobStatusDsc = '';
							this.disabledButton = false;

							// Rollback
							this.rollbackProcess(this.errorMessage, '');
						}
						else {
							// Completed entire job, inspect if there are more data files 
							// within the current node
							if(currentNode.currentDataIndex < currentNode.additionalDataFiles){
								currentNode.currentDataIndex = currentNode.currentDataIndex + 1;
								this.processCurrentObjectLoadNode();
							}
							else{
								// Entire node finished, reset currentNode.currentDataIndex
								currentNode.currentDataIndex = 0;
								
								// now check whether it was the last one
								if(this.currentNodeIndex == this.objectsNodes.size() - 1){
									this.objectsNodes.clear();
									this.currentTimeShiftingNodeIndex = 0;
									this.enableObjectProcessingCheck = false;

									/*if(String.isNotBlank(this.selectedAppMetadata.userProfilePicturesUrl)){
										this.logMessage('Loading user profile photos...');
										utils.uploadUsersPhotos(this.genericAppConfiguration.baseUrl + this.selectedAppMetadata.userProfilePicturesUrl);
										this.logMessage('User profile photos loaded successfully.');
									}*/

									this.disabledButton = false;
									this.logMessage('Done.');
									this.successMessage = 'Data loaded successfully.';								
									WaveConfiguratorUtils.sendEmail(this.emailAddress, 'Prep Core Data completed successfully', 'The Prep Core Data has finished successfully.');
								}
								else {
									// There are more nodes to process, increment index and reset
									// currentNode.currentDataIndex
									this.currentNodeIndex = this.currentNodeIndex + 1;
									this.processCurrentObjectLoadNode();
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
						this.currentNodeIndex = 0;
						this.disabledButton = false;
						this.objectsNodes.clear();
						this.jobStatusDsc = '';

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while loading data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
						this.currentNodeIndex = 0;
						this.disabledButton = false;
						this.objectsNodes.clear();
						this.jobStatusDsc = '';

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());

			this.jobStatusDsc = '';
			this.objectsNodes.clear();
			this.currentNodeIndex = 0;
			this.disabledButton = false;
			
			// Rollback
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}

		return null;
	}

	public PageReference checkTimeShiftingStatus(){
		
		try {
			if(!String.isBlank(this.batchProcessId)){
				WaveTimeShiftingItem currentNode = this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex);
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
				
				if(lstJobs.size() > 0){

					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'The process was interrupted due to errors while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object. See logs for details.';
							this.currentTimeShiftingNodeIndex = 0;
							this.timeShiftingItems.clear();
							this.jobStatusDsc = '';
							this.disabledButton = false;

							// Rollback
							this.rollbackProcess(this.errorMessage, '');
						}
						else {
							// now check whether it was the last one
							if(this.currentTimeShiftingNodeIndex == this.timeShiftingItems.size() - 1){
								this.finishTimeShiftingProcess();
							}
							else {
								// There are more nodes to process, increment index and reset
								this.currentTimeShiftingNodeIndex = this.currentTimeShiftingNodeIndex + 1;
								this.processTimeShiftingObjects();
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object.';
						this.currentTimeShiftingNodeIndex = 0;
						this.timeShiftingItems.clear();
						this.jobStatusDsc = '';
						this.disabledButton = false;

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while time shifting data for the ' + this.timeShiftingItems.get(this.currentTimeShiftingNodeIndex).objectTypeName + ' object.';
						this.currentTimeShiftingNodeIndex = 0;
						this.timeShiftingItems.clear();
						this.jobStatusDsc = '';
						this.disabledButton = false;

						// Rollback
						this.rollbackProcess(this.errorMessage, '');
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			
			this.jobStatusDsc = '';
			this.timeShiftingItems.clear();
			this.currentTimeShiftingNodeIndex = 0;
			this.disabledButton = false;

			// Rollback
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}

		return null;
	}

	public PageReference displayMetadataResponse()
	{
		// Display the response from the client side Metadata API callout
		if(this.MetadataResponse.length()==0)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Remote Site Setting ' + RemoteSiteName + ' has been created. Now you can continue with Wave Apps instalation.' ));
			MetadataConnectionWarning = false;
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, this.MetadataResponse));
			MetadataConnectionWarning = true;
		}
		return null;
	}

	private void rollbackProcess(String mainMessage, String stackTrace){

		this.disabledButton = false;
		this.enableObjectProcessingCheck = false;
		this.enableTimeShiftingCheck = false;
	}

	public void launchObjectsLoading(){
		if(this.objectsNodes.size() > 0){
			// We start loading data for each object
			this.logMessage('This process can take up to 30 minutes. We will refresh status every 5 seconds.');
			this.currentNodeIndex = 0;
			this.disabledButton = true;

			// This launchs all the process of loading data to salesforce objects
			this.processCurrentObjectLoadNode();
		}
		else {
			this.logMessage('There are no objects to load.');
		}
	}

	private void launchRecordTypeCreation(){
		if(this.objectsRecordTypesMatrix.size() > 0){
			this.currentObjectIndex = 0;
			this.currentRecordTypeIndex = 0;
			this.processCurrentRecordType(true);
			this.processingRecordTypes = true;
		}
	}

	public void loadAllObjects(){
		try {
			if(this.installationStep == 'LoadObjects'){
				this.launchObjectsLoading();				
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.installationStep = '';

			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
		finally {
			// We reset this, don't want to re-execute this method. If we don't do this, 
			// page will recall this method.
			this.installationStep = '';
		}

	}


	public void executeSelectedProcess(){

		Boolean passedValidation = true;
		this.resetMessages();

		try{
			if(this.selectedInstallationProcess == 'createMetadata'){
				this.disabledButton = true;
				this.selectAppMetadata();

				if(this.selectedAppMetadata.objects != null){
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process

					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
						this.addRecordTypeNodes(wmaObj);
					}

					this.objectsNodes = lstObjects;
					createObjectsAndFields(this.objectsNodes);
				}
			}
			else if(this.selectedInstallationProcess == 'timeShifting'){
				this.disabledButton = true;
				this.selectAppMetadata();
				
				if(this.selectedAppMetadata.objects != null){	
					this.timeShiftingItems.clear();
				
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						this.addTimeShiftingNode(wmaObj);
					}

					this.currentTimeShiftingNodeIndex = 0;
					this.enableTimeShiftingCheck = true;
					this.processTimeShiftingObjects();
				}
			}
			else if(this.selectedInstallationProcess == 'loadObjects'){
				this.disabledButton = true;
				this.selectAppMetadata();

				if(this.selectedAppMetadata.objects != null){
					this.timeShiftingItems.clear();
				
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						this.addTimeShiftingNode(wmaObj);
					}
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
						this.addRecordTypeNodes(wmaObj);
					}

					this.objectsNodes = lstObjects;
					createObjectsAndFields(this.objectsNodes);
				}
			}
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.disabledButton = false;
			this.installationStep = '';
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
	}

	public void addRecordTypeNodes(WaveMetadataApplicationObject wmaObj){
		
		if(wmaObj.recordTypes != null && wmaObj.recordTypes.size() > 0){
			
			List<SF_MetadataUtils.RecordTypeSpecification> recordTypesToCreate = new List<SF_MetadataUtils.RecordTypeSpecification>();
			
			for(WaveRecordTypeItem rt: wmaObj.recordTypes){
				SF_MetadataUtils.RecordTypeSpecification rtSpec = new SF_MetadataUtils.RecordTypeSpecification();
				rtSpec.ObjectName = wmaObj.name;
				rtSpec.Name = rt.Label;
				rtSpec.DeveloperName = rt.developerName;
				rtSpec.BusinessProcessName = rt.businessProcessName;

				recordTypesToCreate.add(rtSpec);
			}

			if(recordTypesToCreate.size() > 0){
				this.objectsRecordTypesMatrix.add(recordTypesToCreate);
			}
		}
		
	}

	public void addTimeShiftingNode(WaveMetadataApplicationObject wmaObj){
		if(wmaObj.dateFieldsToShift != null && wmaObj.dateFieldsToShift.size() > 0){
			WaveTimeShiftingItem timeShiftingItem = new WaveTimeShiftingItem();
			timeShiftingItem.appType = this.selectedAppMetadata.appType;
			timeShiftingItem.objectTypeName = wmaObj.Name;
			timeShiftingItem.fieldsToTimeShift = wmaObj.dateFieldsToShift;

			this.timeShiftingItems.add(timeShiftingItem);
		}
	}

	public WaveApplicationRow selectAppMetadata(){
		Integer appIndex = this.appIndexes.get(this.selectedWaveApp);
		WaveApplicationRow appRow = this.applicationRows.get(appIndex);
		// Retrieve and parse metadata
		HttpRequest req = new HttpRequest();
		req.setEndpoint(appRow.MetadataUrl);
        req.setMethod('GET');
		Http http = new Http();
        HTTPResponse res = http.send(req);

		String jsonMetadata = res.getBody();
		this.selectedAppMetadata = (WaveMetadataApplication)JSON.deserialize(jsonMetadata, WaveMetadataApplication.class);
		return appRow;
	}

	public void createObjectsAndFields(List<WaveApplicationObject> lstObjects){
		
		List<String> taskFieldErrors = SF_MetadataUtils.assignAccessToField('Task', 'WhatId');
		String errors = '';

		if(taskFieldErrors.size() > 0){
			for(String error: taskFieldErrors){
				errors += error;
			}

			throw new WaveConfiguratorException('WhatId field in Task object could not be granted. Cause: ' + errors);
		}

		List<String> eventFieldErrors = SF_MetadataUtils.assignAccessToField('Event', 'WhatId');
		
		if(eventFieldErrors.size() > 0){
			for(String error: eventFieldErrors){
				errors += error;
			}

			throw new WaveConfiguratorException('WhatId field in Event object could not be granted. Cause: ' + errors);
		}

		// Check if there are objects data to load
		if(lstObjects.size() > 0){						
			
			// Objects and fields Setup
			for(WaveApplicationObject waObj: lstObjects) {
				List<SF_MetadataUtils.CustomFieldSpecification> fieldsToCreate = new List<SF_MetadataUtils.CustomFieldSpecification>();

				// Check fields existence using waObj.fields property
				for(WaveApplicationObjectField field: waObj.fields) {
						
					// If field doesn't exist, create it using field properties
					if(field.Name.endsWithIgnoreCase('__c') && !SF_MetadataUtils.fieldExists(waObj.name, field.Name)){
						SF_MetadataUtils.CustomFieldSpecification fieldSpec = new SF_MetadataUtils.CustomFieldSpecification();
						fieldSpec.ObjectName = waObj.name;
						fieldSpec.Name = field.Name;
				    	fieldSpec.Label = field.Label;
				    	fieldSpec.Type = field.Type;
						fieldSpec.ReferenceTo = field.ReferenceTo;
						fieldSpec.Length = field.Length;
						fieldSpec.Precision = field.Precision;
						fieldSpec.Scale = field.Scale;
						fieldSpec.IsExternalId = field.IsExternalId;
						fieldSpec.IsRequired = field.IsRequired;
						fieldSpec.DefaultValue = field.DefaultValue;
						
						fieldsToCreate.add(fieldSpec);
					}
				}

				if(fieldsToCreate.size() > 0){
					this.objectsAndFieldsMatrix.add(fieldsToCreate);
				}
			}

			if(this.objectsAndFieldsMatrix.size() > 0){
				// We have metadata to process
				this.currentObjectIndex = 0;
				this.currentFieldIndex = 0;
				this.processCurrentObjectAndFieldsMetadata(true);
				this.processingObjectsAndFieldsMetadata = true;
			}
			else {
				// We DON'T have metadata to process
				this.logMessage('No need to create new objects and fields.');
				
				/*if(this.selectedInstallationProcess == 'loadObjects'){
					// We chain this with object data loading
					this.launchObjectsLoading();
				}
				else if(this.selectedInstallationProcess == 'createMetadata'){
					this.disabledButton = false;
				}*/

				if(this.objectsRecordTypesMatrix.size() > 0){
					this.launchRecordTypeCreation();
				}
				else {
					
					if(this.selectedInstallationProcess == 'loadObjects'){
						// We chain this with object data loading
						this.launchObjectsLoading();
					}
					else if(this.selectedInstallationProcess == 'createMetadata'){
						this.disabledButton = false;
					}
				}
			}
		} 
	}

	private void processCurrentRecordType(Boolean startingWithObject){
		SF_MetadataUtils.RecordTypeSpecification initialRecordType = this.objectsRecordTypesMatrix.get(this.currentObjectIndex).get(this.currentRecordTypeIndex);
		
		if(startingWithObject){
			this.logMessage('Processing ' + initialRecordType.ObjectName + ' record type...');
		}

		CreateRecordTypesQueueable recordTypeCreationQueue = new CreateRecordTypesQueueable(initialRecordType, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(recordTypeCreationQueue);		
	}

	public PageReference checkRecordTypeCreationStatus(){
		
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingRecordTypes){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				SF_MetadataUtils.RecordTypeSpecification currentRecordType = this.objectsRecordTypesMatrix.get(this.currentObjectIndex).get(this.currentRecordTypeIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object. See logs for details.';
							this.currentObjectIndex = 0;
							this.currentRecordTypeIndex = 0;
							this.processingRecordTypes = false;
							this.disabledButton = false;
						}
						else {
							// now check whether it was the last one
							List<SF_MetadataUtils.RecordTypeSpecification> currentRecordTypeList = this.objectsRecordTypesMatrix.get(this.currentObjectIndex);

							if(this.currentObjectIndex == this.objectsRecordTypesMatrix.size() - 1){
								
								if(this.currentRecordTypeIndex == currentRecordTypeList.size() - 1){
									this.currentObjectIndex = 0;
									this.currentRecordTypeIndex = 0;
									this.objectsRecordTypesMatrix.clear();
									this.processingRecordTypes = false;
									this.disabledButton = false;
									this.logMessage('All needed metadata was created successfully.');

									if(this.selectedInstallationProcess == 'loadObjects'){
										this.launchObjectsLoading();
									}
									else if(this.selectedInstallationProcess == 'fullInstallation') {
										// Now we configure step to begin loading the edgemarts
										this.installationStep = 'LoadEdgemarts';
									}
								}
								else{
									this.currentRecordTypeIndex = this.currentRecordTypeIndex + 1;
									this.processCurrentRecordType(false);
								}
							}
							else {
								if(this.currentRecordTypeIndex == currentRecordTypeList.size() - 1){
									this.currentObjectIndex = this.currentObjectIndex + 1;
									this.currentRecordTypeIndex = 0;
									this.processCurrentRecordType(true);
								}
								else{
									this.currentRecordTypeIndex = this.currentRecordTypeIndex + 1;
									this.processCurrentRecordType(false);
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object. See logs for details.';
						this.currentObjectIndex = 0;
						this.currentRecordTypeIndex = 0;
						this.processingRecordTypes = false;
						this.disabledButton = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while processing ' + currentRecordType.Name + ' record type for the ' + currentRecordType.ObjectName + ' object. See logs for details.';
						this.currentObjectIndex = 0;
						this.currentRecordTypeIndex = 0;
						this.processingRecordTypes = false;
						this.disabledButton = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentObjectIndex = 0;
			this.currentRecordTypeIndex = 0;
			this.processingRecordTypes = false;
			this.disabledButton = false;
			this.objectsRecordTypesMatrix.clear();
		}

		return null;
	}

	private void processCurrentObjectAndFieldsMetadata(Boolean startingWithObject){

		SF_MetadataUtils.CustomFieldSpecification initialField = this.objectsAndFieldsMatrix.get(this.currentObjectIndex).get(this.currentFieldIndex);
		
		if(startingWithObject){
			this.logMessage('Processing ' + initialField.ObjectName + ' object metadata...');
		}

		if(!SF_MetadataUtils.objectExists(initialField.ObjectName)){
			this.logMessage(initialField.ObjectName + ' doesn\'t exists. Attempting to create it...');										
		}

		CreateObjectsAndFieldsQueueable metadataCreationQueue = new CreateObjectsAndFieldsQueueable(initialField, UserInfo.getSessionId());
		this.queueProcessId = System.enqueueJob(metadataCreationQueue);
	}

	public PageReference checkMetadataCreationStatus(){
		
		try {
			if(!String.isBlank(this.queueProcessId) && this.processingObjectsAndFieldsMetadata){
				List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.queueProcessId];
				SF_MetadataUtils.CustomFieldSpecification currentField = this.objectsAndFieldsMatrix.get(this.currentObjectIndex).get(this.currentFieldIndex);

				if(lstJobs.size() > 0){
					AsyncApexJob asyncJob = lstJobs.get(0);

					if(asyncJob.Status == 'Completed'){
						if(asyncJob.NumberOfErrors > 0) {
							this.errorMessage = 'Error while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + ' .See logs for details.';
							this.currentObjectIndex = 0;
							this.currentFieldIndex = 0;
							this.processingObjectsAndFieldsMetadata = false;
							this.disabledButton = false;
						}
						else {
							// now check whether it was the last one
							List<SF_MetadataUtils.CustomFieldSpecification> currentFieldList = this.objectsAndFieldsMatrix.get(this.currentObjectIndex);

							if(this.currentObjectIndex == this.objectsAndFieldsMatrix.size() - 1){
								
								if(this.currentFieldIndex == currentFieldList.size() - 1){
									this.currentObjectIndex = 0;
									this.currentFieldIndex = 0;
									this.objectsAndFieldsMatrix.clear();
									this.processingObjectsAndFieldsMetadata = false;
									this.disabledButton = false;
									this.logMessage('All needed metadata was created successfully.');
									
									this.launchRecordTypeCreation();

									/*if(this.selectedInstallationProcess == 'loadObjects'){
										this.launchObjectsLoading();
									}
									else if(this.selectedInstallationProcess == 'fullInstallation') {
										// Now we configure step to begin loading the edgemarts
										this.installationStep = 'LoadEdgemarts';
									}*/
								}
								else{
									this.currentFieldIndex = this.currentFieldIndex + 1;
									this.processCurrentObjectAndFieldsMetadata(false);
								}
							}
							else {
								if(this.currentFieldIndex == currentFieldList.size() - 1){
									this.currentObjectIndex = this.currentObjectIndex + 1;
									this.currentFieldIndex = 0;
									this.processCurrentObjectAndFieldsMetadata(true);
								}
								else{
									this.currentFieldIndex = this.currentFieldIndex + 1;
									this.processCurrentObjectAndFieldsMetadata(false);
								}
							}
						}		
					}
					else if(asyncJob.Status == 'Aborted'){
						this.errorMessage = 'The process was aborted while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + ' .See logs for details.';
						this.currentObjectIndex = 0;
						this.currentFieldIndex = 0;
						this.processingObjectsAndFieldsMetadata = false;
						this.disabledButton = false;
					}
					else if(asyncJob.Status == 'Failed'){
						this.errorMessage = 'The process failed while processing metadata for the ' + currentField.ObjectName + ' object. Field: ' + currentField.Name + ' .See logs for details.';
						this.currentObjectIndex = 0;
						this.currentFieldIndex = 0;
						this.processingObjectsAndFieldsMetadata = false;
						this.disabledButton = false;
					}
				}
			}
		}
		catch(Exception e) {
			this.errorMessage = e.getMessage();
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.currentObjectIndex = 0;
			this.currentFieldIndex = 0;
			this.processingObjectsAndFieldsMetadata = false;
			this.disabledButton = false;
			this.objectsAndFieldsMatrix.clear();
		}

		return null;
	}

	private void logMessage(String msg){
		DateTime dtNow = DateTime.now();
		this.processingLog.add(String.format('[{0}] {1}', new String[]{ dtNow.format('yyyyMMdd HH:mm:ss') , msg }));
	}
}