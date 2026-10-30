#import "Utils.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <math.h>
#import "substrate.h"

uint64_t bh_memmem(const uint8_t* haystack, size_t hlen, const uint8_t* needle, size_t nlen) {
    size_t last, scan = 0;
    size_t bad_char_skip[UCHAR_MAX + 1];
    if (nlen <= 0 || !haystack || !needle) return 0;
    for (scan = 0; scan <= UCHAR_MAX; scan = scan + 1) bad_char_skip[scan] = nlen;
    
    last = nlen - 1;
    for (scan = 0; scan < last; scan = scan + 1)
        bad_char_skip[needle[scan]] = last - scan;

    while (hlen >= nlen) {
        for (scan = last; haystack[scan] == needle[scan]; scan = scan - 1) {
            if (scan == 0) return (uint64_t)haystack;
            if (*(uint32_t *)haystack == 0xd65f03c0) return 0; // reached ret
            if (*(uint32_t *)haystack == 0xd65f0fff) return 0; // reached retab
        }
        
        hlen -= bad_char_skip[haystack[last]];
        haystack += bad_char_skip[haystack[last]];
    }
    return 0;
}

int (*__LHPatchMemory)(const struct LHMemoryPatch *patches, int count);
int PatchMemory(const struct LHMemoryPatch *patches, int count) {
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        void* lhImage = dlopen((ROOT_PATH("/usr/lib/libhooker.dylib")), RTLD_NOW);
        if(lhImage) {
            __LHPatchMemory = (void*)dlsym(lhImage, "LHPatchMemory");
        }
    });

    if(__LHPatchMemory) {
        return __LHPatchMemory(patches, count);
    } else {
        for(int i = 0; i < count; i++)
        {
            struct LHMemoryPatch patch = patches[i];
            MSHookMemory(patch.destination, patch.data, patch.size);
        }
        return 0;
    }
}

void HookMemory(Class class, SEL selector, uint64_t offset, uint32_t data) {
	void *final_offset = (void *)[class instanceMethodForSelector:selector] + offset;
	struct LHMemoryPatch patch;
	patch.destination = final_offset;
	patch.data = &data;
	patch.size = sizeof(data);
	patch.options = NULL;

	PatchMemory(&patch, 1);
}

void alert(UIView* object, NSString *title, NSString *message) {
    UIViewController *vc = object.window.rootViewController;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [vc presentViewController:alert animated:YES completion:nil];
}

NSDictionary *getPreferences() {
    static NSDictionary *preferences;
    if (!preferences) {
        CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.fiore.gameseagull.prefs"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

        if (keyList) {
            preferences = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR("com.fiore.gameseagull.prefs"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFRelease(keyList);
        }

        if (!preferences) {
            preferences = [[NSDictionary alloc] initWithContentsOfFile:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.fiore.gameseagull.prefs.plist")];

        }
    }

    return preferences;
}

bool boolForKey(NSString *key) {
    if (!getPreferences()) return false;

    id val = getPreferences()[key];
    return val ? [val boolValue] : false;
}

UIButton *makeButton(NSString *title, CGRect frame, id target, SEL selector) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:frame];
    [button setBackgroundColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:.85]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    button.layer.cornerRadius = 14;
    return button;
}

SCNVector3 getAimbotPos(int multiplier, int number) {
	if (multiplier == 1 && number == 25) {
		return SCNVector3Make(0.0, 0.325, 0.0);
	} else if (multiplier == 1 && number == 50) {
		return SCNVector3Make(0.0, 0.35, 0.0);
	}
	
	NSArray *points = @[
		@[
			@[@0.05, @0.5, @0.0],
			@[@0.2, @0.0, @0.0],
			@[@0.0, @0.0, @0.0],
			@[@0.2, @0.5, @0.0],
			@[@-0.05, @0.5, @0.0],
			@[@0.2, @0.35, @0.0],
			@[@-0.2, @0.0, @0.0],
			@[@-0.2, @0.3, @0.0],
			@[@-0.2, @0.5, @0.0],
			@[@0.2, @0.3, @0.0],
			@[@-0.2, @0.35, @0.0],
			@[@-0.1, @0.5, @0.0],
			@[@0.2, @0.4, @0.0],
			@[@-0.2, @0.4, @0.0],
			@[@0.2, @0.2, @0.0],
			@[@-0.2, @0.2, @0.0],
			@[@0.1, @0.0, @0.0],
			@[@0.1, @0.5, @0.0],
			@[@-0.1, @0.0, @0.0],
			@[@0.0, @0.5, @0.0]
		], @[
			@[@0.15, @0.815, @0.0],
			@[@0.26, @-0.05, @0.0],
			@[@0.0, @-0.145, @0.0],
			@[@0.4, @0.625, @0.0],
			@[@-0.15, @0.815, @0.0],
			@[@0.49, @0.35, @0.0],
			@[@-0.26, @-0.05, @0.0],
			@[@-0.47, @0.175, @0.0],
			@[@-0.4, @0.625, @0.0],
			@[@0.47, @0.175, @0.0],
			@[@-0.49, @0.35, @0.0],
			@[@-0.26, @0.75, @0.0],
			@[@0.47, @0.46, @0.0],
			@[@-0.47, @0.46, @0.0],
			@[@0.4, @0.05, @0.0],
			@[@-0.4, @0.05, @0.0],
			@[@0.15, @-0.125, @0.0],
			@[@0.26, @0.75, @0.0],
			@[@-0.15, @-0.125, @0.0],
			@[@0.0, @0.835, @0.0],
		],
		@[
			@[@0.1, @0.63, @0.0],
			@[@0.175, @0.1, @0.0],
			@[@0.0, @0.035, @0.0],
			@[@0.25, @0.53, @0.0],
			@[@-0.1, @0.63, @0.0],
			@[@0.3, @0.35, @0.0],
			@[@-0.175, @0.1, @0.0],
			@[@-0.28, @0.25, @0.0],
			@[@-0.25, @0.53, @0.0],
			@[@0.28, @0.25, @0.0],
			@[@-0.3, @0.35, @0.0],
			@[@-0.175, @0.59, @0.0],
			@[@0.28, @0.45, @0.0],
			@[@-0.28, @0.45, @0.0],
			@[@0.25, @0.16, @0.0],
			@[@-0.25, @0.16, @0.0],
			@[@0.1, @0.05, @0.0],
			@[@0.175, @0.59, @0.0],
			@[@-0.1, @0.05, @0.0],
			@[@0.0, @0.65, @0.0]
		]
	];

	NSArray *coords = points[multiplier - 1][number - 1];

	return SCNVector3Make([coords[0] floatValue], [coords[1] floatValue], [coords[2] floatValue]);
}

