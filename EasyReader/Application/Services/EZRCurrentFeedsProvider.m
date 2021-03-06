//
//  EZRCurrentFeedsService.m
//  EasyReader
//
//  Created by Joseph Lorich on 4/15/14.
//  Copyright (c) 2014 Cloudspace. All rights reserved.
//

#import "EZRCurrentFeedsProvider.h"
#import "NSSet+CSSortingAdditions.h"

#import "User.h"
#import "Feed.h"
#import "FeedItem.h"

#import <Block-KVO/MTKObserving.h>

/// A dispatch predicate used to ensure only one shared instance is created 
static dispatch_once_t pred;

/// The shared feeds provider instance
static EZRCurrentFeedsProvider *sharedInstance;

#pragma mark - Current feeds provider interface

@interface EZRCurrentFeedsProvider ()

/// The current user
@property User *currentUser;

@end


#pragma mark - Current feeds provider implementation

@implementation EZRCurrentFeedsProvider
{
    /// The currently selected feed (if any)
    Feed *currentFeed;
}

+ (EZRCurrentFeedsProvider *) shared
{
    dispatch_once(&pred, ^{
        if (sharedInstance != nil) {
            return;
        }
        
        sharedInstance = [[EZRCurrentFeedsProvider alloc] init];
    });
    
    return sharedInstance;
}


- (Feed *)currentFeed {
    return currentFeed;
}


/**
 * Sets the singleton EZRCurrentFeedsProvider object
 * @param EZRCurrentFeedsProvider The new shared EZRCurrentFeedsProvider object
 */
+ (void)setShared:(EZRCurrentFeedsProvider *)shared
{
    sharedInstance = shared;
}

- (instancetype) init
{
    self = [super init];
    
    if (self) {
        self.currentUser = [User current];
        _feeds = [self.currentUser.feeds sortedArrayByAttributes:@[@"name"]
                                                       ascending:[self nameSortDirection]];
        
        _feedItems = [self sorted:self.currentUser.feedItems];
        _visibleFeedItems = _feedItems;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectedFeedDidChange:)
                                                     name:@"kEZRFeedSelected"
                                                   object:nil];

        [self observeRelationship:@keypath(self.currentUser.feeds)
                      changeBlock:^(__weak User *user, NSSet *oldFeeds, NSSet *newFeeds) {
                          [self userFeedsDidChange:user oldFeeds:oldFeeds newFeeds:newFeeds];
                      }
                   insertionBlock:nil
                     removalBlock:nil
                 replacementBlock:nil
         ];
    }
    
    return self;
}

/**
 * Called when the selected feed item notification is received
 *
 * @param notification the NSNotification related to teh feed item change
 */
- (void)selectedFeedDidChange:(NSNotification *)notification
{
    Feed *feed = notification.object;
    
    [self willChangeValueForKey:@"visibleFeedItems"];
    
    if (feed) {
        _visibleFeedItems = [self sorted:feed.feedItems];
        currentFeed = feed;
    } else {
        _visibleFeedItems = _feedItems;
        currentFeed = nil;
    }
    
    [self didChangeValueForKey:@"visibleFeedItems"];
}


/**
 * Called when the current users feeds have changed
 *
 * Triggers KVO for feeds, feedItems, and visibleFeedItems
 *
 * @param currentUser The current user object
 * @param notification The old feeds NSSet
 * @param notification The new feeds NSSet
 */
- (void) userFeedsDidChange:(User *)currentUser oldFeeds:(NSSet *)oldFeeds newFeeds:(NSSet *)newFeeds {
    [self willChangeValueForKey:@"feeds"];
    [self willChangeValueForKey:@"feedItems"];
    [self willChangeValueForKey:@"visibleFeedItems"];
    
    
    NSMutableSet *feedItems = [NSMutableSet setWithArray:self.feedItems];
    
    NSMutableArray *addedFeeds = [[newFeeds allObjects] mutableCopy];
    NSMutableArray *removedFeeds = [[oldFeeds allObjects] mutableCopy];
    
    [addedFeeds removeObjectsInArray:[oldFeeds allObjects]];
    [removedFeeds removeObjectsInArray:[newFeeds allObjects]];
    
    // Stop observing old feeds
    for ( Feed *feed in removedFeeds ){
        [feed removeAllObservations];
    }
    
    for (FeedItem *item in _feedItems) {
        if ([removedFeeds containsObject:item.feed]) {
            [feedItems removeObject:item];
        }
    }
    
    [self observeFeedItemsForFeeds:addedFeeds];
    
    // Observe added feeds
    for ( Feed *feed in addedFeeds ) {
        [feedItems addObjectsFromArray:[feed.feedItems sortedArrayUsingDescriptors:nil]];
    }
    
    _feeds = [newFeeds sortedArrayByAttributes:@[@"name"]
                                     ascending:[self nameSortDirection]];
    
    _feedItems = [self sorted:feedItems];
    
    if (!currentFeed) {
        _visibleFeedItems = _feedItems;
    } else if (currentFeed && [removedFeeds containsObject:currentFeed]) {
        _visibleFeedItems = _feedItems;
        currentFeed = nil;
    }
    
    [self didChangeValueForKey:@"feeds"];
    [self didChangeValueForKey:@"feedItems"];
    [self didChangeValueForKey:@"visibleFeedItems"];
}

/**
 *
 */
- (void)observeFeedItemsForFeeds:(NSArray *)feeds {
    for ( Feed *feed in feeds ) {
        [feed observeRelationship:@"feedItems"
                      changeBlock:[self feedItemsDidChange]
                   insertionBlock:nil
                     removalBlock:nil
                 replacementBlock:nil];
    }
}

/**
 * Called when feedItems array on observed feeds change, shows new item button on page control
 */
- (void (^)(Feed *, NSSet *, NSSet *))feedItemsDidChange
{
    return ^void(Feed *feed, NSSet *old, NSSet *new) {
        [self willChangeValueForKey:@"visibleFeedItems"];
        [self willChangeValueForKey:@"feedItems"];
        
        _feedItems = [self sorted:self.currentUser.feedItems];
        
        if (!currentFeed) {
            _visibleFeedItems = _feedItems;
        } else {
            _visibleFeedItems = [self sorted:currentFeed.feedItems];
        }
        
        [self didChangeValueForKey:@"feedItems"];
        [self didChangeValueForKey:@"visibleFeedItems"];
    };
}

- (NSArray *)sorted:(NSSet*)feedItems {
    return [feedItems sortedArrayByAttributes:[self feedItemSortAttributes]
                                    ascending:[self feedItemSortDirection]];
}

- (NSArray *)feedItemSortAttributes
{
    return @[@"publishedAt", @"createdAt"];
}

- (BOOL)feedItemSortDirection {
    return NO;
}


- (BOOL)nameSortDirection {
    return YES;
}


@end
