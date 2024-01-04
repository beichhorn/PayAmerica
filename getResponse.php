<?php

   require_once('iToolkitService.php');

   $port = $_SERVER['SERVER_PORT'];

   // Get "INPUT" parameter
   $in = $_GET['IN'];

   // Try to connect to IBM i (use blanks for User and Password for default authority)
   try {
     $conn = ToolkitService::getInstance('*LOCAL', '', '');

   } catch (Exception $e) {  
     // Determine reason for failure 
     $code = $e->getCode();
     $msg = $e->getMessage();
     echo "Error Code= " . $code . " Error Message= " . $msg;
     return;
   } 
   
   $conn->setOptions(array('stateless'=>true));

   // Call appropiate program based on the Port Number in URL
   switch ($port) {
      case '10003':  // EasyCall

        // Determine if running on Devlopment or PRODUCTION from Data Area QGPL/SYSTEM.
        $dataArea = new DataArea($conn);
        $dataArea->setDataAreaName('SYSTEM', 'QGPL');
        $systemType = $dataArea->readDataArea();
        if ($systemType != "PRD") 
          $DataQLib = 'RTDTADEV';
        else
          $DataQLib = 'RTDTA';

        $KeyFld = date("Y-m-d.H.i.s.u");
        $Data = $KeyFld . $in;

        // Get Data Queue and Return Data Queue Names
        // 17 = EasyCall
        $sql = 'SELECT PIDTAQ FROM ' .$DataQLib.'.RTPIDP WHERE "PIPRC#" = 17';
        $rs[] = $conn->executeQuery($sql);
        $sql = 'SELECT PIRDTQ FROM ' .$DataQLib.'.RTPIDP WHERE "PIPRC#" = 17';
        $rs[] = $conn->executeQuery($sql);
        $DQName = $rs[0][0];
        $retDQName = $rs[1][0];

        // Send REQUEST ($in) to Data Queue
        $dataQueue = new DataQueue($conn);
        $dataQueue->SetDataQName($DQName, $DataQLib);
        $response = $dataQueue->SendDataQueue(2048, $Data);
        $response = $dataQueue->SendDataQueue(2048, $Data); // Data Queue Issues

        // Set up Receive Data Queue
        $dataQueue->SetDataQName($retDQName, $DataQLib);

        // // Receive RESPONSES from Data Queue until '**EOD**'
        $data = "";
        $output = "";
        while ($data != '**EOD**') {
          $response = $dataQueue->receieveDataQueue(25, 'EQ', 26, $KeyFld, 'Y');
          $data = $response['datavalue'];
          if ($data != '**EOD**')
             $output .= $data;
        }  

        echo $output;
        break;
      } 
    
    // print_r(htmlspecialchars($response['io_param']['Response']));
    // echo $response['io_param']['Response'];
    
?>