// =========================================================================================================
//  8 Ball / 9 Ball prediction lines + Find Shot
//
//  Reverse-engineered facts (MessagesExtension arm64, verified in disassembly):
//   - b2Body: m_xf.p @ 0xc, m_linearVelocity @ 0x40, m_next @ 0x68, m_userData @ 0xb0 (no vptr)
//   - b2World: m_bodyList @ 0x19320
//   - body->m_userData is the PoolBall object for numbered balls
//   - scene ivars: white (b2Body* cue), world, holes [6 b2Vec2] inline, hole_radius, rad,
//     table_center (b2Vec2 inline), board_size, board_size_h, direction (aim angle, scene-space),
//     touchDown (B), moving (B), mine (B), cue_ball (SKSpriteNode)
//   - mMove proves direction = atan2(touch.y - ballSprite.y, touch.x - ballSprite.x)
//   - scene = b2 * k (uniform positive scale), proven by the game firing physics with the
//     same direction it draws with
// =========================================================================================================

#pragma mark - pool: tiny math

static inline CGPoint gpSub(CGPoint a, CGPoint b) { return CGPointMake(a.x - b.x, a.y - b.y); }
static inline CGFloat gpDot(CGPoint a, CGPoint b) { return a.x * b.x + a.y * b.y; }
static inline CGFloat gpLen(CGPoint a) { return sqrt(a.x * a.x + a.y * a.y); }
static inline CGPoint gpNorm(CGPoint a) {
	CGFloat l = gpLen(a);
	return l > 1e-9 ? CGPointMake(a.x / l, a.y / l) : CGPointMake(0, 0);
}

// smallest t > 0 where |o + t*d - c| == R, else -1
static CGFloat gpRayCircle(CGPoint o, CGPoint d, CGPoint c, CGFloat R) {
	CGPoint oc = gpSub(o, c);
	CGFloat b = gpDot(oc, d);
	CGFloat cc = gpDot(oc, oc) - R * R;
	CGFloat disc = b * b - cc;
	if (disc < 0) return -1;
	CGFloat sq = sqrt(disc);
	CGFloat t1 = -b - sq, t2 = -b + sq;
	if (t1 > 1e-4) return t1;
	if (t2 > 1e-4) return t2;
	return -1;
}

// smallest t > 0 where ray exits rect, with the wall normal; returns NO when starting outside or no hit
static BOOL gpRayRectExit(CGPoint o, CGPoint d, CGRect r, CGFloat *tOut, CGPoint *normalOut) {
	CGFloat best = 1e30;
	CGPoint n = CGPointZero;
	if (d.x > 1e-9)  { CGFloat t = (CGRectGetMaxX(r) - o.x) / d.x; if (t > 1e-4 && t < best) { best = t; n = CGPointMake(-1, 0); } }
	if (d.x < -1e-9) { CGFloat t = (CGRectGetMinX(r) - o.x) / d.x; if (t > 1e-4 && t < best) { best = t; n = CGPointMake(1, 0); } }
	if (d.y > 1e-9)  { CGFloat t = (CGRectGetMaxY(r) - o.y) / d.y; if (t > 1e-4 && t < best) { best = t; n = CGPointMake(0, -1); } }
	if (d.y < -1e-9) { CGFloat t = (CGRectGetMinY(r) - o.y) / d.y; if (t > 1e-4 && t < best) { best = t; n = CGPointMake(0, 1); } }
	if (best >= 1e30) return NO;
	*tOut = best;
	if (normalOut) *normalOut = n;
	return YES;
}

static CGFloat gpSegPointDist(CGPoint p, CGPoint a, CGPoint b) {
	CGPoint ab = gpSub(b, a), ap = gpSub(p, a);
	CGFloat l2 = gpDot(ab, ab);
	if (l2 < 1e-9) return gpLen(ap);
	CGFloat t = gpDot(ap, ab) / l2;
	t = MAX(0.f, MIN(1.f, t));
	return gpLen(gpSub(p, CGPointMake(a.x + ab.x * t, a.y + ab.y * t)));
}

