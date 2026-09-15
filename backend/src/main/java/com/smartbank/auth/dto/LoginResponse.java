/*
LoginResponse.java
This class represents the response returned 
after a successful login attempt.

*/




package com.smartbank.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class LoginResponse {

    private String token;
}