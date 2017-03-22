@isTest
private class WaveDataManager_test {
	
	@isTest static void basicControllerTest() {

		SmartLookup sm = new SmartLookup(0, 'User');

		WaveDataManagerController cnt = new WaveDataManagerController(); // Constructor
		cnt.resetMessages();

		System.assertEquals(0, cnt.processingLog.size());
	}

	@isTest static void metadataUtilsTest() {

		SF_MetadataUtils mUtils = new SF_MetadataUtils();

		// Null Web Service mock implementation
        Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
		
		List<String> errs = mUtils.createObject('TestObj__c');		

		SF_MetadataUtils.CustomFieldSpecification fieldSpec = new SF_MetadataUtils.CustomFieldSpecification();
		fieldSpec.ObjectName = 'TestObj__c';
		fieldSpec.Name = 'TestField__c';
    	fieldSpec.Label = 'Test field';
    	fieldSpec.Type = 'Text';
		fieldSpec.ReferenceTo = '';
		fieldSpec.Length = 50;
		fieldSpec.Precision = 0;
		fieldSpec.Scale = 0;
		fieldSpec.IsExternalId = false;
		fieldSpec.IsRequired = false;

		Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
		errs = mUtils.createField(fieldSpec);

		Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
		SF_MetadataUtils.checkMetadataAPIConnection();

		fieldSpec = new SF_MetadataUtils.CustomFieldSpecification();
		fieldSpec.ObjectName = 'TestObj__c';
		fieldSpec.Name = 'TestField2__c';
    	fieldSpec.Label = 'Test field 2';
    	fieldSpec.Type = 'Lookup';
		fieldSpec.ReferenceTo = 'User';
		fieldSpec.Length = 0;
		fieldSpec.Precision = 0;
		fieldSpec.Scale = 0;
		fieldSpec.IsExternalId = false;
		fieldSpec.IsRequired = false;

		Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
		errs = mUtils.createField(fieldSpec);
	}

	private static MultiStaticResourceCalloutMock createStaticResources(){
		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		
		String appsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveApplications.csv';
		String usersMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Users_metadata.csv';
		String usersDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Users.csv';
		String accountsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Accounts_metadata.csv';
		String accountsDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Accounts.csv';
		String oppMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/Opportunity_metadata.csv';
		String oppDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/Opportunities.csv';
		String usersDataWithDblqUrl = 'http://www.example.com/usersCsvWithDBLQ';
		String quotaMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/QuotaMetadata.json';
		String waveForSalesJsonUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveForSales.json';
		String waveForSalesDataflowUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/Wave_For_Sales_Dataflow.json';

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String newFolderUrl = salesforceHost + '/services/data/v39.0/wave/folders';

		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStaticResource(usersMetadataUrl, 'UserMetadataCSV');
		multimock.setStaticResource(usersDataUrl, 'UsersDataCSV');
		multimock.setStaticResource(usersDataWithDblqUrl, 'UsersDataCsvWithDBLQ');
		multimock.setStaticResource(accountsMetadataUrl, 'AccountMetadataCSV');
		multimock.setStaticResource(accountsDataUrl, 'AccountsDataCSV');
		multimock.setStaticResource(oppMetadataUrl, 'OpportunityMetadataCSV');
		multimock.setStaticResource(oppDataUrl, 'OpportunitiesDataCSV');
		multimock.setStaticResource(quotaMetadataUrl, 'QuotaMetadataUrl');
		multimock.setStaticResource(waveForSalesJsonUrl, 'WaveForSalesJson');
		multimock.setStaticResource(waveForSalesDataflowUrl, 'WaveForSalesDataflowUrl');
		multimock.setStaticResource(newFolderUrl, 'BlankResponseBody');

		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'text/plain');

		return multimock; 
	}


	@isTest static void installAppValidationsTest(){

		MultiStaticResourceCalloutMock multimock = createStaticResources(); 
		
		WaveDataManagerController cnt = new WaveDataManagerController();

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.selectedWaveApp = 'Wave_for_Sales';
		
		cnt.installApp();

	}


	@isTest static void getWaveAppsAndDescriptionTest(){
		WaveDataManagerController cnt = new WaveDataManagerController();
		List<SelectOption> options = cnt.getWaveApps();

		System.assertEquals(0, options.size());

		cnt.selectedWaveApp = 'Wave for Sales';
		String appDsc = cnt.getAppDescription();

		//System.assertNotEquals('No description available.', appDsc);
	}


 	@isTest static void displayMetadataResponseTest(){
 		WaveDataManagerController cnt = new WaveDataManagerController();

 		cnt.displayMetadataResponse();
		System.assertEquals(false, cnt.MetadataConnectionWarning);

		cnt.MetadataResponse = 'TEST';
		cnt.displayMetadataResponse();
		System.assertEquals(true, cnt.MetadataConnectionWarning);
 	}


	@isTest static void getDataTest(){
		String usersDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Users.csv';
		String usersDataWithDblqUrl = 'http://www.example.com/usersCsvWithDBLQ';
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 
		Test.setMock(HttpCalloutMock.class, multimock);

		WaveCsvDataRetriever wcdr = new WaveCsvDataRetriever();
		wcdr.validateDataURL('');
		wcdr.getSchemaFieldNames(usersDataUrl);
		wcdr.getData(usersDataWithDblqUrl, true);
	}


	@isTest static void installAppTest(){
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		WaveDataManagerController cnt = new WaveDataManagerController();

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.dataflowName = 'TestingDataflowName';
		cnt.dataflowLabel = 'Testing Dataflow Label';
		cnt.folderName = 'TestingFolder';
		cnt.selectedWaveApp = 'Wave_for_Sales';

		cnt.installApp();
	}



	
}