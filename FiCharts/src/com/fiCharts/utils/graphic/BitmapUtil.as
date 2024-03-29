package com.fiCharts.utils.graphic
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;

	public class BitmapUtil
	{
		public function BitmapUtil()
		{
		}
		
		/**
		 * 抓取显示对象的位图数据；
		 */		
		public static function draw(target:DisplayObject):BitmapData
		{
			var myBitmapData:BitmapData = new BitmapData(target.width, target.height, true, 0xFFFFFF);
			myBitmapData.draw(target, null, null, null, null, false);
			
			return myBitmapData;
		}
		
		/**
		 */		
		public static function drawWithSize(target:DisplayObject, width:Number, height:Number, mar:Matrix = null):BitmapData
		{
			var myBitmapData:BitmapData = new BitmapData(width, height, true, 0xFFFFFF);
			myBitmapData.draw(target, mar, null, null, null, true);
			
			return myBitmapData;
		}
	}
}