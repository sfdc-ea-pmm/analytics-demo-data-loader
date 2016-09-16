@isTest(seeAllData=true)
public class DataflowEditor_test {
	
	@isTest
	private static void testController() {
		DataflowEditorController controller = new DataflowEditorController();
		List<SelectOption> apps = controller.getWaveApplications();
		String servicesApp = ((SelectOption)apps.get(0)).getValue();
		String salesApp = ((SelectOption)apps.get(1)).getValue();
		List<SelectOption> dfs = controller.getDataflows();

		controller.save();
		controller.testExceptionCatchBlock = true;
		controller.save();
		controller.testExceptionCatchBlock = false;
		controller.dataflowId = ((SelectOption)dfs.get(0)).getValue();
		controller.waveApp = servicesApp;
		controller.save();
		controller.waveApp = salesApp;
		controller.save();

		controller.waveApp = servicesApp;
		List<Dataflow> dataflows = [SELECT Id FROM Dataflow WHERE DeveloperName = 'New_Service_Wave_SDO_app'];
		if(dataflows.size() > 0){
			Dataflow dfServices = dataflows.get(0);
			controller.dataflowId = dfServices.Id;
			Long ticksNow = Datetime.now().getTime();
			controller.newDataflowName = 'ServiceWaveTest_' + ticksNow;
			controller.newDataflowLabel = 'Service Wave Test - ' + ticksNow;
			Test.setMock(HttpCalloutMock.class, new CreateDataflowHttpCalloutMock());
			controller.save();
			controller.newDataflowName = 'ServWave_Test1';
			controller.newDataflowLabel = 'Service Wave Test - ' + Datetime.now().getTime();
			controller.save();
		}
	}

	@isTest
	private static void testServicesWave() {
		List<Dataflow> dataflows = [SELECT Id FROM Dataflow WHERE DeveloperName = 'New_Service_Wave_SDO_app'];
		if(dataflows.size() > 0){
			Dataflow dfServices = dataflows.get(0);
			ServicesWaveDataflowDefinitionEditor obj = new ServicesWaveDataflowDefinitionEditor(dfServices.Id);
			Test.setMock(HttpCalloutMock.class, new CreateDataflowHttpCalloutMock());
			obj.insertDataflow('');
			obj.zipJSON();
			obj.editAugmentNode(
				'Join_CaseHistory_Case', 
				'Relabel_CustomCaseHistory', 
				'test',
				'test',
				'test',
				'test',
				new String[]{'test'}
			);
			
			StaticResource srJson = [SELECT Body FROM StaticResource WHERE Name = 'WW_CaseHistoryComputedFieldsDefinition'];

			obj.editComputeRelativeNode(
				'compute_CaseHistory_DatePrevious_Owner',
				'test',
				'CaseId__c',
				'CreatedDate__c',
				'asc',
				srJson.Body.toString()
			);
		}
	}

	@isTest
	private static void testSalesWave() {
		List<Dataflow> dataflows = [SELECT Id FROM Dataflow WHERE DeveloperName = 'SalesWaveLuc'];
		if(dataflows.size() > 0){
			Dataflow dfServices = dataflows.get(0);
			SalesWaveDataflowDefinitionEditor obj = new SalesWaveDataflowDefinitionEditor(dfServices.Id);
			Test.setMock(HttpCalloutMock.class, new CreateDataflowHttpCalloutMock());
			obj.insertDataflow('');
			obj.processDataflowNodes(18);
		}
	}	
}