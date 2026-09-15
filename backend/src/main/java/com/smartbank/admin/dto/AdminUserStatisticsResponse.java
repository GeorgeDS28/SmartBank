/*AdminUserStatisticsResponse.java */

package com.smartbank.admin.dto;

public class AdminUserStatisticsResponse {

    private long totalUsers;
    private long totalAdmins;
    private long totalNormalUsers;

    public AdminUserStatisticsResponse() {
    }

    public AdminUserStatisticsResponse(long totalUsers,
                                       long totalAdmins,
                                       long totalNormalUsers) {
        this.totalUsers = totalUsers;
        this.totalAdmins = totalAdmins;
        this.totalNormalUsers = totalNormalUsers;
    }

    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getTotalAdmins() {
        return totalAdmins;
    }

    public void setTotalAdmins(long totalAdmins) {
        this.totalAdmins = totalAdmins;
    }

    public long getTotalNormalUsers() {
        return totalNormalUsers;
    }

    public void setTotalNormalUsers(long totalNormalUsers) {
        this.totalNormalUsers = totalNormalUsers;
    }
}