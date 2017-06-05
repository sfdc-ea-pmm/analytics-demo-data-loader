@isTest
private class WaveDataManager_test {
	
	@isTest static void basicControllerTest() {

		SmartLookup sm = new SmartLookup(0, 'User');

		WaveDataManagerController cnt = new WaveDataManagerController(); // Constructor
		cnt.resetMessages();

		System.assertEquals(0, cnt.processingLog.size());
	}

	@isTest static void metadataUtilsTest() {

		// Null Web Service mock implementation
        Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
		
		List<String> errs = SF_MetadataUtils.createObject('TestObj__c');		

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
		errs = SF_MetadataUtils.createField(fieldSpec);

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
		errs = SF_MetadataUtils.createField(fieldSpec);
	}

	private static MultiStaticResourceCalloutMock createStaticResources(){
		MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
		
		String appsMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/WaveApplications.csv';
		String usersMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/metadata/User_metadata.csv';
		String usersDataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/data/output/latest/User.csv';
		String accountsMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/metadata/Account_metadata.csv';
		String accountsDataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/data/output/latest/Account.csv';

		String oppMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/metadata/Opportunity_metadata.csv';
		String oppDataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/data/output/latest/Opportunity.csv';
		String waveForSalesJsonUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/WaveForSales.json';
		String waveForSalesDataflowUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/dataflows/Wave_For_Sales_Dataflow.json';
		String metadataJsonFriendsUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/FriendsMetadata.json';
		String dataCsvFriendsUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/Friends.csv';
		String metadataJsonSimpleUsersUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/SimpleUsersMetadata.json';
		String metadataJsonUsersFriendsUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/UsersAndFriendsMetadata.json';
		String simpleAppJsonUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/Simple.json';
		String dataCsvSimpleUsersUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/SimpleUsers.csv';
		String dataCsvUsersFriendsUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/UsersAndFriends.csv';
		String dataflowLocationUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/SimpleDataflow.json';
		String filteredFriendShiDashboardpUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/dashboards/FilteredFriendship.json';
		String donutByGenderDashboardUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/dashboards/DonutByGender.json';
		String usersFriendsTableDashboardUrl = 'https://raw.githubusercontent.com/rodrigom-oktana-io/wave-tooling/master/Simple/dashboards/UserFriendsTable.json';

		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String newFolderUrl = salesforceHost + '/services/data/v40.0/wave/folders';
		String datasetsResponse = salesforceHost + '/services/data/v40.0/wave/datasets?pageSize=200';
		String insertFolderResponse = salesforceHost + '/services/data/v40.0/wave/folders';
		String insertDataflowResponse = salesforceHost + '/services/data/v40.0/sobjects/Dataflow';
		String insightsExternalDataResponse = salesforceHost + '/services/data/v40.0/sobjects/InsightsExternalData';
		String insightsExternalDataPartResponse = salesforceHost + '/services/data/v40.0/sobjects/InsightsExternalDataPart';
		String updateInsightsExternalDataResponse = salesforceHost + '/services/data/v40.0/sobjects/InsightsExternalData/06V360000009sKjEAI?_HttpMethod=PATCH';
		String dataflowVersionResponse = salesforceHost + '/services/data/v40.0/sobjects/DataflowVersion';
		String updateDataflowResponse = salesforceHost + '/services/data/v40.0/sobjects/Dataflow/02K36000000E0XDEA0?_HttpMethod=PATCH';
		String deleteDataflowResponse = salesforceHost + '/services/data/v40.0/sobjects/Dataflow/02K36000000E0XDEA0';
		String insertDashboardResponse = salesforceHost + '/services/data/v40.0/wave/dashboards';
		String updateDashboardResponse = salesforceHost + '/services/data/v40.0/wave/dashboards/02K36000000E0XDEA0?_HttpMethod=PATCH';

		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStaticResource(usersMetadataUrl, 'UserMetadataCSV');
		multimock.setStaticResource(usersDataUrl, 'UsersDataCSV');
		multimock.setStaticResource(accountsMetadataUrl, 'AccountMetadataCSV');
		multimock.setStaticResource(accountsDataUrl, 'AccountsDataCSV');
		multimock.setStaticResource(oppMetadataUrl, 'OpportunityMetadataCSV');
		multimock.setStaticResource(oppDataUrl, 'OpportunitiesDataCSV');
		multimock.setStaticResource(waveForSalesJsonUrl, 'WaveForSalesJson');
		multimock.setStaticResource(waveForSalesDataflowUrl, 'WaveForSalesDataflowUrl');
		multimock.setStaticResource(newFolderUrl, 'BlankResponseBody');
		multimock.setStaticResource(datasetsResponse, 'DatasetsResponse');
		multimock.setStaticResource(insertFolderResponse, 'InsertFolderResponse');
		multimock.setStaticResource(insertDataflowResponse, 'InsertDataflowResponse');
		multimock.setStaticResource(metadataJsonFriendsUrl, 'MetadataJsonFriends');
		multimock.setStaticResource(dataCsvFriendsUrl, 'DataCsvFriends');
		multimock.setStaticResource(metadataJsonSimpleUsersUrl, 'MetadataJsonSimpleUsers');
		multimock.setStaticResource(metadataJsonUsersFriendsUrl, 'MetadataJsonUsersFriends');
		multimock.setStaticResource(insightsExternalDataResponse, 'InsightsExternalDataResponse');
		multimock.setStaticResource(insightsExternalDataPartResponse, 'InsightsExternalDataPartResponse');
		multimock.setStaticResource(simpleAppJsonUrl, 'SimpleAppJson');
		multimock.setStaticResource(dataCsvSimpleUsersUrl, 'DataCsvSimpleUsers');
		multimock.setStaticResource(dataCsvUsersFriendsUrl, 'DataCsvUsersFriends');
		multimock.setStaticResource(updateInsightsExternalDataResponse, 'BlankResponseBodyIED');
		multimock.setStaticResource(dataflowLocationUrl, 'DataflowLocation');
		multimock.setStaticResource(dataflowVersionResponse, 'DataflowVersionResponse');
		multimock.setStaticResource(updateDataflowResponse, 'BlankResponseBody');
		multimock.setStaticResource(insertDashboardResponse, 'DataflowVersionResponse');
		multimock.setStaticResource(filteredFriendShiDashboardpUrl, 'FilteredFriendshipDashboard');
		multimock.setStaticResource(donutByGenderDashboardUrl, 'DonutByGenderDashboard');
		multimock.setStaticResource(usersFriendsTableDashboardUrl, 'UserFriendsTableDashboard');
		multimock.setStaticResource(updateDashboardResponse, 'DataflowVersionResponse');
		multimock.setStaticResource(deleteDataflowResponse, 'DataflowVersionResponse');

		multimock.setStatusCode(200);
		multimock.setHeader('Content-Type', 'text/plain');

		return multimock; 
	}
    
