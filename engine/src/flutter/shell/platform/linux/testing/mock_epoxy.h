// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_EPOXY_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_EPOXY_H_

#include "gmock/gmock.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

namespace flutter {
namespace testing {

class MockEpoxy {
 public:
  MockEpoxy();
  ~MockEpoxy();

  MOCK_METHOD(bool, epoxy_has_gl_extension, (const char* extension));
  MOCK_METHOD(bool, epoxy_is_desktop_gl, ());
  MOCK_METHOD(int, epoxy_gl_version, ());
  MOCK_METHOD(void,
              eglCreateImage,
              (EGLDisplay dpy,
               EGLContext ctx,
               EGLenum target,
               EGLClientBuffer buffer,
               const EGLAttrib* attrib_list));
  MOCK_METHOD(void, glClearColor, (GLfloat r, GLfloat g, GLfloat b, GLfloat a));
  MOCK_METHOD(void,
              glBlitFramebuffer,
              (GLint srcX0,
               GLint srcY0,
               GLint srcX1,
               GLint srcY1,
               GLint dstX0,
               GLint dstY0,
               GLint dstX1,
               GLint dstY1,
               GLbitfield mask,
               GLenum filter));
  MOCK_METHOD(void,
              glDeleteFramebuffers,
              (GLsizei n, const GLuint* framebuffers));
  MOCK_METHOD(void,
              glDeleteRenderbuffers,
              (GLsizei n, const GLuint* renderbuffers));
  MOCK_METHOD(void, glDeleteTextures, (GLsizei n, const GLuint* textures));
  MOCK_METHOD(void, glGenFramebuffers, (GLsizei n, GLuint* framebuffers));
  MOCK_METHOD(void, glGenRenderbuffers, (GLsizei n, GLuint* renderbuffers));
  MOCK_METHOD(void, glGenTextures, (GLsizei n, GLuint* textures));
  MOCK_METHOD(const GLubyte*, glGetString, (GLenum pname));
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_EPOXY_H_
