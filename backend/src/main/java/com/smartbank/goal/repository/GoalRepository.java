/*GoalRepository.java*/

package com.smartbank.goal.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smartbank.goal.entity.Goal;
import com.smartbank.user.entity.User;

public interface GoalRepository extends JpaRepository<Goal, Long> {

    List<Goal> findByUser(User user);
    List<Goal> findByUserOrderByCreatedAtDesc(User user);

    Optional<Goal> findByUserAndId(User user, Long id);

}