#pragma mark - pool: ivar helpers (per-class runtime lookup, offsets differ between PoolScene/2/3)

static Ivar GSPoolIvar(id obj, const char *name) {
	return class_getInstanceVariable(object_getClass(obj), name);
}

static void *GSPoolPtrIVar(id obj, const char *name) {
	Ivar iv = GSPoolIvar(obj, name);
	if (!iv) return NULL;
	return *(void **)(((char *)(__bridge void *)obj) + ivar_getOffset(iv));
}

static float GSPoolFloatIVar(id obj, const char *name, float fallback) {
	Ivar iv = GSPoolIvar(obj, name);
	if (!iv) return fallback;
	return *(float *)(((char *)(__bridge void *)obj) + ivar_getOffset(iv));
}

static BOOL GSPoolBoolIVar(id obj, const char *name) {
	Ivar iv = GSPoolIvar(obj, name);
	if (!iv) return NO;
	return *(BOOL *)(((char *)(__bridge void *)obj) + ivar_getOffset(iv));
}

static void GSPoolSetFloatIVar(id obj, const char *name, float value) {
	Ivar iv = GSPoolIvar(obj, name);
	if (!iv) return;
	*(float *)(((char *)(__bridge void *)obj) + ivar_getOffset(iv)) = value;
}

// b2Vec2 position of a b2Body (m_xf.p @ +0xc)
static CGPoint GSPoolBodyPos(void *body) {
	if (!body) return CGPointMake(NAN, NAN);
	float *f = (float *)body;
	return CGPointMake(f[3], f[4]); // 12 / 4 = 3, 16 / 4 = 4
}

// reads the inline [6 x b2Vec2] "holes" ivar
static int GSPoolHoles(id scene, CGPoint outHoles[6]) {
	Ivar iv = GSPoolIvar(scene, "holes");
	if (!iv) return 0;
	float *f = (float *)(((char *)(__bridge void *)scene) + ivar_getOffset(iv));
	int n = 0;
	for (int i = 0; i < 6; i++) {
		CGPoint p = CGPointMake(f[i * 2], f[i * 2 + 1]);
		if (!isnan(p.x) && !isnan(p.y)) outHoles[n++] = p;
	}
	return n;
}

#pragma mark - pool: ball collection (world body walk, confirmed by game's own updateBalls)

@interface GSPoolBallInfo : NSObject
@property (nonatomic, assign) void *body;
@property (nonatomic, retain) PoolBall *ball;
@property (nonatomic, retain) SKSpriteNode *sprite;
@property (nonatomic, assign) int num;
@end
@implementation GSPoolBallInfo
@end

static NSArray *GSPoolCollectBalls(id scene) {
	NSMutableArray *out = [NSMutableArray array];
	Class poolBallClass = NSClassFromString(@"PoolBall");
	void *world = GSPoolPtrIVar(scene, "world");
	if (!world || !poolBallClass) return out;

	void *body = *(void **)((char *)world + 0x19320); // b2World.m_bodyList
	int guard = 0;
	while (body && guard++ < 128) {
		void *ud = *(void **)((char *)body + 0xb0); // b2Body.m_userData
		if (ud) {
			id obj = (__bridge id)ud;
			if ([obj isKindOfClass:poolBallClass]) {
				PoolBall *ball = obj;
				SKSpriteNode *sprite = ball.sprite;
				void *ballBody = GSPoolPtrIVar(ball, "body");
				if (sprite && ballBody && !ball.destroyed) {
					GSPoolBallInfo *info = [[GSPoolBallInfo alloc] init];
					info.body = ballBody;
					info.ball = ball;
					info.sprite = sprite;
					info.num = ball.num;
					[out addObject:info];
				}
			}
		}
		body = *(void **)((char *)body + 0x68); // b2Body.m_next
	}
	return out;
}

#pragma mark - pool: b2 -> scene transform (self calibrating from ball sprite pairs)

typedef struct {
	CGFloat k;    // b2 unit -> scene px (uniform, positive)
	CGPoint o;    // origin: scene = o + b2 * k
	BOOL valid;
} GSPoolTransform;

