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
		
		String appsMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/WaveApplications.csv';
		String simpleAppJsonUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/Simple.json';
		String accountsMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/Account_metadata.csv';
		String accountsDataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/Account.csv';
		String oppMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/Opportunity_metadata.csv';
		String oppDataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/Opportunity.csv';
		String userDataurl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/User.csv';
		String userMetadataUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/simple/User_metadata.csv';
		String waveForSalesJsonUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo/sales/WaveForSales.json';
		String analyticsFaqDemoUrl = 'https://s3-us-west-2.amazonaws.com/ac-sdo-repo-dev/AnalyticsDemoFAQ.json';

		multimock.setStaticResource(appsMetadataUrl, 'WaveAppsMetadataCSV');
		multimock.setStaticResource(accountsMetadataUrl, 'AccountMetadataCSV');
		multimock.setStaticResource(accountsDataUrl, 'AccountsDataCSV');
		multimock.setStaticResource(oppMetadataUrl, 'OpportunityMetadataCSV');
		multimock.setStaticResource(oppDataUrl, 'OpportunitiesDataCSV');
		multimock.setStaticResource(waveForSalesJsonUrl, 'WaveForSalesJson');
		multimock.setStaticResource(simpleAppJsonUrl, 'SimpleAppJson');
		multimock.setStaticResource(userDataurl, 'UsersDataCSV');
		multimock.setStaticResource(userMetadataUrl, 'UserMetadataCSV');
		multimock.setStaticResource(analyticsFaqDemoUrl, 'AnalyticsFAQDemo');
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
		cnt.getAppDescription();

		System.assert(options.size() > 0);
	}
	
	@isTest static void checktimeShiftingStatusTest(){
		MultiStaticResourceCalloutMock multimock = createStaticResources(); 

		WaveDataManagerController cnt = new WaveDataManagerController();

		Test.setMock(HttpCalloutMock.class, multimock);
		cnt.pageLoad();

		cnt.selectedWaveApp = 'Simple';

		cnt.selectedInstallationProcess = 'timeShifting';

		Test.startTest();
        //cnt.selectAppMetadata();
		cnt.executeSelectedProcess();
		Test.stopTest();

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
		TimeShiftingBatch batchProcess = new TimeShiftingBatch('Case', dateFieldNames, 0, '');
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
		TimeShiftingBatch batchProcess = new TimeShiftingBatch('Opportunity', dateFieldNames, 0, '');
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
		cnt.selectedWaveApp = 'Simple';
        
		cnt.selectedInstallationProcess = 'createMetadata';
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

	@isTest static void handlerSectionMethodsTest(){
		WaveDataManagerController cnt = new WaveDataManagerController();
		cnt.advancedTimeShifting = false;
		cnt.advancedOption = false;

		cnt.handleAdvancedSetting();
		cnt.handleAdvancedTimeShifting();
	}

	@isTest static void calculateDaysToShift(){
		Account acc = new Account(Name = 'TestAccount', Description = 'Test Account Desc');
		insert acc;

		Opportunity opp = new Opportunity();
		SObject opptyToTest = opp.getSObjectType().newSObject();

		opptyToTest.put('AccountId', acc.Id);
		opptyToTest.put('External_Id__c', 'W_Opportunity.Test');
		opptyToTest.put('Name', 'TestOpportunity');
		opptyToTest.put('StageName', 'Closed Won');
		opptyToTest.put('CloseDate', Date.today());
		insert opptyToTest;

		MultiStaticResourceCalloutMock multimock = createStaticResources(); 
		Test.setMock(HttpCalloutMock.class, multimock);
		WaveDataManagerController cnt = new WaveDataManagerController();
        
        Test.startTest();
        cnt.pageLoad();
		cnt.selectedWaveApp = 'Simple';
        cnt.selectAppMetadata();
		cnt.selectedInstallationProcess = 'timeShifting';
		cnt.overrideDefaultSettingTS = false;
		cnt.calculateDaysToShift();
        Test.stopTest();
	}
}