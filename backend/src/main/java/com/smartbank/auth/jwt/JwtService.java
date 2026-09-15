/*JwtService.java
  This class is responsible for generating and 
  validating JSON Web Tokens (JWTs) for user authentication.
*/

package com.smartbank.auth.jwt;

import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;


@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    public String generateToken(String email) 
    {

            return Jwts.builder()
              .subject(email)
              .issuedAt(new Date())
              .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
              .signWith(getSigningKey())
              .compact();
                                             
                                             
    }
    public String extractEmail(String token) 
    {
    Claims claims = Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();

            return claims.getSubject();
    
    }
    public Date extractExpiration(String token) {

    Claims claims = Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();

    return claims.getExpiration();
     }

     public boolean isTokenExpired(String token) {
    return extractExpiration(token).before(new Date());
     }



     public boolean isTokenValid(String token, String email) 
     {

    String extractedEmail = extractEmail(token);

    return extractedEmail.equals(email) && !isTokenExpired(token);
       }




}
