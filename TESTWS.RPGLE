    **********************************************************************
    *
    *  PROGRAM NAME - BP715R1
    *
    *  DESCRIPTION  - EasyCall - RPG Program to Receive URL requests
    *
    *  FUNCTION     - This program is called by Web Service WSERVICE1 to
    *                 handle URL requests for data.  Data is then sent to
    *                 a data queue specified in file RTPIDL01.  Data is then
    *                 received from a data queue also specified in RTPIDL01.
    *                 RTPIDL01 is keyed by Company No. (default = 1) and
    *                 Process ID (EasyCall = 17). The response will then be
    *                 sent back to client application or browser.
    *
    **********************************************************************
    *  INDICATOR USAGE SUMMARY
    *    INDICATOR  USE
    *    ---------  ------------------------------------------------------
    *
    **********************************************************************
    *  WORK HISTORY
    *
    *   DATE..........
    *   CREATED BY....
    *
    *   DATE.......... XX/XX/XXXX
    *   CHANGED BY....
    *   REQUESTED BY..
    *   DESCRIPTION...
    *
    **********************************************************************
    *    FUNCTION
    *    KEYS       DESCRIPTION
    *    ---------  ------------------------------------------------------
    *
    **********************************************************************
    *  SUBROUTINES
    *    ROUTINE    DESCRIPTION
    *    ---------  ------------------------------------------------------
    *
    **********************************************************************
    *  RETURN ERROR CODES
    *    CODE  MESSAGE
    *    ----  -----------------------------------------------------------
    *
    **********************************************************************
    *  FILES USED
    *    TYPE  FILE NAME  DESCRIPTION
    *    ----  ---------  ------------------------------------------------
    *
    **********************************************************************
         Dcl-Pr  Call_QSNDDTAQ     Extpgm('QSNDDTAQ');
           DqName   Char(10)     CONST;
           DqLib    Char(10)     CONST;
           DataLen  Packed(5:0)  CONST;
           Data     Char(2048)   CONST;
           KeyLen   Packed(3:0)  CONST;
           KeyFld   Char(26)     CONST;
         End-Pr;

         Dcl-Pr  Call_QRCVDTAQ     Extpgm('QRCVDTAQ');
           DqName   Char(10)     CONST;
           DqLib    Char(10)     CONST;
           DataLen  Packed(5:0)  CONST;
           Data     Char(1024)   CONST;
           WaitTime Packed(5:0)  CONST;
           KeyLen   Packed(3:0)  CONST Options(*NOPASS);
           KeyFld   Char(26)     CONST Options(*NOPASS);
           Sendlen  Packed(3:0)  CONST Options(*NOPASS);
           SendID   Char(128)    CONST Options(*NOPASS);
         End-Pr;

         // Files
         Dcl-F RTPIDL01 Keyed;  // Process ID Master File (by Company and Proces
         Dcl-F RTBLML01 Keyed;

         Dcl-S SystemType  Char(3) Dtaara('QGPL/SYSTEM');
         Dcl-S DqName      Char(10);
         Dcl-S DqLib       Char(10);
         Dcl-S Data        Char(2048);
         Dcl-S WaitTime    Packed(5:0) Inz(-1);
         Dcl-S Keyfld      Char(26);
         Dcl-S Output      Char(10000000);

         // Determine Library for Data Queue based on System Type
         In SystemType;
         If SystemType <> 'PRD';
           DqLib = 'RTDTADEV';
         Else;
           DqLib = 'RTDTA';
         Endif;

         // Get the Send Data Queue and Receive Data Queue names from RTPIDL01
         PICMNO = 1;
         PIPRC# = 17; // EasyCall Process ID = 17
         Chain (PICMNO:PIPRC#) RTPIDL01;

         Dou 1=0;

         // Receive request from Data queue
         // DqName = 'BP715DQ1';
         DqName = 'BP715DQ';

         Call_QRCVDTAQ(DqName:DqLib:%size(Data):Data:WaitTime);

         Keyfld = %subst(Data:1:26);
         Data   = %trim(%subst(Data:27));

         BLCMNO = 1;
         Monitor;
           BLBILR = %int(Data);
         On-Error;
           BLBILR = 0;
           Data = '<ERROR>Invalid Request</ERROR>';
         Endmon;

         If BLBILR  <> 0;
           Chain (BLCMNO:BLBILR) RTBLML01;
           If %found(RTBLML01);
             Data = '<Biller_Name>' + %trim(BLBILN) + '</Biller_Name>';
           Else;
             Data = '<ERROR>Biller ID Not Found</ERROR>';
           Endif;
         Endif;

         DqName = PIRDTQ;
         Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Data = '<Account_Status>' + %char(BLSTS) + '</Account_Status>';
          Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Data = '<Last_Change_Date>' + %char(BLLCDT) + '</Last_Change_Date>';
          Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Data = '<Last_Change_Time>' + %char(BLLCTM) + '</Last_Change_Time>';
          Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Data = '<Last_Change_User>' + %trim(BLLCUS) + '</Last_Change_User>';
          Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Data = '**EOD**';
         Call_QSNDDTAQ(DqName:DqLib:%size(Data):Data:
                         %size(KeyFld):KeyFld);

         Enddo;

         Return;
