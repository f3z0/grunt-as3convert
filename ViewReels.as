package com.ea.slotser.game.slots.view.reels
{
	import com.ea.slotser.comms.GlobalEventDispatcher;
	import com.ea.slotser.comms.events.ReelsEvent;
	import com.ea.slotser.comms.events.SlotsEvent;
	import com.ea.slotser.game.slots.constants.GameConstants;
	import com.ea.slotser.game.slots.constants.ReelConstants;
	import com.ea.slotser.game.slots.events.PlayerGameInteractionEvent;
	import com.ea.slotser.game.slots.events.ServerSpinEvent;
	import com.ea.slotser.game.slots.model.ReelsProxy;
	import com.ea.slotser.game.slots.model.SlotsProxy;
	import com.ea.slotser.game.slots.model.vo.ReqSpinVO;
	import com.ea.slotser.game.slots.service.SpinServiceManager;
	import com.ea.slotser.model.SlotserProxy;
	import com.edgington.util.debug.LOG;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	public class ViewReels extends Sprite
	{
		
		private var WIDTH:int;
		
		private var reels:Vector.<ViewReel>;
		
		private var numReels:int;
		private var numSymbols:int;
		private var visibleSymbols:int;
		private var reelType:String;
		
		private var debugControls:ViewReelsDebugControls;
		
		private var reelsBackgroundVector:MovieClip;
		private var reelsBMD:BitmapData;
		private var reelsBackground:Bitmap;
		private var reelsOverlayBMD:BitmapData;
		private var reelsOverlay:Bitmap;
		
		private var winLines:ViewReelWinLines;
		
		private var slotsProxy:SlotsProxy;

		private var n1:int;
		private var n2:int;
		private var n3:int;
		private var n4:int;
		private var n5:int;
		private var np:String;
		
		private var winLinesOveraly:Sprite;
	

		private function n(f1:int, f2:int, f3:int, f4:int, f5:int, fp:String):void { 
		    n1 = f1;
		    n2 = f2;
		    n3 = f3;
		    n4 = f4;
		    n5 = f5;
		    np = fp;
		} 

		private function nClear():void { 
		    n1 = 0;
		    n2 = 0;
		    n3 = 0;
		    n4 = 0;
		    n5 = 0;
		    np = null;
		} 
		
		private function addListeners():void{
			this.addEventListener(Event.REMOVED_FROM_STAGE, destroy);
			GlobalEventDispatcher.addEventListener(PlayerGameInteractionEvent.INITIATE_SPIN, spinReels);
			GlobalEventDispatcher.addEventListener(ServerSpinEvent.FREE_SPIN_RESPONSE, handleSpinData);
			GlobalEventDispatcher.addEventListener(ServerSpinEvent.SPIN_RESPONSE, handleSpinData);
			GlobalEventDispatcher.addEventListener(ReelsEvent.START_FREE_SPIN, freeSpinReels);
		}
		
		private function applyAdditionalDecals(decalVectors:Vector.<MovieClip>):void{
			
			for(var i:int = 0; i < decalVectors.length; i++){
				decalVectors[i].scaleX = reelsBackgroundVector.scaleX;
				decalVectors[i].scaleY = reelsBackgroundVector.scaleY;
				var matrix:Matrix = new Matrix();
				matrix.scale(decalVectors[i].scaleX, decalVectors[i].scaleY);
				var bmd:BitmapData = new BitmapData(((decalVectors[i].width < 1) ? 1 : decalVectors[i].width), ((decalVectors[i].height < 1) ? 1 : decalVectors[i].height), true, 0);
				bmd.drawWithQuality(decalVectors[i], matrix, null, null, null, true, StageQuality.BEST);
				var bm:Bitmap = new Bitmap(bmd);
				bm.x = decalVectors[i].x*reelsBackgroundVector.scaleX;
				bm.y = decalVectors[i].y*reelsBackgroundVector.scaleY;
				bm.cacheAsBitmap = true;
				this.addChild(bm);
			}
			
		}
		
		private function setupVisuals():void{
			
			var foregroundVectors:Vector.<MovieClip> = new Vector.<MovieClip>;
			var backgroundVectors:Vector.<MovieClip> = new Vector.<MovieClip>;
			
			var reelWidth:int = ReelsProxy.getInstance().baseSymbol.width;
			
			reelsBackgroundVector = slotsProxy.assetModel.getAssetByName("SlotsBackground", null) as MovieClip;
			
			for(var i:int = 0; i < reelsBackgroundVector.numChildren; i++){
				var child:DisplayObject = reelsBackgroundVector.getChildAt(i);
				child.visible = false;
				if(child.name != "background" && child.name != "overlay" && child.name != "playarea"){
					if(child.name.indexOf("foreground_") != -1){
						foregroundVectors.push(child);
					}
					else if(child.name.indexOf("background_") != -1){
						backgroundVectors.push(child);
					}
				}
			}
			
			for(i = 0; i < foregroundVectors.length; i++){
				reelsBackgroundVector.removeChild(foregroundVectors[i]);
			}
			for(i = 0; i < backgroundVectors.length; i++){
				reelsBackgroundVector.removeChild(backgroundVectors[i]);
			}
			
			reelsBackgroundVector.width = ReelsProxy.getInstance().playAreaWidth;
			reelsBackgroundVector.height = ReelsProxy.getInstance().playAreaHeight;
			
			var bounds:Rectangle = reelsBackgroundVector.playarea.getBounds(reelsBackgroundVector);
			
			var reelOffsetX:int = bounds.x * reelsBackgroundVector.scaleX;
			var reelOffsetY:int = bounds.y * reelsBackgroundVector.scaleY;
			
			reelsBackgroundVector.background.visible = true;
			
			var matrix:Matrix = new Matrix();
			matrix.scale(reelsBackgroundVector.scaleX, reelsBackgroundVector.scaleY);
			reelsBMD = new BitmapData(reelsBackgroundVector.width, reelsBackgroundVector.height, true, 0);
			reelsBMD.drawWithQuality(reelsBackgroundVector, matrix, null, null, null, true, StageQuality.BEST);
			reelsBackground = new Bitmap(reelsBMD);
			reelsBackground.cacheAsBitmap = true;
			
			reelsBackgroundVector.background.visible = false;
			reelsBackgroundVector.overlay.visible = true;
			
			applyAdditionalDecals(backgroundVectors);
			
			this.addChild(reelsBackground);
			
			matrix = new Matrix();
			matrix.scale(reelsBackgroundVector.scaleX, reelsBackgroundVector.scaleY);
			reelsOverlayBMD = new BitmapData(reelsBackgroundVector.width, reelsBackgroundVector.height, true, 0);
			reelsOverlayBMD.drawWithQuality(reelsBackgroundVector, matrix, null, null, null, true, StageQuality.BEST);
			reelsOverlay = new Bitmap(reelsOverlayBMD);
			reelsOverlay.cacheAsBitmap = true;
			
			
			winLinesOveraly = new Sprite();
			winLines = new ViewReelWinLines(winLinesOveraly);
			winLines.x = winLinesOveraly.x = reelOffsetX;
			winLines.y = winLinesOveraly.y = reelOffsetY;
			this.addChild(winLines);
			
			for(i = 0; i < numReels; i++){
				var reel:ViewReel = new ViewReel(i, reelWidth, numSymbols, reelType);
				reel.x = reelOffsetX + (reelWidth*i);
				reel.y = reelOffsetY;
				this.addChild(reel);
				reels.push(reel);
			}
			
			if(ReelConstants.DEBUG_MODE){
				debugControls = new ViewReelsDebugControls();
				debugControls.y = reelWidth*(numSymbols+1);
				this.addChild(debugControls);
			}
			
			this.addChild(reelsOverlay);
			applyAdditionalDecals(foregroundVectors);
			
			this.addChild(winLinesOveraly);
		
		}

		public function getReelHeight():int{
			return ReelsProxy.getInstance().baseSymbol.height*numSymbols;
		}
		
		private function spinReelsAfterResize(e:Event):void{
			GlobalEventDispatcher.removeEventListener(SlotsEvent.RESIZE_COMPLETE, spinReelsAfterResize);
			GlobalEventDispatcher.dispatchEvent(new PlayerGameInteractionEvent(PlayerGameInteractionEvent.INITIATE_SPIN));
		}

		private function spinReels(e:Event):void{
			if(SlotsProxy.getInstance().pendingResize){
				GlobalEventDispatcher.addEventListener(SlotsEvent.RESIZE_COMPLETE, spinReelsAfterResize);
				return;
			}
			SpinServiceManager.getInstance().initiateNormalSpin(reels);
			GlobalEventDispatcher.dispatchEvent(new ServerSpinEvent(ServerSpinEvent.REQUEST_SPIN, new ReqSpinVO((slotsProxy.spinConfigVO.isReal) ? slotsProxy.spinConfigVO.betLevelReal : slotsProxy.spinConfigVO.betLevel, (slotsProxy.spinConfigVO.isReal) ? slotsProxy.spinConfigVO.numLinesReal : slotsProxy.spinConfigVO.numLines, slotsProxy.spinConfigVO.isReal, n1, n2, n3, n4, n5, np)));
			nClear();

		}
		
		private function freeSpinReelsAfterResize(e:Event):void{
			GlobalEventDispatcher.removeEventListener(SlotsEvent.RESIZE_COMPLETE, freeSpinReelsAfterResize);
			GlobalEventDispatcher.dispatchEvent(new ReelsEvent(ReelsEvent.START_FREE_SPIN));
		}
		
		private function freeSpinReels(e:Event = null):void{
			if(SlotsProxy.getInstance().pendingResize){
				GlobalEventDispatcher.addEventListener(SlotsEvent.RESIZE_COMPLETE, freeSpinReelsAfterResize);
				return;
			}
			SpinServiceManager.getInstance().initiateNormalSpin(reels);
			
			GlobalEventDispatcher.dispatchEvent(new ServerSpinEvent(ServerSpinEvent.REQUEST_FREE_SPIN, new ReqSpinVO((slotsProxy.spinConfigVO.isReal) ? slotsProxy.spinConfigVO.betLevelReal : slotsProxy.spinConfigVO.betLevel, (slotsProxy.spinConfigVO.isReal) ? slotsProxy.spinConfigVO.numLinesReal : slotsProxy.spinConfigVO.numLines, slotsProxy.spinConfigVO.isReal, n1, n2, n3, n4, n5, np), null, null, slotsProxy.currentActiveFreeSpinsVO.id));
		}
		
		private function handleSpinData(e:ServerSpinEvent):void{
			for(var i:int = 0; i < reels.length; i++){
				reels[i].spliceResults(e.resSpinVO.spin.symbols["reel"+(i+1)]);
			}
			
			//Prints out the spin response lines to the console.
			if(ReelConstants.DEBUG_MODE){
				LOG.debug(
					((e.resSpinVO.spin.symbols.reel1[0] > 9) ? e.resSpinVO.spin.symbols.reel1[0] :  "0"+e.resSpinVO.spin.symbols.reel1[0]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel2[0] > 9) ? e.resSpinVO.spin.symbols.reel2[0] :  "0"+e.resSpinVO.spin.symbols.reel2[0]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel3[0] > 9) ? e.resSpinVO.spin.symbols.reel3[0] :  "0"+e.resSpinVO.spin.symbols.reel3[0]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel4[0] > 9) ? e.resSpinVO.spin.symbols.reel4[0] :  "0"+e.resSpinVO.spin.symbols.reel4[0]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel5[0] > 9) ? e.resSpinVO.spin.symbols.reel5[0] :  "0"+e.resSpinVO.spin.symbols.reel5[0]));
					
				LOG.debug(
					((e.resSpinVO.spin.symbols.reel1[1] > 9) ? e.resSpinVO.spin.symbols.reel1[1] :  "0"+e.resSpinVO.spin.symbols.reel1[1]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel2[1] > 9) ? e.resSpinVO.spin.symbols.reel2[1] :  "0"+e.resSpinVO.spin.symbols.reel2[1]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel3[1] > 9) ? e.resSpinVO.spin.symbols.reel3[1] :  "0"+e.resSpinVO.spin.symbols.reel3[1]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel4[1] > 9) ? e.resSpinVO.spin.symbols.reel4[1] :  "0"+e.resSpinVO.spin.symbols.reel4[1]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel5[1] > 9) ? e.resSpinVO.spin.symbols.reel5[1] :  "0"+e.resSpinVO.spin.symbols.reel5[1]));
					
				LOG.debug(
					((e.resSpinVO.spin.symbols.reel1[2] > 9) ? e.resSpinVO.spin.symbols.reel1[2] :  "0"+e.resSpinVO.spin.symbols.reel1[2]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel2[2] > 9) ? e.resSpinVO.spin.symbols.reel2[2] :  "0"+e.resSpinVO.spin.symbols.reel2[2]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel3[2] > 9) ? e.resSpinVO.spin.symbols.reel3[2] :  "0"+e.resSpinVO.spin.symbols.reel3[2]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel4[2] > 9) ? e.resSpinVO.spin.symbols.reel4[2] :  "0"+e.resSpinVO.spin.symbols.reel4[2]) + 
					" | " + ((e.resSpinVO.spin.symbols.reel5[2] > 9) ? e.resSpinVO.spin.symbols.reel5[2] :  "0"+e.resSpinVO.spin.symbols.reel5[2]));
					
			}
		}
		
		private function destroy(e:Event):void{
			GlobalEventDispatcher.removeEventListener(PlayerGameInteractionEvent.INITIATE_SPIN, spinReels);
			GlobalEventDispatcher.removeEventListener(ServerSpinEvent.FREE_SPIN_RESPONSE, handleSpinData);
			GlobalEventDispatcher.removeEventListener(ServerSpinEvent.SPIN_RESPONSE, handleSpinData);
			GlobalEventDispatcher.removeEventListener(ReelsEvent.START_FREE_SPIN, freeSpinReels);
			
			this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			
			while(this.numChildren > 0){
				this.removeChildAt(0);
			}
		}
		
		override public function get width():Number{
			return ReelsProxy.getInstance().playAreaWidth;
		}
		
		
		override public function get height():Number{
			return ReelsProxy.getInstance().playAreaHeight;
		}
	}
}