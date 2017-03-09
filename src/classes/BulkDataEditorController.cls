public with sharing class BulkDataEditorController {
	
	public String saqlQuery { get; set; }
	public Boolean testExceptionCatchBlock { get; set; }
	public String validationMessage { get; set; }

	public void retrieveSaqlResults() {
        try {
        	List<ApexPages.Message> messages = new List<ApexPages.Message>();

    		if(Test.isRunningTest() && this.testExceptionCatchBlock){
    			Double dFail = 1 / 0; // Will raise exception
    		}

    		if(!String.isBlank(saqlQuery)){
	            String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
	            HttpRequest req = new HttpRequest();
	            String url = salesforceHost + '/services/data/v39.0/wave/query';
	            req.setEndpoint(url);
	            req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
	            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
	            req.setHeader('Accept', 'application/json');
	            String reqBody = '{"query": "' + saqlQuery + '"}';
	            req.setBody(reqBody);
	            System.debug(reqBody);
	            req.setMethod('POST');
	                        
	            Http httpMgr = new Http();
	            HTTPResponse res = httpMgr.send(req);
	            String queryResultsJSON = res.getBody();
	            System.debug(queryResultsJSON);
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