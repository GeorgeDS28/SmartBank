/* TransferAnalyticsResponse.java */

package com.smartbank.analytics.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransferAnalyticsResponse {

    private long totalTransfers;

    private BigDecimal totalTransferredIn;

    private BigDecimal totalTransferredOut;

    private BigDecimal netTransferAmount;
}