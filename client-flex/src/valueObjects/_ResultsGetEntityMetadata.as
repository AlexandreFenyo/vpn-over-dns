
/**
 * This is a generated class and is not intended for modification.  
 */
package valueObjects
{
import com.adobe.fiber.styles.IStyle;
import com.adobe.fiber.styles.Style;
import com.adobe.fiber.styles.StyleValidator;
import com.adobe.fiber.valueobjects.AbstractEntityMetadata;
import com.adobe.fiber.valueobjects.AvailablePropertyIterator;
import com.adobe.fiber.valueobjects.IPropertyIterator;
import mx.events.ValidationResultEvent;
import com.adobe.fiber.core.model_internal;
import com.adobe.fiber.valueobjects.IModelType;
import mx.events.PropertyChangeEvent;

use namespace model_internal;

[ExcludeClass]
internal class _ResultsGetEntityMetadata extends com.adobe.fiber.valueobjects.AbstractEntityMetadata
{
    private static var emptyArray:Array = new Array();

    model_internal static var allProperties:Array = new Array("password", "statusCode", "statusString", "provider", "email", "login", "uuid");
    model_internal static var allAssociationProperties:Array = new Array();
    model_internal static var allRequiredProperties:Array = new Array("password", "statusCode", "statusString", "provider", "email", "login", "uuid");
    model_internal static var allAlwaysAvailableProperties:Array = new Array("password", "statusCode", "statusString", "provider", "email", "login", "uuid");
    model_internal static var guardedProperties:Array = new Array();
    model_internal static var dataProperties:Array = new Array("password", "statusCode", "statusString", "provider", "email", "login", "uuid");
    model_internal static var sourceProperties:Array = emptyArray
    model_internal static var nonDerivedProperties:Array = new Array("password", "statusCode", "statusString", "provider", "email", "login", "uuid");
    model_internal static var derivedProperties:Array = new Array();
    model_internal static var collectionProperties:Array = new Array();
    model_internal static var collectionBaseMap:Object;
    model_internal static var entityName:String = "ResultsGet";
    model_internal static var dependentsOnMap:Object;
    model_internal static var dependedOnServices:Array = new Array();
    model_internal static var propertyTypeMap:Object;

    
    model_internal var _passwordIsValid:Boolean;
    model_internal var _passwordValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _passwordIsValidCacheInitialized:Boolean = false;
    model_internal var _passwordValidationFailureMessages:Array;
    
    model_internal var _statusCodeIsValid:Boolean;
    model_internal var _statusCodeValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _statusCodeIsValidCacheInitialized:Boolean = false;
    model_internal var _statusCodeValidationFailureMessages:Array;
    
    model_internal var _statusStringIsValid:Boolean;
    model_internal var _statusStringValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _statusStringIsValidCacheInitialized:Boolean = false;
    model_internal var _statusStringValidationFailureMessages:Array;
    
    model_internal var _providerIsValid:Boolean;
    model_internal var _providerValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _providerIsValidCacheInitialized:Boolean = false;
    model_internal var _providerValidationFailureMessages:Array;
    
    model_internal var _emailIsValid:Boolean;
    model_internal var _emailValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _emailIsValidCacheInitialized:Boolean = false;
    model_internal var _emailValidationFailureMessages:Array;
    
    model_internal var _loginIsValid:Boolean;
    model_internal var _loginValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _loginIsValidCacheInitialized:Boolean = false;
    model_internal var _loginValidationFailureMessages:Array;
    
    model_internal var _uuidIsValid:Boolean;
    model_internal var _uuidValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _uuidIsValidCacheInitialized:Boolean = false;
    model_internal var _uuidValidationFailureMessages:Array;

    model_internal var _instance:_Super_ResultsGet;
    model_internal static var _nullStyle:com.adobe.fiber.styles.Style = new com.adobe.fiber.styles.Style();

    public function _ResultsGetEntityMetadata(value : _Super_ResultsGet)
    {
        // initialize property maps
        if (model_internal::dependentsOnMap == null)
        {
            // dependents map
            model_internal::dependentsOnMap = new Object();
            model_internal::dependentsOnMap["password"] = new Array();
            model_internal::dependentsOnMap["statusCode"] = new Array();
            model_internal::dependentsOnMap["statusString"] = new Array();
            model_internal::dependentsOnMap["provider"] = new Array();
            model_internal::dependentsOnMap["email"] = new Array();
            model_internal::dependentsOnMap["login"] = new Array();
            model_internal::dependentsOnMap["uuid"] = new Array();

            // collection base map
            model_internal::collectionBaseMap = new Object();
        }

        // Property type Map
        model_internal::propertyTypeMap = new Object();
        model_internal::propertyTypeMap["password"] = "String";
        model_internal::propertyTypeMap["statusCode"] = "String";
        model_internal::propertyTypeMap["statusString"] = "String";
        model_internal::propertyTypeMap["provider"] = "String";
        model_internal::propertyTypeMap["email"] = "String";
        model_internal::propertyTypeMap["login"] = "String";
        model_internal::propertyTypeMap["uuid"] = "String";

        model_internal::_instance = value;
        model_internal::_passwordValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForPassword);
        model_internal::_passwordValidator.required = true;
        model_internal::_passwordValidator.requiredFieldError = "password is required";
        //model_internal::_passwordValidator.source = model_internal::_instance;
        //model_internal::_passwordValidator.property = "password";
        model_internal::_statusCodeValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForStatusCode);
        model_internal::_statusCodeValidator.required = true;
        model_internal::_statusCodeValidator.requiredFieldError = "statusCode is required";
        //model_internal::_statusCodeValidator.source = model_internal::_instance;
        //model_internal::_statusCodeValidator.property = "statusCode";
        model_internal::_statusStringValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForStatusString);
        model_internal::_statusStringValidator.required = true;
        model_internal::_statusStringValidator.requiredFieldError = "statusString is required";
        //model_internal::_statusStringValidator.source = model_internal::_instance;
        //model_internal::_statusStringValidator.property = "statusString";
        model_internal::_providerValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForProvider);
        model_internal::_providerValidator.required = true;
        model_internal::_providerValidator.requiredFieldError = "provider is required";
        //model_internal::_providerValidator.source = model_internal::_instance;
        //model_internal::_providerValidator.property = "provider";
        model_internal::_emailValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForEmail);
        model_internal::_emailValidator.required = true;
        model_internal::_emailValidator.requiredFieldError = "email is required";
        //model_internal::_emailValidator.source = model_internal::_instance;
        //model_internal::_emailValidator.property = "email";
        model_internal::_loginValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForLogin);
        model_internal::_loginValidator.required = true;
        model_internal::_loginValidator.requiredFieldError = "login is required";
        //model_internal::_loginValidator.source = model_internal::_instance;
        //model_internal::_loginValidator.property = "login";
        model_internal::_uuidValidator = new StyleValidator(model_internal::_instance.model_internal::_doValidationForUuid);
        model_internal::_uuidValidator.required = true;
        model_internal::_uuidValidator.requiredFieldError = "uuid is required";
        //model_internal::_uuidValidator.source = model_internal::_instance;
        //model_internal::_uuidValidator.property = "uuid";
    }

    override public function getEntityName():String
    {
        return model_internal::entityName;
    }

    override public function getProperties():Array
    {
        return model_internal::allProperties;
    }

    override public function getAssociationProperties():Array
    {
        return model_internal::allAssociationProperties;
    }

    override public function getRequiredProperties():Array
    {
         return model_internal::allRequiredProperties;   
    }

    override public function getDataProperties():Array
    {
        return model_internal::dataProperties;
    }

    public function getSourceProperties():Array
    {
        return model_internal::sourceProperties;
    }

    public function getNonDerivedProperties():Array
    {
        return model_internal::nonDerivedProperties;
    }

    override public function getGuardedProperties():Array
    {
        return model_internal::guardedProperties;
    }

    override public function getUnguardedProperties():Array
    {
        return model_internal::allAlwaysAvailableProperties;
    }

    override public function getDependants(propertyName:String):Array
    {
       if (model_internal::nonDerivedProperties.indexOf(propertyName) == -1)
            throw new Error(propertyName + " is not a data property of entity ResultsGet");
            
       return model_internal::dependentsOnMap[propertyName] as Array;  
    }

    override public function getDependedOnServices():Array
    {
        return model_internal::dependedOnServices;
    }

    override public function getCollectionProperties():Array
    {
        return model_internal::collectionProperties;
    }

    override public function getCollectionBase(propertyName:String):String
    {
        if (model_internal::collectionProperties.indexOf(propertyName) == -1)
            throw new Error(propertyName + " is not a collection property of entity ResultsGet");

        return model_internal::collectionBaseMap[propertyName];
    }
    
    override public function getPropertyType(propertyName:String):String
    {
        if (model_internal::allProperties.indexOf(propertyName) == -1)
            throw new Error(propertyName + " is not a property of ResultsGet");

        return model_internal::propertyTypeMap[propertyName];
    }

    override public function getAvailableProperties():com.adobe.fiber.valueobjects.IPropertyIterator
    {
        return new com.adobe.fiber.valueobjects.AvailablePropertyIterator(this);
    }

    override public function getValue(propertyName:String):*
    {
        if (model_internal::allProperties.indexOf(propertyName) == -1)
        {
            throw new Error(propertyName + " does not exist for entity ResultsGet");
        }

        return model_internal::_instance[propertyName];
    }

    override public function setValue(propertyName:String, value:*):void
    {
        if (model_internal::nonDerivedProperties.indexOf(propertyName) == -1)
        {
            throw new Error(propertyName + " is not a modifiable property of entity ResultsGet");
        }

        model_internal::_instance[propertyName] = value;
    }

    override public function getMappedByProperty(associationProperty:String):String
    {
        switch(associationProperty)
        {
            default:
            {
                return null;
            }
        }
    }

    override public function getPropertyLength(propertyName:String):int
    {
        switch(propertyName)
        {
            default:
            {
                return 0;
            }
        }
    }

    override public function isAvailable(propertyName:String):Boolean
    {
        if (model_internal::allProperties.indexOf(propertyName) == -1)
        {
            throw new Error(propertyName + " does not exist for entity ResultsGet");
        }

        if (model_internal::allAlwaysAvailableProperties.indexOf(propertyName) != -1)
        {
            return true;
        }

        switch(propertyName)
        {
            default:
            {
                return true;
            }
        }
    }

    override public function getIdentityMap():Object
    {
        var returnMap:Object = new Object();

        return returnMap;
    }

    [Bindable(event="propertyChange")]
    override public function get invalidConstraints():Array
    {
        if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
        {
            return model_internal::_instance.model_internal::_invalidConstraints;
        }
        else
        {
            // recalculate isValid
            model_internal::_instance.model_internal::_isValid = model_internal::_instance.model_internal::calculateIsValid();
            return model_internal::_instance.model_internal::_invalidConstraints;        
        }
    }

    [Bindable(event="propertyChange")]
    override public function get validationFailureMessages():Array
    {
        if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
        {
            return model_internal::_instance.model_internal::_validationFailureMessages;
        }
        else
        {
            // recalculate isValid
            model_internal::_instance.model_internal::_isValid = model_internal::_instance.model_internal::calculateIsValid();
            return model_internal::_instance.model_internal::_validationFailureMessages;
        }
    }

    override public function getDependantInvalidConstraints(propertyName:String):Array
    {
        var dependants:Array = getDependants(propertyName);
        if (dependants.length == 0)
        {
            return emptyArray;
        }

        var currentlyInvalid:Array = invalidConstraints;
        if (currentlyInvalid.length == 0)
        {
            return emptyArray;
        }

        var filterFunc:Function = function(element:*, index:int, arr:Array):Boolean
        {
            return dependants.indexOf(element) > -1;
        }

        return currentlyInvalid.filter(filterFunc);
    }

    /**
     * isValid
     */
    [Bindable(event="propertyChange")] 
    public function get isValid() : Boolean
    {
        if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
        {
            return model_internal::_instance.model_internal::_isValid;
        }
        else
        {
            // recalculate isValid
            model_internal::_instance.model_internal::_isValid = model_internal::_instance.model_internal::calculateIsValid();
            return model_internal::_instance.model_internal::_isValid;
        }
    }

    [Bindable(event="propertyChange")]
    public function get isPasswordAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isStatusCodeAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isStatusStringAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isProviderAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isEmailAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isLoginAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isUuidAvailable():Boolean
    {
        return true;
    }


    /**
     * derived property recalculation
     */
    public function invalidateDependentOnPassword():void
    {
        if (model_internal::_passwordIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfPassword = null;
            model_internal::calculatePasswordIsValid();
        }
    }
    public function invalidateDependentOnStatusCode():void
    {
        if (model_internal::_statusCodeIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfStatusCode = null;
            model_internal::calculateStatusCodeIsValid();
        }
    }
    public function invalidateDependentOnStatusString():void
    {
        if (model_internal::_statusStringIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfStatusString = null;
            model_internal::calculateStatusStringIsValid();
        }
    }
    public function invalidateDependentOnProvider():void
    {
        if (model_internal::_providerIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfProvider = null;
            model_internal::calculateProviderIsValid();
        }
    }
    public function invalidateDependentOnEmail():void
    {
        if (model_internal::_emailIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfEmail = null;
            model_internal::calculateEmailIsValid();
        }
    }
    public function invalidateDependentOnLogin():void
    {
        if (model_internal::_loginIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfLogin = null;
            model_internal::calculateLoginIsValid();
        }
    }
    public function invalidateDependentOnUuid():void
    {
        if (model_internal::_uuidIsValidCacheInitialized )
        {
            model_internal::_instance.model_internal::_doValidationCacheOfUuid = null;
            model_internal::calculateUuidIsValid();
        }
    }

    model_internal function fireChangeEvent(propertyName:String, oldValue:Object, newValue:Object):void
    {
        this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, propertyName, oldValue, newValue));
    }

    [Bindable(event="propertyChange")]   
    public function get passwordStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get passwordValidator() : StyleValidator
    {
        return model_internal::_passwordValidator;
    }

    model_internal function set _passwordIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_passwordIsValid;         
        if (oldValue !== value)
        {
            model_internal::_passwordIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "passwordIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get passwordIsValid():Boolean
    {
        if (!model_internal::_passwordIsValidCacheInitialized)
        {
            model_internal::calculatePasswordIsValid();
        }

        return model_internal::_passwordIsValid;
    }

    model_internal function calculatePasswordIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_passwordValidator.validate(model_internal::_instance.password)
        model_internal::_passwordIsValid_der = (valRes.results == null);
        model_internal::_passwordIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::passwordValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::passwordValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get passwordValidationFailureMessages():Array
    {
        if (model_internal::_passwordValidationFailureMessages == null)
            model_internal::calculatePasswordIsValid();

        return _passwordValidationFailureMessages;
    }

    model_internal function set passwordValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_passwordValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_passwordValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "passwordValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get statusCodeStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get statusCodeValidator() : StyleValidator
    {
        return model_internal::_statusCodeValidator;
    }

    model_internal function set _statusCodeIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_statusCodeIsValid;         
        if (oldValue !== value)
        {
            model_internal::_statusCodeIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusCodeIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get statusCodeIsValid():Boolean
    {
        if (!model_internal::_statusCodeIsValidCacheInitialized)
        {
            model_internal::calculateStatusCodeIsValid();
        }

        return model_internal::_statusCodeIsValid;
    }

    model_internal function calculateStatusCodeIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_statusCodeValidator.validate(model_internal::_instance.statusCode)
        model_internal::_statusCodeIsValid_der = (valRes.results == null);
        model_internal::_statusCodeIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::statusCodeValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::statusCodeValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get statusCodeValidationFailureMessages():Array
    {
        if (model_internal::_statusCodeValidationFailureMessages == null)
            model_internal::calculateStatusCodeIsValid();

        return _statusCodeValidationFailureMessages;
    }

    model_internal function set statusCodeValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_statusCodeValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_statusCodeValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusCodeValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get statusStringStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get statusStringValidator() : StyleValidator
    {
        return model_internal::_statusStringValidator;
    }

    model_internal function set _statusStringIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_statusStringIsValid;         
        if (oldValue !== value)
        {
            model_internal::_statusStringIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusStringIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get statusStringIsValid():Boolean
    {
        if (!model_internal::_statusStringIsValidCacheInitialized)
        {
            model_internal::calculateStatusStringIsValid();
        }

        return model_internal::_statusStringIsValid;
    }

    model_internal function calculateStatusStringIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_statusStringValidator.validate(model_internal::_instance.statusString)
        model_internal::_statusStringIsValid_der = (valRes.results == null);
        model_internal::_statusStringIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::statusStringValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::statusStringValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get statusStringValidationFailureMessages():Array
    {
        if (model_internal::_statusStringValidationFailureMessages == null)
            model_internal::calculateStatusStringIsValid();

        return _statusStringValidationFailureMessages;
    }

    model_internal function set statusStringValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_statusStringValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_statusStringValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusStringValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get providerStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get providerValidator() : StyleValidator
    {
        return model_internal::_providerValidator;
    }

    model_internal function set _providerIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_providerIsValid;         
        if (oldValue !== value)
        {
            model_internal::_providerIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "providerIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get providerIsValid():Boolean
    {
        if (!model_internal::_providerIsValidCacheInitialized)
        {
            model_internal::calculateProviderIsValid();
        }

        return model_internal::_providerIsValid;
    }

    model_internal function calculateProviderIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_providerValidator.validate(model_internal::_instance.provider)
        model_internal::_providerIsValid_der = (valRes.results == null);
        model_internal::_providerIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::providerValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::providerValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get providerValidationFailureMessages():Array
    {
        if (model_internal::_providerValidationFailureMessages == null)
            model_internal::calculateProviderIsValid();

        return _providerValidationFailureMessages;
    }

    model_internal function set providerValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_providerValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_providerValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "providerValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get emailStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get emailValidator() : StyleValidator
    {
        return model_internal::_emailValidator;
    }

    model_internal function set _emailIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_emailIsValid;         
        if (oldValue !== value)
        {
            model_internal::_emailIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "emailIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get emailIsValid():Boolean
    {
        if (!model_internal::_emailIsValidCacheInitialized)
        {
            model_internal::calculateEmailIsValid();
        }

        return model_internal::_emailIsValid;
    }

    model_internal function calculateEmailIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_emailValidator.validate(model_internal::_instance.email)
        model_internal::_emailIsValid_der = (valRes.results == null);
        model_internal::_emailIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::emailValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::emailValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get emailValidationFailureMessages():Array
    {
        if (model_internal::_emailValidationFailureMessages == null)
            model_internal::calculateEmailIsValid();

        return _emailValidationFailureMessages;
    }

    model_internal function set emailValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_emailValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_emailValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "emailValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get loginStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get loginValidator() : StyleValidator
    {
        return model_internal::_loginValidator;
    }

    model_internal function set _loginIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_loginIsValid;         
        if (oldValue !== value)
        {
            model_internal::_loginIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "loginIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get loginIsValid():Boolean
    {
        if (!model_internal::_loginIsValidCacheInitialized)
        {
            model_internal::calculateLoginIsValid();
        }

        return model_internal::_loginIsValid;
    }

    model_internal function calculateLoginIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_loginValidator.validate(model_internal::_instance.login)
        model_internal::_loginIsValid_der = (valRes.results == null);
        model_internal::_loginIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::loginValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::loginValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get loginValidationFailureMessages():Array
    {
        if (model_internal::_loginValidationFailureMessages == null)
            model_internal::calculateLoginIsValid();

        return _loginValidationFailureMessages;
    }

    model_internal function set loginValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_loginValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_loginValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "loginValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }

    [Bindable(event="propertyChange")]   
    public function get uuidStyle():com.adobe.fiber.styles.Style
    {
        return model_internal::_nullStyle;
    }

    public function get uuidValidator() : StyleValidator
    {
        return model_internal::_uuidValidator;
    }

    model_internal function set _uuidIsValid_der(value:Boolean):void 
    {
        var oldValue:Boolean = model_internal::_uuidIsValid;         
        if (oldValue !== value)
        {
            model_internal::_uuidIsValid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "uuidIsValid", oldValue, value));
        }                             
    }

    [Bindable(event="propertyChange")]
    public function get uuidIsValid():Boolean
    {
        if (!model_internal::_uuidIsValidCacheInitialized)
        {
            model_internal::calculateUuidIsValid();
        }

        return model_internal::_uuidIsValid;
    }

    model_internal function calculateUuidIsValid():void
    {
        var valRes:ValidationResultEvent = model_internal::_uuidValidator.validate(model_internal::_instance.uuid)
        model_internal::_uuidIsValid_der = (valRes.results == null);
        model_internal::_uuidIsValidCacheInitialized = true;
        if (valRes.results == null)
             model_internal::uuidValidationFailureMessages_der = emptyArray;
        else
        {
            var _valFailures:Array = new Array();
            for (var a:int = 0 ; a<valRes.results.length ; a++)
            {
                _valFailures.push(valRes.results[a].errorMessage);
            }
            model_internal::uuidValidationFailureMessages_der = _valFailures;
        }
    }

    [Bindable(event="propertyChange")]
    public function get uuidValidationFailureMessages():Array
    {
        if (model_internal::_uuidValidationFailureMessages == null)
            model_internal::calculateUuidIsValid();

        return _uuidValidationFailureMessages;
    }

    model_internal function set uuidValidationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_uuidValidationFailureMessages;

        var needUpdate : Boolean = false;
        if (oldValue == null)
            needUpdate = true;
    
        // avoid firing the event when old and new value are different empty arrays
        if (!needUpdate && (oldValue !== value && (oldValue.length > 0 || value.length > 0)))
        {
            if (oldValue.length == value.length)
            {
                for (var a:int=0; a < oldValue.length; a++)
                {
                    if (oldValue[a] !== value[a])
                    {
                        needUpdate = true;
                        break;
                    }
                }
            }
            else
            {
                needUpdate = true;
            }
        }

        if (needUpdate)
        {
            model_internal::_uuidValidationFailureMessages = value;   
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "uuidValidationFailureMessages", oldValue, value));
            // Only execute calculateIsValid if it has been called before, to update the validationFailureMessages for
            // the entire entity.
            if (model_internal::_instance.model_internal::_cacheInitialized_isValid)
            {
                model_internal::_instance.model_internal::isValid_der = model_internal::_instance.model_internal::calculateIsValid();
            }
        }
    }


     /**
     * 
     * @inheritDoc 
     */ 
     override public function getStyle(propertyName:String):com.adobe.fiber.styles.IStyle
     {
         switch(propertyName)
         {
            default:
            {
                return null;
            }
         }
     }
     
     /**
     * 
     * @inheritDoc 
     *  
     */  
     override public function getPropertyValidationFailureMessages(propertyName:String):Array
     {
         switch(propertyName)
         {
            case("password"):
            {
                return passwordValidationFailureMessages;
            }
            case("statusCode"):
            {
                return statusCodeValidationFailureMessages;
            }
            case("statusString"):
            {
                return statusStringValidationFailureMessages;
            }
            case("provider"):
            {
                return providerValidationFailureMessages;
            }
            case("email"):
            {
                return emailValidationFailureMessages;
            }
            case("login"):
            {
                return loginValidationFailureMessages;
            }
            case("uuid"):
            {
                return uuidValidationFailureMessages;
            }
            default:
            {
                return emptyArray;
            }
         }
     }

}

}
