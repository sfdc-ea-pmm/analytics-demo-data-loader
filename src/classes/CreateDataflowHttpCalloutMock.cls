@isTest
global class CreateDataflowHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request){
        
    	Id dataflowId;
    	List<Dataflow> dataflows = [SELECT Id FROM Dataflow WHERE DeveloperName = 'ServWave_Test1'];
		if(dataflows.size() > 0){
			Dataflow dfServices = dataflows.get(0);
			dataflowId = dfServices.Id;
		}

    	// Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"id": "' + dataflowId + '", "success":true}');
        response.setStatusCode(200);
        return response;
    }
}