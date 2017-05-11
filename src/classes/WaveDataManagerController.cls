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
	public static final String genericAppConfigurationFileName = 'GenericAppConfiguration';
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
		this.MetadataResponse = '';
		this.installationStep = '';
		this.enableTimeShiftingCheck = false;
		this.enableObjectProcessingCheck = false;
		this.processingObjectsAndFieldsMetadata = false;
		this.selectedInstallationProcess = 'fullInstallation';
	}

	public PageReference pageLoad()
	{
		// Get Host Domain
		Host = ApexPages.currentPage().getHeaders().get('Host');
		
		try{

			//Get App Configuration File
			genericAppConfiguration = utils.getAppConfiguration(genericAppConfigurationFileName);
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
				applicationRows = WaveConfiguratorUtils.getWaveApplications(genericAppConfiguration.waveApplicationsUrl);			
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

	public void installApp(){
		
		this.resetMessages();

		// Start with validations
		Boolean passedValidation = true;

		if(String.isBlank(this.folderName)){
			passedValidation = false;
			this.errorMessage = 'A folder/app name must be specified.';
		}

		if(String.isBlank(this.folderLabel)){
			passedValidation = false;
			this.errorMessage = 'A folder/app label name must be specified.';
		}

		if(String.isBlank(this.dataflowName)){
			passedValidation = false;
			this.errorMessage = 'A dataflow name must be specified.';
		}

		if(String.isBlank(this.dataflowLabel)){
			passedValidation = false;
			this.errorMessage = 'A dataflow label must be specified.';
		}

		if(WaveConfiguratorUtils.folderExists(this.folderName)){
			passedValidation = false;
			this.errorMessage = 'The folder ' + this.folderName + ' already exists.';
		}

		if(WaveConfiguratorUtils.dataflowExistsByName(this.dataflowName)){
			passedValidation = false;
			this.errorMessage = 'The dataflow ' + this.dataflowName + ' already exists.';
		}

		if(!String.isBlank(this.emailAddress)){
			if(WaveConfiguratorUtils.isInvalidEmail(this.emailAddress)){
				passedValidation = false;
				this.errorMessage = 'The email address ' + this.emailAddress + ' is invalid.';
			}
		}		

		if(passedValidation){
			
			this.disabledButton = true;
			try {

				WaveApplicationRow appRow = selectAppMetadata();

				if(this.selectedAppMetadata != null){
					
					// Create app/folder
					
					this.folderId = this.createFolder(appRow.Label, this.folderName);

					if(this.selectedAppMetadata.objects != null){
						// Retrieve objects to process
						for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
							List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
							this.objectsNodes.addAll(objs);
							this.addTimeShiftingNode(wmaObj);
						}
					}
					
					createObjectsAndFields(this.objectsNodes);					
				}
			}
			catch(Exception e) {
				System.debug(e.getMessage());
				System.debug(e.getStackTraceString());
				this.errorMessage = e.getMessage();
				this.disabledButton = false;
				this.rollbackProcess(e.getMessage(), e.getStackTraceString());
			}
		}
	}

	public List<WaveApplicationObject> getObjectsToProcess(WaveMetadataApplicationObject wmaObj){
		List<WaveApplicationObject> listToProcess = new List<WaveApplicationObject>();
		WaveApplicationObject rootObj = new WaveApplicationObject();
		rootObj.name = wmaObj.name;
		rootObj.url = wmaObj.url;
		rootObj.additionalDataFiles = wmaObj.additionalDataFiles;
		listToProcess.add(rootObj);

		// We process the fields metadata
		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    	List<List<String>> csvMetadata = iMockHelper.getData(wmaObj.metadataUrl, false);
    	
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
			
			/*
			IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();		
			List<List<String>> csvData;
			
			// Check whether we are in the initial chunk of CSV data or not
			if(currentNode.currentDataIndex == 0){
				
				// We start processing the initial chunk of data
				csvData = iMockHelper.getData(currentNode.url, false);

	    		if(csvData.size() > 0){
					// Will extract headers
					List<String> headers = csvData.remove(0);
					currentNode.fieldPositions = new Map<Integer, String>();
					
					for(Integer i = 0; i < headers.size(); i++) {
						currentNode.fieldPositions.put(i, headers[i]);
					}
				}

				currentObjectProcessing = currentNode.name;
			}
			else {
				String newUrl = currentNode.url.substringBeforeLast('.csv') + currentNode.currentDataIndex + '.csv';
				csvData = iMockHelper.getData(newUrl, false);
			}

			this.processingLog.add('Loading ' + csvData.size() + ' records for ' + currentNode.name + ' object...');*/		

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

				if(csvData.length() > 0){

					this.currentObjectProcessing = currentNode.name;

					this.processingLog.add('Loading records for ' + currentNode.name + ' object...');

					// Start the batch process
					CsvDataImportBatch batchProcess = new CsvDataImportBatch(Schema.getGlobalDescribe().get(currentNode.name), csvData, currentNode.fieldPositions, currentNode.relations);
					this.batchProcessId = Database.executeBatch(batchProcess);
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

			this.processingLog.add('Loading ' + currentNode.fieldsToTimeShift.size() + ' fields for time shifting for ' + currentNode.objectTypeName + ' object...');

			// Start the batch process
			TimeShiftingBatch batchProcess = new TimeShiftingBatch(currentNode.objectTypeName, currentNode.fieldsToTimeShift, currentNode.appType);
			this.batchProcessId = Database.executeBatch(batchProcess);

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

									if(this.selectedInstallationProcess == 'fullInstallation'){
										this.enableTimeShiftingCheck = true;
										this.processTimeShiftingObjects();
									} 
									else {
										this.disabledButton = false;
										this.processingLog.add('Done.');
										this.successMessage = 'Data loaded successfully.';
									}
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
								WaveConfiguratorUtils.sendEmail(this.emailAddress, this.dataflowLabel);
								this.disabledButton = false;
								this.currentTimeShiftingNodeIndex = 0;
								this.timeShiftingItems.clear();
								this.processingLog.add('Done.');

								if(this.selectedInstallationProcess == 'timeShifting'){
									this.successMessage = 'The Time Shifting process has finished successfully.';
								}
								else{
									this.successMessage = 'Application installed successfully. Please open Wave Analytics / Data Manager to run the corresponding Dataflow.';
								}
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

	private void loadEdgemart(Edgemart e, String pFolderId){

		this.processingLog.add('Loading edgmart data for: ' + e.Label);

		utils.loadEdgemart(e, pFolderId);

        this.processingLog.add('Edgmart data loaded successfully.');
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

	/*private String loadDashboardWithURL(String dashJsonUrl, String pFolderId){
		HttpRequest req = new HttpRequest();
		req.setEndpoint(dashJsonUrl);
        req.setMethod('GET');
		Http http = new Http();
        HTTPResponse res = http.send(req);

		return WaveConfiguratorUtils.insertWaveDashboard(res.getBody(), pFolderId, this.edgemartNamesToSave);
	}*/

	private String loadDashboardWithJSON(String dashJson, String pFolderId){
		return utils.insertWaveDashboard(dashJson, pFolderId, null);
	}

	private void updateDashboard(String dashJsonUrl, String dashboardId, String pFolderId){
		HttpRequest req = new HttpRequest();
		req.setEndpoint(dashJsonUrl);
        req.setMethod('GET');
		Http http = new Http();
        HTTPResponse res = http.send(req);

		utils.updateWaveDashboard(res.getBody(), dashboardId, pFolderId, this.edgemartNamesToSave, this.dashboardsIdsByName);
	}

	private void rollbackProcess(String mainMessage, String stackTrace){

		this.disabledButton = false;
		this.enableObjectProcessingCheck = false;
		this.enableTimeShiftingCheck = false;

		// We get the dataflow ID
		String dataflowId = WaveConfiguratorUtils.getDataflowIdByName(this.dataflowName);

		// Delete recently created app/folder here
		WaveConfiguratorUtils.deleteFolder(this.folderId, dataflowId, UserInfo.getSessionId(), genericAppConfiguration.apiVersion, mainMessage, stackTrace);

		// Delete recently created dataflow
		//String dataflowId = WaveConfiguratorUtils.getDataflowIdByName(this.dataflowName);
		//WaveConfiguratorUtils.deleteDataflow(dataflowId, UserInfo.getSessionId(), genericAppConfiguration.apiVersion);
	}

	// Edgemarts
	public void loadAllEdgemarts(){
		try {
			if(this.installationStep == 'LoadEdgemarts'){

				this.edgemarts = this.selectedAppMetadata.edgemarts;

				if(this.edgemarts != null){
					
					
					// Get all the datasets names
					List<WaveAsset> waveAssets = new List<WaveAsset>();
					String jsonDatasets = utils.getWaveAssetsJSON('datasets', null);
		            WaveDatasetsResponse datasetsResponse = (WaveDatasetsResponse)JSON.deserialize(jsonDatasets, WaveDatasetsResponse.class);
		            
		            while(datasetsResponse != null && datasetsResponse.datasets != null){
		                
		                for(WaveDataset dataset : datasetsResponse.datasets){
		                    waveAssets.add(dataset);
		                }

		                if(datasetsResponse.nextPageUrl != null){
		                    jsonDatasets = utils.getWaveAssetsJSON('datasets', datasetsResponse.nextPageUrl);
		                    datasetsResponse = (WaveDatasetsResponse)JSON.deserialize(jsonDatasets, WaveDatasetsResponse.class);
		                }
		                else {
		                    datasetsResponse = null;
		                }
		            }

		            // Here we should have all the datasets, we load the map for searches
		            this.edgemartNamesToSave = new Map<String, String>();

		            for(WaveAsset dataset : waveAssets){
		            	this.edgemartNamesToSave.put(dataset.name, dataset.name);
		            }

					for(Edgemart edg : this.edgemarts){
						// First we have to check dataset's name existance in wave
						Integer iSuffix = 0;
						String edgNameCandidate = edg.Name;

						while(this.edgemartNamesToSave.containsKey(edgNameCandidate)){
							iSuffix++;
							edgNameCandidate = edg.Name + iSuffix;
						}

						// Now we will use edgNameCandidate as edgemart's name to avoid API name collision
						this.edgemartNamesToSave.put(edg.Name, edgNameCandidate);
						edg.Name = edgNameCandidate;

						this.loadEdgemart(edg, this.folderId);
					}
				}

				// Configure next step
				this.installationStep = 'CreateDataflow';
			}
			else {
				// We reset
				this.installationStep = '';
			}			
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.installationStep = '';

			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
	}

	// Create dataflow
	// Create dataflow version
	// Link dataflow to dataflow version current id
	public void createDataflowStep(){
		try{
			if(this.installationStep == 'CreateDataflow'){
				this.processingLog.add('Creating ' + this.dataflowName + ' dataflow...');
						
				String dataflowResponse = utils.createDataflow(this.dataflowName, this.dataflowLabel, this.folderId);

				if(dataflowResponse.contains('Error')){
					this.processingLog.add(dataflowResponse);
					throw new WaveConfiguratorException('Dataflow for ' + this.dataflowLabel + ' could not be created. Check debug logs.');
				}

				String dataflowId = dataflowResponse;

				// Dataflow Definition JSON file
				HttpRequest req = new HttpRequest();
				req.setEndpoint(this.selectedAppMetadata.dataflowLocation);
		    	req.setMethod('GET');
				Http http = new Http();
		    	HTTPResponse resDf = http.send(req);

		    	if(WaveConfiguratorUtils.checkStatus(resDf)){
					String dfDefJsonBody = resDf.getBody();
					if(String.isBlank(dfDefJsonBody)){
						throw new WaveConfiguratorException('Invalid Dataflow Definition JSON for Wave Application. Check URL: ' + selectedAppMetadata.dataflowLocation);
					}
					
					this.dataflowDefinitionJson = dfDefJsonBody;						
				}
				else {
					throw new WaveConfiguratorException('Unable to retrieve Dataflow Definition JSON file for Wave Application.');							
				}
				
				// folderId placeholder substitution
				String jsonDataflowDefToSave = this.dataflowDefinitionJson.replace('<folderId>', this.folderId);

				// Dataset names substitution
				for(String dsDesiredName : this.edgemartNamesToSave.keySet()){
					jsonDataflowDefToSave = jsonDataflowDefToSave.replace('<' + dsDesiredName + '>', this.edgemartNamesToSave.get(dsDesiredName));
				}

				String versionId = utils.createDataflowVersion(dataflowId, jsonDataflowDefToSave);
				utils.linkDataflowToVersion(dataflowId, versionId);

				this.processingLog.add('Dataflow created successfully.');
				this.installationStep = 'LoadDashboards';
			}
			else {
				// We reset
				this.installationStep = '';
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.installationStep = '';

			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}
	}

	public void loadAllDashboards(){
		try {
			if(this.installationStep == 'LoadDashboards'){
				if(this.selectedAppMetadata.dashboards != null && this.selectedAppMetadata.dashboards.size() > 0){
					
					this.processingLog.add('Encountered ' + this.selectedAppMetadata.dashboards.size() + ' dashboards for the application.');
					
					// First we insert dummy dashboards to get the IDs
					List<StaticResource> srList = [SELECT Body FROM StaticResource WHERE Name = 'DummyWaveDashboardJson'];
					if(srList.size() == 0){
						throw new WaveConfiguratorException('DummyWaveDashboardJson Static Resource not found.');
					}
					
					// We create the dummy dashboards and the Map for storing resulting IDs
					this.dashboardsIdsByName = new Map<String, String>();
					String dummyDashboardJson = srList.get(0).Body.toString();
					
					for(WaveMetadataApplicationDashboard dashObj : this.selectedAppMetadata.dashboards){
						String dashId = this.loadDashboardWithJSON(dummyDashboardJson, this.folderId);
						this.dashboardsIdsByName.put(dashObj.Name, dashId);
					}

					// At this point we should have all dashboards created
					// No we update them to reflect links between them and datasets
					for(WaveMetadataApplicationDashboard dashObj : this.selectedAppMetadata.dashboards){
						
						this.processingLog.add('Creating ' + dashObj.Name + ' dashboard...');
						String dashJsonUrl = dashObj.JsonUrl;
						String dashId = this.dashboardsIdsByName.get(dashObj.Name);

						this.updateDashboard(dashJsonUrl, dashId, this.folderId);
					}

					this.processingLog.add('All dashboards were successfully created.');
				}
				else {
					this.processingLog.add('The application doesn\'t contain any dashboard.');
				}

				if(this.selectedInstallationProcess == 'fullInstallation'){
					this.installationStep = 'LoadObjects';
				} 
				else {
					this.installationStep = '';
					this.processingLog.add('Done.');
					this.successMessage = 'Application installed successfully. Please open Wave Analytics / Data Manager to run the corresponding Dataflow.';
					this.disabledButton = false;
				}
				
			}
			else {
				// We reset
				this.installationStep = '';
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
			this.installationStep = '';
			this.rollbackProcess(e.getMessage(), e.getStackTraceString());
		}		
	}

	public void launchObjectsLoading(){
		if(this.objectsNodes.size() > 0){
			// We start loading data for each object
			this.processingLog.add('This process can take up to 30 minutes. We will refresh status every 5 seconds.');
			this.currentNodeIndex = 0;
			this.disabledButton = true;

			// This launchs all the process of loading data to salesforce objects
			this.processCurrentObjectLoadNode();
		}
		else {
			this.processingLog.add('There are no objects to load.');
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
			
			if(this.selectedInstallationProcess == 'fullInstallation'){
				installApp();
			} 

			else if(this.selectedInstallationProcess == 'createMetadata'){
				this.disabledButton = true;
				this.selectAppMetadata();

				if(this.selectedAppMetadata.objects != null){
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
					}

					this.objectsNodes = lstObjects;
					createObjectsAndFields(this.objectsNodes);
				}
			}

			else if(this.selectedInstallationProcess == 'createWaveApp'){

				if(String.isBlank(this.folderName)){
					passedValidation = false;
					this.errorMessage = 'A folder/app name must be specified.';
				}

				if(String.isBlank(this.folderLabel)){
					passedValidation = false;
					this.errorMessage = 'A folder/app label name must be specified.';
				}

				if(WaveConfiguratorUtils.folderExists(this.folderName)){
					passedValidation = false;
					this.errorMessage = 'The folder ' + this.folderName + ' already exists.';
				}

				if(String.isBlank(this.dataflowLabel)){
					passedValidation = false;
					this.errorMessage = 'A dataflow label must be specified.';
				}

				if(WaveConfiguratorUtils.dataflowExistsByName(this.dataflowName)){
					passedValidation = false;
					this.errorMessage = 'The dataflow ' + this.dataflowName + ' already exists.';
				}

				if(passedValidation){
					this.disabledButton = true;
					this.selectAppMetadata();
					this.folderId = this.createFolder(this.folderLabel, this.folderName);
					this.installationStep = 'LoadEdgemarts';
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
					
					List<WaveApplicationObject> lstObjects = new List<WaveApplicationObject>();
					// Retrieve objects to process
					for(WaveMetadataApplicationObject wmaObj: this.selectedAppMetadata.objects) {
						List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
						lstObjects.addAll(objs);
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

	public void addTimeShiftingNode(WaveMetadataApplicationObject wmaObj){
		if(wmaObj.dateFieldsToShift != null && wmaObj.dateFieldsToShift.size() > 0){
			WaveTimeShiftingItem timeShiftingItem = new WaveTimeShiftingItem();
			timeShiftingItem.appType = this.selectedAppMetadata.appType;
			timeShiftingItem.objectTypeName = wmaObj.Name;
			timeShiftingItem.fieldsToTimeShift = wmaObj.dateFieldsToShift;

			this.timeShiftingItems.add(timeShiftingItem);
		}
	}

	public String createFolder(String label, String pFolderName){
		// Create app/folder
		String folderIdToReturn;

		this.processingLog.add('Creating ' + pFolderName + ' folder/application...');

		folderIdToReturn = utils.insertFolder(label, pFolderName);
		
		this.processingLog.add(pFolderName + ' folder/application created successfully.');

		return folderIdToReturn;
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

			this.currentObjectIndex = 0;
			this.currentFieldIndex = 0;
			this.processCurrentObjectAndFieldsMetadata(true);
			this.processingObjectsAndFieldsMetadata = true;
		} 
	}

	private void processCurrentObjectAndFieldsMetadata(Boolean startingWithObject){

		SF_MetadataUtils.CustomFieldSpecification initialField = this.objectsAndFieldsMatrix.get(this.currentObjectIndex).get(this.currentFieldIndex);
		
		if(startingWithObject){
			this.processingLog.add('Processing ' + initialField.ObjectName + ' object metadata...');
		}

		if(!SF_MetadataUtils.objectExists(initialField.ObjectName)){
			this.processingLog.add(initialField.ObjectName + ' doesn\'t exists. Attempting to create it...');										
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
									this.processingLog.add('All needed metadata was created successfully.');

									if(this.selectedInstallationProcess == 'loadObjects'){
										this.launchObjectsLoading();
									}
									else if(this.selectedInstallationProcess == 'fullInstallation') {
										// Now we configure step to begin loading the edgemarts
										this.installationStep = 'LoadEdgemarts';
									}
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
									this.processCurrentObjectAndFieldsMetadata(false);
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
}