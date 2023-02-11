#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct TextureUVCoordinateSet;
struct CompoundTag;
struct Material;
struct BlockSource;
struct PlayerInventoryProxy;

enum class MaterialType : int {
	DEFAULT = 0,
	DIRT,
	WOOD,
	STONE,
	METAL,
	WATER,
	LAVA,
	PLANT,
	DECORATION,
	WOOL = 11,
	BED,
	FIRE,
	SAND,
	DEVICE,
	GLASS,
	EXPLOSIVE,
	ICE,
	PACKED_ICE,
	SNOW,
	CACTUS = 22,
	CLAY,
	PORTAL = 25,
	CAKE,
	WEB,
	CIRCUIT,
	LAMP = 30,
	SLIME
};

enum class BlockSoundType : int {
	NORMAL, GRAVEL, WOOD, GRASS, METAL, STONE, CLOTH, GLASS, SAND, SNOW, LADDER, ANVIL, SLIME, SILENT, DEFAULT, UNDEFINED
};

enum class CreativeItemCategory : unsigned char {
	BLOCKS = 1,
	DECORATIONS,
	TOOLS,
	ITEMS
};

struct Block
{
	void** vtable;
	char filler[0x90-8];
	int category;
	char filler2[0x94+0x19+0x90-4];
};

struct SlabBlock :public Block {};

struct Item {
	void** vtable; // 0
	uint8_t maxStackSize; // 8
	int idk; // 12
	std::string atlas; // 16
	int frameCount; // 40
	bool animated; // 44
	short itemId; // 46
	std::string name; // 48
	std::string idk3; // 72
	bool isMirrored; // 96
	short maxDamage; // 98
	bool isGlint; // 100
	bool renderAsTool; // 101
	bool stackedByData; // 102
	uint8_t properties; // 103
	int maxUseDuration; // 104
	bool explodeable; // 108
	bool shouldDespawn; // 109
	bool idk4; // 110
	uint8_t useAnimation; // 111
	int creativeCategory; // 112
	float idk5; // 116
	float idk6; // 120
	char buffer[12]; // 124
	TextureUVCoordinateSet* icon; // 136
	char filler[100];
};

struct BlockItem :public Item {
	char filler[0xB0];
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	CompoundTag* tag;
	Item* item;
	Block* block;
	int idk[3];
};

struct BlockGraphics {
	void** vtable;
	char filler[0x20 - 8];
	int blockShape;
	char filler2[0x3C0 - 0x20 - 4];
};

/*	1.14's BlockShape
type = enum class BlockShape : int {BlockShape::INVISIBLE = -1, BlockShape::BLOCK, 
    BlockShape::CROSS_TEXTURE, BlockShape::TORCH, BlockShape::FIRE, BlockShape::WATER, 
    BlockShape::RED_DUST, BlockShape::ROWS, BlockShape::DOOR, BlockShape::LADDER, BlockShape::RAIL, 
    BlockShape::STAIRS, BlockShape::FENCE, BlockShape::LEVER, BlockShape::CACTUS, BlockShape::BED, 
    BlockShape::DIODE, BlockShape::IRON_FENCE = 18, BlockShape::STEM, BlockShape::VINE, 
    BlockShape::FENCE_GATE, BlockShape::CHEST, BlockShape::LILYPAD, BlockShape::BREWING_STAND = 25, 
    BlockShape::PORTAL_FRAME, BlockShape::COCOA = 28, BlockShape::TREE = 31, BlockShape::WALL, 
    BlockShape::DOUBLE_PLANT = 40, BlockShape::FLOWER_POT = 42, BlockShape::ANVIL, BlockShape::DRAGON_EGG, 
    BlockShape::STRUCTURE_VOID = 48, BlockShape::BLOCK_HALF = 67, BlockShape::TOP_SNOW, 
    BlockShape::TRIPWIRE, BlockShape::TRIPWIRE_HOOK, BlockShape::CAULDRON, BlockShape::REPEATER, 
    BlockShape::COMPARATOR, BlockShape::HOPPER, BlockShape::SLIME_BLOCK, BlockShape::PISTON, 
    BlockShape::BEACON, BlockShape::CHORUS_PLANT, BlockShape::CHORUS_FLOWER, BlockShape::END_PORTAL, 
    BlockShape::END_ROD, BlockShape::END_GATEWAY, BlockShape::SKULL, BlockShape::FACING_BLOCK, 
    BlockShape::COMMAND_BLOCK, BlockShape::TERRACOTTA, BlockShape::DOUBLE_SIDE_FENCE, 
    BlockShape::ITEM_FRAME, BlockShape::SHULKER_BOX, BlockShape::DOUBLESIDED_CROSS_TEXTURE, 
    BlockShape::DOUBLESIDED_DOUBLE_PLANT, BlockShape::DOUBLESIDED_ROWS, BlockShape::ELEMENT_BLOCK, 
    BlockShape::CHEMISTRY_TABLE, BlockShape::CORAL_FAN = 96, BlockShape::SEAGRASS, BlockShape::KELP, 
    BlockShape::TRAPDOOR, BlockShape::SEA_PICKLE, BlockShape::CONDUIT, BlockShape::TURTLE_EGG, 
    BlockShape::BUBBLE_COLUMN = 105, BlockShape::BARRIER, BlockShape::SIGN, BlockShape::BAMBOO, 
    BlockShape::BAMBOO_SAPLING, BlockShape::SCAFFOLDING, BlockShape::GRINDSTONE, BlockShape::BELL, 
    BlockShape::LANTERN, BlockShape::CAMPFIRE, BlockShape::LECTERN, BlockShape::SWEET_BERRY_BUSH, 
    BlockShape::CARTOGRAPHY_TABLE, BlockShape::COMPOSTER, BlockShape::STONE_CUTTER, 
    BlockShape::HONEY_BLOCK}
*/

