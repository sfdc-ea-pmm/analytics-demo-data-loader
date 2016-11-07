@isTest
private class WaveDataGenerator_test {
	
	@isTest static void basicControllerTest() {
		WaveDataGeneratorController cnt = new WaveDataGeneratorController(); // Constructor
		
		// getWaveApplications()
		List<SelectOption> waveApps = cnt.getWaveApplications();
		
		// getOrgObjects()
		cnt.waveApp = 'SalesWave';
		List<SelectOption> objects = cnt.getOrgObjects();
		cnt.waveApp = 'ServicesWave';
		objects = cnt.getOrgObjects();
		
		// help()
		cnt.help();
		cnt.help();

		// updateWaveApp()
		cnt.updateWaveApp();

		// updateSelectedObj()
		cnt.updateSelectedObj();
	}
	
	@isTest static void basicMockarooHelperTest() {
		String url = 'https://sfdc-mockaroo.herokuapp.com/e7369170/download?count=2&key=ad4356a0';
		String badUrl = 'https://sfdc-mockaroo.herokuapp.com/';
		IMockarooHelper iMockHelper = MockarooHelperFactory.getIMockarooHelper();
		iMockHelper.validateDataURL('');
		iMockHelper.validateDataURL(badUrl);
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(true, false, false));
		iMockHelper.getSchemaFieldNames(url);
		iMockHelper.getData(url, true);
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		iMockHelper.getData(url, true);
	}
	
	@isTest static void schemaValidationTest() {
		String url = 'https://sfdc-mockaroo.herokuapp.com/e7369170/download?count=2&key=ad4356a0';
		String badUrl = 'https://sfdc-mockaroo.herokuapp.com/';
		WaveDataGeneratorController cnt = new WaveDataGeneratorController(); // Constructor
		cnt.validateSchema();
		cnt.waveApp = 'SalesWave';
		cnt.dataUrl = badUrl;
		cnt.validateSchema();
		cnt.dataUrl = url;
		cnt.selectedObject = 'Account';
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		cnt.validateSchema();

		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, true, false));
		cnt.validateSchema();

		cnt.selectedObject = 'Opportunity';
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		cnt.validateSchema();

		cnt.selectedObject = 'Case';
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		cnt.validateSchema();

		cnt.selectedObject = 'User';
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		cnt.validateSchema();
	}

	@isTest static void saveTest() {
		String url = 'https://sfdc-mockaroo.herokuapp.com/e7369170/download?count=2&key=ad4356a0';
		WaveDataGeneratorController cnt = new WaveDataGeneratorController(); // Constructor
		
		// Test catch block and validation IFs
		cnt.testExceptionCatchBlock = true;
		cnt.save();
		cnt.testExceptionCatchBlock = false;
		cnt.save();

		cnt.waveApp = 'SalesWave';
		cnt.dataUrl = url;
		cnt.selectedObject = 'Account';
		
		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, true, false));
		cnt.save();

		Test.setMock(HttpCalloutMock.class, new MockarooHttpCalloutMock(false, false, false));
		cnt.save();
		cnt.monitor();
		cnt.save();
	}

	@isTest static void defaultUrlsTest() {
		
		WaveDataGeneratorController cnt = new WaveDataGeneratorController(); // Constructor
		cnt.selectedObject = 'User';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/283bc870/download?count=20&key=ad4356a0', cnt.dataUrl);

		cnt.selectedObject = 'Account';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/e7369170/download?count=100&key=ad4356a0', cnt.dataUrl);
		
		cnt.selectedObject = 'Opportunity';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/1f197d90/download?count=100&key=ad4356a0', cnt.dataUrl);

		cnt.selectedObject = 'Case';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/faf959e0/download?count=500&key=ad4356a0', cnt.dataUrl);

		cnt.selectedObject = 'Task';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/08b5e490/download?count=100&key=ad4356a0', cnt.dataUrl);

		cnt.selectedObject = 'Event';
		cnt.updateSelectedObj();
		System.assertEquals('https://sfdc-mockaroo.herokuapp.com/d73ca970/download?count=100&key=ad4356a0', cnt.dataUrl);		
	}
}