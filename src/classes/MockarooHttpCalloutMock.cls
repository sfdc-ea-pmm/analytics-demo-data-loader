@isTest
public class MockarooHttpCalloutMock implements HttpCalloutMock {

    private Boolean useDoubleQuotes;
    private Boolean returnEmptyResponse;
    private Boolean onlyHeaders;

    public MockarooHttpCalloutMock(Boolean useDoubleQuotes, Boolean returnEmptyResponse, Boolean onlyHeaders){
        this.useDoubleQuotes = useDoubleQuotes;
        this.returnEmptyResponse = returnEmptyResponse;
        this.onlyHeaders = onlyHeaders;
    }

    public HTTPResponse respond(HTTPRequest req) {

        String headers = 'External_Id__c,Owner.External_Id__c,AccountSource,AnnualRevenue,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,Industry,Name,NumberOfEmployees,Ownership,Phone,Rating,Type,YearStarted';
        String quotedHeaders = '"External_Id__c",Owner.External_Id__c","AccountSource,AnnualRevenue,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,Industry,Name,NumberOfEmployees,Ownership,Phone,Rating,Type,YearStarted';
        String csvData = 'W_Account.00001,W_User.00016,Community,3397000,61 Maryland Hill,Saint Louis,MO,63143,USA,Engineering,Oyoloo,246,Subsidiary,1-(314)446-1070,Warm,Small Business,1907\nW_Account.00002,W_User.00002,Cold Call,2183000,40984 Kinsman Lane,El Paso,TX,79994,USA,Electronics,Jabbersphere,122,Private,1-(915)954-2280,Hot,Small Business,1987';

        String body = '';
        if(!this.returnEmptyResponse){
            if(this.onlyHeaders){
                body = headers;
            }
            else {
                if(this.useDoubleQuotes){
                    body = quotedHeaders + '\n' + csvData;
                }
                else {
                    body = headers + '\n' + csvData;
                }
            }
        }
        
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'text/plain');
        res.setBody(body);
        res.setStatusCode(200);
        
        return res;
    }

}