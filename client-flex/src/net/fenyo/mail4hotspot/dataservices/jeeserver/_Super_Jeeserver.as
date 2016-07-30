/**
 * This is a generated class and is not intended for modification.  To customize behavior
 * of this service wrapper you may modify the generated sub-class of this class - Jeeserver.as.
 */
package net.fenyo.mail4hotspot.dataservices.jeeserver
{
import com.adobe.fiber.core.model_internal;
import com.adobe.fiber.services.wrapper.HTTPServiceWrapper;
import mx.rpc.AbstractOperation;
import mx.rpc.AsyncToken;
import mx.rpc.http.HTTPMultiService;
import mx.rpc.http.Operation;
import valueObjects.Results;
import valueObjects.ResultsCreate;
import valueObjects.ResultsGet;

import com.adobe.serializers.xml.XMLSerializationFilter;

[ExcludeClass]
internal class _Super_Jeeserver extends com.adobe.fiber.services.wrapper.HTTPServiceWrapper
{
    private static var serializer0:XMLSerializationFilter = new XMLSerializationFilter();

    // Constructor
    public function _Super_Jeeserver()
    {
        // initialize service control
        _serviceControl = new mx.rpc.http.HTTPMultiService("https://www.vpnoverdns.com/mail4hotspot/app/");
         var operations:Array = new Array();
         var operation:mx.rpc.http.Operation;
         var argsArray:Array;

         operation = new mx.rpc.http.Operation(null, "MobileCreateUser");
         operation.url = "mobile-create-user";
         operation.method = "POST";
         argsArray = new Array("username","password","info");
         operation.argumentNames = argsArray;         
         operation.serializationFilter = serializer0;
         operation.properties = new Object();
         operation.properties["xPath"] = "/";
         operation.contentType = "application/x-www-form-urlencoded";
         operation.resultType = valueObjects.ResultsCreate;
         operations.push(operation);

         operation = new mx.rpc.http.Operation(null, "MobileDropUser");
         operation.url = "mobile-drop-user";
         operation.method = "POST";
         argsArray = new Array("username","password","info");
         operation.argumentNames = argsArray;         
         operation.serializationFilter = serializer0;
         operation.properties = new Object();
         operation.properties["xPath"] = "/";
         operation.contentType = "application/x-www-form-urlencoded";
         operation.resultType = valueObjects.Results;
         operations.push(operation);

         operation = new mx.rpc.http.Operation(null, "MobileGetUser");
         operation.url = "mobile-get-user";
         operation.method = "POST";
         argsArray = new Array("username","password","info");
         operation.argumentNames = argsArray;         
         operation.serializationFilter = serializer0;
         operation.properties = new Object();
         operation.properties["xPath"] = "/";
         operation.contentType = "application/x-www-form-urlencoded";
         operation.resultType = valueObjects.ResultsGet;
         operations.push(operation);

         operation = new mx.rpc.http.Operation(null, "MobileSetUser");
         operation.url = "mobile-set-user";
         operation.method = "POST";
         argsArray = new Array("username","password","provider","provider_email","provider_login","provider_password","info");
         operation.argumentNames = argsArray;         
         operation.serializationFilter = serializer0;
         operation.properties = new Object();
         operation.properties["xPath"] = "/";
         operation.contentType = "application/x-www-form-urlencoded";
         operation.resultType = valueObjects.Results;
         operations.push(operation);

         _serviceControl.operationList = operations;  


         preInitializeService();
         model_internal::initialize();
    }
    
    //init initialization routine here, child class to override
    protected function preInitializeService():void
    {
      
    }
    

    /**
      * This method is a generated wrapper used to call the 'MobileCreateUser' operation. It returns an mx.rpc.AsyncToken whose
      * result property will be populated with the result of the operation when the server response is received.
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value.
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function MobileCreateUser(username:String, password:String, info:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("MobileCreateUser");
        var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(username,password,info) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'MobileDropUser' operation. It returns an mx.rpc.AsyncToken whose
      * result property will be populated with the result of the operation when the server response is received.
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value.
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function MobileDropUser(username:String, password:String, info:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("MobileDropUser");
        var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(username,password,info) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'MobileGetUser' operation. It returns an mx.rpc.AsyncToken whose
      * result property will be populated with the result of the operation when the server response is received.
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value.
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function MobileGetUser(username:String, password:String, info:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("MobileGetUser");
        var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(username,password,info) ;
        return _internal_token;
    }
     
    /**
      * This method is a generated wrapper used to call the 'MobileSetUser' operation. It returns an mx.rpc.AsyncToken whose
      * result property will be populated with the result of the operation when the server response is received.
      * To use this result from MXML code, define a CallResponder component and assign its token property to this method's return value.
      * You can then bind to CallResponder.lastResult or listen for the CallResponder.result or fault events.
      *
      * @see mx.rpc.AsyncToken
      * @see mx.rpc.CallResponder 
      *
      * @return an mx.rpc.AsyncToken whose result property will be populated with the result of the operation when the server response is received.
      */
    public function MobileSetUser(username:String, password:String, provider:String, provider_email:String, provider_login:String, provider_password:String, info:String) : mx.rpc.AsyncToken
    {
        var _internal_operation:mx.rpc.AbstractOperation = _serviceControl.getOperation("MobileSetUser");
        var _internal_token:mx.rpc.AsyncToken = _internal_operation.send(username,password,provider,provider_email,provider_login,provider_password,info) ;
        return _internal_token;
    }
     
}

}
