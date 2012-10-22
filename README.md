MSVCLeakHunter
==============

Simple and easy tool to discover View Controllers that are not being deallocated when you expect them to.

This is very common with retain cycles using blocks, and it's very tricky sometimes to realize that some view controller is never getting deallocated, because they don't show up as leaks when using Instruments.

# Instalation

- Add ```MSVCLeakHunter.h``` and ```MSVCLeakHunter.m``` to the Xcode project.
- Place a call to ```+[MSVCLeakHunter install]``` somewhere during app initialization (e.g. the ```applicationDidFinishLaunchingWithOptions:``` method of your app delegate.)
- Make sure ```MSVCLeakHunter_ENABLED``` is set to 1 in ```MSVCLeakHunter.h```

# What it looks like

- When you run the app with ```MSVCLeakHunter``` enabled, and it finds a possible view controller that is leaking, this is what you'll see:

<img src="http://f.cl.ly/items/0Y013H42412v2E0H0Y1K/Screen%20Shot%202012-10-20%20at%206.13.27%20PM.png" />
*screenshot from the sample project*

# Compatibility

- ```MSVCLeakHunter``` is compatible with **ARC** and **non-ARC** projects.

# How it works

If you look at the implementation in ```MSVCLeakHunter.m```, it's very naive. All it does is swizzle some methods for every UIViewController instance to discover when a view controller disappear from screen (*it gets a ```viewDidDisappear:``` call*), but isn't deallocated after a certain period of time.

If this happens, it doesn't guarantee 100% that the view controller leaked. For example, if it's inside a ```UITabBarController```, it may disapepar when you select another tab, but it's still retained by the tabbar, and it hasn't leaked.

But it will help you discover, for example, view controllers that you push onto a navigation controller stack, and aren't deallocated when you pop them tapping on the back button.

In the case where you have something like a navigation controller that is shown modally, and then the whole stack goes away when the modal is closed, you may want to tweak the value of ```kMSVCLeakHunterDisappearAndDeallocateMaxInterval``` (*see ```MSVCLeakHunter.h```*) to give ```MSVCLeakHunter``` enough margin to avoid a false positive. Otherwise, you may see a log for a possible leak of the controllers at the bottom of the stack if the modal takes longer to be closed.

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