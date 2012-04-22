//
//  Scanner.mm
//  i-nigmaSdkTest
//
//  Created by 1 on 12/28/09.
//  Copyright 2009 1. All rights reserved.
//

#include "Scanner.h"


CScanner::CScanner(void* pControler)
{
	m_pControler = pControler;
	m_pDecoder = SmartcodeDecoder::Load(this);

}
void CScanner::OnTimeout()
{
	WrapError(m_pControler,"Time Out");

}
void CScanner::OnError(ErrorType error) 
{
	switch (error) {
		case CameraInUseError:
			WrapError(m_pControler,"Camera in use Error");
			break;
		case GeneralError:
			WrapError(m_pControler,"General Error");
			break;
		case LicenseError:
			WrapError(m_pControler,"License Error");
			break;
		case CodeInvalidError:
			WrapError(m_pControler,"Code Invalid Error");
			break;
		case CodeNotSupportedError:
			WrapError(m_pControler,"Code Not Supported Error");
			break;
		default:
			break;
	} 
}
void CScanner::OnNotification(NotificationType notification){
	switch (notification) {
		case GettingLicenseStarted:
			WrapNotify(m_pControler, "Getting License Started");
			break;
		case LicenseProcessSucceeded:
			WrapNotify(m_pControler, "Getting License Succeeded");
			break;
		case LicenseProcessFailed:
			WrapNotify(m_pControler, "License Process Failed");
			break;
		case CameraStarted:
			WrapNotify(m_pControler, "Camera Started");
			break;
		case CameraClosed:
			WrapNotify(m_pControler, "Camera Closed");
			break;
		case CodeFound:
			WrapNotify(m_pControler, "Code Found");
			break;
        default:
			break;
	
	}	
}
void CScanner::OnDecode(unsigned char *result,int len,SmartcodeDecoder::DecodingFlags SymbolType)
{
	// convert raw data to unicode string 
	unsigned short* str = new unsigned short[len+1]; 
	for (int i = 0 ; i < len; i++){
		str[i] = result[i];
	}
	str[len] = 0;
    switch (SymbolType) {
        case SmartcodeDecoder::DecodeEAN8:
            WrapDecode(m_pControler,str,"EAN 8");
            break;
        case SmartcodeDecoder::DecodeEAN13:
            WrapDecode(m_pControler,str,"EAN 13");
            break;
        case SmartcodeDecoder::DecodeDataMatrix:
            WrapDecode(m_pControler,str,"Data Matrix");
            break;
        case SmartcodeDecoder::DecodeQR:
            WrapDecode(m_pControler,str,"QR Code");
            break;
        case SmartcodeDecoder::DecodePDF417:
            WrapDecode(m_pControler,str,"PDF 417");
            break;
        case SmartcodeDecoder::DecodeEAN128:
            WrapDecode(m_pControler,str,"Code 128");
            break;
        case SmartcodeDecoder::DecodeEAN39:
            WrapDecode(m_pControler,str,"Code 39");
            break;
        case SmartcodeDecoder::DecodeMicroQR:
            WrapDecode(m_pControler,str,"Micro QR");
            break;
        default:
            WrapDecode(m_pControler,str,"");
            break;
    }
    delete str;

} 

void CScanner::OnCameraStopOrStart(int on) 
{
	WrapCameraStopOrStart(on,m_pControler);
}
void CScanner::Scan(void* pViewControler)
{
	int nDecodeEAN8 = SmartcodeDecoder::DecodeEAN8; 
	int nDecodeEAN13 = SmartcodeDecoder::DecodeEAN13; 
	int nDecodeEAN128 = SmartcodeDecoder::DecodeEAN128; 
	int nDecodeCode39 = SmartcodeDecoder::DecodeEAN39; 
	int nDecodeMicroQR = SmartcodeDecoder::DecodeMicroQR; 
	int nDecodeQR = SmartcodeDecoder::DecodeQR; 
	int nDecodeDataMatrix = SmartcodeDecoder::DecodeDataMatrix; 
	int nDecodeBlackOnWhite = SmartcodeDecoder::DecodeBlackOnWhite; 
	int nDecodePDF417 = SmartcodeDecoder::DecodePDF417; 
    int nDecode_2_of_5 = SmartcodeDecoder::Decode_2_of_5;
	m_pDecoder->Scan(pViewControler,
                    0,0,320,400,
					 nDecodeEAN8| 
					 nDecodeEAN13 | 
					 nDecodeEAN128 |
					 nDecodeCode39 |
                     nDecodeMicroQR |
					 nDecodeQR |
					 nDecodeDataMatrix| 
					 nDecodeBlackOnWhite|
					 nDecodePDF417|
                     nDecode_2_of_5
					 );
}
void CScanner::UpdateLicense()
{
	m_pDecoder->UpdateLicense();	
}
void CScanner::Abort()
{
	m_pDecoder->Abort();
}
void CScanner::CloseCamera()
{
	m_pDecoder->CloseCamera();
}
int CScanner::IsTorchAvailable()
{
    return m_pDecoder->IsTorchAvailable();
}
void CScanner::TurnTorch(int on)
{
    m_pDecoder->TurnTorch(on);
}

