public class ServicesWaveDataflowDefinitionEditor extends DataflowDefinitionEditor {
	
	public ServicesWaveDataflowDefinitionEditor(Id dataflowId){
		this.relevantDataflowId = dataflowId;
		this.dataflowDefinitionObject = dataflowContentsAsJSON(this.relevantDataflowId);
	}

	public override void processDataflowNodes(Integer numberOfMonths){

		// Get the JSON from the Static Resource
    	StaticResource srJson = [SELECT Body FROM StaticResource WHERE Name = 'WW_CaseHistoryFieldsDefinition'];

		// We override the Extract_CaseHistory_Owner node
		this.editExtractNode(
			'Extract_CaseHistory_Owner',
			'WW_CaseHistory__c',
			'CreatedDate__c >= LAST_N_MONTHS:' + numberOfMonths + ' and Field__c =\'Owner\'',
			srJson.Body.toString(),
			''
		);

		// We override the Extract_CaseHistory_Status node
		this.editExtractNode(
			'Extract_CaseHistory_Status',
			'WW_CaseHistory__c',
			'CreatedDate__c >= LAST_N_MONTHS:' + numberOfMonths + ' and Field__c =\'Status\'',
			srJson.Body.toString(),
			''
		);

		// Now JSON from WW_CaseHistoryComputedFieldsDefinition static resource
		srJson = [SELECT Body FROM StaticResource WHERE Name = 'WW_CaseHistoryComputedFieldsDefinition'];

		// We override the compute_CaseHistory_DatePrevious_Status node
		this.editComputeRelativeNode(
			'compute_CaseHistory_DatePrevious_Status',
			'',
			'CaseId__c',
			'CreatedDate__c',
			'asc',
			srJson.Body.toString()
		);

		// We override the compute_CaseHistory_DatePrevious_Owner node
		this.editComputeRelativeNode(
			'compute_CaseHistory_DatePrevious_Owner',
			'',
			'CaseId__c',
			'CreatedDate__c',
			'asc',
			srJson.Body.toString()
		);

		// Append Relabel_CustomCaseHistory node
		// Now JSON from WW_CaseHistoryRelabelDefinition static resource
		srJson = [SELECT Body FROM StaticResource WHERE Name = 'WW_CaseHistoryRelabelDefinition'];
		this.appendNode('Relabel_CustomCaseHistory', srJson.Body.toString());

		this.editAugmentNode(
			'Join_CaseHistory_Case', 
			'Relabel_CustomCaseHistory', 
			'',
			'',
			'',
			'',
			null
		);
	}

	public override List<String> validateEdition(){
		List<String> validationMessages = new List<String>();

		if(!this.dataflowDefinitionObject.containsKey('Extract_CaseHistory_Owner')){
			validationMessages.add('Extract_CaseHistory_Owner node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('Extract_CaseHistory_Status')){
			validationMessages.add('Extract_CaseHistory_Status node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('compute_CaseHistory_DatePrevious_Status')){
			validationMessages.add('compute_CaseHistory_DatePrevious_Status node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('compute_CaseHistory_DatePrevious_Owner')){
			validationMessages.add('compute_CaseHistory_DatePrevious_Owner node not found in the Dataflow Definition File.');
		}

		if(!this.dataflowDefinitionObject.containsKey('Join_CaseHistory_Case')){
			validationMessages.add('Join_CaseHistory_Case node not found in the Dataflow Definition File.');
		}

		if(validationMessages.size() == 0){
			Integer caseHistCount = [SELECT count() FROM WW_CaseHistory__c];
			if(caseHistCount == 0){
				validationMessages.add('There are no Case History records in the database. Please go to Copy History page to create them.');
			}
		}

		return validationMessages;
	}
}