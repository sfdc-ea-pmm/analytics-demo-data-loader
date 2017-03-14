public with sharing class WaveConfiguratorUtils {
	
	public WaveConfiguratorUtils() {
		
	}

	public static List<WaveApplicationRow> getWaveApplications(String csvUrl){
		
		IMockarooHelper helper = MockarooHelperFactory.getIMockarooHelper();
		List<WaveApplicationRow> apps = new List<WaveApplicationRow>();
		List<List<String>> csvAppsData = helper.getData(csvUrl, false);
		
		if(csvAppsData.size() > 0){
			// Will extract headers
			List<String> headers = csvAppsData.remove(0);
			Map<String, Integer> fieldPositions = new Map<String, Integer>();
			
			for(Integer i = 0; i < headers.size(); i++) {
				fieldPositions.put(headers.get(i), i);
			}

			for(List<String> appCsvRow: csvAppsData) {
				WaveApplicationRow appRow = new WaveApplicationRow();
				
				if(fieldPositions.containsKey('Name')){
					appRow.Name = appCsvRow.get(fieldPositions.get('Name'));
				}
				else {
					throw new WaveConfiguratorException('Name column not found in applications csv file.');
				}

				if(fieldPositions.containsKey('Label')){
					appRow.Label = appCsvRow.get(fieldPositions.get('Label'));
				}
				else {
					throw new WaveConfiguratorException('Label column not found in applications csv file.');
				}

				if(fieldPositions.containsKey('Description')){
					appRow.Description = appCsvRow.get(fieldPositions.get('Description'));
				}
				else {
					throw new WaveConfiguratorException('Description column not found in applications csv file.');
				}

				if(fieldPositions.containsKey('MetadataUrl')){
					appRow.MetadataUrl = appCsvRow.get(fieldPositions.get('MetadataUrl'));
				}
				else {
					throw new WaveConfiguratorException('MetadataUrl column not found in applications csv file.');
				}

				apps.add(appRow);
			}
		}

		return apps;
	}

	public static void loadEdgemart(Edgemart e, String appDeveloperName){
		if(e != null){
			if(String.isNotBlank(appDeveloperName)){
				// Retrive the JSON metadata for edgemart
				Http http = new Http();
				HttpRequest req = new HttpRequest();
				req.setEndpoint(e.MetadataJsonUrl);
		        req.setMethod('GET');
				HTTPResponse res = http.send(req);

				if(checkStatus(res)){

					String jsonMetadata = res.getBody();
					// Retrieve csv data for edgemart
					req = new HttpRequest();
					req.setEndpoint(e.DataUrl);
			        req.setMethod('GET');
			        res = http.send(req);

			        if(checkStatus(res)){

			        	Blob csvBlob = Blob.valueof(res.getBody());
						InsightsExternalData iedObj = new InsightsExternalData();
						iedObj.Format = 'Csv';
				        iedObj.EdgemartAlias = e.Name;
				        iedObj.EdgemartLabel = e.Label;
				        iedObj.EdgemartContainer = appDeveloperName;
				        iedObj.Operation = 'Overwrite';
				        iedObj.Action = 'None';
				        iedObj.MetadataJson = EncodingUtil.base64Decode(EncodingUtil.base64Encode(Blob.valueOf(jsonMetadata)));

				        insert iedObj;        

				        // Add the Data
				        InsightsExternalDataPart dataPart = new InsightsExternalDataPart();
				        dataPart.InsightsExternalDataId = iedObj.Id;
				        dataPart.PartNumber = 1;
				        Integer size = csvBlob.size();
				        dataPart.DataFile = csvBlob;
				        dataPart.DataLength = size;
				        
				        insert dataPart;

				        // Final Step: Manage the Upload
				        iedObj.Action = 'Process';
				        update iedObj;

			        } 
			        else {
			        	throw new WaveConfiguratorException('Unable to retrieve CSV for edgemart: ' + e.Name + '. Check respective URL: ' + e.DataUrl);
				    }
				}
				else {
					throw new WaveConfiguratorException('Unable to retrieve JSON metadata for edgemart: ' + e.Name + '. Check respective URL: ' + e.MetadataJsonUrl);
				}			
			} 
			else {
				throw new WaveConfiguratorException('The folder name can not be blank.');
			}
		} 
		else {
			throw new WaveConfiguratorException('Edgemart can not be null.');
		}		
	}

	private static boolean checkStatus(HTTPResponse r){
		return r.getStatusCode() == 200;
	}
}