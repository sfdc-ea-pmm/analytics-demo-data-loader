@isTest
private class CopyCustomHistory_test {
	
	@isTest static void test_method() {
		CopyCustomHistoryController controller = new CopyCustomHistoryController();
		controller.getWaveApplications();
		controller.waveApp = 'SalesWave';
		controller.getHistoryObjects();
		controller.waveApp = 'ServicesWave';
		controller.getHistoryObjects();
		controller.updateWaveApp();
		controller.updateSelectedObj();
		controller.testExceptionCatchBlock = true;
		controller.process();
		controller.testExceptionCatchBlock = false;
		controller.selectedObject = '';
		controller.process();
		controller.selectedObject = 'FakeObj';
		controller.process();
		
		Test.startTest();
		controller.selectedObject = 'CaseHistory';
		controller.process();
		Test.stopTest();

		controller.monitor();

		controller.selectedObject = 'OpportunityHistory';
		controller.process();

		controller.selectedObject = 'OpportunityFieldHistory';
		controller.process();
	}
	
}