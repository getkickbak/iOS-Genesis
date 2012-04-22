/*
 ============================================================================
 Name		: i_nigma_sdk.h
 Author	  : Adi Gadish
 Copyright   : Copyright 2009
 3GVision Ltd.
 Description : i_nigma_sdk.h - SmartcodeDecoder class header
 ============================================================================
 */

// This file defines the API for i_nigma_sdk.dll

#ifndef __I_NIGMA_SDK_H__
#define __I_NIGMA_SDK_H__

/*
* SmartcodeDecoder
*
* This is the abstract class for barcode decoder software, implemented for Windows Mobile 6 HTC devices.
*  
* Use the Construct function to create an instance of the decoder, then by using the Start/Stop functions you
* can control decoding.  Decoding information or other notifications (timeout, error etc) will be delivered
* to the observer.
* While scanning, the decoder will take over the device's camera, display & keypad, and scan for bar codes.
* The decoder will show the preview on the screen until a bar code was decoded, or timeout. The decoder will 
* prevent other applications using the camera as long as scanning is taking place.  On beginning auto focus 
* process will take place.  The user can also trigger auto focus by pressing the center key.  Also, the user
* can increase/decrease zoom by pressing the up/down keys.  After 45 seconds, timeout will occur if no bar 
* code decoded.
*
* Use this header file (i_nigma_sdk.h) in your application inc directory
* Link against the static library file (i_nigma_sdk.lib).
*
*/
struct SmartcodeDecoder
{

	enum DecodingFlags
	{
		None					= 0x00000000,	//No flags
		DecodeEAN8				= 0x00000001,	//Decode EAN8
		DecodeEAN13				= 0x00000002,	//Decode EAN13
        DecodeMicroQR           = 0x00000080,   //Decode Micro QR 
        DecodeDataMatrix		= 0x00000100,	//Decode DataMatrix
		DecodeQR				= 0x00000200,	//Decode QR
		DecodePDF417			= 0x00000800,	//Decode PDF417
		DecodeEAN128			= 0x00001000,	//Decode Code 128
		DecodeEAN39				= 0x00002000,	//Decode Code 39
		Decode_2_of_5			= 0x00004000,	//Decode 2 of 5
		DecodeBlackOnWhite		= 0x00010000,	//Reverse B&W barcodes
	};
    
    //Observer
	//The application should inherit this class and implement its API
	struct Observer
	{
		virtual void OnTimeout()=0;						//Called if no bar code decoded till timeout occurred
		enum ErrorType
		{
			EmptyError=0,
			CameraInUseError,		// Camera could not be operated because it is used by other application
			GeneralError,			// Could not open the camera / Unknown error occurred
			LicenseError,			// No License / Wrong license / Insufficient license
			CodeInvalidError,
			CodeNotSupportedError
		};
		virtual void OnError(ErrorType error) = 0;		// Called on error
		enum NotificationType
		{
			EmptyNofitication = 0,
			GettingLicenseStarted,
			LicenseProcessSucceeded,
			LicenseProcessFailed,
			CameraStarted,
			CameraClosed,
			CodeFound
		};
		virtual void OnNotification(NotificationType notification) = 0;		// Called on Notification
		virtual void OnDecode(unsigned char* res,int len,DecodingFlags SymbolType) = 0;	// Called on successful decoding with the bar code content
		virtual void OnCameraStopOrStart(int on) {}	// Called on camera view begin or stop 
	};

	//New
	//Application should create an instance of SmartcodeDecoder by calling this function.
	//project is your project id assigned by 3GVision
	//observer points to the Application Observer so notification and results can be indicated
	static SmartcodeDecoder* New(Observer* observer);
	virtual ~SmartcodeDecoder();

	
	//Scan
	//Application should call this function in order to start scanning
	virtual void Scan(void* pUIViewController, 
					  int PrevX,
					  int prevY,
					  int PrevW,
					  int PrevH,
					  int flags, 
					  int timeoutInSeconds = 45) = 0;

	//StartAutoFocus
	//Application should call this function in order to start auto focus process
	virtual void StartAutoFocus() = 0;

	//Stop
	//Application should call this function in order to stop scanning and hide camera
	virtual void Abort() = 0;
	
	//CloseCamera
	//Application should call this function in order to close camera and able to open it on different view
	virtual void CloseCamera() = 0;

	//UpdateLicense
	//Application should call this function if a non scheduled license update is required.
	virtual void UpdateLicense() = 0;

    // Torch function 
    // IsTorchAvailable 
    // Return 1 if device has torch (flashlight)
    virtual int IsTorchAvailable()=0;
    
    // TurnTorch 
    // Turn torch on and off)
    virtual void TurnTorch(int on)=0;

	//Version
	//Returns the version of the decoder.
	virtual int Version();
    
  
  
protected:
	SmartcodeDecoder();

public:
	//Load
	//Application can use this function in order to create an instance of SmartcodeDecoder.
	//The function loads the dll and calls the factory method "New"
	static inline SmartcodeDecoder* Load(Observer* observer)
	{
		return SmartcodeDecoder::New(observer);
	}
};




#endif  // __I_NIGMA_SDK_H__

