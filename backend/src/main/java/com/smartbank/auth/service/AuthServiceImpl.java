// this class implements the interface 

/*
AuthServiceImpl.java
*/
package com.smartbank.auth.service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.smartbank.user.enums.Role;
import com.smartbank.auth.dto.LoginRequest;
import com.smartbank.auth.dto.LoginResponse;
import com.smartbank.auth.dto.RegisterRequest;
import com.smartbank.auth.jwt.JwtService;
import com.smartbank.exception.EmailAlreadyExistsException;
import com.smartbank.exception.InvalidCredentialsException;
import com.smartbank.user.entity.User;
import com.smartbank.user.repository.UserRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class AuthServiceImpl implements AuthService 
{
    private static final Logger log =
        LoggerFactory.getLogger(AuthServiceImpl.class);


    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

  public AuthServiceImpl(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {

    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
}

    @Override
    public void register(RegisterRequest request) {
     
     

     if (userRepository.existsByEmail(request.getEmail())) {
    //  throw new RuntimeException("Email already registered");

      throw new EmailAlreadyExistsException("Email already registered");
}
        User user = new User();

       user.setFirstName(request.getFirstName());
       
       user.setLastName(request.getLastName());


       user.setEmail(request.getEmail());

       user.setPassword(passwordEncoder.encode(request.getPassword())); 
       
       user.setPhone(request.getPhone());
       user.setRole(Role.ROLE_USER);




        userRepository.save(user);
        log.info("User registered successfully");
    }
       @Override
           public LoginResponse login(LoginRequest request) {
            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() ->
                new InvalidCredentialsException("Invalid email or password"));

    boolean matches = passwordEncoder.matches(
        request.getPassword(),
        user.getPassword()
          );




    if (!matches) {
       log.warn("Failed login attempt");
        throw new InvalidCredentialsException("Invalid email or password");


         }
        
        
        String token = jwtService.generateToken(user.getEmail());
        log.info("User logged in successfully");


        return new LoginResponse(token);
        




       }




}