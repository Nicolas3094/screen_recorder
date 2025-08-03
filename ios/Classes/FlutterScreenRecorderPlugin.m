#import "FlutterScreenRecorderPlugin.h"
#if __has_include(<screen_recorder/screen_recorder-Swift.h>)
#import<screen_recorder/screen_recorder-Swift.h>
#else
#import "screen_recorder-Swift.h"
#endif
@implementation FlutterScreenRecorderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [ScreenRecorderPlugin registerWithRegistrar:registrar];
}
@end
