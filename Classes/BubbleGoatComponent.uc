class BubbleGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var SoundCue makeBubbleSound;
var bool mIsMakingBubbles;
var float mTotalTime;
var float mBubbleTime;
//Used as template when spawning new bubbles so that the new bubble can have a random scale and correct collision
var Bubble mTemplateBubble;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			mIsMakingBubbles=true;
			mTotalTime=0.f;
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			mIsMakingBubbles=false;
		}
	}
}

function TickMutatorComponent(float DeltaTime)
{
	super.TickMutatorComponent(DeltaTime);

	mTotalTime += DeltaTime;
	if(mIsMakingBubbles && mTotalTime >= mBubbleTime)
	{
		mTotalTime=0.f;
		MakeBubble();
	}
}

function MakeBubble()
{
	local vector spawnLocation, spawnDir;
	local rotator newRot;

	gMe.Mesh.GetSocketWorldLocationAndRotation( 'Demonic', spawnLocation );
	if(IsZero(spawnLocation))
	{
		spawnLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 70.f));
	}
	// Get a random location around the goat
	spawnDir=spawnLocation - gMe.Location;
	newRot=rotator(Normal(spawnDir));
	newRot.Yaw = Rand(65536);
	spawnLocation = (Normal(vector(newRot)) * VSize(spawnDir)) + gMe.Location;
	//Spawn the bubble
	gMe.PlaySound(makeBubbleSound);
	RandomizeTemplateBubble();
	gMe.Spawn( class'Bubble',,, spawnLocation,, mTemplateBubble, true);
}

function RandomizeTemplateBubble()
{
	if(mTemplateBubble == none || mTemplateBubble.bPendingDelete)
	{
		mTemplateBubble = gMe.Spawn( class'Bubble',,, vect(0, 0, -1000),,, true);
	}

	mTemplateBubble.StaticMeshComponent.SetScale(RandRange(0.2f, 1.f));
}

defaultproperties
{
	mBubbleTime=1.f

	makeBubbleSound=SoundCue'Heist_Audio.Cue.SFX_Camel_Fill_Hump_Cue'
}