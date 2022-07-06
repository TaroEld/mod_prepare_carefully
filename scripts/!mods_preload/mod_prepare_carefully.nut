::PrepareCarefully <- {
	ID = "mod_prepare_carefully",
	Name = "Prepare Carefully",
	Version = "0.9.1",
	PrepareCarefullyMode = false,
	PlayerDeploymentType = null,
	CurrentlySelectedBro = null,
	MaxVertical = 2,
	MaxHorizontal = 2,
	ValidTiles = {
		AsString = [],
		AsTuple = [],
	},
	Clear = function()
	{
		this.PrepareCarefullyMode = false;
		this.CurrentlySelectedBro = null;
		this.PlayerDeploymentType = null;
		this.ValidTiles = {
			AsString = [],
			AsTuple = [],
		};
		local playerUnits = ::World.getPlayerRoster().getAll();
		foreach (idx, bro in playerUnits)
		{
			if("old_updateVisibility" in bro)
			{
				bro.updateVisibility = bro.old_updateVisibility;
				delete bro.old_updateVisibility;
			}
		}
	}
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
		local onFinish = o.onFinish;
		o.onFinish = function()
		{
			onFinish();
			::PrepareCarefully.Clear();
		}

		local initMap = o.initMap;
		o.initMap = function()
		{
			initMap();
			local properties = this.getStrategicProperties();
			::PrepareCarefully.PrepareCarefullyMode = properties.IsPlayerInitiated;
			::PrepareCarefully.PlayerDeploymentType = properties.PlayerDeploymentType;
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				this.getValidPrepareCarefullyTiles();
				this.denyVisibilityPrepareCarefully();
			}
		}

		o.getValidPrepareCarefullyTiles <- function()
		{
			local minX, maxX, minY, maxY;
			local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			local playerDeploymentType = ::PrepareCarefully.PlayerDeploymentType;
			local ambushMode = playerDeploymentType == this.Const.Tactical.DeploymentType.Circle || playerDeploymentType == this.Const.Tactical.DeploymentType.Center;
			foreach (bro in playerUnits)
			{
				local tile = bro.getTile();
				if (minX == null || tile.SquareCoords.X < minX) minX = tile.SquareCoords.X;
				if (maxX == null || tile.SquareCoords.X > maxX) maxX = tile.SquareCoords.X;
				if (minY == null || tile.SquareCoords.Y < minY) minY = tile.SquareCoords.Y;
				if (maxY == null || tile.SquareCoords.Y > maxY) maxY = tile.SquareCoords.Y;
			}
			minX = minX - (ambushMode ? 1 : ::PrepareCarefully.MaxHorizontal);
			maxX = maxX + (ambushMode ? 1 : 0);
			minY = minY - (ambushMode ? 1 : ::PrepareCarefully.MaxVertical);
			maxY = maxY + (ambushMode ? 1 : ::PrepareCarefully.MaxVertical);

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
					return this.old_updateVisibility(_tile, 2, _faction)
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

	::mods_hookNewObject("ui/screens/tactical/tactical_screen", function(o){
		o.onPrepareCarefullyButtonPressed <- function()
		{
			foreach(tuple in ::PrepareCarefully.ValidTiles.AsTuple)
			{
				local tile = this.Tactical.getTileSquare(tuple[0], tuple[1]);
				tile.clear(this.Const.Tactical.DetailFlag.SpecialOverlay);
			}
			::PrepareCarefully.Clear();
			foreach (bro in this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player))
			{
				bro.updateVisibilityForFaction();
			}
		}
	})
})
