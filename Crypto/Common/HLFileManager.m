//
//  HLFileManager.m
//  FileToolObjC
//
//  Created by Matthew Homer on 10/14/17.
//  Copyright © 2017 Matthew Homer. All rights reserved.
//

#import "HLFileManager.h"
#import <stdio.h>

static HLFileManager *sharedManager = nil;

@implementation HLFileManager

FILE *primesReadFile, *primesAppendFile;
FILE *factoredReadFile, *factoredAppendFile;
FILE *nicePrimesWriteFile;
FILE *readTempFile;
int modSize = 1;
int modCounter = 0;

NSString *fileExtension = @"txt";


-(BOOL)createPrimeFileIfNeededWith:(NSString *)path {
    int result = [self openPrimesFileForReadWith: path];
   
    NSString *temp = nil;
    if ( result == 0 )  //  file found, get first line
    {
        temp = [self readPrimesFileLine];
        [self closePrimesFileForRead];
    }
    BOOL isFirstLineValid = [temp isEqualToString: @"1\t2"];    //  '\n' has been removed

    //  if open failed, create new file
    if ( !isFirstLineValid )
    {
        NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
        primesAppendFile = fopen(pathWithExtension.UTF8String, "w");    //  create new file
        
        if ( primesAppendFile != nil )
        {
            [self appendPrimesLine: @"1\t2\n"];
            [self appendPrimesLine: @"2\t3\n"];
            [self closePrimesFileForAppend];
            return 1;   //  sucess
        }
    }
    else
        return 1;   //  sucess
    
    return 0;       //  createPrimeFile failed
}

//************************************************      primes file read        ****************
-(int)openPrimesFileForReadWith:(NSString *)path  {
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    primesReadFile = fopen(pathWithExtension.UTF8String, "r");
    return (primesReadFile == nil); //  return 0 for no error
}
-(void)closePrimesFileForRead
{
    fclose( primesReadFile );
}

-(NSString *)readPrimesFileLine
{
    return [self readLineFromFile:primesReadFile];
}
//************************************************      primes file read        ****************


//************************************************      factored file read      ****************
-(int)openFactoredFileForReadWith:(NSString *)path
{
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    factoredReadFile = fopen(pathWithExtension.UTF8String, "r");

    if ( !factoredReadFile )
        return -1;  //    error
    else
        return 0;   //  no error
}
-(void)closeFactoredFileForRead
{
    fclose( factoredReadFile );
}

-(char *)trimLineEnding:(char *)line
{
    unsigned long len = strlen(line);
    line[len-1] = '\0';       //  need to remove '\n'
   return line;
}

-(NSString *)readFactoredFileLine
{
    return [self readLineFromFile:factoredReadFile];
}
//************************************************      factored file read      ****************

//************************************************      primes file append      ****************
-(void)openPrimesFileForAppendWith:(NSString *)path  {
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
     primesAppendFile = fopen(pathWithExtension.UTF8String, "a");
}
-(void)closePrimesFileForAppend
{
    fclose( primesAppendFile );
}

-(void)appendPrimesLine:(NSString *)line
{
    int n = line.intValue;
    if ( n % modSize == 0 )
        NSLog( @"** new prime: %@", line );
    
    fputs(line.UTF8String, primesAppendFile);
}
//************************************************      primes file append      ****************


//************************************************      factored file append    ****************
-(int)openFactoredFileForAppendWith:(NSString *)path  {
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    factoredAppendFile = fopen(pathWithExtension.UTF8String, "a");
    assert( factoredAppendFile );
    modCounter = 0;
    return 0;   //  no error
}
-(void)closeFactoredFileForAppend
{
    fclose( factoredAppendFile );
}

-(void)appendFactoredLine:(NSString *)line
{
    fprintf(factoredAppendFile, "%s\n", line.UTF8String);
    if ( modCounter++ % modSize == 0 )
        NSLog( @"  ** prime factored: %@", line );
}
//************************************************      factored file append    ****************


//************************************************      nice primes file write  ****************
-(int)openNicePrimesFileForWriteWith:(NSString *)path
{
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    nicePrimesWriteFile = fopen(pathWithExtension.UTF8String, "w");
    assert( nicePrimesWriteFile );
    modCounter = 0;
    return 0;   //  no error
}
-(void)closeNicePrimesFileForWrite
{
    fclose( nicePrimesWriteFile );
}

-(void)writeNicePrimesFile:(NSString *)line
{
//    int n = line.intValue;
//    if ( n % kMOD_SIZE == 0 )
    
    fprintf(nicePrimesWriteFile, "%s\n", line.UTF8String);
    if ( modCounter++ % modSize == 0 )
        NSLog( @"  ** nice prime: %@", line );
}
//************************************************      nice primes file write  ****************


//************************************************      temp file read          ****************
-(void)openTempFileForReadWith:(NSString *)path  {
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    readTempFile = fopen(pathWithExtension.UTF8String, "r");
}
-(void)closeTempFileForRead
{
    fclose( readTempFile );
}

-(NSString *)readLineFromFile:(FILE *)file
{
    int lineSize = 1000;
    char lineBuf[lineSize];
    char *result = fgets(lineBuf, lineSize, file);
    if ( result )
        return [NSString stringWithUTF8String:[self trimLineEnding: result]];
    else
        return nil;
}
//************************************************      temp file read          ****************

-(NSString *)lastLineForFile:(NSString *)path
{
    NSString *pathWithExtension = [NSString stringWithFormat:@"%@.%@",path , fileExtension];
    readTempFile = fopen(pathWithExtension.UTF8String, "r");
    
    if ( readTempFile )  {
        NSString *temp = @"";
        NSString *previous;

        do  {
            previous = temp;
            temp = [self readLineFromFile:readTempFile];
        } while (temp);
        
        fclose( readTempFile );
        return previous;
    }
    
    else
        return nil;
}

-(void)setModSize:(int)size
{
    modSize = size;
}

-(instancetype)init:(int)modulasSize
{
    self = [super init];
    modSize = modulasSize;
    sharedManager = self;
    return self;
}

+(instancetype)sharedManager
{
    return sharedManager;
}


@end
