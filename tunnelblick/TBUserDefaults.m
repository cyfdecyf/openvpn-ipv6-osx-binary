/*
 * Copyright 2009, 2010 Jonathan Bullard
 *
 *  This file is part of Tunnelblick.
 *
 *  Tunnelblick is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  Tunnelblick is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *  or see http://www.gnu.org/licenses/.
 */

#import "TBUserDefaults.h"
#import "MenuController.h"


NSArray * gProgramPreferences;
NSArray * gConfigurationPreferences;

@interface TBUserDefaults()       // PRIVATE METHODS

-(id)   forcedObjectForKey:                    (NSString *) key;

@end


@implementation TBUserDefaults

-(TBUserDefaults *) initWithForcedDictionary:   (NSDictionary *)    inForced
                      andSecondaryDictionary:   (NSDictionary *)    inSecondary
                           usingUserDefaults:   (BOOL)              inUseUserDefaults
{
    if ( ! [super init] ) {
        return nil;
    }
    
    forcedDefaults = [inForced copy];
    
    secondaryDefaults = [inSecondary copy];
    
    if (  inUseUserDefaults  ) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults registerDefaults: [NSMutableDictionary dictionary]];
    } else {
        userDefaults = nil;
    }
    
    return self;
}

-(void) dealloc
{
    [forcedDefaults release];
    [secondaryDefaults release];
    [super dealloc];
}

-(BOOL) canChangeValueForKey: (NSString *) key     // Returns YES if key's value can be modified, NO if it can't
{
    if (   ( ! userDefaults )
        || ([secondaryDefaults objectForKey:  key] != nil)
        || ([self forcedObjectForKey: key] != nil)  ) {
        return NO;
    }
    
    return YES;
}

-(BOOL) boolForKey: (NSString *) key
{
    id value = [self forcedObjectForKey: key];
    if (  value == nil  ) {
        value = [secondaryDefaults objectForKey: key];
        if (  value == nil  ) {
            if (  userDefaults  ) {
                return [userDefaults boolForKey: key];
            }
            return NO;
        }
    }
    
    if (  [[value class] isSubclassOfClass: [NSNumber class]]  ) {
        return [value boolValue];
    }
    
    NSLog(@"boolForKey: Preference '%@' must be a boolean (i.e., an NSNumber), but it is a %@; using a value of NO", key, [[value class] description]);
    return NO;
}

-(id) objectForKey: (NSString *) key
{
    id value = [self forcedObjectForKey: key];
    if (  value == nil  ) {
        value = [secondaryDefaults objectForKey: key];
        if (  value == nil  ) {
            return [userDefaults objectForKey: key];
        }
    }
    
    return value;
}

-(void) setBool: (BOOL) value forKey: (NSString *) key
{
    if (  [self forcedObjectForKey: key] != nil  ) {
        NSLog(@"setBool: forKey: '%@': ignored because the preference is being forced by Deploy/forced-preferences.plist", key);
    } else if (  [secondaryDefaults objectForKey: key] != nil  ) {
        NSLog(@"setBool: forKey: '%@': ignored because the preference is being forced by the secondary dictionary", key);
    } else if (  ! userDefaults  ) {
        NSLog(@"setBool: forKey: '%@': ignored because user preferences are not available", key);
    } else {
        [userDefaults setBool: value forKey: key];
        [userDefaults synchronize];
    }
}

-(void) setObject: (id) value forKey: (NSString *) key
{
    if (  [self forcedObjectForKey: key] != nil  ) {
        NSLog(@"setObject: forKey: '%@': ignored because the preference is being forced by Deploy/forced-preferences.plist", key);
    } else if (  [secondaryDefaults objectForKey: key] != nil  ) {
        NSLog(@"setObject: forKey: '%@': ignored because the preference is being forced by the secondary dictionary", key);
    } else if (  ! userDefaults  ) {
        NSLog(@"setObject: forKey: '%@': ignored because user preferences are not available", key);
    } else {
        [userDefaults setObject: value forKey: key];
        [userDefaults synchronize];
    }
}

-(void) removeObjectForKey: (NSString *) key
{
    if (  [self forcedObjectForKey: key] != nil  ) {
        NSLog(@"removeObjectForKey: '%@': ignored because the preference is being forced by Deploy/forced-preferences.plist", key);
    } else if (  [secondaryDefaults objectForKey: key] != nil  ) {
        NSLog(@"removeObjectForKey: '%@': ignored because the preference is being forced by the secondary dictionary", key);
    } else if (  ! userDefaults  ) {
        NSLog(@"removeObjectForKey: '%@': ignored because user preferences are not available", key);
    } else {
        [userDefaults removeObjectForKey: key];
        [userDefaults synchronize];
    }
}


// Brute force -- try to remove key ending with the suffix for all configurations
-(void) removeAllObjectsWithSuffix: (NSString *) key
{
    NSEnumerator * dictEnum = [[[NSApp delegate] myConfigDictionary] keyEnumerator];
    NSString * displayName;
    while (  displayName = [dictEnum nextObject]  ) {
        NSString * fullKey = [displayName stringByAppendingString: key];
        [self removeObjectForKey: fullKey];
    }
}


-(void) synchronize
{
    [userDefaults synchronize];
}

