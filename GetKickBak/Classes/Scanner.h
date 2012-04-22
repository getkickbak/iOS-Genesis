//
//  Scanner.h
//  i-nigmaSdkTest
//
//  Created by 1 on 12/28/09.
//  Copyright 2009 1. All rights reserved.
//

#include "i_nigma_sdk.h"

void WrapError(void* pThis,const char* str);
void WrapNotify(void* pThis,const char* str);
void WrapDecode(void* pThis,const unsigned short* str,const char*  SymbolType);
void WrapCameraStopOrStart(int on,void* pThis);

class CScanner : public SmartcodeDecoder::Observer {
public:
	CScanner(void* pControler);
	virtual void OnTimeout();						//Called if no bar code decoded till timeout occurred
	virtual void OnError(ErrorType error) ;		// Called on error
	virtual void OnNotification(NotificationType notification);		// Called on Notification
	virtual void OnDecode(unsigned char *result,int len,SmartcodeDecoder::DecodingFlags SymbolType);	// Called on successful decoding with the bar code content
	virtual void OnCameraStopOrStart(int on);	// Called after camera begin or stop to be able to add or remove GUI layers`
	void Scan(void* pViewControler);
	void UpdateLicense();
	void Abort();
	void CloseCamera();
    int IsTorchAvailable();
    void TurnTorch(int on);

private:
	void* m_pControler;
	SmartcodeDecoder* m_pDecoder;
}; 


//@interface Scanner : Observer {

//}

//@end
