//
//  AKRoute.m
//  APIKit Router
//
//  Created by Joseph Lorich on 3/19/14.
//  Copyright (c) 2014 Joseph Lorich.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AKRoute.h"

@implementation AKRoute
{
    NSString *_path;
    AKRequestMethod _requestMethod;
}

- (id)initWithPath:(NSString *)path requestMethod:(AKRequestMethod)requestMethod
{
    self = [super init];
    
    if (self)
    {
        _path = path;
        _requestMethod = requestMethod;
    }
    
    return self;
}

- (NSString *)pathStringForParams:(NSDictionary *)params
{
    return [self replaceTokensInPath:_path params:params];
}

/**
 * Replaces all slug tokens (e.g. ":first_name") in a path with their appropriate param
 *
 * @param urlString the base path to parse
 * @param params the parameters for the URL
 */
- (NSString *)replaceTokensInPath:(NSString*)urlString params:(NSDictionary *)params
{
    NSMutableString *parsedString = [urlString mutableCopy];
    
    for (NSString *param in [params allKeys])
    {
        id value = [params valueForKey:param];
        
        NSString *paramType = NSStringFromClass([value class]);
        
        if ([paramType isEqualToString:@"NSString"])
        {
            NSString *token = [NSString stringWithFormat:@":%@", param];
            [parsedString stringByReplacingOccurrencesOfString:token withString:value];
        }
    }
    
    return parsedString;
}


@end
