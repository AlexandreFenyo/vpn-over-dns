
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
internal class _ResultsEntityMetadata extends com.adobe.fiber.valueobjects.AbstractEntityMetadata
{
    private static var emptyArray:Array = new Array();

    model_internal static var allProperties:Array = new Array("statusCode", "statusString");
    model_internal static var allAssociationProperties:Array = new Array();
    model_internal static var allRequiredProperties:Array = new Array("statusCode", "statusString");
    model_internal static var allAlwaysAvailableProperties:Array = new Array("statusCode", "statusString");
    model_internal static var guardedProperties:Array = new Array();
    model_internal static var dataProperties:Array = new Array("statusCode", "statusString");
    model_internal static var sourceProperties:Array = emptyArray
    model_internal static var nonDerivedProperties:Array = new Array("statusCode", "statusString");
    model_internal static var derivedProperties:Array = new Array();
    model_internal static var collectionProperties:Array = new Array();
    model_internal static var collectionBaseMap:Object;
    model_internal static var entityName:String = "Results";
    model_internal static var dependentsOnMap:Object;
    model_internal static var dependedOnServices:Array = new Array();
    model_internal static var propertyTypeMap:Object;

    
    model_internal var _statusCodeIsValid:Boolean;
    model_internal var _statusCodeValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _statusCodeIsValidCacheInitialized:Boolean = false;
    model_internal var _statusCodeValidationFailureMessages:Array;
    
    model_internal var _statusStringIsValid:Boolean;
    model_internal var _statusStringValidator:com.adobe.fiber.styles.StyleValidator;
    model_internal var _statusStringIsValidCacheInitialized:Boolean = false;
    model_internal var _statusStringValidationFailureMessages:Array;

    model_internal var _instance:_Super_Results;
    model_internal static var _nullStyle:com.adobe.fiber.styles.Style = new com.adobe.fiber.styles.Style();

    public function _ResultsEntityMetadata(value : _Super_Results)
    {
        // initialize property maps
        if (model_internal::dependentsOnMap == null)
        {
            // dependents map
            model_internal::dependentsOnMap = new Object();
            model_internal::dependentsOnMap["statusCode"] = new Array();
            model_internal::dependentsOnMap["statusString"] = new Array();

            // collection base map
            model_internal::collectionBaseMap = new Object();
        }

        // Property type Map
        model_internal::propertyTypeMap = new Object();
        model_internal::propertyTypeMap["statusCode"] = "String";
        model_internal::propertyTypeMap["statusString"] = "String";

        model_internal::_instance = value;
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
            throw new Error(propertyName + " is not a data property of entity Results");
            
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
            throw new Error(propertyName + " is not a collection property of entity Results");

        return model_internal::collectionBaseMap[propertyName];
    }
    
    override public function getPropertyType(propertyName:String):String
    {
        if (model_internal::allProperties.indexOf(propertyName) == -1)
            throw new Error(propertyName + " is not a property of Results");

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
            throw new Error(propertyName + " does not exist for entity Results");
        }

        return model_internal::_instance[propertyName];
    }

    override public function setValue(propertyName:String, value:*):void
    {
        if (model_internal::nonDerivedProperties.indexOf(propertyName) == -1)
        {
            throw new Error(propertyName + " is not a modifiable property of entity Results");
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
            throw new Error(propertyName + " does not exist for entity Results");
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
    public function get isStatusCodeAvailable():Boolean
    {
        return true;
    }

    [Bindable(event="propertyChange")]
    public function get isStatusStringAvailable():Boolean
    {
        return true;
    }


    /**
     * derived property recalculation
     */
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

    model_internal function fireChangeEvent(propertyName:String, oldValue:Object, newValue:Object):void
    {
        this.dispatchEvent(mx.events.PropertyChangeEvent.createUpdateEvent(this, propertyName, oldValue, newValue));
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
            case("statusCode"):
            {
                return statusCodeValidationFailureMessages;
            }
            case("statusString"):
            {
                return statusStringValidationFailureMessages;
            }
            default:
            {
                return emptyArray;
            }
         }
     }

}

}
