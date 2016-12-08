@isTest
private class WaveAssetsUtility_Test {
	
	@isTest static void test_method_one() {

		// Multiple mocks
		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String waveRestApiBaseUrl = salesforceHost + '/services/data/v38.0/wave/';
		multimock.setStaticResource(waveRestApiBaseUrl + 'folders?pageSize=200', 'WaveFoldersResponseMock');
		multimock.setStaticResource(waveRestApiBaseUrl + 'datasets?pageSize=200', 'WaveDatasetsResponseMock');
		multimock.setStaticResource(waveRestApiBaseUrl + 'lenses?pageSize=200', 'WaveLensesResponseMock');
		multimock.setStaticResource(waveRestApiBaseUrl + 'dashboards?pageSize=200', 'WaveDashboardsResponseMock');
		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'application/json');
		
        // Test validation of dataset name not starting with non alpha
        WaveAssetsUtility.Response res = WaveAssetsUtility.extractAssetsAndBuildDataset('1test');
        System.assertEquals(false, res.success);
        res = WaveAssetsUtility.extractAssetsAndBuildDataset('');
        System.assertEquals(false, res.success);

        // Test validation of dataset name not ending with __c
        res = WaveAssetsUtility.extractAssetsAndBuildDataset('test__c');
        System.assertEquals(false, res.success);

        // Test validation of dataset name up to 80 characters length 
        String tooLongName = 't'.center(81, 't');
        res = WaveAssetsUtility.extractAssetsAndBuildDataset(tooLongName);
        System.assertEquals(false, res.success);

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);

        String testDatasetName = 'WaveAssetsTestDataset';
        res = WaveAssetsUtility.extractAssetsAndBuildDataset(testDatasetName);
        List<InsightsExternalData> datasets = [SELECT EdgemartAlias FROM InsightsExternalData WHERE EdgemartAlias = :testDatasetName];
		System.System.debug(res.messagesList);
		System.assertEquals(true, res.success);
		System.assert(datasets.size() > 0);
	}

}