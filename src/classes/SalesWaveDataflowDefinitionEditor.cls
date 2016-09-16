public class SalesWaveDataflowDefinitionEditor extends DataflowDefinitionEditor {
	
	public SalesWaveDataflowDefinitionEditor(Id dataflowId){
		this.relevantDataflowId = dataflowId;
		this.dataflowDefinitionObject = dataflowContentsAsJSON(this.relevantDataflowId);
	}

	public override void processDataflowNodes(Integer numberOfMonths){
		
		// Get the JSON from the Static Resource
    	StaticResource srOppHistFields = [SELECT Body FROM StaticResource WHERE Name = 'WW_OppHistoryFieldsDefinition'];
    	StaticResource srOppHistSchema = [SELECT Body FROM StaticResource WHERE Name = 'WW_OppHistorySchemaDefinition'];

		// We override the Extract_OpportunityHistory node
		this.editExtractNode(
			'Extract_OpportunityHistory',
			'WW_OppHistory__c',
			'',
			srOppHistFields.Body.toString(),
			srOppHistSchema.Body.toString()
		);

		// Append Relabel_CustomOppHistory node
		// Now JSON from WW_OppHistoryRelabelDefinition static resource
		StaticResource srOppHistRelabel = [SELECT Body FROM StaticResource WHERE Name = 'WW_OppHistoryRelabelDefinition'];
		this.appendNode(
			'Relabel_CustomOppHistory', 
			srOppHistRelabel.Body.toString()
		);

		StaticResource srOppHistFlagFields = [SELECT Body FROM StaticResource WHERE Name = 'WW_OppHistoryFlagForDaysInCurrentStageComputedFieldsDefinition'];
		this.editComputeExpressionNode(
			'Flag_For_Days_in_Current_Stage',
			'Relabel_CustomOppHistory',
			true,
			srOppHistFlagFields.Body.toString()
		);


		// We override the computeTrending node
		StaticResource srOppHistTrendingFields = [SELECT Body FROM StaticResource WHERE Name = 'WW_OppHistoryTrendingComputedFieldsDefinition'];
		this.editComputeRelativeNode(
			'computeTrending',
			'',
			'OpportunityId__c',
			'CreatedDate__c',
			'asc',
			srOppHistTrendingFields.Body.toString()
		);
	}

	public override List<String> validateEdition(){
		List<String> validationMessages = new List<String>();

		if(!this.dataflowDefinitionObject.containsKey('Extract_OpportunityHistory')){
			validationMessages.add('Extract_OpportunityHistory node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('Flag_For_Days_in_Current_Stage')){
			validationMessages.add('Flag_For_Days_in_Current_Stage node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('computeTrending')){
			validationMessages.add('computeTrending node not found in the Dataflow Definition File.');
		}

		return validationMessages;
	}
}