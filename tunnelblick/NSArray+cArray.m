/*
 *  Created by Angelo Laub on 7/5/06
 * Copyright 2004, 2005, 2006, 2007, 2008, 2009 Angelo Laub
 * Contributions by Jonathan K. Bullard Copyright 2011
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

#import "NSArray+cArray.h"


@implementation NSArray (cArray)

/* returns an array of character pointers that is guaranteed to be NULL terminated */
-(char **) cArray 
{
	int i=0;
	int count = [self count];
	char **myCArray = calloc(count + 1, sizeof(char *));
	for(i=0;i < count;i++) {
		const char *string = [[self objectAtIndex:i] UTF8String];
		if(!string)
			break;
		myCArray[i] = strdup(string);
	}
	myCArray[i] = NULL;
	return myCArray;
}

void freeCArray(char ** theArray)
{
    // Free the individual strings in the array
    int i = 0;
    while (  theArray[i] != NULL  ) {
        free(theArray[i]);
        i++;
    }
    
    // Free the array itself
    free(theArray);
}

@end
