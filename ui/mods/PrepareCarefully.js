
var createDIV = TacticalScreenTopbarRoundInformationModule.prototype.createDIV;
TacticalScreenTopbarRoundInformationModule.prototype.createDIV = function(_parentDiv)
{
	createDIV.call(this, _parentDiv);
	var self = this;
	this.mStartBattleContainer = $('<div class="prepare-for-battle-button-container"/>');
	this.mContainer.append(this.mStartBattleContainer);
	this.mStartBattleContainer.createTextButton("Start Battle", function ()
	{
	    self.onPrepareCarefullyButtonPressed();
	}, null, 4)
}

var update = TacticalScreenTopbarRoundInformationModule.prototype.update;
TacticalScreenTopbarRoundInformationModule.prototype.update = function (_data)
{
	update.call(this, _data);
	if ("PrepareCarefullyMode" in _data && _data.PrepareCarefullyMode )
	{
		this.mStartBattleContainer.addClass("display-block").removeClass("display-none");
	}
	else
	{
		this.mStartBattleContainer.addClass("display-none").removeClass("display-block");
	}
}

TacticalScreenTopbarRoundInformationModule.prototype.onPrepareCarefullyButtonPressed = function()
{
	this.mStartBattleContainer.addClass("display-none").removeClass("display-block");
    SQ.call(Screens["TacticalScreen"].mSQHandle, 'onPrepareCarefullyButtonPressed');
}
