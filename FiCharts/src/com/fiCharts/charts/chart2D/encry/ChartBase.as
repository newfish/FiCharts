package com.fiCharts.charts.chart2D.encry
{
	import com.fiCharts.charts.chart2D.area2D.AreaSeries2D;
	import com.fiCharts.charts.chart2D.bar.BarSeries;
	import com.fiCharts.charts.chart2D.bar.stack.StackedBarSeries;
	import com.fiCharts.charts.chart2D.bar.stack.StackedPercentBarSeries;
	import com.fiCharts.charts.chart2D.bubble.BubbleItemRender;
	import com.fiCharts.charts.chart2D.bubble.BubbleSeries;
	import com.fiCharts.charts.chart2D.column2D.ColumnSeries2D;
	import com.fiCharts.charts.chart2D.column2D.stack.StackedColumnCombieItemRender;
	import com.fiCharts.charts.chart2D.column2D.stack.StackedColumnSeries;
	import com.fiCharts.charts.chart2D.column2D.stack.StackedPercentColumnSeries;
	import com.fiCharts.charts.chart2D.column2D.stack.StackedSeries;
	import com.fiCharts.charts.chart2D.core.Chart2DStyleSheet;
	import com.fiCharts.charts.chart2D.core.ScrollImageRenderForDataResize;
	import com.fiCharts.charts.chart2D.core.TitleBox;
	import com.fiCharts.charts.chart2D.core.axis.AxisBase;
	import com.fiCharts.charts.chart2D.core.axis.AxisContianer;
	import com.fiCharts.charts.chart2D.core.axis.DataRange;
	import com.fiCharts.charts.chart2D.core.axis.LinearAxis;
	import com.fiCharts.charts.chart2D.core.backgound.ChartBGUI;
	import com.fiCharts.charts.chart2D.core.backgound.GridFieldUI;
	import com.fiCharts.charts.chart2D.core.events.DataResizeEvent;
	import com.fiCharts.charts.chart2D.core.events.FiChartsEvent;
	import com.fiCharts.charts.chart2D.core.itemRender.ItemRenderBace;
	import com.fiCharts.charts.chart2D.core.itemRender.ItemRenderEvent;
	import com.fiCharts.charts.chart2D.core.model.AxisModel;
	import com.fiCharts.charts.chart2D.core.model.Chart2DModel;
	import com.fiCharts.charts.chart2D.core.model.Series;
	import com.fiCharts.charts.chart2D.core.series.ChartCanvas;
	import com.fiCharts.charts.chart2D.marker.MarkerSeries;
	import com.fiCharts.charts.common.IChart;
	import com.fiCharts.charts.legend.LegendPanel;
	import com.fiCharts.charts.legend.LegendStyle;
	import com.fiCharts.charts.legend.model.LegendVO;
	import com.fiCharts.ui.toolTips.ToolTipsManager;
	import com.fiCharts.ui.toolTips.TooltipDataItem;
	import com.fiCharts.utils.ExternalUtil;
	import com.fiCharts.utils.RexUtil;
	import com.fiCharts.utils.StageUtil;
	import com.fiCharts.utils.XMLConfigKit.XMLVOLib;
	import com.fiCharts.utils.XMLConfigKit.XMLVOMapper;
	import com.fiCharts.utils.XMLConfigKit.style.LabelUI;
	import com.fiCharts.utils.graphic.BitmapUtil;
	import com.fiCharts.utils.system.GC;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	/**
	 */
	[Event(name="legendDataChanged", type = "com.fiCharts.charts.chart2D.core.events.FiChartsEvent")]
	[Event(name="ready", type = "com.fiCharts.charts.chart2D.core.events.FiChartsEvent")]
	[Event(name="itemClicked", type = "com.fiCharts.charts.chart2D.core.events.FiChartsEvent")]
	[Event(name="rendered", type = "com.fiCharts.charts.chart2D.core.events.FiChartsEvent")]
	
	/**
	 * ChartBase
	 */	
	public class ChartBase extends Sprite implements IChart
	{
		/**
		 *  Constructor.
		 */
		public function ChartBase()
		{
			super();
			
			// Class list.
			
			//LineSeries;
			AreaSeries2D;
			MarkerSeries; 
			BubbleSeries;
			
			//ColumnSeries2D;
			StackedColumnSeries;
			StackedPercentColumnSeries;
			StackedSeries;	
			
			BarSeries;
			StackedBarSeries;
			StackedPercentBarSeries;
			
			init();
		}
		
		
		
		
		//----------------------------------------------------------------------------------------
		//
		// 数据 缩放与滚动处理访方式类似，缩放过程中和滚动过程中的
		//
		// 性能开销很大，需优化区别对待
		//
		//
		//  完成缩放时：
		//  1.坐标轴计算计算尺寸缩放关系，生成新label数据， label位置偏移式定位； 
		//  2.序列整体渲染， 截图整体序列和渲染节点，数据标签，供后继滚动用
		//  3.背景网格全数据渲染，仅范围内可见
		//  4.label容器，背景网格容器位置清零
		//
		//  开始滚动时：
		//  1.序列截图呈现
		//  2.坐标label容器， 背景网格和截图一起鼠标一起移动；
		//  
		//
		//  移动结束时：
		//  1.坐标轴根据移动位置计算新的取值范围，从而得出新的位置偏移量
		//  2.根据新的数据范围渲染序列等
		//  3.移除序列截图
		//  (移动过程中坐标轴的fullSize没有变，数据范围差值没有变，刻度数据没有变，仅是移动幻象而已)
		//  (尺寸缩放过程中进渲染一次全序列，其他都是局部序列渲染) 
		//
		//
		//
		//  缩放和滚动的截图一次截序列宽度的3倍大小
		//  1.先给3倍范围内数据给序列让其渲染
		//  2.按照尺寸范围截取序列的图
		//  3.将截图交给截图呈现器
		//  4.只有滚动和缩放时截图才呈现
		//  5.当截图范围不能满足需要时，给新数据并重新截图
		//  6.截图不会重复绘制，尺寸缩放后先清空截图呈现器
		//
		//--------------------------------------------------------------------------------------
		
		
		/**
		 */		
		public function setDataScalable(value:Boolean):void
		{
			chartModel.dataScale.enable = value;
		}
		
		/**
		 * 
		 * 动态进行数据缩放的对外接口, 用于Flash/AIR等类型的项目中， web用配置文件方式处理数据缩放
		 * 
		 */		
		public function scaleData(startValue:Object, endValue:Object):void
		{
			if (chartModel.dataScale.enable)
			{
				currentDataRange.min = scrollBaseAxis.getDataPercent(startValue);
				currentDataRange.max = scrollBaseAxis.getDataPercent(endValue);		
				
				this.dataResized(currentDataRange.min, currentDataRange.max);
			}
		}
		
		/**
		 */		
		private function initDataResizeContorl():void
		{
			 stage.addEventListener(MouseEvent.MOUSE_DOWN, stageDownHadler, false, 0, true);
			 stage.addEventListener(MouseEvent.MOUSE_UP, stopMoveHandler);
			 stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler, false, 0, true);
			 
			 ExternalUtil.addCallback("onWebmousewheel", onWebMouseWheel);
		}
		
		/**
		 * 网页中的Flash无法接受滚轮，需要先屏蔽web中的滚轮事件，将滚动值传给Flash
		 */		
		private function onWebMouseWheel(value:Number):void
		{
			if(chartModel.dataScale.enable)
			{
				var percent:Number = this.mouseX / this.chartWidth;
				var dis:Number = this.currentDataRange.max - this.currentDataRange.min;
				
				var targetPer:Number = this.currentDataRange.min + dis * percent;
				var newStart:Number, newEnd:Number;
				var zoomPer:Number = dis * chartModel.dataScale.zoomScale;
				var minZoom:Number = zoomPer * targetPer;
				var maxZoom:Number = zoomPer - minZoom;
				
				if (value > 0) // 放大
				{
					if (dis <= 1 / chartModel.dataScale.maxScale) return;
					
					newStart = this.currentDataRange.min + minZoom
					newEnd = this.currentDataRange.max - maxZoom
				}
				else// 缩小
				{
					newStart = this.currentDataRange.min - minZoom;
					newEnd = this.currentDataRange.max + maxZoom
					
					if (newStart < 0 && newEnd <= 1)
					{
						newEnd += zoomPer;
						newStart = 0;
					}
					else if (newEnd > 1 && newStart >= 0)
					{
						newStart -= zoomPer;
						newEnd = 1;
					}
				}
				
				if (newStart < 0)
					newStart = 0;
				
				if (newEnd > 1)
					newEnd = 1;
				
				this.dataResized(newStart, newEnd);
				
			}
		}
		
		/**
		 */		
		private function mouseWheelHandler(evt:MouseEvent):void
		{
			onWebMouseWheel(evt.delta);
		}
		
		/**
		 */		
		private function stopMoveHandler(evt:MouseEvent):void
		{
			if(chartModel.dataScale.enable)
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, checkScrollHandler);
		}
		
		/**
		 */		
		private function stageDownHadler(evt:MouseEvent):void
		{
			if(chartModel.dataScale.enable)
			{
				currentPosition = evt.stageX;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, checkScrollHandler);
			}
		}
		
		/**
		 */		
		private function checkScrollHandler(evt:MouseEvent):void
		{
			if (currentDataRange.min == 0 && currentDataRange.max == 1) return;
			
			var offset:Number = evt.stageX - currentPosition; 
			
			// 只要有一次移动距离大于特定值就证明开始了滚动
			if (ifSrollingData == false && Math.abs(offset) >= 3)
			{
				ifSrollingData = true;
				stage.addEventListener(MouseEvent.MOUSE_UP, endScrollHadler);
				chartCanvas.visible = chartCanvas.mouseChildren = chartCanvas.mouseEnabled = false;
				this.scrollImgRender.visible = true;
				
				firstDraw();
			}
			
			if (ifSrollingData)
			{
				scrollData(offset);
				currentPosition = evt.stageX;
				//evt.updateAfterEvent();
			}
		}
		
		/**
		 */		
		private function endScrollHadler(evt:MouseEvent):void
		{
			ifSrollingData = false;
			
			this.chartCanvas.clearValuelabels();
			scrollBaseAxis.dataScrolled(this.currentDataRange);
			
			chartCanvas.visible = true;
			scrollImgRender.visible = false;
			this.chartCanvas.mouseChildren = chartCanvas.mouseEnabled = true;
			
			stage.removeEventListener(MouseEvent.MOUSE_UP, endScrollHadler);
		}
		
		/**
		 * 数据滚动的过程中序列是不渲染的，只是移动的截图
		 */		
		private function scrollData(offset:Number):void
		{
			scrollBaseAxis.srcollingData(offset);
			
			this.gridField.scrollHGrid(scrollBaseAxis.currentScrollPos);
			this.scrollImgRender.scroll(scrollBaseAxis.currentScrollPos);
			
			var start:Number;
			var end:Number;
			
			if (- scrollBaseAxis.currentScrollPos + this.sizeX > scrollImgRender.endPos)
			{
				start = scrollBaseAxis.posToPercent(scrollImgRender.endPos + scrollBaseAxis.currentScrollPos);
				end = start + dataDis;
				
				renderSeriesForDraw(start, end);
			}
			
			if (scrollBaseAxis.currentScrollPos + scrollImgRender.startPos > 0)
			{
				end = scrollBaseAxis.posToPercent(scrollImgRender.startPos 
					+ scrollBaseAxis.currentScrollPos);
				
				start = end - dataDis;
				
				renderSeriesForDraw(start, end);
			}
			
		}
		
		/**
		 * 不是鼠标按下后一移动就还是数据滚动，而是移动一小段距离后才
		 * 
		 * 正式开始滚动数据
		 */		
		private var ifSrollingData:Boolean = false;
		
		/**
		 */		
		private var currentPosition:Number = 0;
		
		/**
		 *
		 * 制定数据范围，此范围是在整体数据中的比例范围， 因尺寸缩放比例好根据
		 * 
		 * 设备输入值计算，用户操控用比例方式计算，接口用原始数据转换；
		 *  
		 */		
		private function dataResized(startPercent:Number, endPercent:Number):void
		{
			if( startPercent >= 0 && startPercent <= 1 && endPercent >= 0 && endPercent <= 1)
			{
				currentDataRange.min = startPercent;
				currentDataRange.max = endPercent;
				
				// 每次都会重新绘制   数值标签， 只有范围内的数值标签才会被渲染，其他都被清空掉；
				this.chartCanvas.clearValuelabels();
				
				// 坐标轴会驱动序列按照节点位置或数据范围方式完成, 序列再驱动渲染节点等的更新
				scrollBaseAxis.dataResized(currentDataRange.min, currentDataRange.max);
				scrollBaseAxis.renderHoriticalAxis();
				
				this.combileItemRender();
				gridField.render(this.hAxises[0].ticks, this.vAxises[0].ticks, chartModel.gridField);
				
				if (this.chartModel.dataScale.enable && scrollImgRender  == null)
				{
					scrollImgRender = new ScrollImageRenderForDataResize;
					scrollImgRender.x = this.originX;
					scrollImgRender.y = this.originY;
					scrollImgRender.visible = false;
					this.addChild(scrollImgRender);					
				}
				
				scrollImgRender.reset();
				ifDrawedAfterResized = false;
			}
		}
		
		/**
		 * 开始拖动时， 一次截取3屏的图表，为当前屏前后各一屏
		 *
		 * 数据滚动过程中，如截屏不够显示则一次截取一瓶动态补上
		 */		
		private function firstDraw():void
		{
			if (ifDrawedAfterResized == false)
			{
				dataDis = currentDataRange.max - currentDataRange.min;
				var drawStart:Number = currentDataRange.min - dataDis;
				var drawEnd:Number = currentDataRange.max + dataDis;
				
				renderSeriesForDraw(drawStart, drawEnd);
				
				ifDrawedAfterResized = true;
			}
		}
		
		/**
		 */		
		private var ifDrawedAfterResized:Boolean = false;
		
		/**
		 * 根据取值比例范围，截取图表的图
		 */		
		private function renderSeriesForDraw(drawStart:Number, drawEnd:Number):void
		{
			if(drawStart < 0)
				drawStart = 0;
			
			if(drawEnd > 1)
				drawEnd = 1;
			
			if (drawStart == 1) return;
			
			this.chartCanvas.clearValuelabels();
			scrollBaseAxis.renderSeries(drawStart, drawEnd);
			
			var startPos:Number = scrollBaseAxis.percentToPos(drawStart);
			var endPos:Number = scrollBaseAxis.percentToPos(drawEnd);
			var posDis:Number = endPos - startPos;;
			
			if (posDis < 5) return;
			
			this.chartMask.visible = false;
			this.chartCanvas.mask = null;
			
			var matr:Matrix = new Matrix;
			matr.tx = - startPos ;
			matr.ty = sizeY;
			
			var myBitmapData:BitmapData = new BitmapData(posDis, sizeY, true, 0xFFFFFF);
			myBitmapData.draw(chartCanvas, matr, null, null, null, false);
			
			this.chartCanvas.mask = chartMask;
			this.chartMask.visible = true;
			
			matr.tx = startPos - scrollBaseAxis.currentScrollPos;
			matr.ty = - sizeY;
			scrollImgRender.draw(myBitmapData, matr, posDis, this.sizeY);
		}
		
		/**
		 */		
		private var scrollImgRender:ScrollImageRenderForDataResize;
		
		/**
		 * 目前仅横向支持数据滚动
		 */		
		private var scrollBaseAxis:AxisBase;
		
		/**
		 * 绘制序列的数值标签
		 */		
		private function drawResizeValueLabels(evt:DataResizeEvent):void
		{
			evt.stopPropagation();
			this.drawValueLabels(evt.sizedItemRenders);
		}
		
		/**
		 */		
		private var dataDis:Number = 0;
		

		/**
		 */		
		private var currentDataRange:DataRange;
		
		
		
		
		
		//----------------------------------
		//
		// 用户定制的配置文件
		//
		//-----------------------------------
		
		private var _customConfig:XML;

		/**
		 */
		public function get customConfig():XML
		{
			return _customConfig;
		}

		/**
		 * @private
		 */
		public function set customConfig(value:XML):void
		{
			_customConfig = value;
		}
		
		/**
		 * 默认如果存在用户配置文件则后继的配置都要继承预先配置文件；
		 * 
		 * 也可以设置忽略预先配置文件；
		 */		
		private var _usePreConfig:Number = 1;

		/**
		 */
		public function get ifCustomConfig():Number
		{
			return _usePreConfig;
		}

		/**
		 * @private
		 */
		public function set ifCustomConfig(value:Number):void
		{
			_usePreConfig = value;
		}
		
		
		
		//---------------------------
		//
		// 数据处理
		//
		//----------------------------
		
		public function get configXML():XML
		{
			return chartProxy.configXML;
		}
		
		/**
		 * 默认配置包含完整信息，既有配置又有数据，也可以只有配置，
		 * 
		 * 数据用dataXML接口传输， 两个接口配合使用既可以实现数据分离；
		 */		
		public function set configXML(value:XML):void
		{
			chartProxy.configXML = value;
			this.initLegend();
			
			chartProxy.setConfigCore(XMLVOMapper.extendFrom(
				chartProxy.currentStyleXML.copy(), configXML.copy()));
			
			if (value.hasOwnProperty('data') && value.data.children().length())
				this.dataXML = XML(value.data.toXMLString());
		}
		
		/**
		 */
		private var _dataXML:XML;

		/**
		 */
		public function set dataXML(value:XML):void
		{
			_dataXML = value;

			ifSourceDataChanged = true;
		}
		
		/**
		 */		
		public function get dataXML():XML
		{
			return _dataXML;
		}

		/**
		 */		
		private var ifSourceDataChanged:Boolean = false;
		
		
		//----------------------------------------------
		//
		// 	Render the chart.
		//
		//-----------------------------------------------

		/**
		 *  When do first render, use this method.
		 */
		public function render():void
		{
			if (configXML && this.dataXML && chartModel.series.length)
				ifRenderable = true;
			
			this.vAxisLabelOffset = this.hAxisLabelOffset = 0;
			
			renderStart();
			
			// 初次渲染时坐标轴尺寸渲染后会变，需要重新调整布局再渲染；
			if(isLayoutUpdated())
			{
				renderStart();
				renderEnd();
			}
			else
			{
				renderEnd();
			}
			
		}
		
		/**
		 */		
		private function renderStart():void
		{
			preLayout();
			preRender();
			coreRender();
		}
		
		/**
		 */		
		private function renderEnd():void
		{
			if(chartModel.dataScale.enable)
			{
				if (currentDataRange == null)
					currentDataRange = new DataRange;
					
				if (this.chartModel.dataScale.changed)
				{
					currentDataRange.min = scrollBaseAxis.getDataPercent(this.chartModel.dataScale.start);
					currentDataRange.max = scrollBaseAxis.getDataPercent(this.chartModel.dataScale.end);		
					this.chartModel.dataScale.changed = false;
				}
				
				this.dataResized(currentDataRange.min, currentDataRange.max);
				scrollImgRender.drawMask(sizeX, sizeY);
			}
			
			//openFlash();
			GC.run();
			ifRenderable = false;
		}
		
		/**
		 */		
		private var ifRenderable:Boolean = false;// TODO
		
		/**
		 */		
		private function preRender():void
		{
			if (ifRenderable)
			{
				configSeriesAxis();
				configSeriesData();
				updateAxisData();
			}
		}
		
		/**
		 * 预先刷新
		 */		
		private function preLayout():void
		{
			leftSpace = temLeftSpace;
			rightSpace = temRightSpace;
			
			topSpace = temTopSpace;
			bottomSpace = temBottomSpace;
			
			updateSizeY();
			updateSizeX();
		}
			
		/**
		 *  This is the true method to render.
		 */
		protected function coreRender():void
		{
			if (ifRenderable)
			{
				renderTitle();
				renderAxis();
				renderSeries();
				renderBG();
				
				if (legendPanel && chartModel.legend.enable)
					legendPanel.render();
				
				layoutChart(); 
			}
		}

		/**
		 */
		private function renderBG():void
		{
			if (ifLayoutChanged)
			{
				chartModel.chartBG.width = chartWidth;
				chartModel.chartBG.height = chartHeight;
				
				chartModel.gridField.width = sizeX;
				chartModel.gridField.height = sizeY;
			}
			
			gridField.render(this.hAxises[0].ticks, this.vAxises[0].ticks, chartModel.gridField);
			chartBG.render(chartModel.chartBG);
		}

		/**
		 */		
		private function renderTitle():void
		{
			if (ifRenderable)
			{
				title.boxWidth = this.sizeX;
				title.render();
				title.x = this.originX;
				
				title.y = (topSpace - this.topAxisContainer.height - title.boxHeight) * .5;
			}
		}
		
		/**
		 *  Draw axisLabels.
		 */
		private function renderAxis():void
		{
			var axis:AxisBase;
			var temOffset:Number = 0;
			if (ifLayoutChanged || this.chartModel.axis.changed)
			{
				for each (axis in hAxises)
				{
					axis.size = sizeX;
					axis.x = originX;
				}
				
				for each (axis in this.vAxises)
				{
					axis.size = sizeY;
					axis.y = originY;
				}
				
				this.chartModel.axis.changed = false;
			}
			
			this.bottomAxisContainer.size = this.topAxisContainer.size = 0;
			for each (axis in hAxises)
			{
				axis.beforeRender();
				axis.renderHoriticalAxis();
				
				temOffset = axis.minUintSize;
				if (temOffset > hAxisLabelOffset)
					hAxisLabelOffset = temOffset;
				
				if (axis.position == 'bottom')
				{
					axis.y = originY + bottomAxisContainer.size;
					bottomAxisContainer.size += axis.height;
				}
				else
				{
					axis.y = originY - this.sizeY - topAxisContainer.size;
					topAxisContainer.size += axis.height;
				}
				
			}
			
			// 坐标轴渲染后才会具有尺寸， 所以布局会在渲染后重新调整；
			this.leftAxisContainer.size = this.rightAxisContainer.size = 0;
			for each (axis in this.vAxises)
			{
				axis.beforeRender();
				axis.renderVerticalAxis();
				
				temOffset = axis.minUintSize;
				if (temOffset > vAxisLabelOffset)
					vAxisLabelOffset = temOffset;
				
				if (axis.position == 'left')
				{
					axis.x = originX - leftAxisContainer.size;
					leftAxisContainer.size += axis.width;
				}
				else
				{
					axis.x = originX + sizeX + rightAxisContainer.size;
					rightAxisContainer.size += axis.width;
				}
			}
		}
		
		/**
		 * 坐标轴的的设定尺寸与实际尺寸穿在相对偏差 ， 因Label引起；
		 */		
		private var hAxisLabelOffset:Number = 0;
		
		/**
		 * 
		 */		
		private var vAxisLabelOffset:Number = 0;
		
		/**
		 */
		protected function renderSeries():void
		{
			var seriesItem:SeriesBase;
			var itemRender:ItemRenderBace;
			
			for each (seriesItem in series)
			{
				seriesItem.seriesWidth = sizeX;
				seriesItem.seriesHeight = sizeY;
				seriesItem.renderSeries();
			}
			
			if (chartModel.series.changed || ifSourceDataChanged)
			{
				itemRenders = [];
				chartCanvas.clearItemRenders();
				
				// 汇总  节点渲染器；
				for each (seriesItem in series)
				{
					// 柱状图与散点图的节点渲染器优先作为主体渲染节点
					if (seriesItem is ColumnSeries2D || seriesItem is MarkerSeries)
					{
						var renders:Array = [];
						renders = renders.concat(seriesItem.itemRenders);
						itemRenders = renders.concat(itemRenders);
					}
					else
					{
						itemRenders = itemRenders.concat(seriesItem.itemRenders);
					}
				}
				
				leftOffBubblesItemRender();// 调节显示列表深度；
				for each (itemRender in itemRenders)
				{
					itemRender.render();
					this.chartCanvas.addItemRender(itemRender);
				}
				
				chartModel.series.changed = ifSourceDataChanged = false;
			}
			
			for each (itemRender in itemRenders)
				itemRender.layout();
				
			combileItemRender();
			
			this.chartCanvas.clearValuelabels();
			drawValueLabels(itemRenders);
		}
		
		/**
		 */		
		private function updateValueLabelHandler(evt:ItemRenderEvent):void
		{
			this.chartCanvas.clearValuelabels();
			drawValueLabels(this.itemRenders);
		}
		
		/**
		 * 当布局或者图例显示状态发生改变时更新数值标签显示；
		 */		
		private function drawValueLabels(renders:Array):void
		{
			var px:Number;
			var py:Number;
			var bd:BitmapData;
			var bm:Bitmap = new Bitmap(bd);
			var mar:Matrix = new Matrix;
			
			for each (var itemRender:ItemRenderBace in renders)
			{
				if (itemRender.valueLabel.enable == false) continue;
				
				px = itemRender.x + itemRender.valueLabelUI.x;
				py = itemRender.y + itemRender.valueLabelUI.y;
				
				mar.tx = px;
				mar.ty = py;
				
				bd = itemRender.valueLabelUI.bitmapData.clone();
				
				if (itemRender.valueLabelUI.visible && itemRender.isEnable && itemRender.visible)
				{
					if (itemRender.valueLabelUI.rotation == 0)
					{
						this.chartCanvas.drawValueLabel(bd, mar, px, py);
					}
					else
					{
						bm = new Bitmap(bd, PixelSnapping.ALWAYS, true);
						bm.x = px;
						bm.y = py;
						bm.rotation = itemRender.valueLabelUI.rotation;
						chartCanvas.addValueLabel(bm);
					}
				}
			}
		}
		
		/**
		 * 把汽包渲染器靠前排列， 这样可以先加入显示列表， 不至于遮盖住其他节点渲染器；
		 */		
		private function leftOffBubblesItemRender():void
		{
			var bubbles:Array = [];
			var length:uint = itemRenders.length;
			for (var i:uint = 0; i < length;)
			{
				if (itemRenders[i] is BubbleItemRender)
				{
					bubbles.push(itemRenders[i]);
					itemRenders.splice(i, 1);
					length -= 1;
				}
				else
				{
					i ++;
				}
			}
			
			bubbles.sort(orderBubbles, Array.NUMERIC);
			itemRenders = bubbles.concat(itemRenders);
		}
		
		/**
		 * 从大到小排列Bubble,大的在下， 小的在上显示；
		 */		
		private function orderBubbles(prev:BubbleItemRender, next:BubbleItemRender):int
		{
			if (Number(prev.itemVO.zValue) < Number(next.itemVO.zValue))
				return 1;
			else if (Number(prev.itemVO.zValue) > Number(next.itemVO.zValue))
				return - 1;
			else 
				return 0;
		}
		
		/**
		 * 将距离较近的节点渲染器合并
		 */		
		private function combileItemRender():void
		{
			var itemRenderLength:uint = itemRenders.length;
			var prevItemRender:ItemRenderBace;
			var nextItemRender:ItemRenderBace;
			var prevLabels:Vector.<TooltipDataItem>;
			var nextLabels:Vector.<TooltipDataItem>;
			var itemDistance:Number;
			var xDis:Number;
			var yDis:Number;
			var labelVO:TooltipDataItem;
			
			for (var i:uint = 0; i < itemRenderLength; i ++)
			{
				prevItemRender = itemRenders[i];
				
				for (var j:uint = i + 1; j < itemRenderLength; j ++)
				{
					nextItemRender = itemRenders[j];
					
					// 两个数据结点均不在渲染范围内，忽略
					if (prevItemRender.visible == false && nextItemRender.visible == false)
						continue;
					
					// 开启 工具提示时才会合并将要显示的toolTip;  
					if (prevItemRender.tooltip.enable && nextItemRender.tooltip.enable)
					{
						prevLabels = prevItemRender.toolTipsHolder.tooltips;
						nextLabels = nextItemRender.toolTipsHolder.tooltips;
						
						if (prevItemRender is StackedColumnCombieItemRender || nextItemRender is StackedColumnCombieItemRender)
						{
							j ++;	
							continue;	
						}
						
						xDis = Math.abs(prevItemRender.itemVO.dataItemX - nextItemRender.itemVO.dataItemX);
						yDis = Math.abs(prevItemRender.itemVO.dataItemY - nextItemRender.itemVO.dataItemY)
						itemDistance = Math.sqrt(xDis * xDis + yDis * yDis);
						
						for each (labelVO in nextLabels)
						{
							// 合并节点
							if (itemDistance <= (prevItemRender.radius + nextItemRender.radius) &&
								prevLabels.indexOf(labelVO) == - 1 && nextItemRender.isEnable && !(nextItemRender is BubbleItemRender)) 
							{
								prevLabels.push(labelVO);
								nextItemRender.disable();// 销毁节点渲染器， 不再接受事件；
							}// 分离节点
							else if (itemDistance > (prevItemRender.radius + nextItemRender.radius) && 
								prevLabels.indexOf(labelVO) != - 1 && !nextItemRender.isEnable)
							{
								prevLabels.splice(prevLabels.indexOf(labelVO), 1);
								nextItemRender.enable();
							}
						}
					}
				}
			}
		}
		
		/**
		 * Renderer target
		 * @param seriesItem target series
		 *
		 */
		protected var itemRenders:Array;
		
		
		
		
		//----------------------------------------------------
		//
		// 动画控制
		//
		//----------------------------------------------------
		
		
		/**
		 * 仅当动画开关开启并且初次加载时动画才会播放；
		 * 
		 * 如果开启滤镜效果会特别豪资源，所以在动画播放之前要关闭滤镜效果；
		 */		
		private function openFlash():void
		{
			var seriesItem:SeriesBase;
			
			// 为播放动画做准备；
			if (chartModel.animation && ifFirstRender)
			{
				flashSeriesPercent = 0;
				this.chartCanvas.setItemAndValueLabelsAlpha(flashItemRenderPercent);
			}
			else
			{
				flashSeriesPercent = 1;
			}
			
			for each (seriesItem in series)
				seriesItem.setPercent(flashSeriesPercent);
			
			//播放动画
			if (chartModel.animation && ifFirstRender)
			{
				flashTimmer.addEventListener(TimerEvent.TIMER, flashSeriesHandler, false, 0, true);
				flashTimmer.start();
			}
			else
			{
				this.dispatchEvent(new FiChartsEvent(FiChartsEvent.RENDERED));
			}
		}
		
		/**
		 */		
		private function flashSeriesHandler(evt:Event):void
		{
			flashSeriesPercent += .05;
			if (flashSeriesPercent > 1)
			{
				ifFirstRender = false;// 新数据渲染动画仅播放一次；
				flashSeriesPercent = 1;
				flashTimmer.stop();
				flashTimmer.removeEventListener(TimerEvent.TIMER, flashSeriesHandler);
				
				// 柱体动画播放完毕后播放渲染节点动画；
				flashItemRenderPercent = .05;
				flashTimmer.addEventListener(TimerEvent.TIMER, flashItemRendersHandler, false, 0, true);
				flashTimmer.start();
			}
			
			for each (var seriesItem:SeriesBase in series)
				seriesItem.setPercent(flashSeriesPercent);
		}
		
		/**
		 */		
		private function flashItemRendersHandler(evt:TimerEvent):void
		{
			flashItemRenderPercent += .1;
			if (flashItemRenderPercent >= 1)
			{
				flashItemRenderPercent = 1;
				flashTimmer.stop();
				flashTimmer.removeEventListener(TimerEvent.TIMER, flashItemRendersHandler);
				
				this.dispatchEvent(new FiChartsEvent(FiChartsEvent.RENDERED));
			}
			
			this.chartCanvas.setItemAndValueLabelsAlpha(flashItemRenderPercent);
		}
		
		/**
		 */		
		private var flashSeriesPercent:Number;
		
		/**
		 */		
		private var flashItemRenderPercent:Number;
		
		/**
		 */		
		private var ifFirstRender:Boolean = true;
		
		/**
		 */		
		private var flashTimmer:Timer = new Timer(30, 0);
			
		
		
		
		//---------------------------------
		//
		// 尺寸与布局的计算
		//
		//---------------------------------
		
		
		/**
		 * Set items' position and size.
		 */
		private function layoutChart():void
		{
			if (ifLayoutChanged)
			{
				this.chartMask.x = chartCanvas.x = gridField.x = originX;
				this.chartMask.y = chartCanvas.y = originY; 
					
				if (scrollImgRender)
				{
					scrollImgRender.x = originX;
					scrollImgRender.y = originY;
				}
				
				gridField.y = topY;
				
				drawMask(chartMask);
				
				layoutLegendPanel();
				ifLayoutChanged = false;
			}
		}
		
		/**
		 */		
		private function drawMask(mask:Shape):void
		{
			mask.graphics.clear();
			mask.graphics.beginFill(0);
			mask.graphics.drawRect(0, 0, this.sizeX, - this.sizeY);
		}
		
		/**
		 */
		private function layoutLegendPanel():void
		{
			var bottomGutter:Number = bottomSpace;
			
			if (this.bottomAxisContainer.numChildren)
				bottomGutter = bottomSpace - bottomAxisContainer.height;
			
			if (this.legendPanel)
			{
				legendPanel.x = (this.chartWidth - legendPanel.width) / 2;
				legendPanel.y = this.chartHeight - bottomGutter / 2 - legendPanel.height / 2 //- legendPanel.style.vMargin
			}
		}
		
		/**
		 */		
		private function isLayoutUpdated():Boolean
		{
			if (temBottomSpace > bottomSpace) 
			{
				bottomSpace = temBottomSpace;
				updateSizeY();
			}
			
			if (temTopSpace > topSpace)
			{
				topSpace = temTopSpace;
				updateSizeY();
			}
			
			if (temLeftSpace > leftSpace || temLeftSpace < hAxisLabelOffset / 2) 
			{
				leftSpace = temLeftSpace;
				updateSizeX();
			}
			
			if (temRightSpace > rightSpace || temRightSpace < hAxisLabelOffset / 2)
			{
				rightSpace = temRightSpace;
				updateSizeX();
			}
			
			return this.ifLayoutChanged;
		}
		
		/**
		 */		
		private function updateSizeX():void
		{
			if (hAxisLabelOffset > 0)
			{
				// 仅左侧有坐标轴
				if (leftAxisContainer.numChildren && !rightAxisContainer.numChildren)
					rightSpace += hAxisLabelOffset / 2;
				else if (!leftAxisContainer.numChildren && rightAxisContainer.numChildren) // 右侧坐标轴
					leftSpace += hAxisLabelOffset / 2;
				
				// 左右皆有坐标轴的情况下无需调节尺寸， 两侧空隙挺宽敞的， 不用考虑Label的越界太多.
			}
			
			sizeX = chartWidth - this.leftSpace - this.rightSpace;
			
			if (legendPanel)
				legendPanel.panelWidth = this.chartWidth - legendPanel.style.hMargin * 2;
			
			ifLayoutChanged = true; 
		}
		
		/**
		 */		
		private function updateSizeY():void
		{
			if (vAxisLabelOffset > 0)
			{
				if (bottomAxisContainer.numChildren && !topAxisContainer.numChildren)
					topSpace += vAxisLabelOffset / 2;
				else if (!bottomAxisContainer.numChildren && topAxisContainer.numChildren)
					bottomSpace += vAxisLabelOffset / 2;
			}
			
			sizeY = chartHeight - this.bottomSpace - this.topSpace;
			ifLayoutChanged = true;
		}
		
		/**
		 */		
		private function get temBottomSpace():Number
		{
			var result:Number = chartModel.chartBG.paddingBottom;
			result =  this.bottomAxisContainer.height + result;
			
			if (legendPanel && chartModel.legend && chartModel.legend.enable)
				result = result + this.legendPanel.height + legendPanel.style.vMargin * 2;
			
			return result;
		}
		
		/**
		 */		
		private function get temTopSpace():Number
		{
			return chartModel.chartBG.paddingTop + this.topAxisContainer.height + this.title.boxHeight;
		}
		
		/**
		 */		
		private function get temLeftSpace():Number
		{
			return leftAxisContainer.width + chartModel.chartBG.paddingLeft;
		}
		
		/**
		 */		
		private function get temRightSpace():Number
		{
			return this.rightAxisContainer.width + chartModel.chartBG.paddingRight;
		}
		
		/**
		 */		
		private var leftSpace:Number = 0;
		private var rightSpace:Number = 0;
		private var bottomSpace:Number = 0;
		private var _topSpace:Number = 0;

		/**
		 */		
		public function get topSpace():Number
		{
			return _topSpace;
		}

		public function set topSpace(value:Number):void
		{
			_topSpace = value;
		}

		
		/**
		 */
		private var sizeX:Number;
		private var sizeY:Number;
		
		/**
		 */		
		private var _chartWidth:Number = 100;
		private var _chartHeight:Number = 100;
		
		/**
		 */		
		private var ifLayoutChanged:Boolean = false;
		
		/**
		 */		
		public function get originX():Number
		{
			return leftSpace;
		}
		
		public function get originY():Number
		{
			return chartHeight - bottomSpace
		}
		
		public function get topY():Number
		{
			return topSpace;
		}
		
		/**
		 */
		public function resize(w:Number, h:Number):void
		{
			chartWidth = w;
			chartHeight = h;
		}
		
		/**
		 */
		public function get chartWidth():Number
		{
			return _chartWidth;
		}
		
		public function set chartWidth(value:Number):void
		{
			if (_chartWidth != value)
				_chartWidth = value;
		}
		
		/**
		 */
		public function get chartHeight():Number
		{
			return _chartHeight;
		}
		
		/**
		 */		
		public function set chartHeight(value:Number):void
		{
			if (_chartHeight != value)
				_chartHeight = value;
		}
		
		
		
		
		//---------------------------------
		//
		//  创建
		//
		//---------------------------------

		
		/**
		 */		
		private function startAxisCreateHandler(value:Object):void
		{
			while (bottomAxisContainer.numChildren)
				bottomAxisContainer.removeChildAt(0);
			
			while (topAxisContainer.numChildren)
				topAxisContainer.removeChildAt(0);
			
			while (leftAxisContainer.numChildren)
				leftAxisContainer.removeChildAt(0);
			
			while (rightAxisContainer.numChildren)
				rightAxisContainer.removeChildAt(0);
		}
		
		/**
		 */		
		private function createHoriAxisBottomHandler(value:AxisBase):void
		{
			addAxis(value, bottomAxisContainer, AxisBase.HORIZONTAL_AXIS);
		}
		
		/**
		 */		
		private function createHoriAxisTopHandler(value:AxisBase):void
		{
			addAxis(value, topAxisContainer, AxisBase.HORIZONTAL_AXIS);
		}
		
		/**
		 */		
		private function createVertiAxisLeftHandler(value:AxisBase):void
		{
			addAxis(value, leftAxisContainer, AxisBase.VERTICAL_AXIX);
		}
		
		/**
		 */		
		private function createVertiAxisRightHandler(value:AxisBase):void
		{
			addAxis(value, rightAxisContainer, AxisBase.VERTICAL_AXIX);
		}
		
		/**
		 */		
		private function addAxis(axis:AxisBase, viewContainer:Sprite, direction:String):void
		{
			axis.dataFormatter = chartModel.dataFormatter;
			axis.direction = direction;
			viewContainer.addChild(axis);
		}

		/**
		 * 创建序列
		 */		
		private function createSeriesHandler(value:Vector.<SeriesBase>):void
		{
			this.chartCanvas.addSeries(value);
		}
		
		/**
		 * 当仅有一个轴时直接返回， 只有在多个轴的情况下
		 * 
		 * 才根据ID来检索；
		 */		
		private function getAxisByID(id:String, axises:Vector.<AxisBase>):AxisBase
		{
			if (axises.length == 1)
				return axises[0];
			
			for each (var aixs:AxisBase in axises)
			{
				if (aixs.id == id)
					return aixs;
			}
			
			return null;
		}
		
		/**
		 * 配置序列坐标轴;
		 */
		protected function configSeriesAxis():void
		{
			var seriesItem:SeriesBase;
			if (chartModel.axis.changed && chartModel.series.changed)
			{
				for each (seriesItem in series)
				{
					seriesItem.horizontalAxis = getAxisByID(seriesItem.xAxis, this.hAxises);
					seriesItem.verticalAxis = getAxisByID(seriesItem.yAxis, this.vAxises);
					
					if (seriesItem is BubbleSeries)
					{
						if (bubbleRadiusAxis == null)
						{
							bubbleRadiusAxis = new LinearAxis;  
							bubbleRadiusAxis.autoAdjust = false;
							bubbleRadiusAxis.dataFormatter = chartModel.dataFormatter;
						}
								
						(seriesItem as BubbleSeries).radiusAxis = this.bubbleRadiusAxis;
					}
				}
				
				//目前仅横轴方向支持数据滚动和缩放，并且仅单轴支持
				if(chartModel.dataScale.enable)
					scrollBaseAxis = hAxises[0];
			}
			
			
			
		}
		
		/**
		 * 序列或者原始数据改变时更新序列数据， 更新图例数据；
		 */		
		private function configSeriesData():void
		{
			var legends:Vector.<LegendVO> = new Vector.<LegendVO>();
			
			if (chartModel.series.changed || ifSourceDataChanged)
			{
				for each (var seriesItem:SeriesBase in series)  
				{
					seriesItem.configed(this.chartModel.series.colorMananger);// 图表整体配置完毕， 可以开始子序列的定义了；					
					seriesItem.dataProvider = this.dataXML;
					
					if (chartModel.legend.enable)
						legends = legends.concat(seriesItem.legendData);
				}
				
				legends.reverse();
				if (legendPanel && chartModel.legend.enable)
					legendPanel.legendData = legends;
			}
		}
		
		/**
		 */		
		private function updateAxisData():void
		{
			if (chartModel.axis.changed || chartModel.series.changed || ifSourceDataChanged)
			{
				var axis:AxisBase;
				
				// 准备更新数据
				for each (axis in this.hAxises)
					axis.redyToUpdateData();
				
				for each (axis in this.vAxises)
					axis.redyToUpdateData();
				
				if (bubbleRadiusAxis)
					bubbleRadiusAxis.redyToUpdateData();
					
				//数据更新后同步刷新坐标轴的数据；
				for each (var seriesVO:SeriesBase in series)
					seriesVO.updateAxisValueRange();
				
				// 数据更新完毕；	
				for each (axis in this.hAxises)
					axis.dataUpdated();
				
				for each (axis in this.vAxises)
					axis.dataUpdated();
				
				if (bubbleRadiusAxis)
					bubbleRadiusAxis.dataUpdated();
			}
		}

		
		//----------------------------------------
		//
		// 坐标轴及序列
		//
		//----------------------------------------
		
		/**
		 */		
		private var bubbleRadiusAxis:LinearAxis;
		
		/**
		 */
		public function get series():Vector.<SeriesBase>
		{
			return this.chartModel.series.items;
		}
		
		
		
		//---------------------------------------
		//
		// 样式配置
		//
		//---------------------------------------
		
		/**
		 * 设置和改变样式表；
		 */		
		public function setStyle(newStyle:String):void
		{
			if (chartProxy.currentStyleName == newStyle) return;
			chartProxy.styleInit(newStyle);
			
			if (configXML)
				chartProxy.setConfigCore(XMLVOMapper.extendFrom(
					chartProxy.currentStyleXML.copy(), configXML.copy()));
		}
		
		/**
		 * 完全由用户自定义的样式表；
		 */		
		public function setCustomStyle(style:XML):void
		{
			chartProxy.currentStyleName = Chart2DStyleSheet.CUSTOM;
			chartProxy.currentStyleXML = style;
			
			if (configXML)
				chartProxy.setConfigCore(XMLVOMapper.extendFrom(
					chartProxy.currentStyleXML.copy(), configXML.copy()));
		}
			 
		/**
		 */		
		private function updateLegendStyleHandler(value:Object):void
		{
			if (legendPanel)
				this.legendPanel.setStyle(value as LegendStyle);
		}	
		
		/**
		 */		
		private function updateTitleStyleHandler(value:Object):void
		{
			title.updateStyle(chartModel.title, chartModel.subTitle);
			this.renderTitle();
		}
		
		
		
		
		
		
		//----------------------------------
		//
		// 初始化
		//
		//----------------------------------
		
		/**
		 */
		protected function init():void
		{
			initContainers();
			createBG();
			addChild(title);
			
			toolTipManager = new ToolTipsManager(this);
			
			chartProxy = new ChartProxy();
			initListeners();
			
			// 设置当前默认的样式配置
			chartProxy.styleInit();
			chartProxy.setConfigCore(chartProxy.currentStyleXML);
			
			StageUtil.initApplication(this, initDataResizeContorl);
		}
		
		/**
		 */		
		private function initLegend():void
		{
			if (legendPanel)
			{
				this.removeChild(legendPanel)
				legendPanel = null;				
			}
			
			legendPanel =  new LegendPanel();
			addChild(legendPanel);
		}
		
		/**
		 */		
		private var legendPanel:LegendPanel;
		
		/**
		 */		
		private var toolTipManager:ToolTipsManager;
		
		/**
		 */		
		private function fullScreenHandler(evt:Event):void
		{
			if (chartModel.fullScreen)
			{
				if (stage.displayState == StageDisplayState.NORMAL)
					stage.displayState = StageDisplayState.FULL_SCREEN;
				else
					stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		/**
		 */		
		private function createBG():void
		{
			chartBG = new ChartBGUI();
			chartBG.doubleClickEnabled = true;
			chartBG.addEventListener(MouseEvent.DOUBLE_CLICK, fullScreenHandler, false, 0, true);
			bgContainer.addChild(chartBG);
			
			gridField = new GridFieldUI();
			bgContainer.addChild(gridField);
		}
		
		/**
		 */
		private function initContainers():void
		{
			bgContainer = new Sprite();
			addChild(bgContainer);
			
			bottomAxisContainer = new AxisContianer;
			addChild(bottomAxisContainer);
			
			topAxisContainer = new AxisContianer;
			addChild(topAxisContainer);
			
			leftAxisContainer = new AxisContianer;
			addChild(leftAxisContainer);
			
			rightAxisContainer = new AxisContianer;
			addChild(rightAxisContainer);
			
			chartCanvas = new ChartCanvas
			addChild(chartCanvas);
			
			chartMask = new Shape;
			addChild(chartMask);
			
			chartCanvas.mask = chartMask;
		}
		
		/**
		 */
		private function initListeners():void
		{
			XMLVOLib.addCreationHandler(AxisModel.START_AXIS_CREATION, startAxisCreateHandler);
			XMLVOLib.addCreationHandler(AxisModel.CREATE_LEFT_AXIS, createVertiAxisLeftHandler);
			XMLVOLib.addCreationHandler(AxisModel.CREATE_RIGHT_AXIS, createVertiAxisRightHandler);
			XMLVOLib.addCreationHandler(AxisModel.CREATE_TOP_AXIS, createHoriAxisTopHandler);
			XMLVOLib.addCreationHandler(AxisModel.CREATE_BOTTOM_AXIS, createHoriAxisBottomHandler);
			XMLVOLib.addCreationHandler(Series.SERIES_CREATED, createSeriesHandler);
			
			XMLVOLib.addCreationHandler(Chart2DModel.UPDATE_TITLE_STYLE, updateTitleStyleHandler);
			XMLVOLib.addCreationHandler(Chart2DModel.UPDATE_LEGEND_STYLE, updateLegendStyleHandler);
			
			this.addEventListener(ItemRenderEvent.UPDATE_VALUE_LABEL, updateValueLabelHandler, false, 0, true);
			this.addEventListener(DataResizeEvent.RENDER_SIZED_VALUE_LABELS, drawResizeValueLabels, false, 0, true);
		}
		
		/**
		 * @return 
		 */		
		private function get hAxises():Vector.<AxisBase>
		{
			return this.chartModel.axis.horizontalAxis;
		}
		
		/**
		 */		
		private function get vAxises():Vector.<AxisBase>
		{
			return this.chartModel.axis.verticalAxis;
		}
		
		/**
		 */		
		private function get chartModel():Chart2DModel
		{
			return chartProxy.chartModel;
		}
		
		/**
		 */
		protected var chartProxy:ChartProxy;
		
		/**  
		 * 网格/序列背景
		 */
		protected var gridField:GridFieldUI;
		
		/**
		 * 图表背景 
		 */		
		protected var chartBG:ChartBGUI;
		
		/**
		 * 标题
		 */
		private var title:TitleBox = new TitleBox;
		
		/**
		 * 容器
		 */
		private var bottomAxisContainer:AxisContianer;
		private var topAxisContainer:AxisContianer;
		private var leftAxisContainer:AxisContianer;
		private var rightAxisContainer:AxisContianer;
		
		/**
		 */		
		private var bgContainer:Sprite;
		private var chartCanvas:ChartCanvas;
		private var chartMask:Shape;
		
	}
}