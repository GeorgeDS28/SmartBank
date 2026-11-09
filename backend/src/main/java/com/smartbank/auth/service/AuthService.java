//think of this as a contract 


/*
AuthService.java

*/

package com.smartbank.auth.service;

import com.smartbank.auth.dto.ChangePasswordRequest;
import com.smartbank.auth.dto.LoginRequest;
import com.smartbank.auth.dto.LoginResponse;
import com.smartbank.auth.dto.RegisterRequest;

public interface AuthService {

    void register(RegisterRequest request);

    LoginResponse login(LoginRequest request);

    // Voluntary, from inside a session: the caller proves the current password
    // before a new one is stored.
    void changePassword(ChangePasswordRequest request);

}