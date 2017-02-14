public with sharing class WaveDataManagerController {
	
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }
	public Id batchProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }

	// TODO: Comment this
	private List<SObject> lstToInsert;
	private List<SObject> lstToUpdate;

	public WaveDataManagerController() {
		this.lstToInsert = new List<SObject>();
		this.lstToUpdate = new List<SObject>();
	}

	private void resetMessages(){
		this.errorMessage = '';
		this.successMessage = '';
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

			SObjectTransference processedObjs = new SObjectTransference();

			if(metadata.salesWave != null && metadata.salesWave.objects != null) {
				for(WaveMetadataApplicationObject wmaObj: metadata.salesWave.objects) {
					SObjectTransference currentObjs = this.handleDataForObject(wmaObj);
					processedObjs.sObjectsToInsert.addAll(currentObjs.sObjectsToInsert);
					processedObjs.sObjectsToUpdate.addAll(currentObjs.sObjectsToUpdate);
				}
			}

			// DML
			update processedObjs.sObjectsToUpdate;
			insert processedObjs.sObjectsToInsert;

			//System.debug('Will insert ' + processedObjs.sObjectsToInsert.size());
			//System.debug('Will update ' + processedObjs.sObjectsToUpdate.size());

			this.successMessage = 'Data Generation finished successfully.';
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
			System.debug(e.getStackTraceString());
			this.errorMessage = e.getMessage();
		}
	}

	public SObjectTransference handleDataForObject(WaveMetadataApplicationObject wmaObj){
		
		System.debug('Handling data for ' + wmaObj.name);
		System.debug('Data URL: ' + wmaObj.url);
		SObjectTransference processedObjs = new SObjectTransference();

		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
    	List<List<String>> csvData = iMockHelper.getData(wmaObj.url, false);
    	if(csvData.size() > 0){
			// Will extract headers
			List<String> headers = csvData.remove(0);
			Map<Integer, String> fieldPositions = new Map<Integer, String>();
			
			for(Integer i = 0; i < headers.size(); i++) {
				fieldPositions.put(i, headers[i]);
			}

			// Start the process
			WaveDataUtils dataUtils = new WaveDataUtils(Schema.getGlobalDescribe().get(wmaObj.name), csvData, fieldPositions);
			SObjectTransference currentObjs = dataUtils.processData();
			processedObjs.sObjectsToInsert.addAll(currentObjs.sObjectsToInsert);
			processedObjs.sObjectsToUpdate.addAll(currentObjs.sObjectsToUpdate);

			if(wmaObj.children != null) {
				// Now the children objects
				for(WaveMetadataApplicationObject chObj: wmaObj.children) {
					SObjectTransference childrenObjs = handleDataForObject(chObj);
					processedObjs.sObjectsToInsert.addAll(childrenObjs.sObjectsToInsert);
					processedObjs.sObjectsToUpdate.addAll(childrenObjs.sObjectsToUpdate);
				}
			}
		}
		else {
			// No data rows retrieved
			this.successMessage = 'No data to process.';
		}

		return processedObjs;
	}
}