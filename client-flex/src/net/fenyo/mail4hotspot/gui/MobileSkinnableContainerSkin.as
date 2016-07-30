// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

//package spark.skins.mobile
package net.fenyo.mail4hotspot.gui
{
	import spark.components.Group;
	import spark.components.SkinnableContainer;
	import spark.skins.mobile.supportClasses.MobileSkin;

	import flash.display.*;

	/**
	 *  ActionScript-based skin for SkinnableContainer in mobile applications.
	 * 
	 *  @langversion 3.0
	 *  @playerversion Flash 10.1
	 *  @playerversion AIR 2.5 
	 *  @productversion Flex 4.5
	 */
	//public class SkinnableContainerSkin extends MobileSkin
	public class MobileSkinnableContainerSkin extends MobileSkin
	{
		[Bindable]
		[Embed(source="/assets/fond-Snow-UI-Kit.png")]
		private var MyGfx : Class; 

		[Bindable]
		[Embed(source="/assets/fond-shiny.png")] 
		private var MyGfx2 : Class; 

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		/**
		 *  Constructor. 
		 * 
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 2.5 
		 *  @productversion Flex 4.5
		 * 
		 */ 
		public function MobileSkinnableContainerSkin()
		{
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		//  SkinParts
		//
		//--------------------------------------------------------------------------
		/**
		 *  An optional skin part that defines the Group where the content 
		 *  children get pushed into and laid out.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 2.5
		 *  @productversion Flex 4.5
		 */
		public var contentGroup:Group;
		
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		/** 
		 * @copy spark.skins.spark.ApplicationSkin#hostComponent
		 */
		public var hostComponent:SkinnableContainer; // SkinnableComponent will popuplate
		
		//--------------------------------------------------------------------------
		//
		//  Overridden methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private 
		 */ 
		override protected function commitCurrentState():void
		{
			super.commitCurrentState();
			
			alpha = currentState.indexOf("disabled") == -1 ? 1 : 0.5;
		}
		
		/**
		 *  @private 
		 */ 
		override protected function createChildren():void
		{      
			contentGroup = new Group();
			contentGroup.id = "contentGroup";
			contentGroup.left = contentGroup.right = contentGroup.top = contentGroup.bottom = 0;
			contentGroup.minWidth = contentGroup.minHeight = 0;
			
			addChild(contentGroup);
		}
		
		/**
		 *  @private 
		 */ 
		override protected function measure():void
		{        
			super.measure();
			
			measuredWidth = contentGroup.getPreferredBoundsWidth();
			measuredHeight = contentGroup.getPreferredBoundsHeight();
		}
		
		/**
		 *  @private
		 */
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.layoutContents(unscaledWidth, unscaledHeight);
			
			contentGroup.setLayoutBoundsSize(unscaledWidth, unscaledHeight);
			contentGroup.setLayoutBoundsPosition(0, 0);
		}
		
		/**
		 *  @private
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.drawBackground(unscaledWidth, unscaledHeight);

			// Draw the background
//			graphics.beginFill(getStyle("backgroundColor"), getStyle("backgroundAlpha"));
//			graphics.beginFill(2500, getStyle("backgroundAlpha"));
//			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
//			graphics.endFill();
			var myBitmap : BitmapData;
			if (!Main.new_skin) myBitmap = new MyGfx().bitmapData;
			else myBitmap = new MyGfx2().bitmapData;
			graphics.beginBitmapFill(myBitmap);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill(); 
		}
	}
}
