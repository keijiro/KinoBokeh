KinoBokeh
=========

KinoBokeh is an image effect for Unity, which simulates depth-of-field blurring
effects with hexagonal shaped apertures.

![gif](http://33.media.tumblr.com/52c89daced7ddb568f58cfc9dadc6a1c/tumblr_nsz54yKIkk1qio469o1_400.gif)
![gif](http://33.media.tumblr.com/e405745a370b3c1c141f4ccf46b474ad/tumblr_nsxbzf1J5g1qio469o1_400.gif)

KinoBokeh uses a separable DOF filter technique, which was originally developed
by [Lorne McIntosh][McIntosh]. This is not an artifact-free filter, but has a
good cost vs. quality balance and can create characteristic bokeh effects.

[McIntosh]: http://lorneswork.com/work/view/7

System Requirements
-------------------

Unity 5.0 or later versions.

KinoBokeh requires HDR rendering and linear-space lighting, and thus it's
difficult to use the effect on mobile platforms.

License
-------

Copyright (C) 2015 Keijiro Takahashi

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
