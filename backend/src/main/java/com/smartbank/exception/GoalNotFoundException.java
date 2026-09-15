/*GoalNotFoundException.java */

package com.smartbank.exception;

public class GoalNotFoundException extends RuntimeException {

    public GoalNotFoundException(String message) {
        super(message);
    }

}