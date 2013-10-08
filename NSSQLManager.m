//
//  NSSQLManager.m
//  dataTest
//
//  Created by mac on 13-6-17.
//  Copyright (c) 2013年 383541328@qq.com All rights reserved.
//

#import "NSSQLManager.h"
#import <objc/runtime.h>
#import "sqlite3.h"

//字符截取
static void substring(char *s,uint left,int right,char *t){
    int i=0,j=0,end=0;
    if (right < 0) {
        int len = 0;
        while(s[len]){
            len++;  
        }
        end = len + right;
    }else {
        end = left + right;
    }
    for(i=left;i<end;i++) {
        t[j]=s[i];  
        j++;
    }
    t[j]='\0';
}
//sqlite类型名称
static id sqliteTypeName(int type){
    switch (type) {
        case SQLITE_TEXT:
            return @"text";
        case SQLITE_BLOB:
            return @"blob";
        case SQLITE_FLOAT:
            return @"real";
        case SQLITE_INTEGER:
            return @"integer";
        default:
            break;
    }
    return nil;
}
//修正sqlite类型值
static id sqliteReviseValue(int type,id value){
    if (SQLITE_TEXT == type) {
        if (value && value!=[NSNull null]) {
            return [NSString stringWithFormat:@"\"%@\"",value];
        }
        return @"\" \"";
    }
    if (value && value!=[NSNull null]) {
        return value;
    }
    return @"0";
}
//转换到sqlite类型
static int sqliteConverType(const char *type){
    switch (type[0]) {
        case '@':{
            char className[1024];
            substring((char*)type,2,-1,className);
            Class class = objc_lookUpClass(className);
            if ([class isSubclassOfClass:NSData.class]) {
                return SQLITE_BLOB;
            }
            if ([class isSubclassOfClass:NSString.class]) {
                return SQLITE_TEXT;
            }
            if ([class isSubclassOfClass:NSNumber.class]) {
                return SQLITE_FLOAT;
            }
            if ([class isSubclassOfClass:NSSQLObject.class]) {
                return SQLITE_ID;
            }
        }
        case 'f':
        case 'd':
            return SQLITE_FLOAT;
        case 'i':
        case 'l':
        case 'q':
        case 's':
        case 'I':
        case 'L':
        case 'Q':
        case 'S':
        case 'B':
            return SQLITE_INTEGER;
        default:
            break;
    }
    return SQLITE_VOID;
}
//属性名，属性类型
static id attributeWithName(const char *name, bool isField){
    static  NSMutableDictionary *attributeList;
    if (nil == attributeList) {
        attributeList = [[NSMutableDictionary alloc] init];
    }
    Class class = objc_getClass(name);
    if (class) {
        NSString *nameString = [NSString stringWithUTF8String:name];
        if (nil == [attributeList objectForKey:nameString]) {
            NSMutableDictionary *object = [NSMutableDictionary dictionary];
            NSMutableDictionary *field = [NSMutableDictionary dictionary];
            unsigned int count = 0;
            objc_property_t *propertys = class_copyPropertyList(class, &count);
            for (int i=0; i<count ; i++){
                Ivar ivar = class_getInstanceVariable(class, property_getName(propertys[i]));
                if (ivar) {
                    NSInteger itype = sqliteConverType(ivar_getTypeEncoding(ivar));
                    if (itype != SQLITE_VOID) {
                        NSString *name = [NSString stringWithUTF8String:ivar_getName(ivar)];
                        if (itype == SQLITE_ID) {
                            [object setValue:[NSNumber numberWithInt:itype] forKey:name];
                        }else{
                            [field setValue:[NSNumber numberWithInt:itype] forKey:name];
                        }
                    }
                }
            }
            free(propertys);
            [attributeList setValue:[NSDictionary dictionaryWithObjectsAndKeys:object,@"object",field,@"field", nil] forKey:nameString];
        }
        if (isField) {
            return [[attributeList objectForKey:nameString] objectForKey:@"field"];
        }
        return [[attributeList objectForKey:nameString] objectForKey:@"object"];
    }
    return nil;
}