    @isTest static void prepCoreTest(){
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		WaveDataManagerController cnt = new WaveDataManagerController();

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.selectedWaveApp = 'Simple';
		cnt.selectedInstallationProcess = 'loadObjects';
		
		cnt.executeSelectedProcess();

		Test.startTest();
		cnt.loadAllObjects();
		Test.stopTest();

		cnt.checkObjectLoadingStatus();
		List<SelectOption> options = cnt.getWaveApps();
		cnt.waveAppSelected();
		cnt.getAppDescription();

		System.assert(options.size() > 0);
	}
	
	@isTest static void checktimeShiftingStatusTest(){
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		WaveDataManagerController cnt = new WaveDataManagerController();

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.dataflowName = 'TestingDataflowName';
		cnt.dataflowLabel = 'Testing Dataflow Label';
		cnt.folderName = 'TestingFolder';
		cnt.folderLabel = 'Testing Folder';
		cnt.selectedWaveApp = 'Simple';

		cnt.installationStep = 'LoadObjects';

		Test.startTest();
		cnt.loadAllObjects();
		Test.stopTest();

		cnt.currentTimeShiftingNodeIndex = 0;
		cnt.checkTimeShiftingStatus();
	}
	
	@isTest static void timeShiftingTestServices(){
		List<String> dateFieldNames = new List<String>();
		dateFieldNames.add('CreatedDate__c');

		Case cs = new Case();
		SObject caseToTest = cs.getSObjectType().newSObject();
		caseToTest.put('Subject', 'TestCase');
		caseToTest.put('Status', 'Closed');
		caseToTest.put('Priority', 'Medium');
		caseToTest.put('Origin', 'Email');
		caseToTest.put('CreatedDate__c', DateTime.now().addDays(-5));

		//Case cas = new Case(Subject='TestCase', Status ='Closed', Priority = 'Medium', Origin = 'Email', CreatedDate__c = DateTime.now().addDays(-5));
        insert caseToTest;

		Test.startTest();
		TimeShiftingBatch batchProcess = new TimeShiftingBatch('Case', dateFieldNames, 'Services');
		ID batchId = Database.executeBatch(batchProcess);
		Test.stopTest();
	}


