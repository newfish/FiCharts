package com.fiCharts.charts.chart2D.bar
{
	import com.fiCharts.charts.chart2D.column2D.ColumnItemRender;
	
	/**
	 */	
	public class BarItemRender extends ColumnItemRender
	{
		public function BarItemRender(visible:Boolean = false)
		{
			super(visible);
			
			this.isHorizontal = true;
		}
		
		/**
		 */		
		override protected function layoutInnerLabel():void
		{
			valueLabelUI.y = - valueLabelUI.height / 2;
			
			if (Number(_itemVO.xValue) > 0)
				valueLabelUI.x = - valueLabelUI.width - this.style.radius;
			else
				valueLabelUI.x = this.style.radius;
				
				// 当柱体太小不能容纳标签时隐藏标签；
				if (Math.abs(columnDataItem.width) < valueLabelUI.width)
					valueLabelUI.visible = false;
				else
					valueLabelUI.visible = true;
		}
		
		/**
		 */		
		override protected function layoutValueLabel():void
		{
			valueLabelUI.y = - valueLabelUI.height / 2;
			
			if (Number(_itemVO.xValue) > 0)
				valueLabelUI.x = this.style.radius;
			else
				valueLabelUI.x = - this.style.radius - valueLabelUI.width;
		}
		
	}
}