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

	@isTest static void intermediateControllerTest(){

		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		
		String appsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveApplications.csv';
		String usersMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Users_metadata.csv';
		String usersDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Users.csv';
		String accountsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Accounts_metadata.csv';
		String accountsDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Accounts.csv';
		String oppMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/Opportunity_metadata.csv';
		String oppDataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Sales/Opportunities.csv';
		String usersDataWithDblqUrl = 'http://www.example.com/usersCsvWithDBLQ';

		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStaticResource(usersMetadataUrl, 'UserMetadataCSV');
		multimock.setStaticResource(usersDataUrl, 'UsersDataCSV');
		multimock.setStaticResource(usersDataWithDblqUrl, 'UsersDataCsvWithDBLQ');
		multimock.setStaticResource(accountsMetadataUrl, 'AccountMetadataCSV');
		multimock.setStaticResource(accountsDataUrl, 'AccountsDataCSV');
		multimock.setStaticResource(oppMetadataUrl, 'OpportunityMetadataCSV');
		multimock.setStaticResource(oppDataUrl, 'OpportunitiesDataCSV');
		
		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'text/plain');
		
		WaveDataManagerController cnt = new WaveDataManagerController();
		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		List<SelectOption> options = cnt.getWaveApps();

		System.assertNotEquals(0, options.size());
		/*
		cnt.selectedWaveApp = 'Wave for Sales';
		String appDsc = cnt.getAppDescription();

		System.assertNotEquals('No description available.', appDsc);

		cnt.displayMetadataResponse();
		cnt.MetadataResponse = 'TEST';
		cnt.displayMetadataResponse();

		WaveCsvDataRetriever wcdr = new WaveCsvDataRetriever();
		wcdr.validateDataURL('');
		wcdr.getSchemaFieldNames(usersDataUrl);
		wcdr.getData(usersDataWithDblqUrl, true);

		cnt.installApp();
		cnt.checkProcessingStatus();*/
	}

	@isTest static void insertFolderTest(){

		WaveDataManagerController cnt = new WaveDataManagerController();
		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		String appsMetadataUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/WaveApplications.csv';
		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'text/plain');		
		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();
		cnt.folderName = 'TestingApp';
		String message = 'The Folder name must be specified, cannot be empty and must adhere to the Salesforce DeveloperName format'; 
		String mockResponseBody = '[{"errorCode" : "228","message" : "' + message +'"}]';
		WaveFolderCreationHttpCalloutMock httpCallout = new WaveFolderCreationHttpCalloutMock(200,'',mockResponseBody, new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, httpCallout);
		cnt.selectedWaveApp = 'Wave_for_Sales';
		String res = cnt.insertFolder();
		System.assertEquals(message,res);
	}

	/*@isTest static void checkExistanceFolderTest(){

		WaveDataManagerController cnt = new WaveDataManagerController();
		
	}*/
	
}