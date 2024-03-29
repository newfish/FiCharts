package com.fiCharts.charts.chart2D.column2D
{
	import com.fiCharts.charts.chart2D.core.itemRender.ItemRenderProxy;
	import com.fiCharts.utils.XMLConfigKit.style.LabelStyle;
	
	/**
	 * 只做显示用，不接收鼠标事件;
	 */	
	public class ColumnItemRender extends ItemRenderProxy
	{
		public function ColumnItemRender(visible:Boolean = true)
		{
			super(visible);
		}
		
		/**
		 */		
		override public function render():void
		{
			super.render();
		}
		
		/**
		 */		
		override public function layout():void
		{
			x = _itemVO.dataItemX;
			y = _itemVO.dataItemY;
			
			if (this.valueLabel.enable)
			{
				if(valueLabelUI == null)
				{
					valueLabelUI = createValueLabelUI();
					//addChild(valueLabelUI);
					
					if (valueLabel.layout == LabelStyle.NORMAL)
						layoutValueLabel();
				}
				
				if (valueLabel.layout == LabelStyle.INNER)
					layoutInnerLabel();
			}
		}
		
		/**
		 */		
		protected function layoutInnerLabel():void
		{
			var temHeight:Number = Math.abs(columnDataItem.height)
			var temX:Number;
			var temY:Number;
			valueLabelUI.rotation = 0;
			
			if (columnDataItem.width < valueLabelUI.width)
			{
				valueLabelUI.rotation = - 90;
				temX = - valueLabelUI.width / 2;
				if (Number(_itemVO.yValue) < 0)
					temY = - this.style.radius;
				else
					temY = this.style.radius + valueLabelUI.height;
				
				if (temHeight < valueLabelUI.height)
					valueLabelUI.visible = false;
				else
					valueLabelUI.visible = true;
			}
			else
			{
				temX = - valueLabelUI.width / 2;
				if (Number(_itemVO.yValue) < 0)
					temY = - valueLabelUI.height - this.style.radius;
				else
					temY = this.style.radius;
				
				// 当柱体太小不能容纳标签时隐藏标签；
				if (temHeight < valueLabelUI.height)
					valueLabelUI.visible = false;
				else
					valueLabelUI.visible = true;
			}
			
			valueLabelUI.x = temX;
			valueLabelUI.y = temY;
		}
		
		/**
		 */		
		protected function get columnDataItem():ColumnDataItem
		{
			return this.itemVO as ColumnDataItem;
		}

	}
}