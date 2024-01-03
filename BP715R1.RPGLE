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
         Ctl-Opt     Pgminfo(*PCML:*MODULE);

         Dcl-Pr   Entry   Extpgm('BP715R1');
           Request    Char(2022);
           Response   Char(10000000);
         End-Pr;

         Dcl-Pi   Entry;
           Request    Char(2022);
           Response   Char(10000000);
         End-Pi;

         Dcl-Pr  Call_QSNDDTAQ     Extpgm('QSNDDTAQ');
           DqName   Char(10)     CONST;
           DqLib    Char(10)     CONST;
           DataLen  Packed(5:0)  CONST;
           Data     Char(2048)   CONST;
           KeyLen   Packed(3:0)  CONST  Options(*NOPASS);
           KeyFld   Char(26)     CONST  Options(*NOPASS);

         End-Pr;

         Dcl-Pr  Call_QRCVDTAQ     Extpgm('QRCVDTAQ');
           DqName   Char(10)     CONST;
           DqLib    Char(10)     CONST;
           DataLen  Packed(5:0)  CONST;
           Data     Char(1024)   CONST;
           WaitTime Packed(5:0)  CONST;
           KeyOrder Char(2)      CONST;
           KeyLen   Packed(3:0)  CONST Options(*NOPASS);
           KeyFld   Char(26)     CONST Options(*NOPASS);
           Sendlen  Packed(3:0)  CONST Options(*NOPASS);
           SendID   Char(128)    CONST Options(*NOPASS);
         End-Pr;

         // Files
         Dcl-F RTPIDL01 Keyed;  // Process ID Master File (by Company and Proces

         Dcl-S SystemType  Char(3) Dtaara('QGPL/SYSTEM');
         Dcl-S DqName      Char(10);
         Dcl-S DqLib       Char(10);
         Dcl-S Dqlen       Packed(5:0) Inz(2048);
         Dcl-S Data        Char(2048);
         Dcl-S WaitTime    Packed(5:0) Inz(25);
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

         // Send request to data queue
         DqName = PIDTAQ;
         KeyFld = %char(%timestamp:*ISO);
         Data = KeyFld + Request;
         Call_QSNDDTAQ(DqName:DqLib:Dqlen:Data);
         Call_QSNDDTAQ(DqName:DqLib:Dqlen:Data); // Data Queue Issue

         // Build Response from Data Queue
         Dou Data = '**EOD**';
           DqName = PIRDTQ;
           Data = *blanks;
           Call_QRCVDTAQ(DqName:DqLib:Dqlen:Data:WaitTime:'EQ':
                         %size(KeyFld):KeyFld:0:' ');

           Select;
             When Data = '**EOD**'; // EOD = End of Data
               Iter;
             When Data = *blanks;  // No response from Data Queue
               Leave;
             Other;
               Output = %trim(Output) + %trim(Data);
           Endsl;

         Enddo;

         If Data <> '**EOD**';  // Incomplete Data from Data Queue
           Response = '<Response>No Data Returned from Server</Response>';
         Else;
           Response = Output;
         Endif;

         *INLR = *On;
