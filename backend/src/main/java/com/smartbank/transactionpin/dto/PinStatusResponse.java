/*PinStatusResponse.java */

package com.smartbank.transactionpin.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PinStatusResponse {

    private boolean pinConfigured;

    private String message;
}