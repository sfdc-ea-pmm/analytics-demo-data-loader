public with sharing class WaveDataManagerController {
	
	public String errorMessage { get; set; }
	public String successMessage  { get; set; }
	public Id batchProcessId { get; set; }
	public Boolean monitorJobExecution { get; set; }
	public Boolean showJobStatistics { get; set; }
	public Integer batchesProcessed { get; set; }
	public Integer totalBatches { get; set; }
	public String jobStatusDsc { get; set; }

	// This will hold, for each object type, all the CSV data generated for it.
	// The main reason for this structure, is to avoid the 
	// "System.CalloutException: You have uncommitted work pending. Please commit or 
	// rollback before calling out." exception.
	// This was designed to be filled with CSV data in subsequent callouts, before sending all to database.
	private Map<String, List<List<String>>> objectsDataTableInCsv;

	public WaveDataManagerController() {
		this.objectsDataTableInCsv = new Map<String, List<List<String>>>();
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

			for(WaveMetadataApplicationObject wmaObj: metadata.salesWave.objects) {
				this.createDataForObject(wmaObj);
			}

			this.successMessage = 'Data Generation finished successfully.';
		} 
		catch(Exception e) {
			System.debug(e.getMessage());
			this.errorMessage = e.getMessage();
		}
	}

	public void createDataForObject(WaveMetadataApplicationObject wmaObj){
		
		System.debug('Creating data for ' + wmaObj.name);
		System.debug('Data URL: ' + wmaObj.url);

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
			dataUtils.processData();

			// Now the children objects
			for(WaveMetadataApplicationObject chObj: wmaObj.children) {
				createDataForObject(chObj);
			}
		}
		else {
			// No data rows retrieved
			this.successMessage = 'No data to process.';
		}
	}
}