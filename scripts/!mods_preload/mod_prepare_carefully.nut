::PrepareCarefully <- {
	ID = "mod_prepare_carefully",
	Name = "Prepare Carefully",
	Version = "0.9.1",
	PrepareCarefullyMode = false,
	CurrentlySelectedBro = null,
	MaxVertical = 2,
	MaxHorizontal = 2,
	ValidTiles = {
		AsString = [],
		AsTuple = [],
	},
}
::mods_registerMod(::PrepareCarefully.ID, ::PrepareCarefully.Version);

::mods_queue(::PrepareCarefully.ID, null, function()
{
	mods_registerJS("PrepareCarefully.js");
	mods_registerCSS("PrepareCarefully.css");
	::mods_hookExactClass("entity/tactical/actor", function(o)
	{
		local red = this.createColor("#ff0000")
		local onInit = o.onInit;
		o.onInit = function()
		{
			onInit();
			local arrow = this.addSprite("PrepareCarefullyArrow");
			arrow.setBrush("bust_arrow");
			arrow.Visible = false;
			arrow.Color = red;
			this.setSpriteColorization("PrepareCarefullyArrow", false);
		}

		o.showPrepareCarefullyArrow <- function( _v )
		{
			local arrow = this.getSprite("PrepareCarefullyArrow");

			if (_v)
			{
				arrow.Visible = true;
				arrow.fadeIn(100);
			}
			else
			{
				arrow.fadeOutAndHide(100);
			}
		}
	})

	::mods_hookExactClass("states/tactical_state", function(o){
		local init = o.init;
		o.init = function()
		{
			init();
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				this.getValidPrepareCarefullyTiles();
				this.denyVisibilityPrepareCarefully();
			}
		}

		local onFinish = o.onFinish;
		o.onFinish = function()
		{
			onFinish();
			::PrepareCarefully.PrepareCarefullyMode = false;
			::PrepareCarefully.CurrentlySelectedBro = null;
			::PrepareCarefully.ValidTiles = {
				AsString = [],
				AsTuple = [],
			};
		}

		local setStrategicProperties = o.setStrategicProperties;
		o.setStrategicProperties = function(_properties)
		{
			setStrategicProperties(_properties);
			::PrepareCarefully.PrepareCarefullyMode = _properties.IsPlayerInitiated;
		}

		o.getValidPrepareCarefullyTiles <- function()
		{
			local minX, maxX, minY, maxY;
			local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			foreach (bro in playerUnits)
			{
				local tile = bro.getTile();
				if (minX == null || tile.SquareCoords.X < minX) minX = tile.SquareCoords.X;
				if (maxX == null || tile.SquareCoords.X > maxX) maxX = tile.SquareCoords.X;
				if (minY == null || tile.SquareCoords.Y < minY) minY = tile.SquareCoords.Y;
				if (maxY == null || tile.SquareCoords.Y > maxY) maxY = tile.SquareCoords.Y;
			}
			minX = minX - ::PrepareCarefully.MaxHorizontal;
			minY = minY - ::PrepareCarefully.MaxVertical;
			maxY = maxY + ::PrepareCarefully.MaxVertical;

			for( local x = minX; x != maxX + 1; x++ )
			{
				for( local y = minY; y != maxY + 1; y++ )
				{
					::PrepareCarefully.ValidTiles.AsString.push(x.tostring() + "." +  y.tostring());
					::PrepareCarefully.ValidTiles.AsTuple.push([x, y]);
					local tile = this.Tactical.getTileSquare(x, y);
					tile.spawnDetail("mortar_target_02", this.Const.Tactical.DetailFlag.SpecialOverlay, false, true);
				}
			}
		}

		o.denyVisibilityPrepareCarefully <- function()
		{
			this.Tactical.clearVisibility();
			local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			foreach (bro in playerUnits)
			{
				bro.old_updateVisibility <- bro.updateVisibility;
				bro.updateVisibility = function(_tile, _vision, _faction)
				{
					return old_updateVisibility(_tile, 2, _faction)
				}
			}
			foreach(bro in playerUnits)
			{
				bro.updateVisibilityForFaction()
			}
		}

		local onMouseInput = o.onMouseInput;
		o.onMouseInput = function( _mouseEvent )
		{
			if (!::PrepareCarefully.PrepareCarefullyMode || _mouseEvent.getID() != 1)
				return onMouseInput(_mouseEvent);
			local tile = this.Tactical.getTile(this.Tactical.screenToTile(_mouseEvent.getX(), _mouseEvent.getY()));
			if (!tile.IsEmpty && !tile.IsOccupiedByActor) return onMouseInput(_mouseEvent);
			local entity = tile.getEntity();
			if (entity != null)
			{
				if (entity.isPlayerControlled())
				{
					if (::PrepareCarefully.CurrentlySelectedBro != null)
						::PrepareCarefully.CurrentlySelectedBro.showPrepareCarefullyArrow(false);
					entity.showPrepareCarefullyArrow(true);
					::PrepareCarefully.CurrentlySelectedBro = entity;
				}
			}
			else if (::PrepareCarefully.CurrentlySelectedBro != null)
			{
				local X = tile.SquareCoords.X;
				local Y = tile.SquareCoords.Y;
				local asString = X.tostring() + "." + Y.tostring();
				if (::PrepareCarefully.ValidTiles.AsString.find(asString) != null)
				{
					this.Tactical.getNavigator().teleport(::PrepareCarefully.CurrentlySelectedBro, tile, null, null, false, 0.0);
				}
				else
				{
					this.Tactical.getShaker().shake(::PrepareCarefully.CurrentlySelectedBro, tile, 1);
				}
			}
			return onMouseInput(_mouseEvent);
		}

		local topbar_round_information_onQueryRoundInformation = o.topbar_round_information_onQueryRoundInformation;
		o.topbar_round_information_onQueryRoundInformation = function()
		{
			local ret = topbar_round_information_onQueryRoundInformation();
			ret.PrepareCarefullyMode <- ::PrepareCarefully.PrepareCarefullyMode;
			return ret;
		}

		local setInputLocked = o.setInputLocked;
		o.setInputLocked = function(_bool)
		{
			if (::PrepareCarefully.PrepareCarefullyMode)
				return setInputLocked(false);
			return setInputLocked(_bool);
		}


		local updateCurrentEntity = o.updateCurrentEntity;
		o.updateCurrentEntity = function()
		{
			if(::PrepareCarefully.PrepareCarefullyMode)
				return;

			return updateCurrentEntity();
		}

		local turnsequencebar_onNextRound = o.turnsequencebar_onNextRound;
		o.turnsequencebar_onNextRound = function( _round )
		{
			if(::PrepareCarefully.PrepareCarefullyMode)
			{
				local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
				foreach(bro in playerUnits)
				{
					bro.updateVisibilityForFaction()
				}
				return;
			}
			return turnsequencebar_onNextRound( _round );
		}
	})

	::mods_hookNewObject("camera/tactical_camera_director", function(o){
		local isInputAllowed = o.isInputAllowed;
		o.isInputAllowed = function()
		{
			if(::PrepareCarefully.PrepareCarefullyMode)
				return true;
			return isInputAllowed();
		}
	})

	// ::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o){
	// 	local initNextTurn = o.initNextTurn;
	// 	o.initNextTurn = function(_force = false)
	// 	{
	// 		if (::PrepareCarefully.PrepareCarefullyMode)
	// 			return;
	// 		return initNextTurn(_force);
	// 	}
	// })

	::mods_hookNewObject("ui/screens/tactical/tactical_screen", function(o){
		o.onPrepareCarefullyButtonPressed <- function()
		{
			::PrepareCarefully.PrepareCarefullyMode = false;
			foreach(tuple in ::PrepareCarefully.ValidTiles.AsTuple)
			{
				local tile = this.Tactical.getTileSquare(tuple[0], tuple[1]);
				tile.clear(this.Const.Tactical.DetailFlag.SpecialOverlay);
			}
			local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			foreach (idx, bro in playerUnits)
			{
				bro.updateVisibility = bro.old_updateVisibility;
				delete bro.old_updateVisibility;
				bro.updateVisibilityForFaction();
			}
		}
	})
})
