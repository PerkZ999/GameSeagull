@import Foundation;
@import UIKit;

#import <rootless.h>

#import "Headers.h"

// minimal libhooker memory-patch ABI (avoids requiring the libhooker SDK at build time;
// identical layout to libhooker.h's LHMemoryPatch)
typedef struct LHMemoryPatch {
	void *destination;
	const void *data;
	unsigned long size;
	void *options;
} LHMemoryPatch;

uint64_t bh_memmem(const uint8_t* haystack, size_t hlen, const uint8_t* needle, size_t nlen);
void HookMemory(Class class, SEL selector, uint64_t offset, uint32_t data);
int PatchMemory(const struct LHMemoryPatch *patches, int count);
void alert(UIView *object, NSString *title, NSString *message);
NSDictionary* getPreferences();
bool boolForKey(NSString *key);
UIButton *makeButton(NSString *title, CGRect frame, id target, SEL selector);
SCNVector3 getAimbotPos(int multiplier, int number);
void GSPoolUpdate(SKScene *scene);