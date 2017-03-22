@isTest
private class WaveConfiguratorUtils_test {

	@isTest static void insertFolderTest() {
		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		String appsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveApplications.csv';
		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'text/plain');		
		Test.setMock(HttpCalloutMock.class, multimock);

		String message = 'The Folder name must be specified, cannot be empty and must adhere to the Salesforce DeveloperName format'; 
		String mockResponseBody = '[{"errorCode" : "228","message" : "' + message +'"}]';
		
		WaveFolderCreationHttpCalloutMock httpCallout = new WaveFolderCreationHttpCalloutMock(200,'',mockResponseBody, new Map<String, String>());
		
		Test.setMock(HttpCalloutMock.class, httpCallout);
				
		String res = WaveConfiguratorUtils.insertFolder('TestingFolderLabel','Testing FolderName');
		System.assertEquals(message,res);
	}

}