enum class LevelSoundEvent : unsigned int {
	ItemUseOn, Hit, Step, Fly, Jump, Break, Place, HeavyStep, 
    Gallop, Fall, Ambient, AmbientBaby, AmbientInWater, Breathe, Death, DeathInWater, 
    DeathToZombie, Hurt, HurtInWater, Mad, Boost, Bow, SquishBig, SquishSmall, FallBig, 
    FallSmall, Splash, Fizz, Flap, Swim, Drink, Eat, Takeoff, Shake, Plop, 
    Land, Saddle, Armor, ArmorPlace, AddChest, Throw, Attack, AttackNoDamage, AttackStrong, 
    Warn, Shear, Milk, Thunder, Explode, Fire, Ignite, Fuse, Stare, Spawn
};

enum class EntityType : int
{
	IDK = 1,
    ITEM = 64,
    PRIMED_TNT,
    FALLING_BLOCK,
    EXPERIENCE_POTION = 68,
    EXPERIENCE_ORB,
    FISHINGHOOK = 77,
    ARROW = 80,
    SNOWBALL,
    THROWNEGG,
    PAINTING,
    LARGE_FIREBALL = 85,
    THROWN_POTION,
    LEASH_FENCE_KNOT = 88,
    BOAT = 90,
    LIGHTNING_BOLT = 93,
    SAMLL_FIREBALL,
    TRIPOD_CAMERA = 318,
    PLAYER,
    IRON_GOLEM = 788,
    SOWN_GOLEM,
    VILLAGER = 1807,
    CREEPER = 2849,
    SLIME = 2853,
    ENDERMAN,
    GHAST = 2857,
    LAVA_SLIME,
    BLAZE,
    WITCH = 2861,
    CHICKEN = 5898,
    COW ,
    PIG,
    SHEEP,
    MUSHROOM_COW = 5904,
    RABBIT = 5906,
    SQUID = 10001,
    WOLF = 22286,
    OCELOT = 22294,
    BAT = 33043,
    PIG_ZOMBIE = 68388,
    ZOMBIE = 199456,
    ZOMBIE_VILLAGER = 199468,
    SPIDER = 264995,
    SILVERFISH = 264999,
    CAVE_SPIDER,
    MINECART_RIDEABLE = 524372,
    MINECART_HOPPER = 524384,
    MINECART_MINECART_TNT,
    MINECART_CHEST,
    SKELETON = 1116962,
    WITHER_SKELETON = 1116974,
    STRAY = 1116976,
    HORSE = 2119447,
    DONKEY,
    MULE,
    SKELETON_HORSE,
    ZOMBIE_HORSE
};

