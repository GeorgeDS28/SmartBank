/* JwtAuthenticationFilter.java */


package com.smartbank.security;

import java.io.IOException;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.smartbank.auth.jwt.JwtService;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {


     private static final Logger log =
            LoggerFactory.getLogger(JwtAuthenticationFilter.class);


    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String email;

        // Check if Authorization header exists
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        
    

        // Extract JWT token
        jwt = authHeader.substring(7);

        try {
            // Extract email from token
            email = jwtService.extractEmail(jwt);

            log.debug("JWT email extracted successfully");

            // Authenticate only if not already authenticated
            if (email != null &&
                    SecurityContextHolder.getContext().getAuthentication() == null) {

                UserDetails userDetails =
                        userDetailsService.loadUserByUsername(email);

                boolean valid = jwtService.isTokenValid(jwt, userDetails.getUsername());

                if (!valid) {
                    log.warn("Invalid JWT token");
                } else {

                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails,
                                    null,
                                    userDetails.getAuthorities());

                    authToken.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authToken);

                    log.debug("JWT authentication successful");
                }
            }
        } catch (JwtException | IllegalArgumentException e) {
            // Malformed, expired or forged bearer token. Nothing here may
            // escape: this filter runs before the MVC exception handling the
            // controllers get, so an uncaught throw becomes a container-made
            // 500 rather than the 401 the client can act on.
            log.debug("Rejected bearer token ({})", e.getClass().getSimpleName());
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        } catch (UsernameNotFoundException e) {
            // Signed by us but naming a subject that no longer exists.
            log.debug("Rejected bearer token: unknown subject");
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        filterChain.doFilter(request, response);

                }// end of doFilterInternal method
                
                }//class JwtAuthenticationFilter end
                
                

                

