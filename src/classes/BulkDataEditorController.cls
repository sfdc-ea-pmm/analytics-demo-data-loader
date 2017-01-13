public with sharing class BulkDataEditorController {
	
	public String saqlQuery { get; set; }
	public Boolean testExceptionCatchBlock { get; set; }
	public String validationMessage { get; set; }

	public void save() {
        try {
        	List<ApexPages.Message> messages = new List<ApexPages.Message>();

    		if(Test.isRunningTest() && this.testExceptionCatchBlock){
    			Double dFail = 1 / 0; // Will raise exception
    		}

    		if(messages.size() == 0){
    			    			
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