//********************************************
@interface NSSQLManager()
@property(nonatomic,readonly) sqlite3 *database;
@end

@implementation NSSQLManager
@synthesize transaction;
@synthesize database;
@synthesize conned;
+(NSSQLManager*)shareInstance{
    static NSSQLManager *instance;
    @synchronized(self){
        if (nil == instance){
            instance = [[NSSQLManager alloc] init];
        }
    }
    return instance;
}
-(id)init{
    self = [super init];
    if (self) {
        transaction = [[NSSQLTransaction alloc] init];
    }
    return self;
}
-(void)dealloc{
    [self close];
    [transaction release];
    [super dealloc];
}
-(bool)connect:(NSString *)path{
    if (false==conned) {
        if (SQLITE_OK==sqlite3_open([path UTF8String], &database)) {
            conned = true;
        }
    }
    return conned;
}
-(bool)query:(NSString *)sql{
    if (false==conned){
        @throw [NSException exceptionWithName:@"query" reason:@"select a dataBase file" userInfo:nil];
    }
    if(SQLITE_OK==sqlite3_exec(database, [sql UTF8String], 0, 0, NULL)){
        return true;
    } else{
        @throw [NSException exceptionWithName:@"query" reason:sql userInfo:nil];
    }
    return false;
}
-(id)fetch:(NSString *)sql{
    if (false==conned){
        @throw [NSException exceptionWithName:@"fetch" reason:@"select a dataBase file" userInfo:nil];
    }
    sqlite3_stmt *statement;
    if (SQLITE_OK==sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement,NULL)){
        NSMutableArray *result = [[NSMutableArray alloc] init];
        int len = sqlite3_column_count(statement);
        while (sqlite3_step(statement) == SQLITE_ROW){
            NSMutableDictionary *rows = [[NSMutableDictionary alloc] init];
            for (unsigned int i=0; i<len; i++){
                NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement,i)];
                switch(sqlite3_column_type(statement, i)){
                    case SQLITE_BLOB:
                        [rows setValue:[NSData dataWithBytes:sqlite3_column_blob(statement, i) length:sqlite3_column_bytes(statement, i)] forKey:name];
                        break;
                    case SQLITE_TEXT:
                        [rows setValue:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)] forKey:name];
                        break;
                    case SQLITE_FLOAT:
                        [rows setValue:[NSNumber numberWithFloat:sqlite3_column_double(statement,i)] forKey:name];
                        break;
                    case SQLITE_INTEGER:
                        [rows setValue:[NSNumber numberWithInt:sqlite3_column_int(statement,i)] forKey:name];
                        break;
                    case SQLITE_NULL:
                        [rows setValue:[NSNull null] forKey:name];
                        break;
                    default:
                        break;
                }
            }
            [result addObject:rows];
            [rows release];
        }
        sqlite3_finalize(statement);
        return [result autorelease];
    }else{
        @throw [NSException exceptionWithName:@"fetch" reason:sql userInfo:nil];
    }
    return nil;
}
-(void)close{
    if (conned) {
        sqlite3_close(database);
        database = NULL;
        conned = false;
    }
}
@end

//*********************************************************
@implementation NSSQLTransaction
-(bool)end{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"transaction end" reason:@"select a dataBase file" userInfo:nil];
    }
    if( SQLITE_OK==sqlite3_exec([[NSSQLManager shareInstance] database],"end transaction" , 0 , 0 , NULL)){
        return true;
    }
    return false;
}
-(bool)begin{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"transaction begin" reason:@"select a dataBase file" userInfo:nil];
    }
    if( SQLITE_OK==sqlite3_exec([[NSSQLManager shareInstance] database],"begin transaction" , 0 , 0 , NULL)){
        return true;
    }
    return false;
}
-(bool)commit{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"transaction commit" reason:@"select a dataBase file" userInfo:nil];
    }
    if( SQLITE_OK==sqlite3_exec([[NSSQLManager shareInstance] database],"commit transaction" , 0 , 0 , NULL)){
        return true;
    }
    return false;
}
-(bool)rollback{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"transaction rollback" reason:@"select a dataBase file" userInfo:nil];
    }
    if( SQLITE_OK==sqlite3_exec([[NSSQLManager shareInstance] database],"rollback transaction" , 0 , 0 , NULL)){
        return true;
    }
    return false;
}
@end

