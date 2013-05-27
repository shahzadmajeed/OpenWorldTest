//
//  SKRAppDelegate.m
//  OpenWorldTest
//
//  Created by Steven Troughton-Smith on 23/12/2012.
//  Copyright (c) 2012 High Caffeine Content. All rights reserved.
//

/*
 
	The following GL code was written by Thomas Goossens, one of the
	engineers behind SceneKit @ Apple. Thanks Thomas!
 
 */

#import "OWTAppDelegate.h"
#import "OWTGameView.h"

typedef struct {
    GLuint fbo;
    GLuint colorTexture;
    GLuint depthTexture;
} FBOAndTextures;

@implementation OWTAppDelegate
{
    GLuint _program;
	GLint _cafbo;
    NSMutableDictionary *_fbos;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _view.leftEyeView.delegate = self;
    _view.rightEyeView.delegate = self;
    
    _fbos = [NSMutableDictionary dictionaryWithCapacity:2];
}

- (FBOAndTextures)setupOffscreenFramebuffer:(NSSize)size withContext:(NSOpenGLContext *)context
{
    FBOAndTextures fboAndTextures;
    
    //start GL stuffs
    assert(context != nil);

    [context makeCurrentContext];
    
    //create a fbo
    glGenFramebuffersEXT (1, &fboAndTextures.fbo);
    
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboAndTextures.fbo);
    
    //create a texture to render into
    glGenTextures(1, &fboAndTextures.colorTexture);
    glGenTextures(1, &fboAndTextures.depthTexture);
    
    //setup and attach color
    glBindTexture(GL_TEXTURE_2D, fboAndTextures.colorTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, size.width, size.height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
                              GL_TEXTURE_2D, fboAndTextures.colorTexture, 0);
	
    //setup and attach depth
    glBindTexture(GL_TEXTURE_2D, fboAndTextures.depthTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, size.width, size.height, 0,
                 GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);
    
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
                              GL_TEXTURE_2D, fboAndTextures.depthTexture, 0);
	
    
    GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
        NSLog(@"failed to create the FBO : %d", status);
    
    //unbind for now
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

    return fboAndTextures;
}

- (void) loadFogShader
{
    
    //load shader if needed
    GLuint prgName;
    
    GLint logLength, status;
    
    // Create a program object
    prgName = glCreateProgram();
    
    // Indicate the attribute indicies on which vertex arrays will be
    //  set with glVertexAttribPointer
    //  See buildVAO to see where vertex arrays are actually set
    glBindAttribLocation(prgName, 0, "a_position");
    
    //////////////////////////////////////
    // Specify and compile VertexShader //
    //////////////////////////////////////
    
    NSString *vertexPath = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"vert"];
    NSString *fragmentPath = [[NSBundle mainBundle] pathForResource:@"shader" ofType:@"frag"];
    
    // Allocate memory for the source string including the version preprocessor information
    NSString *vertexString = [NSString stringWithContentsOfFile:vertexPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fragmentString = [NSString stringWithContentsOfFile:fragmentPath encoding:NSUTF8StringEncoding error:nil];
    
    const char *vertex = [vertexString cStringUsingEncoding:NSUTF8StringEncoding];
    const char *fragment = [fragmentString cStringUsingEncoding:NSUTF8StringEncoding];
    
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, (const GLchar **)&(vertex), NULL);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0)
    {
        GLchar *log = (GLchar*) malloc(logLength);
        glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
        NSLog(@"Vtx Shader compile log:%s\n", log);
        free(log);
    }
    
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to compile vtx shader:\n%s\n", vertex);
        exit(0);
    }
    
    // Attach the vertex shader to our program
    glAttachShader(prgName, vertexShader);
    
    
    // Specify and compile Fragment Shader //
    
    GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, (const GLchar **)&(fragment), NULL);
    glCompileShader(fragShader);
    glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(fragShader, logLength, &logLength, log);
        NSLog(@"Frag Shader compile log:\n%s\n", log);
        free(log);
    }
    
    glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to compile frag shader:\n%s\n", fragment);
        exit(0);
    }
    
    // Attach the fragment shader to our program
    glAttachShader(prgName, fragShader);
    
    
    // Link the program //
    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(prgName, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to link program");
        exit(0);
    }
    
    glValidateProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to validate program");
        exit(0);
    }
    
