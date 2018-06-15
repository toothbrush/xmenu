@import Cocoa;

#include <stdbool.h>
#include <stdio.h>
#include "draw.h"
#include "view.h"
#include "items.h"
#include "util.h"

char *toReturn = "";

bool topbar = true;
bool caseSensitive;
float window_height = -1;
const char *promptCStr = "$";
const char *font;
const char *normbgcolor = "#1F1F21";
const char *normfgcolor = "#F7F7F7";
const char *selbgcolor = "#34AADC";
const char *selfgcolor = "#F7F7F7";

int main(int argc, const char **argv) {
  parseargs(argc, argv);

  DrawCtx drawCtx;
  drawCtx.nbg = mkColor(normbgcolor);
  drawCtx.nfg = mkColor(normfgcolor);
  drawCtx.sbg = mkColor(selbgcolor);
  drawCtx.sfg = mkColor(selfgcolor);
  drawCtx.x = 0;
  drawCtx.font_siz = 14.0;  // TODO: Fix shadows

  CFStringRef fontStr = CFStringCreateWithCString(NULL, "Consolas", kCFStringEncodingUTF8);

  if (font) {
    fontStr = CFStringCreateWithCString(NULL, font, kCFStringEncodingUTF8);
  }

  CFStringRef promptStr = CFStringCreateWithCString(NULL, promptCStr, kCFStringEncodingUTF8);
  CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithNameAndSize(fontStr, drawCtx.font_siz);
  CTFontRef fontRef = CTFontCreateWithFontDescriptor(fontDesc, 0.0, NULL);
  CFRelease(fontStr);
  drawCtx.font = fontRef;


  initDraw(&drawCtx);

  if(window_height == -1) { // not set by user
    // work out decent height based on font
    NSSize size = [@"Sygq" sizeWithAttributes:
                      [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Hack" size:14.0f]
                                                  forKey: NSFontAttributeName]];

    window_height = size.height - 1;
  }

  ItemList itemList = ReadStdin();
  if (!itemList.len) {
    return 1;
  }
  itemList.item[0].sel = true;

  [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

  NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
  CGFloat y = screenFrame.origin.y;
  if (topbar) {
    y += screenFrame.size.height - window_height;
  }

  NSRect windowRect = NSMakeRect(screenFrame.origin.x, y, screenFrame.size.width, window_height);
  BorderlessWindow *window = [[[BorderlessWindow alloc] initWithContentRect:windowRect
                                                                  styleMask:NSWindowStyleMaskBorderless
                                                                    backing:NSBackingStoreBuffered
                                                                      defer:NO] autorelease];
  [window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];

  XmenuMainView *view = [[XmenuMainView alloc] initWithFrame:windowRect
                                                       items:itemList
                                                     drawCtx:&drawCtx
                                                   promptStr:promptStr];
  [view setWantsLayer:YES];
  [window setContentView:view];
  [window makeFirstResponder:view];
  [window setupWindowForEvents];
  [NSApp run];
  [view release];
  if (toReturn != NULL) {
    puts(toReturn);
  }

  return 0;
}