struct LevelData {
	char filler[48];
	std::string levelName;
	char filler2[44];
	int time;
	char filler3[144];
	int gameType;
	int difficulty;
};

struct Level {
	char filler[160];
	LevelData data;
};

struct Entity {
	char filler[64];
	Level* level;
	char filler2[104];
	BlockSource* region;
};

struct Player :public Entity {
	char filler[4400];
	PlayerInventoryProxy* inventory;
};

struct Vec3 {
	float x, y, z;
};

struct BlockPos {
	int x, y, z;
};

struct AABB {
	Vec3 min, max;
	bool valid;
};

struct BlockID {
	static BlockID AIR;

	unsigned char id;

	BlockID() : id(0) {}
	BlockID(unsigned char id) : id(id) {}
	BlockID(const BlockID& other) {id = other.id;}
};

struct FullBlock {
	static FullBlock AIR;

	BlockID id;
	unsigned char aux;

	FullBlock() : id(0), aux(0) {};
	FullBlock(BlockID tileId, unsigned char aux_) : id(tileId), aux(aux_) {}
};

namespace Json { class Value; }

Item** Item$mItems;
Block** Block$mBlocks;
BlockGraphics** BlockGraphics$mBlocks;

static std::unordered_map<std::string, Block*>* Block$mBlockLookupMap;

BlockItem*(*BlockItem$BlockItem)(BlockItem*, std::string const&, int);

ItemInstance*(*ItemInstance$ItemInstance)(ItemInstance*, int, int, int);

void(*Item$addCreativeItem)(const ItemInstance&);

Block*(*Block$Block)(Block*, std::string const&, int, Material const&);
SlabBlock*(*SlabBlock$SlabBlock)(SlabBlock*, std::string const&, int, bool, Material const&);

Material&(*Material$getMaterial)(MaterialType);

BlockGraphics*(*BlockGraphics$BlockGraphics)(BlockGraphics*, std::string const&);
void(*BlockGraphics$setCarriedTextureItem)(BlockGraphics*, std::string const&, std::string const&, std::string const&);
void(*BlockGraphics$setTextureItem)(BlockGraphics*, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&);

BlockID(*BlockSource$getBlockID)(BlockSource*, BlockPos const&);
void(*BlockSource$setBlock)(BlockSource*, BlockPos const&, BlockID, int);
FullBlock(*BlockSource$getBlockAndData)(BlockSource*, BlockPos const&);

void(*Level$broadcastSoundEvent)(Level*, BlockSource&, LevelSoundEvent, Vec3 const&, int, EntityType, bool, bool);

//slab
int testItem = 238;
BlockItem* myItemPtr;
SlabBlock* myBlockPtr;
BlockGraphics* myBlockGraphicsPtr;

//double_slab
int DoubletestItem = 239;
BlockItem* myDoubleItemPtr;
SlabBlock* myDoubleBlockPtr;
BlockGraphics* myDoubleBlockGraphicsPtr;

static uintptr_t** VTAppPlatformiOS;

static bool (*_File$exists)(std::string const&);
static bool File$exists(std::string const& path) {
	if(path.find("minecraftpe.app/data/resourcepacks/vanilla/client/textures/blocks/test.png") != std::string::npos)
		return true;

	return _File$exists(path);
}

static std::string (*_AppPlatformiOS$readAssetFile)(uintptr_t*, std::string const&);
static std::string AppPlatformiOS$readAssetFile(uintptr_t* self, std::string const& str) {

    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/blocks/test.png"))
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addtestblockmod/test.png");

    std::string content = _AppPlatformiOS$readAssetFile(self, str);
    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/terrain_texture.json")) {
        NSString *jsonString = [NSString stringWithUTF8String:content.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];

        NSMutableDictionary *jsonTextureData = [jsonDict objectForKey:@"texture_data"];
        [jsonTextureData setObject:@{
            @"textures": @[@"textures/blocks/test"]
        } forKey:@"test"];
       
        jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        content = std::string([jsonString UTF8String]);
    }
    return content;
}

