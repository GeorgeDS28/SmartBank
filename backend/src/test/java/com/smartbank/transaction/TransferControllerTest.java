//TransactionControllerTest.java
package com.smartbank.transaction.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartbank.auth.jwt.JwtService;
import com.smartbank.security.JwtAuthenticationFilter;
import com.smartbank.transaction.dto.TransferRequest;
import com.smartbank.transaction.dto.TransferResponse;
import com.smartbank.transaction.service.TransferService;

@WebMvcTest(TransferController.class)
@AutoConfigureMockMvc(addFilters = false)
class TransferControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private TransferService transferService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    // =========================================================
    // TRANSFER
    // =========================================================

    @Test
    void transfer_success() throws Exception {

        TransferRequest request = new TransferRequest();
        request.setFromAccountNumber("SB100001");
        request.setToAccountNumber("SB100002");
        request.setAmount(new BigDecimal("500.00"));
        request.setDescription("Test transfer");

        TransferResponse response = new TransferResponse(
                "Transfer successful",
                "SB100001",
                "SB100002",
                new BigDecimal("500.00")
        );

        when(transferService.transfer(any(TransferRequest.class)))
                .thenReturn(response);

        mockMvc.perform(
                post("/api/accounts/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message")
                .value("Transfer successful"))
        .andExpect(jsonPath("$.fromAccountNumber")
                .value("SB100001"))
        .andExpect(jsonPath("$.toAccountNumber")
                .value("SB100002"))
        .andExpect(jsonPath("$.amount")
                .value(500.00));

        verify(transferService, times(1))
                .transfer(any(TransferRequest.class));
    }

    @Test
    void transfer_invalidSenderAccount_returnsBadRequest()
            throws Exception {

        TransferRequest request = new TransferRequest();
        request.setFromAccountNumber("");
        request.setToAccountNumber("SB100002");
        request.setAmount(new BigDecimal("500.00"));

        mockMvc.perform(
                post("/api/accounts/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(transferService, times(0))
                .transfer(any(TransferRequest.class));
    }

    @Test
    void transfer_invalidReceiverAccount_returnsBadRequest()
            throws Exception {

        TransferRequest request = new TransferRequest();
        request.setFromAccountNumber("SB100001");
        request.setToAccountNumber("");
        request.setAmount(new BigDecimal("500.00"));

        mockMvc.perform(
                post("/api/accounts/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(transferService, times(0))
                .transfer(any(TransferRequest.class));
    }

    @Test
    void transfer_missingAmount_returnsBadRequest()
            throws Exception {

        TransferRequest request = new TransferRequest();
        request.setFromAccountNumber("SB100001");
        request.setToAccountNumber("SB100002");
        request.setAmount(null);

        mockMvc.perform(
                post("/api/accounts/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(transferService, times(0))
                .transfer(any(TransferRequest.class));
    }

    @Test
    void transfer_amountBelowMinimum_returnsBadRequest()
            throws Exception {

        TransferRequest request = new TransferRequest();
        request.setFromAccountNumber("SB100001");
        request.setToAccountNumber("SB100002");
        request.setAmount(new BigDecimal("0.00"));

        mockMvc.perform(
                post("/api/accounts/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
        )
        .andExpect(status().isBadRequest());

        verify(transferService, times(0))
                .transfer(any(TransferRequest.class));
    }
}

