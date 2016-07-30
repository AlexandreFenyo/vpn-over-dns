/**
 * This is a generated class and is not intended for modification.  To customize behavior
 * of this value object you may modify the generated sub-class of this class - ResultsGet.as.
 */

package valueObjects
{
import com.adobe.fiber.services.IFiberManagingService;
import com.adobe.fiber.util.FiberUtils;
import com.adobe.fiber.valueobjects.IValueObject;
import flash.events.Event;
import flash.events.EventDispatcher;
import mx.binding.utils.ChangeWatcher;
import mx.collections.ArrayCollection;
import mx.events.PropertyChangeEvent;
import mx.validators.ValidationResult;

import flash.net.registerClassAlias;
import flash.net.getClassByAlias;
import com.adobe.fiber.core.model_internal;
import com.adobe.fiber.valueobjects.IPropertyIterator;
import com.adobe.fiber.valueobjects.AvailablePropertyIterator;

use namespace model_internal;

[ExcludeClass]
public class _Super_ResultsGet extends flash.events.EventDispatcher implements com.adobe.fiber.valueobjects.IValueObject
{
    model_internal static function initRemoteClassAliasSingle(cz:Class) : void
    {
    }

    model_internal static function initRemoteClassAliasAllRelated() : void
    {
    }

    model_internal var _dminternal_model : _ResultsGetEntityMetadata;
    model_internal var _changedObjects:mx.collections.ArrayCollection = new ArrayCollection();

    public function getChangedObjects() : Array
    {
        _changedObjects.addItemAt(this,0);
        return _changedObjects.source;
    }

    public function clearChangedObjects() : void
    {
        _changedObjects.removeAll();
    }

    /**
     * properties
     */
    private var _internal_password : String;
    private var _internal_statusCode : String;
    private var _internal_statusString : String;
    private var _internal_provider : String;
    private var _internal_email : String;
    private var _internal_login : String;
    private var _internal_uuid : String;

    private static var emptyArray:Array = new Array();


    /**
     * derived property cache initialization
     */
    model_internal var _cacheInitialized_isValid:Boolean = false;

    model_internal var _changeWatcherArray:Array = new Array();

    public function _Super_ResultsGet()
    {
        _model = new _ResultsGetEntityMetadata(this);

        // Bind to own data or source properties for cache invalidation triggering
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "password", model_internal::setterListenerPassword));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "statusCode", model_internal::setterListenerStatusCode));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "statusString", model_internal::setterListenerStatusString));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "provider", model_internal::setterListenerProvider));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "email", model_internal::setterListenerEmail));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "login", model_internal::setterListenerLogin));
        model_internal::_changeWatcherArray.push(mx.binding.utils.ChangeWatcher.watch(this, "uuid", model_internal::setterListenerUuid));

    }

    /**
     * data/source property getters
     */

    [Bindable(event="propertyChange")]
    public function get password() : String
    {
        return _internal_password;
    }

    [Bindable(event="propertyChange")]
    public function get statusCode() : String
    {
        return _internal_statusCode;
    }

    [Bindable(event="propertyChange")]
    public function get statusString() : String
    {
        return _internal_statusString;
    }

    [Bindable(event="propertyChange")]
    public function get provider() : String
    {
        return _internal_provider;
    }

    [Bindable(event="propertyChange")]
    public function get email() : String
    {
        return _internal_email;
    }

    [Bindable(event="propertyChange")]
    public function get login() : String
    {
        return _internal_login;
    }

    [Bindable(event="propertyChange")]
    public function get uuid() : String
    {
        return _internal_uuid;
    }

    public function clearAssociations() : void
    {
    }

    /**
     * data/source property setters
     */

    public function set password(value:String) : void
    {
        var oldValue:String = _internal_password;
        if (oldValue !== value)
        {
            _internal_password = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "password", oldValue, _internal_password));
        }
    }

    public function set statusCode(value:String) : void
    {
        var oldValue:String = _internal_statusCode;
        if (oldValue !== value)
        {
            _internal_statusCode = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusCode", oldValue, _internal_statusCode));
        }
    }

    public function set statusString(value:String) : void
    {
        var oldValue:String = _internal_statusString;
        if (oldValue !== value)
        {
            _internal_statusString = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "statusString", oldValue, _internal_statusString));
        }
    }

    public function set provider(value:String) : void
    {
        var oldValue:String = _internal_provider;
        if (oldValue !== value)
        {
            _internal_provider = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "provider", oldValue, _internal_provider));
        }
    }

    public function set email(value:String) : void
    {
        var oldValue:String = _internal_email;
        if (oldValue !== value)
        {
            _internal_email = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "email", oldValue, _internal_email));
        }
    }

    public function set login(value:String) : void
    {
        var oldValue:String = _internal_login;
        if (oldValue !== value)
        {
            _internal_login = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "login", oldValue, _internal_login));
        }
    }

    public function set uuid(value:String) : void
    {
        var oldValue:String = _internal_uuid;
        if (oldValue !== value)
        {
            _internal_uuid = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "uuid", oldValue, _internal_uuid));
        }
    }

    /**
     * Data/source property setter listeners
     *
     * Each data property whose value affects other properties or the validity of the entity
     * needs to invalidate all previously calculated artifacts. These include:
     *  - any derived properties or constraints that reference the given data property.
     *  - any availability guards (variant expressions) that reference the given data property.
     *  - any style validations, message tokens or guards that reference the given data property.
     *  - the validity of the property (and the containing entity) if the given data property has a length restriction.
     *  - the validity of the property (and the containing entity) if the given data property is required.
     */

    model_internal function setterListenerPassword(value:flash.events.Event):void
    {
        _model.invalidateDependentOnPassword();
    }

    model_internal function setterListenerStatusCode(value:flash.events.Event):void
    {
        _model.invalidateDependentOnStatusCode();
    }

    model_internal function setterListenerStatusString(value:flash.events.Event):void
    {
        _model.invalidateDependentOnStatusString();
    }

    model_internal function setterListenerProvider(value:flash.events.Event):void
    {
        _model.invalidateDependentOnProvider();
    }

    model_internal function setterListenerEmail(value:flash.events.Event):void
    {
        _model.invalidateDependentOnEmail();
    }

    model_internal function setterListenerLogin(value:flash.events.Event):void
    {
        _model.invalidateDependentOnLogin();
    }

    model_internal function setterListenerUuid(value:flash.events.Event):void
    {
        _model.invalidateDependentOnUuid();
    }


    /**
     * valid related derived properties
     */
    model_internal var _isValid : Boolean;
    model_internal var _invalidConstraints:Array = new Array();
    model_internal var _validationFailureMessages:Array = new Array();

    /**
     * derived property calculators
     */
    

    /**
     * isValid calculator
     */
    model_internal function calculateIsValid():Boolean
    {
        var violatedConsts:Array = new Array();
        var validationFailureMessages:Array = new Array();

        var propertyValidity:Boolean = true;
        if (!_model.passwordIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_passwordValidationFailureMessages);
        }
        if (!_model.statusCodeIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_statusCodeValidationFailureMessages);
        }
        if (!_model.statusStringIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_statusStringValidationFailureMessages);
        }
        if (!_model.providerIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_providerValidationFailureMessages);
        }
        if (!_model.emailIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_emailValidationFailureMessages);
        }
        if (!_model.loginIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_loginValidationFailureMessages);
        }
        if (!_model.uuidIsValid)
        {
            propertyValidity = false;
            com.adobe.fiber.util.FiberUtils.arrayAdd(validationFailureMessages, _model.model_internal::_uuidValidationFailureMessages);
        }

        model_internal::_cacheInitialized_isValid = true;
        model_internal::invalidConstraints_der = violatedConsts;
        model_internal::validationFailureMessages_der = validationFailureMessages;
        return violatedConsts.length == 0 && propertyValidity;
    }

    /**
     * derived property setters
     */

    model_internal function set isValid_der(value:Boolean) : void
    {
        var oldValue:Boolean = model_internal::_isValid;
        if (oldValue !== value)
        {
            model_internal::_isValid = value;
            _model.model_internal::fireChangeEvent("isValid", oldValue, model_internal::_isValid);
        }
    }

    /**
     * derived property getters
     */

    [Transient]
    [Bindable(event="propertyChange")]
    public function get _model() : _ResultsGetEntityMetadata
    {
        return model_internal::_dminternal_model;
    }

    public function set _model(value : _ResultsGetEntityMetadata) : void
    {
        var oldValue : _ResultsGetEntityMetadata = model_internal::_dminternal_model;
        if (oldValue !== value)
        {
            model_internal::_dminternal_model = value;
            this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, "_model", oldValue, model_internal::_dminternal_model));
        }
    }

    /**
     * methods
     */


    /**
     *  services
     */
    private var _managingService:com.adobe.fiber.services.IFiberManagingService;

    public function set managingService(managingService:com.adobe.fiber.services.IFiberManagingService):void
    {
        _managingService = managingService;
    }

    model_internal function set invalidConstraints_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_invalidConstraints;
        // avoid firing the event when old and new value are different empty arrays
        if (oldValue !== value && (oldValue.length > 0 || value.length > 0))
        {
            model_internal::_invalidConstraints = value;
            _model.model_internal::fireChangeEvent("invalidConstraints", oldValue, model_internal::_invalidConstraints);
        }
    }

    model_internal function set validationFailureMessages_der(value:Array) : void
    {
        var oldValue:Array = model_internal::_validationFailureMessages;
        // avoid firing the event when old and new value are different empty arrays
        if (oldValue !== value && (oldValue.length > 0 || value.length > 0))
        {
            model_internal::_validationFailureMessages = value;
            _model.model_internal::fireChangeEvent("validationFailureMessages", oldValue, model_internal::_validationFailureMessages);
        }
    }

    model_internal var _doValidationCacheOfPassword : Array = null;
    model_internal var _doValidationLastValOfPassword : String;

    model_internal function _doValidationForPassword(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfPassword != null && model_internal::_doValidationLastValOfPassword == value)
           return model_internal::_doValidationCacheOfPassword ;

        _model.model_internal::_passwordIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isPasswordAvailable && _internal_password == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "password is required"));
        }

        model_internal::_doValidationCacheOfPassword = validationFailures;
        model_internal::_doValidationLastValOfPassword = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfStatusCode : Array = null;
    model_internal var _doValidationLastValOfStatusCode : String;

    model_internal function _doValidationForStatusCode(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfStatusCode != null && model_internal::_doValidationLastValOfStatusCode == value)
           return model_internal::_doValidationCacheOfStatusCode ;

        _model.model_internal::_statusCodeIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isStatusCodeAvailable && _internal_statusCode == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "statusCode is required"));
        }

        model_internal::_doValidationCacheOfStatusCode = validationFailures;
        model_internal::_doValidationLastValOfStatusCode = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfStatusString : Array = null;
    model_internal var _doValidationLastValOfStatusString : String;

    model_internal function _doValidationForStatusString(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfStatusString != null && model_internal::_doValidationLastValOfStatusString == value)
           return model_internal::_doValidationCacheOfStatusString ;

        _model.model_internal::_statusStringIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isStatusStringAvailable && _internal_statusString == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "statusString is required"));
        }

        model_internal::_doValidationCacheOfStatusString = validationFailures;
        model_internal::_doValidationLastValOfStatusString = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfProvider : Array = null;
    model_internal var _doValidationLastValOfProvider : String;

    model_internal function _doValidationForProvider(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfProvider != null && model_internal::_doValidationLastValOfProvider == value)
           return model_internal::_doValidationCacheOfProvider ;

        _model.model_internal::_providerIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isProviderAvailable && _internal_provider == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "provider is required"));
        }

        model_internal::_doValidationCacheOfProvider = validationFailures;
        model_internal::_doValidationLastValOfProvider = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfEmail : Array = null;
    model_internal var _doValidationLastValOfEmail : String;

    model_internal function _doValidationForEmail(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfEmail != null && model_internal::_doValidationLastValOfEmail == value)
           return model_internal::_doValidationCacheOfEmail ;

        _model.model_internal::_emailIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isEmailAvailable && _internal_email == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "email is required"));
        }

        model_internal::_doValidationCacheOfEmail = validationFailures;
        model_internal::_doValidationLastValOfEmail = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfLogin : Array = null;
    model_internal var _doValidationLastValOfLogin : String;

    model_internal function _doValidationForLogin(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfLogin != null && model_internal::_doValidationLastValOfLogin == value)
           return model_internal::_doValidationCacheOfLogin ;

        _model.model_internal::_loginIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isLoginAvailable && _internal_login == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "login is required"));
        }

        model_internal::_doValidationCacheOfLogin = validationFailures;
        model_internal::_doValidationLastValOfLogin = value;

        return validationFailures;
    }
    
    model_internal var _doValidationCacheOfUuid : Array = null;
    model_internal var _doValidationLastValOfUuid : String;

    model_internal function _doValidationForUuid(valueIn:Object):Array
    {
        var value : String = valueIn as String;

        if (model_internal::_doValidationCacheOfUuid != null && model_internal::_doValidationLastValOfUuid == value)
           return model_internal::_doValidationCacheOfUuid ;

        _model.model_internal::_uuidIsValidCacheInitialized = true;
        var validationFailures:Array = new Array();
        var errorMessage:String;
        var failure:Boolean;

        var valRes:ValidationResult;
        if (_model.isUuidAvailable && _internal_uuid == null)
        {
            validationFailures.push(new ValidationResult(true, "", "", "uuid is required"));
        }

        model_internal::_doValidationCacheOfUuid = validationFailures;
        model_internal::_doValidationLastValOfUuid = value;

        return validationFailures;
    }
    

}

}
