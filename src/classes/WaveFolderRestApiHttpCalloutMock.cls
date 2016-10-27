@isTest
public class WaveFolderRestApiHttpCalloutMock implements HttpCalloutMock {

    protected Integer code;
    protected String status;
    protected String body;
    protected Map<String, String> responseHeaders;

    public WaveFolderRestApiHttpCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.responseHeaders = responseHeaders;
    }

    public HTTPResponse respond(HTTPRequest req) {

        /*
        HttpResponse res = new HttpResponse();
        for (String key : this.responseHeaders.keySet()) {
            res.setHeader(key, this.responseHeaders.get(key));
        }
        res.setBody(this.body);
        res.setStatusCode(this.code);
        //res.setStatus(this.status);
        */

        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"folders":[{"applicationStatus":"completedstatus","assetSharingUrl":"https://na30.salesforce.com/analytics/wave/application?assetId=00l36000001A8o8AAC&orgId=00D36000001H55A&loginHost=na30.salesforce.com&urlType=sharing","canBeSharedExternally":false,"createdBy":{"id":"00536000002AVSiAAO","name":"Dylan Thom","profilePhotoUrl":"https://c.na30.content.force.com/profilephoto/72936000000g24q/T"},"createdDate":"2016-09-09T19:33:34.000Z","icon":{"id":"00l36000001A8o8AAC","name":"6.png","url":"/analytics/wave/web/proto/images/app/icons/6.png"},"id":"00l36000001A8o8AAC","label":"SalesWaveLuc","lastAccessedDate":"2016-10-26T19:14:49.000Z","lastModifiedBy":{"id":"00536000002AVSiAAO","name":"Dylan Thom","profilePhotoUrl":"https://c.na30.content.force.com/profilephoto/72936000000g24q/T"},"lastModifiedDate":"2016-09-09T19:37:22.000Z","name":"SalesWaveLuc","permissions":{"manage":true,"modify":true,"view":true},"shares":[],"templateOptions":{},"templateSourceId":"sfdc_internal__Sales_Analytics","templateValues":{},"templateVersion":"2.0","type":"folder","url":"/services/data/v38.0/wave/folders/00l36000001A8o8AAC"}],"totalSize":1,"url":"/services/data/v38.0/wave/folders"}');
        res.setStatusCode(200);

        return res;
    }

}