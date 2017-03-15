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

	public static HttpResponse httpCallout(String url, String method, Boolean sfdcApi, String parameter){
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		String totalUrl = url;

		if(sfdcApi){
			String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
			totalUrl = salesforceHost + url;

			if(method.toUpperCase() == 'DELETE'){
				totalUrl += '/' + parameter;
			}

			if(method.toUpperCase() == 'POST'){
				req.setBody(parameter);
			}
		}

		req.setMethod(method);
		req.setEndpoint(totalUrl);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());

		HttpResponse response = http.send(req);
		return response;
	}

	public static String createDataflow(String devName, String label, String folderId)
	{
		String dataflowJson = '{' + 
		'	"attributes":{' + 
		'		"type":"Dataflow"' + 
		'	},' + 
		'	"DeveloperName":"' + devName + '",' + 
  		'	"MasterLabel":"' + label + '",' + 
  		'	"State":"Active",' + 
  		'	"FolderId":"' + folderId + '",' +
  		'	"DataflowType":"User"' +
  		'}';

  		HttpResponse res = WaveConfiguratorUtils.httpCallout('/services/data/v39.0/sobjects/Dataflow', 'POST', true, dataflowJson);
  		
  		if(!WaveConfiguratorUtils.checkStatus(res)){
  			if(res.getBody().contains('errorCode')){
				List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
				System.debug('Dataflow for ' + label + ' could not be created. Detailed message: ' + r.get(0).message);
			}

  			throw new WaveConfiguratorException('Dataflow for ' + label + ' could not be created. Check debug logs.');
  		}
  		else {
  			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			if(!responseBody.success){
  				// Future: process errors property  				  			
  				throw new WaveConfiguratorException('Dataflow for ' + label + ' could not be created. Check debug logs.');
  			}
  			else {
  				return responseBody.id;
  			}
  		}
	}
}