//*********************************************************
@interface NSSQLObject(){
    bool hasChanges;
}
@end

@implementation NSSQLObject
+(id)find:(NSString *)sql{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"find" reason:@"select a dataBase file" userInfo:nil];
    }
    NSDictionary *fieldList = attributeWithName(class_getName(self),true);
    if (fieldList.allKeys.count > 0) {
        sqlite3_stmt *statement;
        sqlite3 *database = [[NSSQLManager shareInstance] database];
        NSString *params = [fieldList.allKeys componentsJoinedByString:@","];
        NSString *sqliteSql = [NSString stringWithFormat:@"SELECT %@ FROM %s %@", params, class_getName(self), (sql ? [NSString stringWithFormat:@"WHERE %@",sql] : @"")];
        if (SQLITE_OK==sqlite3_prepare_v2(database, [sqliteSql UTF8String], -1, &statement,NULL)) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            int len = sqlite3_column_count(statement);
            while (sqlite3_step(statement) == SQLITE_ROW){
                NSSQLObject *obj = [[[self class] alloc] init];
                for (unsigned int i=0; i<len; i++){
                    bool isNull = (SQLITE_NULL==sqlite3_column_type(statement, i));
                    NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement,i)];
                    NSNumber *type = [fieldList objectForKey:name];
                    switch ([type intValue]) {
                        case SQLITE_BLOB:{
                            id value = isNull ? [NSData data] : [NSData dataWithBytes:sqlite3_column_blob(statement, i) length:sqlite3_column_bytes(statement, i)];
                            [obj setValue:value forKey:name];
                        }
                            break;
                        case SQLITE_INTEGER:{
                            id value = isNull ? [NSNumber numberWithInteger:0] : [NSNumber numberWithInteger:sqlite3_column_int(statement,i)];
                            [obj setValue:value forKey:name];
                        }
                            break;
                        case SQLITE_FLOAT:{
                            id value = isNull ? [NSNumber numberWithFloat:0] : [NSNumber numberWithFloat:sqlite3_column_double(statement,i)];
                            [obj setValue:value forKey:name];
                        }
                            break;
                        case SQLITE_TEXT:{
                            id value = isNull ? @"" : [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement,i)];
                            [obj setValue:value forKey:name];
                        }
                            break;
                        default:
                            break;
                    }
                }
                obj->hasChanges = NO;
                [result addObject:obj];
                [obj release];
            }
            sqlite3_finalize(statement);
            return [result autorelease];
        }
    }
    return nil;
}
+(bool)make{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"make" reason:@"select a dataBase file" userInfo:nil];
    }
    bool valid = false;
    sqlite3_stmt *statement;
    sqlite3 *database = [[NSSQLManager shareInstance] database];
    NSString *sqliteSql = [NSString stringWithFormat:@"PRAGMA table_info(\"%s\")",class_getName(self)];
    if (SQLITE_OK==sqlite3_prepare_v2(database, [sqliteSql UTF8String], -1, &statement,NULL)) {
        if (sqlite3_step(statement) == SQLITE_ROW){
            valid = true;
        }
        sqlite3_finalize(statement);
    }
    if (false==valid) {
        NSDictionary *fieldList = attributeWithName(class_getName(self),true);
        if (fieldList.allKeys.count > 0) {
            if ([fieldList objectForKey:@"id"]) {
                NSString *params = @"";
                for (int i=0; i<fieldList.allKeys.count; i++) {
                    if (valid) {
                        params = [params stringByAppendingString:@","];
                    }
                    //
                    NSString *name = [fieldList.allKeys objectAtIndex:i];
                    NSNumber *type = [fieldList objectForKey:name];
                    params = [params stringByAppendingFormat:@"\"%@\" %@ DEFAULT %@",name,sqliteTypeName([type intValue]),sqliteReviseValue([type intValue],NULL)];
                    valid = true;
                }
                if (valid) {
                    NSString *sqliteSql = [NSString stringWithFormat:@"CREATE TABLE %s (%@,PRIMARY KEY(\"id\"))",class_getName(self),params];
                    if(SQLITE_OK==sqlite3_exec(database, [sqliteSql UTF8String], 0, 0, NULL)){
                        valid = true;
                    }else{
                        @throw [NSException exceptionWithName:@"creat" reason:sqliteSql userInfo:nil];
                    }
                }
            }else{
                @throw [NSException exceptionWithName:@"creat" reason:@"must have the 'id' attribute" userInfo:nil];
            }
        }
    }
    return valid;
}
-(id)init{
    self = [super init];
    if (self) {
        NSDictionary *fieldList = attributeWithName(class_getName(self.class),true);
        for (id key in fieldList) {
            [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    return self;
}
-(void)dealloc{
    NSDictionary *fieldList = attributeWithName(class_getName(self.class),true);
    for (id key in fieldList) {
        [self removeObserver:self forKeyPath:key];
    }
    [super dealloc];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    hasChanges = true;
}
-(bool)save{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"save" reason:@"select a dataBase file" userInfo:nil];
    }
    NSDictionary *objectList = attributeWithName(class_getName(self.class),false);
    for (int i=0; i<objectList.allKeys.count; i++) {
        NSString *name = [objectList.allKeys objectAtIndex:i];
        NSSQLObject *obj = [self valueForKey:name];
        [obj save];
    }
    if (hasChanges) {
        hasChanges = false;
        NSDictionary *fieldList = attributeWithName(class_getName(self.class),true);
        if (fieldList.allKeys.count > 0) {
            BOOL valid = false;
            NSString *params = @"";
            NSString *values = @"";
            for (int i=0; i<fieldList.allKeys.count; i++) {
                if (valid) {
                    params = [params stringByAppendingString:@","];
                    values = [values stringByAppendingString:@","];
                }
                NSString *name = [fieldList.allKeys objectAtIndex:i];
                NSNumber *type = [fieldList objectForKey:name];
                params = [params stringByAppendingFormat:@"%@",name];
                values = [values stringByAppendingFormat:@"%@",sqliteReviseValue([type intValue],[self valueForKey:name])];
                valid = true;
            }
            if (valid){
                valid = false;
                sqlite3 *database = [[NSSQLManager shareInstance] database];
                NSString *sqliteSql = [NSString stringWithFormat:@"REPLACE INTO %s (%@) VALUES (%@)",class_getName(self.class),params,values];
                if(SQLITE_OK==sqlite3_exec(database, [sqliteSql UTF8String], 0, 0, NULL)){
                    valid = true;
                }else {
                    @throw [NSException exceptionWithName:@"save" reason:sqliteSql userInfo:nil];
                }
            }
            return valid;
        }
    }
    return false;
}
-(bool)free{
    if (false==[[NSSQLManager shareInstance] conned]){
        @throw [NSException exceptionWithName:@"free" reason:@"select a dataBase file" userInfo:nil];
    }
    NSDictionary *objectList = attributeWithName(class_getName(self.class),false);
    for (int i=0; i<objectList.allKeys.count; i++) {
        NSString *name = [objectList.allKeys objectAtIndex:i];
        NSSQLObject *obj = [self valueForKey:name];
        [obj free];
    }
    sqlite3 *database = [[NSSQLManager shareInstance] database];
    NSString *sqliteSql = [NSString stringWithFormat:@"DELETE FROM %s WHERE id ='%@'",class_getName(self.class),[self valueForKey:@"id"]];
    if(SQLITE_OK==sqlite3_exec(database, [sqliteSql UTF8String], 0, 0, NULL)){
        return true;
    }else {
        @throw [NSException exceptionWithName:@"free" reason:sqliteSql userInfo:nil];
    }
    return false;
}
@end