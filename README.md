MSLeakHunter
==============

### Series of tools to help you find and debug objects that are leaking in your iOS apps.

There are very common cases where objects may be leaking (not being deallocated when you expect them to) and instruments fails to detect this. One particular example is due to retain cycles using blocks, and it's very tricky sometimes to realize that some object isn't being deallocated.

**MSLeakHunter** provides a generic interface to construct "leak hunter" objects, that are in charge of monitoring the allocation and deallocation of objects of a particular class. In this repo, two particular implementations are provided: `MSViewControllerLeakHunter` and `MSViewLeakHunter` (for `UIViewController` and `UIView` instances respectively).

However, you can create as many leak hunters as you wish. The only thing they need is that the object they're expecting to be deallocated to have some method that gets called before this deallocation is supposed to happen.
For example, `UIViewController` will get a `-viewDidDisappear:` call some time before its deallocation. What `MSLeakHunter` allows you to do, is to keep track of that object, and in case `-dealloc` isn't called some time  after that, it's considered pottentially leaked and it's logged in the console.

The implementation is pretty cheap, so it shouldn't hurt the performance of any application, but it's advised to keep this code disabled (through the `MSLeakHunter_ENABLED` macro) when shipping an app.

For more instructions on how to create other leak hunter objects, refer to the `MSLeakHunter+Private` header and to the included sample implementations.

# Installation

- Add ```MSVCLeakHunter.{h,m}``` to the Xcode project.
- Somewhere during app initialization (e.g. the ```applicationDidFinishLaunchingWithOptions:``` method of your app delegate.), install the leak hunters that you want to enable:

```objc
[MSLeakHunter installLeakHunter:[MSViewControllerLeakHunter class]];
```
- Make sure ```MSVCLeakHunter_ENABLED``` is set to 1 in ```MSVCLeakHunter.h```

# What it looks like

- When you run the app with a leak hunter enabled, and it finds a possible object that is leaking, this is what you'll see:

<img src="http://f.cl.ly/items/0Y013H42412v2E0H0Y1K/Screen%20Shot%202012-10-20%20at%206.13.27%20PM.png" />
*screenshot from the sample project*

# MSLeakHunterRetainBreakpointsHelper

This other tool lets you debug a leak once you know it exists. It provides a very simple way to make the debugger stop on a breakpoint every time one of the 4 memory management methods is called on the object that you're interested in monitoring. This should help you find out where that extra -retain call is coming from, or who is retaining that object but never releasing it, etc.
Using it is as simple as calling this method declared in `MSLeakHunterRetainBreakpointsHelper.h` with the object that you want to monitor:

```objc
ms_stopOnMemoryManagementMethodsOfObject(object);
```

* Note: `MSLeakHunterRetainBreakpointsHelper.m` has to be compiled without ARC. If your project uses ARC, refer to [this tutorial](http://maniacdev.com/2012/01/easily-get-non-arc-enabled-open-source-libraries-working-in-arc-enabled-projects/) to know how to disable ARC only for that file.

# Compatibility

- ```MSLeakHunter``` is compatible with **ARC** and **non-ARC** projects.

# Caveats of the leak hunter implementations

If you look at the implementation in ```MSViewControllerLeakHunter.m```, it's very naive. All it does is swizzle some methods for every UIViewController instance to discover when a view controller disappear from screen( *it gets a ```viewDidDisappear:``` call* ), but isn't deallocated after a certain period of time.

If this happens, it doesn't guarantee 100% that the view controller leaked. For example, if it's inside a ```UITabBarController```, it may disapepar when you select another tab, but it's still retained by the tabbar, and it hasn't leaked.

But it will help you discover, for example, view controllers that you push onto a navigation controller stack, and aren't deallocated when you pop them tapping on the back button.

In the case where you have something like a navigation controller that is shown modally, and then the whole stack goes away when the modal is closed, you may want to tweak the value of ```kMSVCLeakHunterDisappearAndDeallocateMaxInterval``` ( *see ```MSViewControllerLeakHunter.h```* ) to give ```MSViewCOntrollerLeakHunter``` enough margin to avoid a false positive. Otherwise, you may see a log for a possible leak of the controllers at the bottom of the stack if the modal takes longer to be closed.

# License

Copyright 2012 MindSnacks

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
