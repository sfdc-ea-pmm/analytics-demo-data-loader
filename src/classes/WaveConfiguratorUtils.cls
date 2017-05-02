public with sharing class WaveConfiguratorUtils {
	
	private String apiVersion;

	public WaveConfiguratorUtils() {
		
	}


	public GenericAppConfiguration getAppConfiguration(String configurationFileName){
		StaticResource[] sr = [SELECT Id, Body FROM StaticResource WHERE Name = :configurationFileName LIMIT 1];
		
		if(sr.size() > 0){
			String body = sr.get(0).Body.toString();
			GenericAppConfiguration appConfig = (GenericAppConfiguration)JSON.deserialize(body, GenericAppConfiguration.class);
			apiVersion = appConfig.apiVersion;

			return appConfig;
		} 
		else {
			throw new WaveConfiguratorException('The configuration file ' + configurationFileName + ' does not exist. Please add it as static resource to initialize the installation proccess.');
		}
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

	public void loadEdgemart(Edgemart e, String appDeveloperName){
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

				        String jsonToSend = '{' + 
							'	"attributes":{' + 
							'		"type":"InsightsExternalData"' + 
							'	},' + 
							'	"Format":"csv",' + 
					  		'	"EdgemartAlias":"' + e.Name + '",' + 
					  		'	"EdgemartLabel":"' + e.Label + '",' + 
					  		'	"EdgemartContainer":"' + appDeveloperName + '",' + 
					  		'	"Operation":"Overwrite",' + 
					  		'	"Action":"None",' + 
					  		'	"MetadataJson":"' + EncodingUtil.base64Encode(Blob.valueOf(jsonMetadata)) + '"' +
					  		'}';

				        res = httpCallout('/services/data/' + apiVersion + '/sobjects/InsightsExternalData', 'POST', true, jsonToSend);
				        if(checkStatus(res)){

				        	RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
				   			
			   				//Add the Data

					        Integer size = csvBlob.size();
					        jsonToSend = '{' + 
							'	"attributes":{' + 
							'		"type":"InsightsExternalDataPart"' + 
							'	},' + 
							'	"InsightsExternalDataId":"' + responseBody.Id + '",' + 
							'	"PartNumber":"1",' + 
					  		'	"DataFile":"' + EncodingUtil.base64Encode(csvBlob) + '",' + 
					  		'	"DataLength":"' + size + '"' + 
					  		'}';

					        res = httpCallout('/services/data/' + apiVersion + '/sobjects/InsightsExternalDataPart', 'POST', true, jsonToSend);
					        if(checkStatus(res)){

					        	//Final Step: Manage the Upload
						        
						        jsonToSend = '{' + 
								'	"attributes":{' + 
								'		"type":"InsightsExternalData"' + 
								'	},' + 
						  		'	"Action":"Process"' + 
						  		'}';
								
						        res = httpCallout('/services/data/' + apiVersion + '/sobjects/InsightsExternalData/' + responseBody.Id + '?_HttpMethod=PATCH', 'POST', true, jsonToSend);
						        if(!checkStatus(res) || res.getBody().containsIgnoreCase('errorCode')){
						        	List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
						        	
						        	throw new WaveConfiguratorException('Error updating InsightsExternalData object: ' + r.get(0).message);
						        }
						    } 
						    else {
								List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);	
						    	
						    	throw new WaveConfiguratorException('Error inserting InsightsExternalDataPart object: ' + r.get(0).message);
						    } 	        

					    } 
					    else{
					    	List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);	
						    throw new WaveConfiguratorException('Error inserting InsightsExternalData object: ' + r.get(0).message);
					    } 

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

	public static boolean checkStatus(HTTPResponse r){
		String strStatusCode = String.valueOf(r.getStatusCode());
		return !(strStatusCode.startsWith('4') || strStatusCode.startsWith('5'));
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

	public String createDataflow(String devName, String label, String folderId)
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

  		HttpResponse res = WaveConfiguratorUtils.httpCallout('/services/data/' + apiVersion + '/sobjects/Dataflow', 'POST', true, dataflowJson);
  		
  		if(!WaveConfiguratorUtils.checkStatus(res) || res.getBody().containsIgnoreCase('errorCode')){

			List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
			System.debug('Dataflow for ' + label + ' could not be created. Detailed message: ' + r.get(0).message);	

			return 'Error: ' + r.get(0).message;

			//throw new WaveConfiguratorException('Dataflow for ' + label + ' could not be created. Check debug logs.');
  		}
  		else {
  			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			if(!responseBody.success){
  				// Future: process errors property  				  			
  				throw new WaveConfiguratorException('Dataflow for ' + label + ' could not be created.');
  			}
  			else {
  				return responseBody.id;
  			}
  		}
	}

	public String createDataflowVersion(String dataflowId, String dataflowDefinitionJson)
	{
		String postJson = '{' + 
		'	"attributes":{' + 
		'		"type":"DataflowVersion"' + 
		'	},' + 
		'	"DataflowId":"' + dataflowId + '",' + 
  		'	"DataflowDefinition":' + JSON.serialize(dataflowDefinitionJson) + 
  		'}';

  		HttpResponse res = WaveConfiguratorUtils.httpCallout('/services/data/' + apiVersion + '/sobjects/DataflowVersion', 'POST', true, postJson);
  		
  		if(!WaveConfiguratorUtils.checkStatus(res)){
  			if(res.getBody().containsIgnoreCase('errorCode')){
				List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
				System.debug('Dataflow Definition could not be created. Detailed message: ' + r.get(0).message);				
			}

			throw new WaveConfiguratorException('Dataflow Definition could not be created. Check debug logs.');
  		}
  		else {
  			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			if(!responseBody.success){
  				// Future: process errors property  				  			
  				throw new WaveConfiguratorException('Dataflow Definition could not be created.');
  			}
  			else {
  				return responseBody.id;
  			}
  		}
	}

	public void linkDataflowToVersion(String dataflowId, String versionId) {

		String postJson = '{' + 
		'	"attributes":{' + 
		'		"type":"Dataflow"' + 
		'	},' + 
		'	"CurrentId":"' + versionId + '"' + 
  		'}';

		Http http = new Http();
		HttpRequest req = new HttpRequest();

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String url = salesforceHost + '/services/data/' + apiVersion + '/sobjects/Dataflow/' + dataflowId + '?_HttpMethod=PATCH';

		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setBody(postJson);

		HTTPResponse res = http.send(req);

		if(!WaveConfiguratorUtils.checkStatus(res)){
  			if(res.getBody().containsIgnoreCase('errorCode')){
				List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
				System.debug('Dataflow Definition version id could not be set. Detailed message: ' + r.get(0).message);
			}

			throw new WaveConfiguratorException('Dataflow Definition version id could not be set. Check debug logs.');
  		}
	}

	public static Boolean dataflowExistsByName(String devName){
		Dataflow[] dfResults = [SELECT Id FROM Dataflow WHERE DeveloperName = :devName AND State = 'Active'];
		
		return dfResults.size() > 0;
	}

	public static String getDataflowIdByName(String devName){
		Dataflow[] dfResults = [SELECT Id FROM Dataflow WHERE DeveloperName = :devName AND State = 'Active'];
		String dfId = '';

		if(dfResults.size() > 0){
			dfId = dfResults.get(0).Id;
		}

		return dfId;
	}

	public static void deleteDataflow(String dataflowId, String sessionId, String apiVersion){
		System.debug('Attempting to delete wave dataflow Id: ' + dataflowId);
		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('DELETE');
		req.setEndpoint(salesforceHost + '/services/data/' + apiVersion + '/sobjects/Dataflow/' + dataflowId);
		req.setHeader('Authorization', 'OAuth ' + sessionId);

		HttpResponse res = http.send(req);

		if(!WaveConfiguratorUtils.checkStatus(res)){
			System.debug('Dataflow ' + dataflowId + ' could not be deleted.');
		}
	}

	@future(callout=true)
	public static void deleteFolder(String folderId, String dataflowId, String sessionId, String apiVersion, String mainMessage, String stackTrace){
		
		if(String.isNotBlank(dataflowId)){
			// First we have to delete the dataflow
			WaveConfiguratorUtils.deleteDataflow(dataflowId, sessionId, apiVersion);
		}

		System.debug('Attempting to delete wave folder/application Id: ' + folderId);
		
		if(String.isNotBlank(mainMessage)){
			System.debug('Reason: ' + mainMessage);
		}

		if(String.isNotBlank(stackTrace)){
			System.debug('Stack trace: ' + stackTrace);
		}

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('DELETE');
		req.setEndpoint(salesforceHost + '/services/data/' + apiVersion + '/wave/folders/' + folderId);
		req.setHeader('Authorization', 'OAuth ' + sessionId);

		HttpResponse res = http.send(req);

		if(!WaveConfiguratorUtils.checkStatus(res)){
			System.debug(res.getBody());
			System.debug('Wave folder/application could not be deleted.');
		}
	}

	public String insertFolder(String appRowLabel, String folderName) {
		String jsonToPost = '{"label":"' + appRowLabel + '","name":"' + folderName + '"}';

		HTTPResponse res = WaveConfiguratorUtils.httpCallout('/services/data/' + apiVersion + '/wave/folders', 'POST', true, jsonToPost);

		if(!WaveConfiguratorUtils.checkStatus(res)){
			if(res.getBody().containsIgnoreCase('errorCode')){
				List<RestApiFolderErrorResponse> r = (List<RestApiFolderErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiFolderErrorResponse>.class);
				throw new WaveConfiguratorException('There was an error in the attempt to create the: ' + folderName + ' folder. Cause: ' + r.get(0).message + '.');
			} 

			throw new WaveConfiguratorException('There was an error in the attempt to create the: ' + folderName + ' folder.');
		} 
		else {
			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			return responseBody.id;		
		}
	}

	public String insertWaveDashboard(String dashboardJsonTemplate, String folderId, Map<String, String> datasetsMap){
		String dashboardJsonToSend = dashboardJsonTemplate;
		String replacement = folderId; 
		String target = '<folderId>';

		dashboardJsonToSend = dashboardJsonToSend.replace(target, replacement);

		if(datasetsMap != null){
			for(String dsDesiredName : datasetsMap.keySet()){
				dashboardJsonToSend = dashboardJsonToSend.replace('<' + dsDesiredName + '>', datasetsMap.get(dsDesiredName));
			}
		}

		HTTPResponse res = WaveConfiguratorUtils.httpCallout('/services/data/' + apiVersion + '/wave/dashboards', 'POST', true, dashboardJsonToSend);

		if(!WaveConfiguratorUtils.checkStatus(res)){
			if(res.getBody().containsIgnoreCase('errorCode')){
				List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
				throw new WaveConfiguratorException('Dashboard could not be created. Cause: ' + r.get(0).message + '.');
			}

			throw new WaveConfiguratorException('Dashboard could not be created. Check debug logs.');
		} 
		else {
			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			return responseBody.id;		
		}
	}	

	public String updateWaveDashboard(String dashboardJsonTemplate, String dashboardId, String folderId, Map<String, String> datasetsMap, Map<String, String> dashboardsIdsByNameMap){

		// We replace the <folderId>
		String dashboardJsonToSend = dashboardJsonTemplate.replace('<folderId>', folderId);
		
		// We replace the dataset names
		if(datasetsMap != null){
			for(String dsDesiredName : datasetsMap.keySet()){
				dashboardJsonToSend = dashboardJsonToSend.replace('<' + dsDesiredName + '>', datasetsMap.get(dsDesiredName));
			}
		}

		// We replace the dashboard names for internal linking
		if(dashboardsIdsByNameMap != null){
			for(String nameLink : dashboardsIdsByNameMap.keySet()){
				dashboardJsonToSend = dashboardJsonToSend.replace('<' + nameLink + '>', dashboardsIdsByNameMap.get(nameLink));
			}
		}

		HTTPResponse res = WaveConfiguratorUtils.httpCallout('/services/data/' + apiVersion + '/wave/dashboards/' + dashboardId + '?_HttpMethod=PATCH', 'POST', true, dashboardJsonToSend);

		if(!WaveConfiguratorUtils.checkStatus(res)){
			if(res.getBody().containsIgnoreCase('errorCode')){
				List<RestApiErrorResponse> r = (List<RestApiErrorResponse>)JSON.deserialize(res.getBody(), List<RestApiErrorResponse>.class);
				throw new WaveConfiguratorException('Dashboard could not be updated. Cause: ' + r.get(0).message + '.');
			}

			throw new WaveConfiguratorException('Dashboard could not be updated. Check debug logs.');
		} 
		else {
			RestApiResponseBody responseBody = (RestApiResponseBody)JSON.deserialize(res.getBody(), RestApiResponseBody.class);
  			return responseBody.id;		
		}
	}


	public static void sendEmail(String address, String dataflowLabel){
		if(!String.isBlank(address)){
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] { address };
			String body = 'Congratulations, your data and Wave dataflow have been loaded into ' + UserInfo.getOrganizationId() + '.'; 
			body += 'Please log-in and Start the ' + dataflowLabel + ' Data Flow from the Wave Dataflow editor.';
			
			mail.setToAddresses(toAddresses);
			mail.setSubject('Wave application installation succeeded');
			mail.setPlainTextBody(body);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}

	public static Boolean isInvalidEmail(String address){
		String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
	    Pattern MyPattern = Pattern.compile(emailRegex);
	    Matcher MyMatcher = MyPattern.matcher(address);

	    return !MyMatcher.matches(); 
	}

	
	public static boolean folderExists(String folderName){
		Folder[] lstFolders = [SELECT Id FROM Folder WHERE DeveloperName = :folderName AND Type = 'Insights'];
		return lstFolders.size() > 0;
	}

	// Retrieves asset JSON through WAVE REST API, only works within the ORG in which this code executes
	// @param waveAssets: Type of asset to retrieve [folders, datasets, lenses, dashboards]
	// @param requestUrl: If not null, uses this URL to request data
	public String getWaveAssetsJSON(String waveAssets, String requestUrl){
        HttpRequest req = new HttpRequest();
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url = salesforceHost + (requestUrl != null ? requestUrl : '/services/data/' + apiVersion + '/wave/' + waveAssets + '?pageSize=200');
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setMethod('GET');

        Http httpMgr = new Http();
        HTTPResponse res = httpMgr.send(req);

        return res.getBody();
    }
}