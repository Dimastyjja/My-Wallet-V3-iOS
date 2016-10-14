//
//  TransferAllFundsBuilder.h
//  Blockchain
//
//  Created by Kevin Wu on 10/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TransferAllFundsDelegate
- (void)didFinishTransferFunds:(NSString *)summary;
@end

@interface TransferAllFundsBuilder : NSObject
@property (nonatomic) id <TransferAllFundsDelegate> delegate;

@property (nonatomic) NSMutableArray *transferAllAddressesToTransfer;
@property (nonatomic) NSMutableArray *transferAllAddressesTransferred;
@property (nonatomic) int transferAllAddressesInitialCount;
@property (nonatomic) int transferAllAddressesUnspendable;

@property (nonatomic, readonly) int destinationAccount;
@property (nonatomic, readonly) BOOL usesSendScreen;

@property (nonatomic) BOOL userCancelledNext;

// Callbacks for each transfer
@property(nonatomic, copy) void (^on_before_send)();
@property(nonatomic, copy) void (^on_prepare_next_transfer)(NSArray *transferAllAddressesToTransfer);
@property(nonatomic, copy) void (^on_success)(NSString*secondPassword);
@property(nonatomic, copy) void (^on_error)(NSString*error, NSString*secondPassword);

- (id)initUsingSendScreen:(BOOL)usesSendScreen;
- (void)setupTransfersToAccount:(int)account;
- (void)setupFirstTransferWithAddressesUsed:(NSArray *)addressesUsed;
- (void)transferAllFundsToAccountWithSecondPassword:(NSString *)secondPassword;
- (NSString *)getLabelForDestinationAccount;
- (NSString *)getLabelForAmount:(uint64_t)amount;
@end