static void (*_Item$initCreativeItems)();
static void Item$initCreativeItems() {
	_Item$initCreativeItems();

	ItemInstance inst;
	ItemInstance$ItemInstance(&inst, testItem, 1, 0);
	Item$addCreativeItem(inst);

	ItemInstance instDouble;
	ItemInstance$ItemInstance(&instDouble, DoubletestItem, 1, 0);
	Item$addCreativeItem(instDouble);	
}

static void (*_Item$addBlockItems)();
static void Item$addBlockItems() {
	_Item$addBlockItems();

	myItemPtr = new BlockItem();
	BlockItem$BlockItem(myItemPtr, "test_block_slab", testItem - 0x100);
	Item$mItems[testItem] = myItemPtr;

	myDoubleItemPtr = new BlockItem();
	BlockItem$BlockItem(myDoubleItemPtr, "double_test_block_slab", DoubletestItem - 0x100);
	Item$mItems[DoubletestItem] = myDoubleItemPtr;
}

static void (*_Block$initBlocks)();
static void Block$initBlocks() {
	_Block$initBlocks();

	myBlockPtr = new SlabBlock();
	//Block$Block(myBlockPtr, "testblock", testItem, Material$getMaterial(MaterialType::DEFAULT));
	SlabBlock$SlabBlock(myBlockPtr, "test_block_slab", testItem, false, Material$getMaterial(MaterialType::DEFAULT));
	Block$mBlocks[testItem] = myBlockPtr;
	(*Block$mBlockLookupMap)["test_block_slab"] = myBlockPtr;
	myBlockPtr->category = 1;

	myDoubleBlockPtr = new SlabBlock();
	//Block$Block(myBlockPtr, "testblock", testItem, Material$getMaterial(MaterialType::DEFAULT));
	SlabBlock$SlabBlock(myDoubleBlockPtr, "double_test_block_slab", DoubletestItem, true, Material$getMaterial(MaterialType::DEFAULT));
	Block$mBlocks[DoubletestItem] = myDoubleBlockPtr;
	(*Block$mBlockLookupMap)["double_test_block_slab"] = myDoubleBlockPtr;
	myDoubleBlockPtr->category = 1;
}

static void (*_BlockGraphics$initBlocks)();
static void BlockGraphics$initBlocks() {
	_BlockGraphics$initBlocks();

	myBlockGraphicsPtr = new BlockGraphics();
	BlockGraphics$BlockGraphics(myBlockGraphicsPtr, "test_block_slab");
	BlockGraphics$mBlocks[testItem] = myBlockGraphicsPtr;
	myBlockGraphicsPtr->blockShape = 67;
	BlockGraphics$setCarriedTextureItem(myBlockGraphicsPtr, "test", "test", "test");
	BlockGraphics$setTextureItem(myBlockGraphicsPtr, "test", "test", "test", "test", "test", "test");

	myDoubleBlockGraphicsPtr = new BlockGraphics();
	BlockGraphics$BlockGraphics(myDoubleBlockGraphicsPtr, "double_test_block_slab");
	BlockGraphics$mBlocks[DoubletestItem] = myDoubleBlockGraphicsPtr;
	myDoubleBlockGraphicsPtr->blockShape = 67;
	BlockGraphics$setCarriedTextureItem(myDoubleBlockGraphicsPtr, "test", "test", "test");
	BlockGraphics$setTextureItem(myDoubleBlockGraphicsPtr, "test", "test", "test", "test", "test", "test");
}

bool (*_BlockItem$useOn)(BlockItem*, ItemInstance*, Player*, int, int, int, signed char, float, float, float);
bool BlockItem$useOn(BlockItem* self, ItemInstance* inst, Player* player, int x, int y , int z, signed char side, float xx, float yy, float zz) {

    if(self == Item$mItems[testItem]) {
        FullBlock fullBlock = BlockSource$getBlockAndData(player->region, BlockPos({x, y, z}));
        bool usedOnSlab = fullBlock.id.id == testItem;

        if((side == 1 && (fullBlock.aux & 8) == 0 && usedOnSlab) || (side == 0 && (fullBlock.aux & 8) != 0 && usedOnSlab)) {
            BlockSource$setBlock(player->region, BlockPos({x, y, z}), BlockID(DoubletestItem), 0);
            Level$broadcastSoundEvent(player->level, *player->region, LevelSoundEvent::ItemUseOn, Vec3({x + 0.5f, y + 0.5f, z + 0.5f}), DoubletestItem, EntityType::IDK, false, false);
            return true;
        }
    }

    return _BlockItem$useOn(self, inst, player, x, y, z, side, xx, yy, zz);
}

