/*
The controller doesn't know how to register.
AuthController.java

It simply delegates the work.

*/



package com.smartbank.auth.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smartbank.auth.dto.LoginRequest;
import com.smartbank.auth.dto.LoginResponse;
import com.smartbank.auth.dto.RegisterRequest;
import com.smartbank.auth.service.AuthService;


//added this imports later 
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;


import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
@Tag(
        name = "Authentication",
        description = "User registration and authentication APIs"
)
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }









@Operation(
        summary = "Register a new user",
        description = "Creates a new SmartBank user account."
)
@ApiResponses({
        @ApiResponse(
                responseCode = "200",
                description = "User registered successfully"
        ),
        @ApiResponse(
                responseCode = "400",
                description = "Invalid registration data"
        ),
        @ApiResponse(
                responseCode = "409",
                description = "User already exists"
        )
})






@PostMapping("/register")
    public ResponseEntity<String> register(
            @Valid @RequestBody RegisterRequest request) {

        
        authService.register(request);

        return ResponseEntity.ok("User registered successfully");
    }







@Operation(
        summary = "Login user",
        description = "Authenticates a registered user and returns a JWT token."
)
@ApiResponses({
        @ApiResponse(
                responseCode = "200",
                description = "Login successful"
        ),
        @ApiResponse(
                responseCode = "400",
                description = "Invalid login request"
        ),
        @ApiResponse(
                responseCode = "401",
                description = "Invalid username or password"
        )
})
@PostMapping("/login")
        public ResponseEntity<LoginResponse> login(
        @Valid @RequestBody LoginRequest request) {

    return ResponseEntity.ok(authService.login(request));
      }
}