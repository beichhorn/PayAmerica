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

        // Set up library list and Program Library
        if ($systemType != "PRD") {
          $response = $conn->CLCommand("ADDLIBLE LIB(RTOBJDEV)");
          $response = $conn->CLCommand("ADDLIBLE LIB(RTDTADEV)");
          $programLib = "RTOBJDEV";
        } 
        else {
          $response = $conn->CLCommand("ADDLIBLE LIB(RTOBJ)");
          $response = $conn->CLCommand("ADDLIBLE LIB(RTDTA)");
          $programLib = "RTOBJ";
        };

        //  define parameters
        $params = []; // start with empty array
        $params[] = $conn->AddParameterChar('in', 2022, 'Request', 'Request', $in);
        $params[] = $conn->AddParameterChar('out', 10000000, 'Response', 'Response', '');
        $retParam = [];

        // Call program 
        $response = $conn->PgmCall('BP715R1', $programLib, $params, $retParam);

        break;
      } 
    
    // print_r(htmlspecialchars($response['io_param']['Response']));
    echo $response['io_param']['Response'];
    
?>