static GSPoolTransform GSPoolCalibrate(id scene, NSArray *balls, CGPoint cueB2, SKSpriteNode *cueSprite) {
	GSPoolTransform t;
	t.k = 0; t.o = CGPointZero; t.valid = NO;

	NSMutableArray *bp = [NSMutableArray array]; // b2 positions (NSValue-encoded CGPoint)
	NSMutableArray *sp = [NSMutableArray array]; // scene positions
	float rad = GSPoolFloatIVar(scene, "rad", 0.f);

	for (GSPoolBallInfo *info in balls) {
		CGPoint b = GSPoolBodyPos(info.body);
		if (isnan(b.x)) continue;
		CGPoint s = [scene convertPoint:info.sprite.position fromNode:info.sprite.parent];
		[bp addObject:[NSValue valueWithCGPoint:b]];
		[sp addObject:[NSValue valueWithCGPoint:s]];
	}
	if (cueSprite && !isnan(cueB2.x)) {
		CGPoint s = [scene convertPoint:cueSprite.position fromNode:cueSprite.parent];
		[bp addObject:[NSValue valueWithCGPoint:cueB2]];
		[sp addObject:[NSValue valueWithCGPoint:s]];
	}
	if ([bp count] < 2) return t;

	// reference anchor: scene point closest to screen center (stable choice)
	NSUInteger ref = 0;
	CGPoint sceneCenter = CGPointMake(scene.frame.size.width / 2.f, scene.frame.size.height / 2.f);
	CGFloat bestD = 1e30;
	for (NSUInteger i = 0; i < [bp count]; i++) {
		CGFloat d = gpLen(gpSub([sp[i] CGPointValue], sceneCenter));
		if (d < bestD) { bestD = d; ref = i; }
	}
	CGPoint bRef = [bp[ref] CGPointValue];
	CGPoint sRef = [sp[ref] CGPointValue];

	// least squares k over pairs: k = sum(db . ds) / sum(db . db)
	CGFloat num = 0, den = 0;
	for (NSUInteger i = 0; i < [bp count]; i++) {
		if (i == ref) continue;
		CGPoint db = gpSub([bp[i] CGPointValue], bRef);
		CGPoint ds = gpSub([sp[i] CGPointValue], sRef);
		if (gpLen(db) < 1e-3) continue;
		num += gpDot(db, ds);
		den += gpDot(db, db);
	}
	if (den < 1e-6) return t;
	CGFloat k = num / den;
	if (!isfinite(k) || k <= 0.01) return t;

	// residual check
	CGFloat err = 0; int n = 0;
	for (NSUInteger i = 0; i < [bp count]; i++) {
		CGPoint b = [bp[i] CGPointValue];
		CGPoint pred = CGPointMake(sRef.x + (b.x - bRef.x) * k, sRef.y + (b.y - bRef.y) * k);
		err += gpLen(gpSub(pred, [sp[i] CGPointValue]));
		n++;
	}
	if (n == 0 || err / n > 4.0) return t;

	t.k = k;
	t.o = CGPointMake(sRef.x - bRef.x * k, sRef.y - bRef.y * k);

	// sanity: ball radius in scene should roughly match a ball sprite
	if (rad > 0) {
		CGFloat rScene = rad * k;
		for (GSPoolBallInfo *info in balls) {
			CGFloat w = info.sprite.frame.size.width / 2.f;
			if (w > 1 && rScene > 0.4 && (rScene / w > 2.0 || w / rScene > 2.0)) {
				t.valid = NO;
				return t;
			}
			break;
		}
	}
	t.valid = YES;
	return t;
}

static inline CGPoint GSPoolToScene(GSPoolTransform t, CGPoint b2) {
	return CGPointMake(t.o.x + b2.x * t.k, t.o.y + b2.y * t.k);
}

#pragma mark - pool: shot simulation (b2 space)

#define GP_MAX_SEGMENTS 8

typedef struct {
	CGPoint segs[GP_MAX_SEGMENTS * 2]; // flat pairs: [i*2]=start, [i*2+1]=end
	int segCount;
	int hitIdx;          // index into ball positions, -1 when no ball hit
	CGPoint ghost;       // moving ball center at contact
	BOOL pocketable;     // object line reached a pocket
	int pocketIdx;
	CGPoint pocketPos;
} GSPoolSim;

static void GSPoolPushSeg(GSPoolSim *sim, CGPoint a, CGPoint b) {
	if (sim->segCount >= GP_MAX_SEGMENTS) return;
	sim->segs[sim->segCount * 2] = a;
	sim->segs[sim->segCount * 2 + 1] = b;
	sim->segCount++;
}

// simulate a ball: bounce off cushion rect, stop at first ball hit (or pocket capture for object lines)
static void GSPoolSimulatePath(CGPoint o, CGPoint dir, const CGPoint *ballPos, int ballCount, int excludeIdx,
							   CGFloat ballR, CGRect cushion, int maxBounces, GSPoolSim *sim, BOOL isCue,
							   const CGPoint *pockets, int pocketCount, CGFloat captureR) {
	memset(sim, 0, sizeof(*sim));
	sim->hitIdx = -1;
	sim->pocketIdx = -1;

	CGPoint p = o, d = gpNorm(dir);
	if (gpLen(d) < 1e-9) return;

	CGFloat contactR = ballR * 2; // cue + object ball radii

	for (int bounce = 0; bounce <= maxBounces && sim->segCount < GP_MAX_SEGMENTS; bounce++) {
		CGFloat tWall;
		CGPoint n;
		BOOL hasWall = gpRayRectExit(p, d, cushion, &tWall, &n);

		// nearest ball hit along the way
		CGFloat tBall = 1e30;
		int hitIdx = -1;
		for (int i = 0; i < ballCount; i++) {
			if (i == excludeIdx) continue;
			CGFloat t = gpRayCircle(p, d, ballPos[i], contactR);
			if (t > 0 && t < tBall) { tBall = t; hitIdx = i; }
		}

		if (hitIdx >= 0 && tBall < (hasWall ? tWall : 1e30)) {
			CGPoint g = CGPointMake(p.x + d.x * tBall, p.y + d.y * tBall);
			GSPoolPushSeg(sim, p, g);
			sim->hitIdx = hitIdx;
			sim->ghost = g;
			return;
		}

		if (!hasWall) break;
		CGPoint end = CGPointMake(p.x + d.x * tWall, p.y + d.y * tWall);

		// pocket capture check (object ball lines only)
		if (!isCue && captureR > 0) {
			for (int i = 0; i < pocketCount; i++) {
				if (gpSegPointDist(pockets[i], p, end) < captureR) {
					CGPoint ab = gpSub(end, p);
					CGFloat l2 = gpDot(ab, ab);
					CGFloat tt = l2 > 1e-9 ? gpDot(gpSub(pockets[i], p), ab) / l2 : 0;
					tt = MAX(0.f, MIN(1.f, tt));
					end = CGPointMake(p.x + ab.x * tt, p.y + ab.y * tt);
					sim->pocketable = YES;
					sim->pocketIdx = i;
					sim->pocketPos = pockets[i];
					GSPoolPushSeg(sim, p, end);
					return;
				}
			}
		}

		GSPoolPushSeg(sim, p, end);
		p = end;
		CGFloat dn = gpDot(d, n);
		d = gpNorm(CGPointMake(d.x - 2 * dn * n.x, d.y - 2 * dn * n.y));
	}
}