-(BOOL) movePreferencesFrom: (NSString *) sourceDisplayName
                         to: (NSString *) targetDisplayName
{
    if (  ! userDefaults  ) {
        return TRUE;
    }
    
    if (  [sourceDisplayName isEqualToString: targetDisplayName]  ) {
        NSLog(@"copyPreferencesFrom:to: ignored because target '%@' is the same as source", targetDisplayName);
        return FALSE;
    }
    
    BOOL problemsFound = FALSE;
    
    // First, remove all preferences for the target configuration
    if (  ! [self removePreferencesFor: targetDisplayName]  ) {
        problemsFound = TRUE;
    }
    
    // Then, add the non-forced preferences from the source configuration
    NSEnumerator * arrayEnum = [gConfigurationPreferences objectEnumerator];
    NSString * preferenceSuffix;
    while (  preferenceSuffix = [arrayEnum nextObject]  ) {
        NSString * sourceKey = [sourceDisplayName stringByAppendingString: preferenceSuffix];
        NSString * targetKey = [targetDisplayName stringByAppendingString: preferenceSuffix];
        id obj;
        if (  obj = [userDefaults objectForKey: sourceKey]  ) {
            if (  [self canChangeValueForKey: targetKey]  ) {
                [userDefaults setObject: obj forKey: targetKey];
            } else {
                NSLog(@"Preference '%@' is forced and cannot be set.", targetKey);
                problemsFound = TRUE;
            }
        }
    }
    
    // Then, remove all preferences for the source configuration
    if (  ! [self removePreferencesFor: sourceDisplayName]  ) {
        problemsFound = TRUE;
    }
    
    return ! problemsFound;
}


-(BOOL) copyPreferencesFrom: (NSString *) sourceDisplayName
                         to: (NSString *) targetDisplayName
{
    if (  ! userDefaults  ) {
        return TRUE;
    }

    if (  [sourceDisplayName isEqualToString: targetDisplayName]  ) {
        NSLog(@"copyPreferencesFrom:to: ignored because target '%@' is the same as source", targetDisplayName);
        return FALSE;
    }
    
    BOOL problemsFound = FALSE;
    
    // First, remove all preferences for the target configuration
    if (  ! [self removePreferencesFor: targetDisplayName]  ) {
        problemsFound = TRUE;
    }
    
    // Then, add the non-forced preferences from the source configuration
    NSEnumerator * arrayEnum = [gConfigurationPreferences objectEnumerator];
    NSString * preferenceSuffix;
    while (  preferenceSuffix = [arrayEnum nextObject]  ) {
        NSString * sourceKey = [sourceDisplayName stringByAppendingString: preferenceSuffix];
        NSString * targetKey = [targetDisplayName stringByAppendingString: preferenceSuffix];
        id obj;
        if (  obj = [userDefaults objectForKey: sourceKey]  ) {
            if (  [self canChangeValueForKey: targetKey]  ) {
                [userDefaults setObject: obj forKey: targetKey];
            } else {
                NSLog(@"Preference '%@' is forced and cannot be set.", targetKey);
                problemsFound = TRUE;
            }
        }
    }
    
    return ! problemsFound;
}


-(BOOL) removePreferencesFor: (NSString *) displayName
{
    BOOL problemsFound = FALSE;
    NSEnumerator * arrayEnum = [gConfigurationPreferences objectEnumerator];
    NSString * preferenceSuffix;
    while (  preferenceSuffix = [arrayEnum nextObject]  ) {
        NSString * key = [displayName stringByAppendingString: preferenceSuffix];
        if (  [userDefaults objectForKey: key]  ) {
            if (  [self canChangeValueForKey: key]  ) {
                [userDefaults removeObjectForKey: key];
            } else {
                NSLog(@"Preference '%@' is forced and cannot be removed.", key);
                problemsFound = TRUE;
            }
        }
    }
    
    return ! problemsFound;
}


-(void) scanForUnknownPreferencesInDictionary: (NSDictionary *) dict displayName: (NSString *) dictName
{
    NSEnumerator * dictEnum = [dict keyEnumerator];
    NSString * preferenceKey;
    while (  preferenceKey = [dictEnum nextObject]  ) {
        if (  ! [gProgramPreferences containsObject: preferenceKey]  ) {
            NSEnumerator * prefEnum = [gConfigurationPreferences objectEnumerator];
            NSString * knownKey;
            BOOL found = FALSE;
            while (  knownKey = [prefEnum nextObject]  ) {
                if (  [preferenceKey hasSuffix: knownKey]  ) {
                    found = TRUE;
                    break;
                }
            }
            if (  ! found  ) {
                NSLog(@"Warning: %@ contain unknown preference '%@'", dictName, preferenceKey);
            }
        }
    }
}


// Checks for a forced object for a key, implementing wildcard matches
-(id) forcedObjectForKey: (NSString *) key
{
    id value = [forcedDefaults objectForKey: key];
    if (  value == nil  ) {
        // No tbDefaults key for XYZABCDE, so try for a wildcard match
        // If tbDefaults has a *ABCDE key, returns it's value
        NSEnumerator * e = [forcedDefaults keyEnumerator];
        NSString * forcedKey;
        while (  forcedKey = [e nextObject]  ) {
            if (   [forcedKey hasPrefix: @"*"] 
                && ( [forcedKey length] != 1)  ) {
                if (  [key hasSuffix: [forcedKey substringFromIndex: 1]]  ) {
                    return [forcedDefaults objectForKey: forcedKey];
                }
            }
        }
    }
    
    return value;
}

@end
