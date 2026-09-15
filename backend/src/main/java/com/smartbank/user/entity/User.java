/*User.java */


package com.smartbank.user.entity;
import com.smartbank.user.enums.Role;

import jakarta.persistence.*;
import lombok.*;


import com.smartbank.account.entity.Account;
import java.util.List;

import com.smartbank.goal.entity.Goal;
import java.util.ArrayList;
import java.util.List;



@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

  

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String phone;


    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
     private Role role;



   @OneToMany(mappedBy = "user",
        cascade = CascadeType.ALL,
        orphanRemoval = true)
private List<Account> accounts;




    @OneToMany(
        mappedBy = "user",
        cascade = CascadeType.ALL,
        orphanRemoval = true
)
private List<Goal> goals = new ArrayList<>();




}