#pragma mark - pool: overlay nodes

static SKShapeNode *GSPoolOverlayShape(SKScene *scene, NSString *name, UIColor *color, CGFloat width, CGFloat glow) {
	SKShapeNode *node = (SKShapeNode *)[scene childNodeWithName:name];
	if (!node) {
		node = [SKShapeNode node];
		node.name = name;
		node.zPosition = 950;
		[scene addChild:node];
	}
	node.lineWidth = width;
	node.glowWidth = glow;
	node.strokeColor = color;
	node.fillColor = [UIColor clearColor];
	node.isHidden = YES;
	return node;
}

static void GSPoolSetPolyline(SKShapeNode *node, const CGPoint *pts, int count) {
	if (count < 2) {
		node.isHidden = YES;
		return;
	}
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, pts[0].x, pts[0].y);
	for (int i = 1; i < count; i++) CGPathAddLineToPoint(path, NULL, pts[i].x, pts[i].y);
	node.path = path;
	CGPathRelease(path);
	node.isHidden = NO;
}

static void GSPoolSetCircle(SKShapeNode *node, CGPoint center, CGFloat radius) {
	if (radius <= 0 || isnan(center.x)) {
		node.isHidden = YES;
		return;
	}
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddEllipseInRect(path, NULL, CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2));
	node.path = path;
	CGPathRelease(path);
	node.isHidden = NO;
}

static void GSPoolSetSegments(SKShapeNode *node, const CGPoint *flat, int segCount) {
	if (segCount < 1) {
		node.isHidden = YES;
		return;
	}
	CGMutablePathRef path = CGPathCreateMutable();
	for (int i = 0; i < segCount; i++) {
		CGPathMoveToPoint(path, NULL, flat[i * 2].x, flat[i * 2].y);
		CGPathAddLineToPoint(path, NULL, flat[i * 2 + 1].x, flat[i * 2 + 1].y);
	}
	node.path = path;
	CGPathRelease(path);
	node.isHidden = NO;
}

static SKLabelNode *GSPoolLabel(SKScene *scene) {
	SKLabelNode *node = (SKLabelNode *)[scene childNodeWithName:@"gs_best_label"];
	if (!node) {
		node = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Heavy"];
		node.name = @"gs_best_label";
		node.fontSize = 15;
		node.fontColor = [UIColor cyanColor];
		node.zPosition = 951;
		node.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
		[scene addChild:node];
	}
	node.isHidden = YES;
	return node;
}

#pragma mark - pool: find shot

static NSString *GSPoolPocketName(CGPoint pocket, CGRect cushion) {
	CGFloat cx = CGRectGetMidX(cushion), cy = CGRectGetMidY(cushion);
	NSString *vertical = pocket.y > cy ? @"top" : @"bottom";
	if (fabs(pocket.x - cx) < (cushion.size.width * 0.18)) return [NSString stringWithFormat:@"%@-middle", vertical];
	NSString *side = pocket.x > cx ? @"right" : @"left";
	return [NSString stringWithFormat:@"%@-%@", vertical, side];
}

typedef struct {
	BOOL found;
	int ballIdx;
	int pocketIdx;
	CGPoint ghost;      // b2
	CGPoint pocket;     // b2
	CGFloat cutCos;
	CGFloat scoreF;
} GSPoolBestShot;

