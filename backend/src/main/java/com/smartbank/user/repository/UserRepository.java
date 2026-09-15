/*
UserRepository.java
This interface defines the repository for managing User entities in the database.

*/






package com.smartbank.user.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smartbank.user.entity.User;


import com.smartbank.user.enums.Role;

public interface UserRepository
        extends JpaRepository<User, Long> {


Optional<User> findByEmail(String email);


 boolean existsByEmail(String email);

//added method to count users by role
long countByRole(Role role);

}