	@isTest static void timeShiftingTestSales(){
		List<String> dateFieldNames = new List<String>();
		dateFieldNames.add('DateTimeCreated__c'); //Type DateTime
		dateFieldNames.add('CloseDate'); //Type Date
		
		Account acc = new Account(Name = 'TestAccount', Description = 'Test Account Desc');
		insert acc;

		Opportunity opp = new Opportunity(); 
		SObject opptyToTest = opp.getSObjectType().newSObject();
		opptyToTest.put('AccountId', acc.Id);
		opptyToTest.put('Name', 'TestOpportunity');
		opptyToTest.put('StageName', 'Closed Won');
		opptyToTest.put('DateTimeCreated__c', DateTime.now().addDays(-5));
		opptyToTest.put('CloseDate', Date.today().addDays(-1));
		/*opp.AccountId = acc.Id;
		opp.Name = 'TestOpportunity';
		opp.StageName = 'Closed Won';
		opp.CloseDate = Date.today();
		opp.CreatedDate__c = Date.today().addDays(-5);*/
		insert opptyToTest;

		Test.startTest();
		TimeShiftingBatch batchProcess = new TimeShiftingBatch('Opportunity', dateFieldNames, 'Sales');
		ID batchId = Database.executeBatch(batchProcess);
		Test.stopTest();
	}

	@isTest static void getWaveAppsAndDescriptionTest(){
		WaveDataManagerController cnt = new WaveDataManagerController();
		List<SelectOption> options = cnt.getWaveApps();

		System.assertEquals(0, options.size());

		cnt.selectedWaveApp = 'Wave for Sales';
		String appDsc = cnt.getAppDescription();
	}


 	@isTest static void displayMetadataResponseTest(){
 		WaveDataManagerController cnt = new WaveDataManagerController();

 		cnt.displayMetadataResponse();
		System.assertEquals(false, cnt.MetadataConnectionWarning);

		cnt.MetadataResponse = 'TEST';
		cnt.displayMetadataResponse();
		System.assertEquals(true, cnt.MetadataConnectionWarning);
 	}
    
	@isTest static void sendEmailTest(){
		String address = 'test@test.com';		
		String label = 'Test label'; 
		WaveConfiguratorUtils.sendEmail(address, label);		
	}

	@isTest static void executeSelectedProcessTest(){
		WaveDataManagerController cnt = new WaveDataManagerController();
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.selectedInstallationProcess = 'createMetadata';
		cnt.selectedWaveApp = 'Simple';
		cnt.executeSelectedProcess();

		cnt.selectedInstallationProcess = 'createWaveApp';
		cnt.dataflowName = 'TestingDataflowName';
		cnt.dataflowLabel = 'Testing Dataflow Label';
		cnt.folderName = 'TestingFolder';
		cnt.folderLabel = 'Testing Folder';
		cnt.executeSelectedProcess();

		cnt.selectedInstallationProcess = 'timeShifting';
		cnt.executeSelectedProcess();
	}

	@isTest static void loadObjectsThroughChoosingProcess(){
		WaveDataManagerController cnt = new WaveDataManagerController();
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.selectedWaveApp = 'Simple';
		cnt.selectedInstallationProcess = 'loadObjects';
		cnt.executeSelectedProcess();
	}
}