/*
AccountController.java
*/

package com.smartbank.account.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.account.dto.AccountResponse;
import com.smartbank.account.dto.CreateAccountRequest;
import com.smartbank.account.service.AccountService;
import com.smartbank.transaction.dto.DepositRequest;
import com.smartbank.transaction.dto.DepositResponse;
import com.smartbank.transaction.dto.TransactionResponse;
import com.smartbank.transaction.dto.WithdrawRequest;
import com.smartbank.transaction.dto.WithdrawResponse;
import com.smartbank.transaction.service.TransactionService;



//added these imports lateer 
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;






import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor

//added this 
@Tag(
        name = "Accounts",
        description = "Account management, deposits, withdrawals and transaction history APIs"
)





public class AccountController {
    private final TransactionService transactionService;
    private final AccountService accountService;
    
    //added this 
     @Operation(
            summary = "Create a new account",
            description = "Creates a new bank account for the authenticated user."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "Account created successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid account creation request"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
    })













    @PostMapping
    public ResponseEntity<AccountResponse> createAccount(
            @Valid @RequestBody CreateAccountRequest request) {
        

      
        AccountResponse response = accountService.createAccount(request);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }



       @Operation(
            summary = "Get my accounts",
            description = "Retrieves all bank accounts belonging to the authenticated user."
         )
        @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Accounts retrieved successfully"
            ),
        @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
        @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            )
        })
     


    
    @GetMapping
    public ResponseEntity<List<AccountResponse>> getMyAccounts() {

        return ResponseEntity.ok(accountService.getMyAccounts());
    }
      @Operation(
            summary = "Get account by account number",
            description = "Retrieves account details using the account number."
    )
       @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Account retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Account not found"
            )
       })





    @GetMapping("/{accountNumber}")
    public ResponseEntity<AccountResponse> getAccountByNumber(@PathVariable String accountNumber) {


              

        return ResponseEntity.ok(
                accountService.getAccountByNumber(accountNumber));
    }
       @Operation(
            summary = "Deposit money",
            description = "Deposits money into the specified bank account."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Deposit completed successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid deposit request"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Account not found"
            )
    })


    @PostMapping("/{accountNumber}/deposit")
       public ResponseEntity<DepositResponse> deposit(
        
         @Parameter(
                    description = "Account number receiving the deposit",
                    required = true,
                    example = "ACC10001"
            )
        
    
        @PathVariable String accountNumber,
        @Valid @RequestBody DepositRequest request)
         {

        DepositResponse response = accountService.deposit(accountNumber, request);

        return ResponseEntity.ok(response);
       }
   
    //adding these 
    @Operation(
            summary = "Withdraw money",
            description = "Withdraws money from the specified bank account."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Withdrawal completed successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid withdrawal request"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Account not found"
            )
    })












      @PostMapping("/{accountNumber}/withdraw")
     public ResponseEntity<WithdrawResponse> withdraw(
     //added these 
       @Parameter(
                    description = "Account number from which money is withdrawn",
                    required = true,
                    example = "ACC10001"
            )
     
     
     
     
     
     
        @PathVariable String accountNumber,
        @Valid @RequestBody WithdrawRequest request) {

    WithdrawResponse response =
            accountService.withdraw(accountNumber, request);

    return ResponseEntity.ok(response);
}





//added these 
 @Operation(
            summary = "Get account transactions",
            description = "Retrieves the transaction history for the specified account."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Transactions retrieved successfully"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Authentication required"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Access denied"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Account not found"
            )
    })








  @GetMapping("/{accountNumber}/transactions")
public ResponseEntity<List<TransactionResponse>> getTransactions(
    
    
         @Parameter(
                    description = "Account number whose transactions are requested",
                    required = true,
                    example = "ACC10001"
            )
    
    
        @PathVariable String accountNumber) {

    
    return ResponseEntity.ok(
            transactionService.getTransactions(accountNumber));
}
         



}