/*TransferController.java */
package com.smartbank.transaction.controller;

import com.smartbank.transaction.dto.TransferRequest;
import com.smartbank.transaction.dto.TransferResponse;
import com.smartbank.transaction.service.TransferService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

//added these imports 
import io.swagger.v3.oas.annotations.Operation;
 import io.swagger.v3.oas.annotations.responses.ApiResponse; 
 import io.swagger.v3.oas.annotations.responses.ApiResponses; 
 import io.swagger.v3.oas.annotations.tags.Tag;


@RestController
@RequestMapping("/api/accounts")

@Tag( name = "Transactions", description = "Money transfer and transaction-related APIs" )



public class TransferController {

    private final TransferService transferService;

    public TransferController(TransferService transferService) {
        this.transferService = transferService;
    }
   

   //added here 
 @Operation( summary = "Transfer money", description = "Transfers money from one bank account to another." )
    @ApiResponses({ 

     @ApiResponse(
         responseCode = "200", description = "Money transferred successfully" 
         ), 
     @ApiResponse(
         responseCode = "400", description = "Invalid transfer request" 
         ),
     @ApiResponse( 
        responseCode = "401", description = "Authentication required"
      ), 
     @ApiResponse( 
        responseCode = "403", description = "Access denied" 
        ), 
     @ApiResponse( 
        responseCode = "404", description = "Source or destination account not found" 
        ) 
     })









    @PostMapping("/transfer")
    public ResponseEntity<TransferResponse> transfer(
            @Valid @RequestBody TransferRequest request) {

        TransferResponse response = transferService.transfer(request);

        return ResponseEntity.ok(response);
    }
}