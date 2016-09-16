public class DataflowEditorController {
	
	public String waveApp { get; set; }
	public Id dataflowId { get; set; }
	public String newDataflowName { get; set; }
	public String newDataflowLabel { get; set; }
	public Boolean testExceptionCatchBlock = false;

	public DataflowEditorController(){

	}

	public List<SelectOption> getWaveApplications() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('ServicesWave', 'Services Wave'));
        options.add(new SelectOption('SalesWave', 'Sales Wave'));

        return options;
    }

	public List<SelectOption> getDataflows() {

        List<SelectOption> options = new List<SelectOption>();
        List<Dataflow> dataflows = [SELECT Id,MasterLabel FROM Dataflow WHERE DataflowType = 'User' AND State = 'Active'];

        for(Dataflow df: dataflows) {
        	options.add(new SelectOption(df.Id, df.MasterLabel));
        }

        return options;
    }

    public void save() {
        try {
    		List<ApexPages.Message> messages = new List<ApexPages.Message>();

    		if(Test.isRunningTest() && this.testExceptionCatchBlock){
    			Double dFail = 1 / 0; // Will raise exception
    		}

    		DataflowDefinitionEditor ddeInstance = null;
    		if(this.waveApp == 'ServicesWave'){
    			ddeInstance = new ServicesWaveDataflowDefinitionEditor(dataflowId);
    		}
    		else if (this.waveApp == 'SalesWave') {
    			ddeInstance = new SalesWaveDataflowDefinitionEditor(dataflowId);
    		}
    		else {
    			messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Wave App.'));
    		}

    		if(String.isBlank(this.newDataflowName)){
	            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Dataflow Name can\'t be blank.'));
	        }

	        if(String.isBlank(this.newDataflowLabel)){
	            messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Dataflow Label can\'t be blank.'));
	        }

	        List<String> validationMessages = ddeInstance.validateEdition();
	        for(String sMessage : validationMessages) {
	        	messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, sMessage));
	        }

    		if(messages.size() == 0){
    			ddeInstance.processEdition(this.newDataflowName, this.newDataflowLabel, 18);
    			messages.add(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The dataflow was generated successfully.'));
    		}
    		
    		for(ApexPages.Message msg: messages) {
				ApexPages.addMessage(msg);
			}
    	}
    	catch(Exception e) {
    		ApexPages.addMessages(e);
    		System.debug(e.getMessage());
    		System.debug(e.getStackTraceString());    		
    	}        
    }

}