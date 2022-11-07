::PrepareCarefully <- {
	ID = "mod_prepare_carefully",
	Name = "Prepare Carefully",
	Version = "0.9.3",
	PrepareCarefullyMode = false,
	PlayerDeploymentType = null,
	CurrentlySelectedBro = null,
	MaxVertical = 2,
	MaxHorizontal = 2,
	InvalidColor = this.createColor("#ff0000"),
	ValidColor = this.createColor("#00ff1d"),
	MinimalValidTiles = {
		AsString = [],
		AsTiles = [],
		Details = [],
	},
	ValidTiles = {
		AsString = [],
		AsTiles = [],
		Details = [],
	},
	ExtraValidTiles = {
		AsString = [],
		AsTiles = [],
		Details = [],
	},
	InvalidTraits = [
		"trait.clubfooted",
		"trait.clumsy",
		"trait.hesitant",
		"trait.fat",
		"background.cripple",
	],
	ExtraValidTraits = [
		"trait.weasel",
		"trait.athletic",
		"trait.quick",
		"trait.sure_footing",
		"trait.impatient",
		"trait.swift",
		"background.poacher",
		"background.hunter",
		"background.thief",
	],

	// BRO DEPENDANT FUNCTIONS
	setCurrentlySelectedBro = function(_bro)
	{
		if (this.CurrentlySelectedBro != null)
			this.showSelectedArrow(this.CurrentlySelectedBro, false);
		this.showSelectedArrow(_bro, true);
		this.CurrentlySelectedBro = ::WeakTableRef(_bro);
		this.colorSpritesBasedOnValid(_bro);
	},

	colorSpritesBasedOnValid = function(_bro)
	{
		foreach (detail in this.ExtraValidTiles.Details)
		{
			detail.Visible = false;
		}
		local function iterateTiles(_tiles)
		{
			foreach (detail in _tiles)
			{
				detail.Visible = true;
			}
		}
		if (this.isInvalidBro(_bro))
			iterateTiles(this.MinimalValidTiles.Details);
		else if (this.isExtraValidBro(_bro))
			iterateTiles(this.ExtraValidTiles.Details);
		else
			iterateTiles(this.ValidTiles.Details);
	},

	isTileValidForBro = function(_tile, _bro)
	{
		local X = _tile.SquareCoords.X;
		local Y = _tile.SquareCoords.Y;
		local asString = X.tostring() + "." + Y.tostring();
		if (this.isInvalidBro(_bro))
		{
			return this.MinimalValidTiles.AsString.find(asString) != null
		}

		if (this.ValidTiles.AsString.find(asString) != null
			|| (this.isExtraValidBro(_bro) && this.ExtraValidTiles.AsString.find(asString) != null))
		{
			return true;
		}
		return false;
	},

	isInvalidBro = function(_bro)
	{
		local skills = _bro.getSkills();
		foreach (trait in this.InvalidTraits)
		{
			if (skills.hasSkill(trait))
				return true;
		}
		return false;
	}

	isExtraValidBro = function(_bro)
	{
		local skills = _bro.getSkills();
		foreach (trait in this.ExtraValidTraits)
		{
			if (skills.hasSkill(trait))
				return true;
		}
		return false;
	}

	showSelectedArrow = function( _bro, _v )
	{
		local arrow = _bro.getSprite("PrepareCarefullyArrow");
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
	// END BRO FUNCTIONS

	getValidTiles = function()
	{
		local minX, maxX, minY, maxY, icon, tile, x, y, asString;
		local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
		local playerDeploymentType = this.PlayerDeploymentType;
		local ambushMode = playerDeploymentType == this.Const.Tactical.DeploymentType.Circle || playerDeploymentType == this.Const.Tactical.DeploymentType.Center;
		foreach (bro in playerUnits)
		{
			tile = bro.getTile();
			x = tile.SquareCoords.X;
			y = tile.SquareCoords.Y;
			this.MinimalValidTiles.AsString.push(x + "." +  y);
			this.MinimalValidTiles.AsTiles.push(tile);

			if (minX == null || tile.SquareCoords.X < minX) minX = tile.SquareCoords.X;
			if (maxX == null || tile.SquareCoords.X > maxX) maxX = tile.SquareCoords.X;
			if (minY == null || tile.SquareCoords.Y < minY) minY = tile.SquareCoords.Y;
			if (maxY == null || tile.SquareCoords.Y > maxY) maxY = tile.SquareCoords.Y;
		}
		minX = minX - (ambushMode ? 1 : this.MaxHorizontal);
		maxX = maxX + (ambushMode ? 1 : 0);
		minY = minY - (ambushMode ? 1 : this.MaxVertical);
		maxY = maxY + (ambushMode ? 1 : this.MaxVertical);
		for( local x = minX; x != maxX + 1; x++ )
		{
			for( local y = minY; y != maxY + 1; y++ )
			{
				if (!this.Tactical.isValidTileSquare(x, y))
					continue;
				asString = x + "." +  y;
				this.ValidTiles.AsString.push(asString);
				tile = this.Tactical.getTileSquare(x, y);
				this.ValidTiles.AsTiles.push(tile);
				icon = tile.spawnDetail("zone_target_overlay", this.Const.Tactical.DetailFlag.SpecialOverlay, false, false);
				icon.Color = this.ValidColor;
				icon.Saturation = 60;
				this.ValidTiles.Details.push(icon);
				if (this.MinimalValidTiles.AsString.find(asString) != null)
					this.MinimalValidTiles.Details.push(icon);
			}
		}

		this.ExtraValidTiles.AsString = clone this.ValidTiles.AsString;
		this.ExtraValidTiles.AsTiles = clone this.ValidTiles.AsTiles;
		this.ExtraValidTiles.Details = clone this.ValidTiles.Details;
		foreach (validTile in this.ValidTiles.AsTiles)
		{
			for( local j = 0; j < 6; j++ )
			{
				if (validTile.hasNextTile(j))
				{
					local neighbor = validTile.getNextTile(j);
					x = neighbor.SquareCoords.X;
					y = neighbor.SquareCoords.Y;
					asString = x.tostring() + "." + y.tostring();
					if (this.ExtraValidTiles.AsString.find(asString) == null)
					{
						this.ExtraValidTiles.AsString.push(asString);
						this.ExtraValidTiles.AsTiles.push(neighbor);
						if (this.ValidTiles.AsString.find(asString) == null)
						{
							icon = neighbor.spawnDetail("zone_target_overlay", this.Const.Tactical.DetailFlag.SpecialOverlay, false, false);
							icon.Color = this.ValidColor;
							icon.Saturation = 60;
							icon.Visible = false;
							this.ExtraValidTiles.Details.push(icon);
						}
					}
				}
			}
		}
	},

	denyVisibility = function(_changeVisibilityFunction = true)
	{
		local tile;
		this.Tactical.clearVisibility();
		foreach (tile in this.ExtraValidTiles.AsTiles)
		{
			tile.addVisibilityForFaction(this.Const.Faction.Player);
		}

		if (_changeVisibilityFunction)
		{
			local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			foreach (bro in playerUnits)
			{
				bro.old_updateVisibility <- bro.updateVisibility;
				bro.updateVisibility = function(_tile, _vision, _faction)
				{
					return;
				}
			}
		}

	},

	onLeftClickPrepareCarefully = function(_mouseEvent)
	{
		local tile = this.Tactical.getTile(this.Tactical.screenToTile(_mouseEvent.getX(), _mouseEvent.getY()));
		if (!tile.IsEmpty && !tile.IsOccupiedByActor) return;
		local entity = tile.getEntity();
		if (entity != null)
		{
			if (entity.isPlayerControlled())
			{
				this.setCurrentlySelectedBro(entity);
			}
		}
		else if (this.CurrentlySelectedBro != null)
		{
			if(!this.isTileValidForBro(tile, this.CurrentlySelectedBro))
			{
				this.Tactical.getShaker().shake(this.CurrentlySelectedBro, tile, 1);
				return
			}
			this.Tactical.getNavigator().teleport(this.CurrentlySelectedBro, tile, null, null, false, 0.0);
		}
	}

	onRightClickPrepareCarefully = function(_mouseEvent)
	{
		local tile = this.Tactical.getTile(this.Tactical.screenToTile(_mouseEvent.getX(), _mouseEvent.getY()));
		if (!tile.IsEmpty && !tile.IsOccupiedByActor) return;
		local entity = tile.getEntity();
		if (entity != null && entity.isPlayerControlled())
		{
			if (this.CurrentlySelectedBro != null)
			{
				local valid = true;
				if (!this.isTileValidForBro(this.CurrentlySelectedBro.getTile(), entity))
				{
					this.Tactical.getShaker().shake(entity, tile, 1);
					valid = false;
				}
				if (!this.isTileValidForBro(tile, this.CurrentlySelectedBro))
				{
					this.Tactical.getShaker().shake(this.CurrentlySelectedBro, tile, 1);
					valid = false;
				}
				if (valid)
				{
					this.Tactical.getNavigator().switchEntities(entity, this.CurrentlySelectedBro, null, null, 1.0);
				}
			}
			else
			{
				this.setCurrentlySelectedBro(entity);
			}
		}
	},

	clearVariables = function()
	{
		this.PrepareCarefullyMode = false;
		if (this.CurrentlySelectedBro != null && !this.CurrentlySelectedBro.isNull())
		{
			this.showSelectedArrow(this.CurrentlySelectedBro, false);
		}
		this.CurrentlySelectedBro = null;
		this.PlayerDeploymentType = null;
		this.MinimalValidTiles = {
			AsString = [],
			AsTiles = [],
			Details = [],
		},
		this.ValidTiles = {
			AsString = [],
			AsTiles = [],
			Details = [],
		};
		this.ExtraValidTiles = {
			AsString = [],
			AsTiles = [],
			Details = [],
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
	},
}

::mods_registerMod(::PrepareCarefully.ID, ::PrepareCarefully.Version);

::mods_queue(::PrepareCarefully.ID, null, function()
{
	mods_registerJS("PrepareCarefully.js");
	mods_registerCSS("PrepareCarefully.css");
	::mods_hookExactClass("entity/tactical/actor", function(o)
	{
		local onInit = o.onInit;
		o.onInit = function()
		{
			onInit();
			local arrow = this.addSprite("PrepareCarefullyArrow");
			this.setSpriteColorization("PrepareCarefullyArrow", false);
			arrow.setBrush("bust_arrow");
			arrow.Visible = false;
			arrow.Color = ::PrepareCarefully.InvalidColor;
		}
	})

	::mods_hookExactClass("states/tactical_state", function(o){
		local onFinish = o.onFinish;
		o.onFinish = function()
		{
			onFinish();
			::PrepareCarefully.clearVariables();
		}

		local initMap = o.initMap;
		o.initMap = function()
		{
			initMap();
			::PrepareCarefully.clearVariables();
			local properties = this.getStrategicProperties();
			::PrepareCarefully.PrepareCarefullyMode = properties.IsPlayerInitiated;
			// if (this.World.Retinue.hasFollower("follower.lookout"))
			// 	::PrepareCarefully.PrepareCarefullyMode = true;
			::PrepareCarefully.PlayerDeploymentType = properties.PlayerDeploymentType;
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				::PrepareCarefully.getValidTiles();
				::PrepareCarefully.denyVisibility();
			}
		}

		local onMouseInput = o.onMouseInput;
		o.onMouseInput = function( _mouseEvent )
		{
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				if (_mouseEvent.getID() == 1)
					return ::PrepareCarefully.onLeftClickPrepareCarefully(_mouseEvent);
				else if (_mouseEvent.getID() == 2)
					return ::PrepareCarefully.onRightClickPrepareCarefully(_mouseEvent);
				else return onMouseInput(_mouseEvent);
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
			local ret = turnsequencebar_onNextRound( _round );
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				::PrepareCarefully.denyVisibility(false);
				local playerUnits = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
				foreach(bro in playerUnits)
				{
					bro.updateVisibilityForFaction()
				}
			}
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
			foreach (tile in ::PrepareCarefully.ExtraValidTiles.AsTiles)
			{
				tile.clear(this.Const.Tactical.DetailFlag.SpecialOverlay);
			}
			::PrepareCarefully.clearVariables();
			this.Tactical.fillVisibility(this.Const.Faction.Player, false);
			foreach (bro in this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player))
			{
				bro.updateVisibilityForFaction();
			}
		}
	})

	::mods_hookNewObject("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o)
	{
		local entityWaitTurn = o.entityWaitTurn;
		o.entityWaitTurn = function(_entity)
		{
			if (::PrepareCarefully.PrepareCarefullyMode)
			{
				return true;
			}
			return entityWaitTurn(_entity);
		}

		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(__force = false)
		{
			if (::PrepareCarefully.PrepareCarefullyMode)
				return;
			return initNextTurn(__force);
		}
	})
})
