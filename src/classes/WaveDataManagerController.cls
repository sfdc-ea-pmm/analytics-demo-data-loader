public with sharing class WaveDataManagerController {
	
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }
	public String warningMessage  { get; set; }
	public Id batchProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }
	public List<String> processingLog { get; set; }
	public Integer currentNodeIndex { get; set; }
	public List<WaveApplicationObject> objectsNodes { get; set; }

	public WaveDataManagerController() {
		this.objectsNodes = new List<WaveApplicationObject>();
		this.processingLog = new List<String>();
	}

	private void resetMessages(){
		this.errorMessage = '';
		this.successMessage = '';
		this.warningMessage = '';
		this.jobStatusDsc = '';
		this.processingLog.clear();
	}

	public void run(){
		this.resetMessages();

		try {
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveMetadata.json');
	        req.setMethod('GET');

			Http http = new Http();
	        HTTPResponse res = http.send(req);

			String jsonMetadata = res.getBody();
			WaveMetadata metadata = (WaveMetadata)JSON.deserialize(jsonMetadata, WaveMetadata.class);

			// We build the node array
			this.objectsNodes.clear();

			// We start collecting the common object to add to the node array
			if(metadata.commonObjects != null) {
				for(WaveMetadataApplicationObject wmaObj: metadata.commonObjects) {
					List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
					this.objectsNodes.addAll(objs);
				}
			}
			
			if(metadata.waveApplications != null){
				for(WaveMetadataApplication genericApp: metadata.waveApplications) {
					if(genericApp.objects != null){
						for(WaveMetadataApplicationObject wmaObj: genericApp.objects) {							
							List<WaveApplicationObject> objs = this.getObjectsToProcess(wmaObj);
							this.objectsNodes.addAll(objs);
						}
					}
				}
			}

			if(this.objectsNodes.size() > 0){
				this.currentNodeIndex = 0;
				
				SF_MetadataUtils mdUtils = new SF_MetadataUtils();

				// Objects and fields Setup
				for(WaveApplicationObject waObj: this.objectsNodes) {
					
					this.processingLog.add('Processing ' + waObj.name + ' object...');

					// Check object existence using waObj.name property					
					if(!mdUtils.objectExists(waObj.name)){
						// If object doesn't exist, create it
						this.processingLog.add(waObj.name + ' doesn\'t exists. Attempting to create it...');
						List<String> errors = mdUtils.createObject(waObj.name);
						if(errors.size() == 0){
							this.processingLog.add(waObj.name + ' object created successfully.');
						}
						else {
							this.processingLog.addAll(errors);
						}						
					}

					// Check fields existence using waObj.fields property
					for(WaveApplicationObjectField field: waObj.fields) {
						// If field doesn't exist, create it using field properties
						if(field.Name.endsWithIgnoreCase('__c') && !mdUtils.fieldExists(waObj.name, field.Name)){
							this.processingLog.add(waObj.name + '.' + field.Name + ' field doesn\'t exists. Attempting to create it...');
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

							List<String> errors = mdUtils.createField(fieldSpec);
							if(errors.size() == 0){
								this.processingLog.add(waObj.name + '.' + field.Name + ' field created successfully.');
							}
							else {
								this.processingLog.add(waObj.name + '.' + field.Name + ' field couldn\'t be created. Reasons: ');
								this.processingLog.addAll(errors);
							}
						}
					}
				}

				// Print some message at the UI to inform that setup has succeeded

				// We start loading data for each object
				//this.processNode();
			}
			else {
				this.warningMessage = 'No data to process.';
			}
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
		}
	}

	public List<WaveApplicationObject> getObjectsToProcess(WaveMetadataApplicationObject wmaObj){
		List<WaveApplicationObject> listToProcess = new List<WaveApplicationObject>();
		WaveApplicationObject rootObj = new WaveApplicationObject();
		rootObj.name = wmaObj.name;
		rootObj.url = wmaObj.url;
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
				fieldMetadata.Label = metadataRow.get(fieldPositions.get('Label'));
				fieldMetadata.Name = metadataRow.get(fieldPositions.get('Name'));
				fieldMetadata.Type = metadataRow.get(fieldPositions.get('Type'));
				fieldMetadata.ReferenceTo = metadataRow.get(fieldPositions.get('ReferenceTo'));
				fieldMetadata.Length = Integer.valueOf(metadataRow.get(fieldPositions.get('Length')));
				fieldMetadata.Precision = Integer.valueOf(metadataRow.get(fieldPositions.get('Precision')));
				fieldMetadata.Scale = Integer.valueOf(metadataRow.get(fieldPositions.get('Scale')));
				fieldMetadata.IsExternalId = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsExternalId')));
				fieldMetadata.IsRequired = Boolean.valueOf(metadataRow.get(fieldPositions.get('IsRequired')));

				rootObj.fields.add(fieldMetadata);
			}
		}

		// We process the children
		if(wmaObj.children != null) {
			// Now the children objects
			for(WaveMetadataApplicationObject chObj: wmaObj.children) {
				List<WaveApplicationObject> childrenObjs = getObjectsToProcess(chObj);
				listToProcess.addAll(childrenObjs);
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

		return listToProcess;
	}

	private void processNode(){
		WaveApplicationObject currentNode = this.objectsNodes.get(this.currentNodeIndex);
		this.processingLog.add('Processing data for ' + currentNode.name + ' object...');
		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    	List<List<String>> csvData = iMockHelper.getData(currentNode.url, false);
    	
    	if(csvData.size() > 0){
			// Will extract headers
			List<String> headers = csvData.remove(0);
			Map<Integer, String> fieldPositions = new Map<Integer, String>();
			
			for(Integer i = 0; i < headers.size(); i++) {
				fieldPositions.put(i, headers[i]);
			}

			// Start the batch process
			CsvDataImportBatch batchProcess = new CsvDataImportBatch(Schema.getGlobalDescribe().get(currentNode.name), csvData, fieldPositions, currentNode.relations);
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
			this.warningMessage = 'No data to process for the ' + currentNode.name + ' object.';
		}
	}

	public PageReference checkProcessingStatus(){
		
		if(!String.isBlank(this.batchProcessId)){
			List<AsyncApexJob> lstJobs = [SELECT CompletedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE Id = :this.batchProcessId];
			if(lstJobs.size() > 0){
				
				AsyncApexJob asyncJob = lstJobs.get(0);

				if(asyncJob.Status == 'Completed'){
					if(asyncJob.NumberOfErrors > 0) {
						this.errorMessage = 'The process failed while generating data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
						this.currentNodeIndex = 0;
						this.objectsNodes.clear();
						this.jobStatusDsc = '';
						this.processingLog.clear();
					}
					else {
						if(this.currentNodeIndex == this.objectsNodes.size() - 1){
							this.successMessage = 'The entire process finished successfully.';
							this.currentNodeIndex = 0;
							this.objectsNodes.clear();
							this.jobStatusDsc = '';
							this.processingLog.clear();
						}
						else {
							this.currentNodeIndex = this.currentNodeIndex + 1;
							this.processNode();
						}
					}					
				}
				else if(asyncJob.Status == 'Aborted'){
					this.errorMessage = 'The process was aborted while generating data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
					this.currentNodeIndex = 0;
					this.objectsNodes.clear();
					this.jobStatusDsc = '';
					this.processingLog.clear();
				}
				else if(asyncJob.Status == 'Failed'){
					this.errorMessage = 'The process failed while generating data for the ' + this.objectsNodes.get(this.currentNodeIndex).name + ' object.';
					this.currentNodeIndex = 0;
					this.objectsNodes.clear();
					this.jobStatusDsc = '';
					this.processingLog.clear();
				}
			}
		}		

		return null;
	}
}