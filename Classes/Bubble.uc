class Bubble extends GGKActor
placeable;

var SoundCue mPopSound;
var float mBubbleImpulse;
var float mRadius;

simulated event PostBeginPlay()
{
	local box myBox;
	local vector dist;

	super.PostBeginPlay();

	// Make bubble float
	StaticMeshComponent.BodyInstance.CustomGravityFactor=0.f;
	// Give bubble a lifetime
	SetTimer(RandRange(30.f, 300.f), false, nameof( PopBubble ));
	// Add movement
	AddRandomInpulse();
	// Compute radius
	GetComponentsBoundingBox(myBox);
	dist = myBox.Max-myBox.Min;
	mRadius=dist.Z / 2.f;
	// Try merge on spawn
	CheckNearbyForMerge();
	// Enable physics
	CollisionComponent.WakeRigidBody();
}

function string GetActorName()
{
	return "Bubble";
}

function int GetScore()
{
	return 1;
}

function AddRandomInpulse()
{
	local vector direction, vel;

	SetTimer(RandRange(5.f, 10.f), false, nameof( AddRandomInpulse ));
	if(VSize(StaticMeshComponent.GetRBLinearVelocity()) > 0.1f)
		return;

	direction.X=RandRange( -1.0f, 1.0f );
	direction.Y=RandRange( -1.0f, 1.0f );
	direction.Z=RandRange( -1.0f, 1.0f );
	vel = Normal(direction) * (mBubbleImpulse * RandRange(1.f, 2.f));
	StaticMeshComponent.SetRBLinearVelocity(vel);
}

function bool shouldIgnoreActor(Actor act)
{
	return (
	act == none
	|| Volume(act) != none
	|| GGApexDestructibleActor(act) != none
	|| act == self);
}
// Allow goat to step on bubble
function bool shouldIgnoreDamageTypeForActor(class< DamageType > damageType, Actor act)
{
	//WorldInfo.Game.Broadcast(self, "shouldIgnoreDamageTypeForActor=" $ act $ ", type=" $ damageType $ ", actZ=" $ act.Location.Z $ ", myZ=" $ Location.Z $ ", radius=" $ mRadius);
	return GGGoat(act) != none && damageType == class'GGDamageTypeCollision' && act.Location.Z > Location.Z + mRadius;
}

simulated event TakeDamage( int damage, Controller eventInstigator, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	super.TakeDamage(damage, eventInstigator, hitLocation, momentum, damageType, hitInfo, damageCauser);
	//WorldInfo.Game.Broadcast(self, "TakeDamage=" $ damageCauser $ ", type=" $ damageType);
	HitActorWithDamage(damageCauser, damageType);
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
    super.Bump(Other, OtherComp, HitNormal);
	//WorldInfo.Game.Broadcast(self, "Bump=" $ other);
	HitActorWithDamage(other, class'GGDamageTypeCollision');
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex);
	//WorldInfo.Game.Broadcast(self, "RBCollision=" $ OtherComponent.Owner);
	HitActorWithDamage(OtherComponent!=none?OtherComponent.Owner:none, class'GGDamageTypeCollision');
}

function HitActorWithDamage(Actor act, class< DamageType > damageType)
{
	local Bubble otherBubble;

	if(!shouldIgnoreActor(act) && !shouldIgnoreDamageTypeForActor(damageType, act))
	{
		otherBubble=Bubble(act);
		if(otherBubble != none && !HaveBasedPawn() && !otherBubble.HaveBasedPawn())
		{
			MergeWith(otherBubble);
		}
		else
		{
			PopBubble();
		}
	}
}

function bool HaveBasedPawn()
{
 	local GGPawn gpawn;

	foreach BasedActors(class'GGPawn', gpawn)
 	{
 		if(gpawn != none)
			return true;
 	}

 	return false;
}

function OnGrabbed( Actor grabbedByActor )
{
	PopBubble();
}

function MergeWith(Bubble otherBubble)
{
	local vector spawnLocation;
	local float mySurface, newSurface, otherSurface, newRadius, newScale;

	// Place new bubble in the middle of others
	spawnLocation = Location + ((otherBubble.Location - Location) / 2.f);
	// Add their surface
	mySurface = 4.f * Pi * mRadius * mRadius;
	otherSurface = 4.f * Pi * otherBubble.mRadius * otherBubble.mRadius;
	newSurface = mySurface + otherSurface;
	// Determine new radius (and scale)
	newRadius = Sqrt(newSurface / (4.f * Pi));
	newScale = (StaticMeshComponent.scale / mRadius) * newRadius;
	// Move bubble out of the way and destroy other bubble
	otherBubble.Destroy();
	StaticMeshComponent.SetRBPosition(vect(0, 0, -2000));
	// Set new scale and spawn bubble
	StaticMeshComponent.SetScale(newScale);
	Spawn( class'Bubble',,, spawnLocation,, self, true);
	// Destroy old bubble
	Destroy();
}

function CheckNearbyForMerge()
{
 	local Bubble hitBubble;
	local TraceHitInfo hitInfo;

	foreach VisibleCollidingActors( class'Bubble', hitBubble, mRadius, Location,,,,, hitInfo )
	{
		if(hitBubble != none && !HaveBasedPawn() && !hitBubble.HaveBasedPawn())
		{
			MergeWith(hitBubble);
			break;
		}
	}
}

function PopBubble()
{
	PlaySound(mPopSound);
	Destroy();
}

DefaultProperties
{
	bStatic=false
	bNoDelete=false

	mBubbleImpulse=10.f

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Space_Museum_Exterior.Meshes.Sphere'
		//Materials[0]=MaterialInstanceConstant'Camper.Materials.Camper_Glass_Mat_01_INST'//Sound
		//Materials[0]=Material'House_01.Materials.Window_Mat_01'
		//Materials[0]=Material'Hotel_01.Materials.Balcony_Glass_Mat_01'//Sound
		Materials[0]=Material'Space_FlightSimulator.Materials.CockpitGlass_Mat_01'
		//Materials[0]=Material'Space_Museum_Exterior.Materials.Glass_Mat_01'
		//Materials[0]=Material'Space_Museum_Exterior.Materials.GlassFence_Glass_Mat'
		//Materials[0]=Material'Space_Restaurant.Materials.GlassTransparent_Mat_01'
		//Materials[0]=Material'Space_CrowdfundingCentral.Materials.GoldPipe_Glass_Mat_01'
		//Materials[0]=Material'Heist_BaseMaterials.Materials.Heist_Glass_Master_DoubleSided_03'
		//Materials[0]=Material'Hotel_01.Materials.Lobby_Glass_Mat_01'
		//Materials[0]=Material'Space_ParticleAccelerator.Materials.PA_Glass_Mat_01'
		Scale3D=(X=0.5f, Y=0.5f, Z=0.5f)
	End Object

	mPopSound=SoundCue'Heist_Audio.Cue.SFX_Syringe_Shot_Mono_01_Cue'
}