static GSPoolBestShot GSPoolFindBestShot(const CGPoint *ballPos, const int *ballNums, int ballCount, int cueIdx,
										 CGFloat ballR, CGRect cushion, const CGPoint *pockets, int pocketCount, CGFloat captureR) {
	GSPoolBestShot best;
	memset(&best, 0, sizeof(best));

	CGFloat diag = hypot(cushion.size.width, cushion.size.height);
	int nonCueCount = 0;
	for (int i = 0; i < ballCount; i++) if (i != cueIdx && ballNums[i] != 8) nonCueCount++;

	for (int i = 0; i < ballCount; i++) {
		if (i == cueIdx) continue;
		for (int pk = 0; pk < pocketCount; pk++) {
			CGPoint u = gpNorm(gpSub(pockets[pk], ballPos[i]));
			if (gpLen(u) < 1e-6) continue;
			CGPoint ghost = CGPointMake(ballPos[i].x - u.x * 2 * ballR, ballPos[i].y - u.y * 2 * ballR);

			CGPoint toGhost = gpSub(ghost, ballPos[cueIdx]);
			if (gpLen(toGhost) < 2 * ballR) continue;
			CGPoint aim = gpNorm(toGhost);
			CGFloat cutCos = gpDot(aim, u);
			if (cutCos < 0.25) continue; // cut angle too extreme

			// cue path to ghost must be clear
			BOOL clear = YES;
			for (int j = 0; j < ballCount && clear; j++) {
				if (j == cueIdx || j == i) continue;
				if (gpSegPointDist(ballPos[j], ballPos[cueIdx], ghost) < 2 * ballR - 0.5) clear = NO;
			}
			// object path to pocket must be clear
			for (int j = 0; j < ballCount && clear; j++) {
				if (j == i) continue;
				if (gpSegPointDist(ballPos[j], ballPos[i], pockets[pk]) < 2 * ballR - 0.5) clear = NO;
			}
			if (!clear) continue;

			// ghost point must sit inside the table
			if (!CGRectContainsPoint(CGRectInset(cushion, -ballR, -ballR), ghost)) continue;

			CGFloat travel = gpLen(toGhost) + gpLen(gpSub(pockets[pk], ballPos[i]));
			CGFloat score = cutCos * cutCos * (diag / (diag + 0.35 * travel));
			if (ballNums[i] == 8 && nonCueCount > 0) score *= 0.35; // don't throw the 8 early

			if (!best.found || score > best.scoreF) {
				best.found = YES;
				best.ballIdx = i;
				best.pocketIdx = pk;
				best.ghost = ghost;
				best.pocket = pockets[pk];
				best.cutCos = cutCos;
				best.scoreF = score;
			}
		}
	}
	return best;
}

#pragma mark - pool: find-shot button