%ctor {
	VTAppPlatformiOS = (uintptr_t**)(0x1011695f0 + _dyld_get_image_vmaddr_slide(0));
	_AppPlatformiOS$readAssetFile = (std::string(*)(uintptr_t*, std::string const&)) VTAppPlatformiOS[58];
	VTAppPlatformiOS[58] = (uintptr_t*)&AppPlatformiOS$readAssetFile;

	Item$mItems = (Item**)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));
	Block$mBlocks = (Block**)(0x1012d1860 + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$mBlocks = (BlockGraphics**)(0x10126a100 + _dyld_get_image_vmaddr_slide(0));

	Block$mBlockLookupMap = (std::unordered_map<std::string, Block*>*)(0x1012d2078 + _dyld_get_image_vmaddr_slide(0));

	BlockItem$BlockItem = (BlockItem*(*)(BlockItem*, std::string const&, int))(0x1007281e0 + _dyld_get_image_vmaddr_slide(0));

	ItemInstance$ItemInstance = (ItemInstance*(*)(ItemInstance*, int, int, int))(0x100756c70 + _dyld_get_image_vmaddr_slide(0));

	Item$addCreativeItem = (void(*)(const ItemInstance&))(0x100745f10 + _dyld_get_image_vmaddr_slide(0));

	Block$Block = (Block*(*)(Block*, std::string const&, int, Material const&))(0x1007d7e20 + _dyld_get_image_vmaddr_slide(0));
	SlabBlock$SlabBlock = (SlabBlock*(*)(SlabBlock*, std::string const&, int, bool, Material const&))(0x10082027c + _dyld_get_image_vmaddr_slide(0));

	Material$getMaterial = (Material&(*)(MaterialType))(0x1008c6e74 + _dyld_get_image_vmaddr_slide(0));

	BlockGraphics$BlockGraphics = (BlockGraphics*(*)(BlockGraphics*, std::string const&))(0x100388338 + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$setCarriedTextureItem = (void(*)(BlockGraphics*, std::string const&, std::string const&, std::string const&))(0x100382f0c + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$setTextureItem = (void(*)(BlockGraphics*, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&))(0x1003829c8 + _dyld_get_image_vmaddr_slide(0));

	BlockSource$getBlockID = (BlockID(*)(BlockSource*, BlockPos const&))(0x10079a014 + _dyld_get_image_vmaddr_slide(0));
	BlockSource$setBlock = (void(*)(BlockSource*, BlockPos const&, BlockID, int))(0x10079b3a4 + _dyld_get_image_vmaddr_slide(0));
	BlockSource$getBlockAndData = (FullBlock(*)(BlockSource*, BlockPos const&))(0x10079a1fc + _dyld_get_image_vmaddr_slide(0));

	Level$broadcastSoundEvent = (void(*)(Level*, BlockSource&, LevelSoundEvent, Vec3 const&, int, EntityType, bool, bool))(0x1007a780c + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x1005316ec + _dyld_get_image_vmaddr_slide(0)), (void*)&File$exists, (void**)&_File$exists);

	MSHookFunction((void*)(0x100734d00 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initCreativeItems, (void**)&_Item$initCreativeItems);
	MSHookFunction((void*)(0x100745f6c + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$addBlockItems, (void**)&_Item$addBlockItems);
	MSHookFunction((void*)(0x1007d451c + _dyld_get_image_vmaddr_slide(0)), (void*)&Block$initBlocks, (void**)&_Block$initBlocks);
	MSHookFunction((void*)(0x1003845e0 + _dyld_get_image_vmaddr_slide(0)), (void*)&BlockGraphics$initBlocks, (void**)&_BlockGraphics$initBlocks);

	MSHookFunction((void*)(0x1007282d8 + _dyld_get_image_vmaddr_slide(0)), (void*)&BlockItem$useOn, (void**)&_BlockItem$useOn);
}