//    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, currentFramebuffer);
    
    _program = prgName;
}

- (void)bindFogShaderWithColorTexture:(GLuint)colorTexture depthTexture:(GLuint)depthTexture
{
    if(_program == 0){
        [self loadFogShader];
    }
	
    //bind
    glUseProgram(_program);
    
    //set texture inputs
    GLint samplerLoc = glGetUniformLocation(_program, "colorTexture");
    
    // Indicate that the diffuse texture will be bound to texture unit 0
    GLint unit = 0;
    glUniform1i(samplerLoc, unit);
	
    samplerLoc = glGetUniformLocation(_program, "depthTexture");
    
    // Indicate that the depth texture will be bound to texture unit 1
    unit = 1;
    glUniform1i(samplerLoc, unit);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, colorTexture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, depthTexture);
}

- (void) drawFullscreenQuad
{
    const float vertices[] = {-1,-1,
        1,-1,
        1,1,
        -1,1
    };
    const GLubyte indices[] = {0,1,2,0,2,3};
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, sizeof(float)*2, &vertices[0]);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
}

// SCNView delegate
- (void)renderer:(id <SCNSceneRenderer>)aRenderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    SCNView *view = (SCNView *)aRenderer;
    [view.openGLContext makeCurrentContext];
    NSString *eye = [view.layer valueForKey:@"eye"];
    eye = @"FOO";
    NSValue *fboAndTexturesValue = [_fbos objectForKey:eye];
    FBOAndTextures fboAndTextures;
    if(fboAndTexturesValue)
    {
        [fboAndTexturesValue getValue:&fboAndTextures];
    }
    else
    {
        CGRect viewBounds = [view bounds];
        NSSize viewportSize = [view convertRectToBase:viewBounds].size; //HiDPI
        fboAndTextures = [self setupOffscreenFramebuffer:viewportSize withContext:view.openGLContext];
        fboAndTexturesValue = [NSValue valueWithBytes:&fboAndTextures objCType:@encode(FBOAndTextures)];
        [_fbos setObject:fboAndTexturesValue forKey:eye];
    }
    
    if (fboAndTextures.fbo > 0)
    {
        //save fbo
        glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &_cafbo);
        
        //bind our fbo so that scenekit renders into it
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboAndTextures.fbo);
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    [(id <SCNSceneRendererDelegate>)_view renderer:aRenderer willRenderScene:scene atTime:time];
}

- (void)renderer:(id <SCNSceneRenderer>)aRenderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    SCNView *view = (SCNView *)aRenderer;
    [view.openGLContext makeCurrentContext];
    NSString *eye = [view.layer valueForKey:@"eye"];
    eye = @"FOO";
    NSValue *fboAndTexturesValue = [_fbos objectForKey:eye];
    FBOAndTextures fboAndTextures;
    if(fboAndTexturesValue)
    {
        [fboAndTexturesValue getValue:&fboAndTextures];
    }
    if (fboAndTextures.fbo > 0 && _cafbo > 0)
    {
        glActiveTexture(GL_TEXTURE0);
        GLint boundTexture0;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture0);
        glActiveTexture(GL_TEXTURE1);
        GLint boundTexture1;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture1);
        GLint currentProgram;
        glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
        
        //draw the texture inside the view
        [self bindFogShaderWithColorTexture:fboAndTextures.colorTexture depthTexture:fboAndTextures.depthTexture];
        
        //unbind FBO
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, _cafbo);
        
        [self drawFullscreenQuad];
        
        //cleanup
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, boundTexture1);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, boundTexture0);
        glUseProgram(currentProgram);
	
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    }
    
	[(id <SCNSceneRendererDelegate>)_view renderer:aRenderer didRenderScene:scene atTime:time];
}
@end