@interface GSPoolShotToggle : NSObject
- (void)toggle:(UIButton *)sender;
@end
@implementation GSPoolShotToggle
- (void)toggle:(UIButton *)sender {
	SKScene *scene = objc_getAssociatedObject(sender, "gs_scene");
	if (!scene) return;
	NSNumber *cur = objc_getAssociatedObject(scene, "gs_findshot_on");
	BOOL on = cur ? ![cur boolValue] : YES;
	objc_setAssociatedObject(scene, "gs_findshot_on", @(on), OBJC_ASSOCIATION_RETAIN);
	sender.backgroundColor = on ? [UIColor colorWithRed:0.2 green:0.85 blue:0.4 alpha:0.85]
								: [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
	[sender setTitle:on ? @"Find Shot ✓" : @"Find Shot" forState:UIControlStateNormal];
}
@end

#pragma mark - pool: main update

static void GSPoolHideAll(SKScene *scene) {
	for (NSString *name in @[@"gs_pred_cue", @"gs_pred_ghost", @"gs_pred_obj", @"gs_pred_defl", @"gs_pred_pocket",
							 @"gs_best_cue", @"gs_best_ghost", @"gs_best_obj", @"gs_best_target", @"gs_best_pocket"]) {
		SKNode *n = [scene childNodeWithName:name];
		if (n) n.isHidden = YES;
	}
	SKNode *l = [scene childNodeWithName:@"gs_best_label"];
	if (l) l.isHidden = YES;
}

void GSPoolUpdate(SKScene *scene) {
	BOOL findShotPref = boolForKey(@"kFindShot");
	BOOL predictionPref = boolForKey(@"kPredictionLines");

	// keep the button alive (and bound to the *current* scene)
	if (findShotPref && scene.view) {
		UIButton *btn = (UIButton *)[scene.view viewWithTag:0x5348];
		if (!btn) {
			btn = makeButton(@"Find Shot", CGRectMake(10, 64, 112, 36), [GSPoolShotToggle new], @selector(toggle:));
			btn.tag = 0x5348;
			[scene.view addSubview:btn];
			[scene.view bringSubviewToFront:btn];
		}
		objc_setAssociatedObject(btn, "gs_scene", scene, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	void *white = GSPoolPtrIVar(scene, "white");
	BOOL moving = GSPoolBoolIVar(scene, "moving");
	if (moving || !white) {
		GSPoolHideAll(scene);
		return;
	}

	NSArray *balls = GSPoolCollectBalls(scene);
	CGPoint cueB2 = GSPoolBodyPos(white);
	SKSpriteNode *cueSprite = [scene valueForKey:@"cue_ball"];
	GSPoolTransform t = GSPoolCalibrate(scene, balls, cueB2, cueSprite);
	if (!t.valid) {
		GSPoolHideAll(scene);
		return;
	}

	// build b2-space model
	CGPoint ballPos[32];
	int ballNums[32];
	int cueIdx = -1;
	int n = 0;
	for (GSPoolBallInfo *info in balls) {
		if (n >= 30) break;
		void *b = info.body;
		if (b == white) { cueIdx = n; }
		ballPos[n] = GSPoolBodyPos(b);
		ballNums[n] = info.num;
		n++;
	}
	if (cueIdx == -1) {
		// white has no PoolBall wrapper; add it ourselves
		ballPos[n] = cueB2;
		ballNums[n] = 0;
		cueIdx = n;
		n++;
	}
	if (cueIdx == -1 || n < 2) {
		GSPoolHideAll(scene);
		return;
	}

	// cushion rect from table_center / board_size / board_size_h
	Ivar tcIvar = GSPoolIvar(scene, "table_center");
	CGPoint tableCenter = CGPointZero;
	if (tcIvar) {
		float *f = (float *)(((char *)(__bridge void *)scene) + ivar_getOffset(tcIvar));
		tableCenter = CGPointMake(f[0], f[1]);
	}
	CGFloat boardW = GSPoolFloatIVar(scene, "board_size", 0.f);
	CGFloat boardH = GSPoolFloatIVar(scene, "board_size_h", 0.f);
	CGFloat rad = GSPoolFloatIVar(scene, "rad", 0.f);
	CGFloat holeR = GSPoolFloatIVar(scene, "hole_radius", 0.f);
	if (rad <= 0 || boardW <= 0 || boardH <= 0) {
		GSPoolHideAll(scene);
		return;
	}
	CGRect cushion = CGRectMake(tableCenter.x - boardW / 2, tableCenter.y - boardH / 2, boardW, boardH);
	cushion = CGRectInset(cushion, rad, rad); // ball centers reflect one radius inside the rails

	// sanity: cue ball should be inside the playfield
	if (!CGRectContainsPoint(CGRectInset(cushion, -2 * rad, -2 * rad), cueB2)) {
		GSPoolHideAll(scene);
		return;
	}

	// pockets
	CGPoint pockets[6];
	int pocketCount = GSPoolHoles(scene, pockets);
	if (pocketCount == 6) {
		// sanity: pockets should sit on/near the cushion edge
		BOOL ok = YES;
		for (int i = 0; i < 6; i++) {
			if (!CGRectContainsPoint(CGRectInset(cushion, -3 * rad, -3 * rad), pockets[i])) { ok = NO; break; }
		}
		if (!ok) pocketCount = 0;
	}
	if (pocketCount < 6) {
		// fallback: corners + rail midpoints
		pockets[0] = CGPointMake(CGRectGetMinX(cushion), CGRectGetMinY(cushion));
		pockets[1] = CGPointMake(CGRectGetMidX(cushion), CGRectGetMaxY(cushion));
		pockets[2] = CGPointMake(CGRectGetMaxX(cushion), CGRectGetMaxY(cushion));
		pockets[3] = CGPointMake(CGRectGetMaxX(cushion), CGRectGetMinY(cushion));
		pockets[4] = CGPointMake(CGRectGetMidX(cushion), CGRectGetMinY(cushion));
		pockets[5] = CGPointMake(CGRectGetMinX(cushion), CGRectGetMaxY(cushion));
		pocketCount = 6;
	}
	CGFloat captureR = holeR > 0 ? holeR : 2.2 * rad;

	BOOL touchDown = GSPoolBoolIVar(scene, "touchDown");
	BOOL findShotOn = [(objc_getAssociatedObject(scene, "gs_findshot_on") ?: @NO) boolValue];

	// ---- Find Shot overlay + auto aim ----
	if (findShotPref && findShotOn) {
		GSPoolBestShot best = GSPoolFindBestShot(ballPos, ballNums, n, cueIdx, rad, cushion, pockets, pocketCount, captureR);
		if (best.found) {
			// auto aim (only while idle: same write the game itself honors between drags)
			if (!touchDown) {
				CGPoint sGhost = GSPoolToScene(t, best.ghost);
				CGPoint sCue = GSPoolToScene(t, ballPos[cueIdx]);
				GSPoolSetFloatIVar(scene, "direction", (float)atan2(sGhost.y - sCue.y, sGhost.x - sCue.x));
			}

			CGFloat rScene = rad * t.k;
			CGPoint sCue = GSPoolToScene(t, ballPos[cueIdx]);
			CGPoint sGhost = GSPoolToScene(t, best.ghost);
			CGPoint sBall = GSPoolToScene(t, ballPos[best.ballIdx]);
			CGPoint sPocket = GSPoolToScene(t, best.pocket);

			GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_best_cue", [UIColor cyanColor], 3, 4),
							  (CGPoint[]){sCue, sGhost}, 2);
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_ghost", [UIColor cyanColor], 2, 3), sGhost, rScene);
			GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_best_obj", [UIColor colorWithRed:0.1 green:0.9 blue:0.3 alpha:1], 3, 4),
							  (CGPoint[]){sBall, sPocket}, 2);
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_target", [UIColor cyanColor], 2, 3), sBall, rScene * 1.45);
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4),
							sPocket, captureR * t.k);

			SKLabelNode *label = GSPoolLabel(scene);
			NSString *ballText = ballNums[best.ballIdx] > 0 ? [NSString stringWithFormat:@"Ball %d", ballNums[best.ballIdx]] : @"Cue";
			label.text = [NSString stringWithFormat:@"%@ → %@  (%ld%% cut)",
						  ballText,
						  GSPoolPocketName(best.pocket, cushion),
						  (long)llround(best.cutCos * 100)];
			label.position = CGPointMake(scene.frame.size.width / 2, scene.frame.size.height - 56);
			label.isHidden = NO;
		} else {
			GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_best_cue", [UIColor cyanColor], 3, 4), NULL, 0);
			SKLabelNode *label = GSPoolLabel(scene);
			label.text = @"No clear shot";
			label.position = CGPointMake(scene.frame.size.width / 2, scene.frame.size.height - 56);
			label.isHidden = NO;
		}
	} else {
		GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_best_cue", [UIColor cyanColor], 3, 4), NULL, 0);
		GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_ghost", [UIColor cyanColor], 2, 3), CGPointZero, 0);
		GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_best_obj", [UIColor colorWithRed:0.1 green:0.9 blue:0.3 alpha:1], 3, 4), NULL, 0);
		GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_target", [UIColor cyanColor], 2, 3), CGPointZero, 0);
		GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_best_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4), CGPointZero, 0);
		GSPoolLabel(scene).isHidden = YES;
	}

	// ---- live aim prediction ----
	if (predictionPref && touchDown) {
		CGFloat direction = GSPoolFloatIVar(scene, "direction", 0.f);
		if (!isnan(direction)) {
		CGPoint dir = CGPointMake(cos(direction), sin(direction));

		GSPoolSim cueSim;
		GSPoolSimulatePath(ballPos[cueIdx], dir, ballPos, n, cueIdx, rad, cushion, 3, &cueSim, YES, NULL, 0, 0);

		// transform segments to scene
		CGPoint scenePts[GP_MAX_SEGMENTS * 2];
		for (int i = 0; i < cueSim.segCount * 2; i++) scenePts[i] = GSPoolToScene(t, cueSim.segs[i]);
		GSPoolSetSegments(GSPoolOverlayShape(scene, @"gs_pred_cue", [UIColor whiteColor], 2.5, 3),
						  scenePts, cueSim.segCount);

		if (cueSim.hitIdx >= 0) {
			CGPoint ghostScene = GSPoolToScene(t, cueSim.ghost);
			CGFloat rScene = rad * t.k;
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_ghost", [UIColor whiteColor], 2, 3), ghostScene, rScene);

			// object ball: transfers along (ball - ghost)
			CGPoint u = gpNorm(gpSub(ballPos[cueSim.hitIdx], cueSim.ghost));
			GSPoolSim objSim;
			GSPoolSimulatePath(ballPos[cueSim.hitIdx], u, ballPos, n, cueSim.hitIdx, rad, cushion, 2, &objSim, NO,
							   pockets, pocketCount, captureR);

			CGPoint objPts[GP_MAX_SEGMENTS * 2];
			for (int i = 0; i < objSim.segCount * 2; i++) objPts[i] = GSPoolToScene(t, objSim.segs[i]);
			UIColor *objColor = objSim.pocketable
				? [UIColor colorWithRed:0.1 green:0.9 blue:0.3 alpha:1]
				: [UIColor colorWithWhite:0.85 alpha:0.55];
			GSPoolSetSegments(GSPoolOverlayShape(scene, @"gs_pred_obj", objColor, 2.5, objSim.pocketable ? 3 : 0),
							  objPts, objSim.segCount);

			if (objSim.pocketable) {
				GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4),
								GSPoolToScene(t, objSim.pocketPos), captureR * t.k);
			} else {
				GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4), CGPointZero, 0);
			}

			// cue ball deflection (tangent line after contact)
			CGFloat dn = gpDot(dir, u);
			CGPoint tangent = CGPointMake(dir.x - dn * u.x, dir.y - dn * u.y);
			if (gpLen(tangent) > 0.05) {
				tangent = gpNorm(tangent);
				CGFloat deflectLen = 2.2 * 2 * rad; // ~2.2 ball diameters in b2 units
				CGPoint tEnd = CGPointMake(cueSim.ghost.x + tangent.x * deflectLen, cueSim.ghost.y + tangent.y * deflectLen);
				GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_pred_defl", [UIColor colorWithRed:1 green:0.35 blue:0.3 alpha:0.9], 2, 2),
								  (CGPoint[]){GSPoolToScene(t, cueSim.ghost), GSPoolToScene(t, tEnd)}, 2);
			} else {
				GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_pred_defl", [UIColor colorWithRed:1 green:0.35 blue:0.3 alpha:0.9], 2, 2), NULL, 0);
			}
		} else {
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_ghost", [UIColor whiteColor], 2, 3), CGPointZero, 0);
			GSPoolSetSegments(GSPoolOverlayShape(scene, @"gs_pred_obj", [UIColor colorWithWhite:0.85 alpha:0.55], 2.5, 0), NULL, 0);
			GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_pred_defl", [UIColor colorWithRed:1 green:0.35 blue:0.3 alpha:0.9], 2, 2), NULL, 0);
			GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4), CGPointZero, 0);
		}
	} else {
		GSPoolSetSegments(GSPoolOverlayShape(scene, @"gs_pred_cue", [UIColor whiteColor], 2.5, 3), NULL, 0);
		GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_ghost", [UIColor whiteColor], 2, 3), CGPointZero, 0);
		GSPoolSetSegments(GSPoolOverlayShape(scene, @"gs_pred_obj", [UIColor colorWithWhite:0.85 alpha:0.55], 2.5, 0), NULL, 0);
		GSPoolSetPolyline(GSPoolOverlayShape(scene, @"gs_pred_defl", [UIColor colorWithRed:1 green:0.35 blue:0.3 alpha:0.9], 2, 2), NULL, 0);
		GSPoolSetCircle(GSPoolOverlayShape(scene, @"gs_pred_pocket", [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1], 2.5, 4), CGPointZero, 0);
	}
}
}

