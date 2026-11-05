import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/features/analytics/data/models/analytics_models.dart';
import 'package:smartbank/features/goal/data/models/goal_model.dart';
import 'package:smartbank/features/transaction/data/models/money_models.dart';
import 'package:smartbank/features/transaction/data/models/transaction_model.dart';
import 'package:smartbank/features/user/data/models/account_model.dart';
import 'package:smartbank/features/user/data/models/dashboard_model.dart';

void main() {
  group('AccountModel', () {
    test('parses the AccountResponse shape', () {
      final account = AccountModel.fromJson(const {
        'accountNumber': 'SB17785331',
        'accountType': 'SAVINGS',
        'balance': 12450.6,
        'status': 'ACTIVE',
      });

      expect(account.accountNumber, 'SB17785331');
      expect(account.accountType, 'SAVINGS');
      expect(account.balance, 12450.6);
      expect(account.status, 'ACTIVE');
    });
  });

  group('TransactionModel', () {
    test('parses the TransactionResponse shape', () {
      final transaction = TransactionModel.fromJson(const {
        'transactionReference': 'TXN-5364E5DD2992',
        'transactionType': 'WITHDRAW',
        'amount': 120.00,
        'description': 'Cash Withdrawal',
        'createdAt': '2026-11-03T23:02:50.292835',
      });

      expect(transaction.transactionReference, 'TXN-5364E5DD2992');
      expect(transaction.transactionType, 'WITHDRAW');
      expect(transaction.amount, 120.0);
      expect(transaction.createdAt.year, 2026);
      expect(transaction.accountNumber, isNull);
    });

    test('carries the owning account when supplied by the caller', () {
      final transaction = TransactionModel.fromJson(const {
        'transactionReference': 'TXN1',
        'transactionType': 'DEPOSIT',
        'amount': 500,
        'description': 'Cash Deposit',
        'createdAt': '2026-11-03T23:02:50.14118',
      }, accountNumber: 'SB79696475');

      expect(transaction.accountNumber, 'SB79696475');
    });
  });

  group('DashboardModel', () {
    test('parses recent transactions and defaults missing numbers', () {
      final dashboard = DashboardModel.fromJson(const {
        'totalBalance': 24850.75,
        'numberOfAccounts': 3,
        'totalTransactions': 12,
        'recentTransactions': [
          {
            'transactionReference': 'TXN1',
            'transactionType': 'TRANSFER_OUT',
            'amount': 50.0,
            'description': 'rent',
            'accountNumber': 'SB1',
            'createdAt': '2026-11-03T23:02:50.481176',
          },
        ],
      });

      expect(dashboard.totalBalance, 24850.75);
      expect(dashboard.numberOfAccounts, 3);
      expect(dashboard.recentTransactions, hasLength(1));

      final model = dashboard.recentTransactions.single.toModel();
      expect(model.transactionType, 'TRANSFER_OUT');
      expect(model.accountNumber, 'SB1');
    });

    test('tolerates an empty dashboard payload', () {
      final dashboard = DashboardModel.fromJson(const {
        'totalBalance': 0,
        'numberOfAccounts': 0,
        'totalTransactions': 0,
        'recentTransactions': [],
      });

      expect(dashboard.recentTransactions, isEmpty);
    });
  });

  group('GoalModel', () {
    test('parses GoalResponse and derives progress', () {
      final goal = GoalModel.fromJson(const {
        'id': 4,
        'goalName': 'Laptop',
        'targetAmount': 1500.00,
        'currentAmount': 300.00,
        'progressPercentage': 20,
        'status': 'IN_PROGRESS',
        'targetDate': '2026-12-31',
        'createdAt': '2026-11-03T23:02:51.001104',
      });

      expect(goal.id, 4);
      expect(goal.progressPercentage, 20);
      expect(goal.remainingAmount, 1200.0);
      expect(goal.progressRatio, closeTo(0.2, 0.0001));
      expect(goal.isCompleted, isFalse);
      expect(goal.targetDate.day, 31);
    });

    test('clamps progress when saved exceeds target', () {
      final goal = GoalModel.fromJson(const {
        'id': 5,
        'goalName': 'Overfunded',
        'targetAmount': 100,
        'currentAmount': 180,
        'progressPercentage': 180,
        'status': 'COMPLETED',
        'targetDate': '2026-12-31',
        'createdAt': '2026-11-03T23:02:51.001104',
      });

      expect(goal.progressRatio, 1.0);
      expect(goal.remainingAmount, 0);
      expect(goal.isCompleted, isTrue);
    });

    test('avoids dividing by zero for an empty target', () {
      final goal = GoalModel.fromJson(const {
        'id': 6,
        'goalName': 'Empty',
        'targetAmount': 0,
        'currentAmount': 0,
        'progressPercentage': 0,
        'status': 'IN_PROGRESS',
        'targetDate': '2026-12-31',
        'createdAt': '2026-11-03T23:02:51.001104',
      });

      expect(goal.progressRatio, 0);
    });
  });

  group('Money result models', () {
    test('DepositResponse', () {
      final result = DepositResult.fromJson(const {
        'accountNumber': 'SB79696475',
        'depositedAmount': 500,
        'currentBalance': 500.00,
        'message': 'Deposit successful',
      });
      expect(result.currentBalance, 500);
      expect(result.message, 'Deposit successful');
    });

    test('WithdrawResponse', () {
      final result = WithdrawResult.fromJson(const {
        'message': 'Withdrawal successful',
        'accountNumber': 'SB79696475',
        'withdrawnAmount': 120,
        'updatedBalance': 380.00,
      });
      expect(result.updatedBalance, 380);
    });

    test('TransferResponse', () {
      final result = TransferResult.fromJson(const {
        'message': 'Transfer successful',
        'fromAccountNumber': 'SB1',
        'toAccountNumber': 'SB2',
        'amount': 50,
      });
      expect(result.toAccountNumber, 'SB2');
    });
  });

  group('Analytics models', () {
    test('FinancialSummaryModel derives inflow and outflow', () {
      final summary = FinancialSummaryModel.fromJson(const {
        'totalBalance': 1000,
        'totalDeposits': 600,
        'totalWithdrawals': 100,
        'totalTransferredIn': 50,
        'totalTransferredOut': 200,
        'netCashFlow': 350,
        'totalGoalSavings': 300,
      });

      expect(summary.totalInflow, 650);
      expect(summary.totalOutflow, 300);
    });

    test('MonthlyActivityModel parses the /monthly list item', () {
      final month = MonthlyActivityModel.fromJson(const {
        'month': 'November',
        'deposits': 500.00,
        'withdrawals': 120.00,
        'transfersIn': 50.00,
        'transfersOut': 50.00,
      });

      expect(month.month, 'November');
      expect(month.inflow, 550);
      expect(month.outflow, 170);
    });

    test('GoalAnalyticsModel reads counts as ints', () {
      final analytics = GoalAnalyticsModel.fromJson(const {
        'totalGoals': 3,
        'activeGoals': 2,
        'completedGoals': 1,
        'totalTargetAmount': 5000,
        'totalSavedAmount': 1200,
        'overallProgress': 24,
      });

      expect(analytics.totalGoals, 3);
      expect(analytics.completedGoals, 1);
      expect(analytics.overallProgress, 24);
    });

    test('TransferAnalyticsModel', () {
      final analytics = TransferAnalyticsModel.fromJson(const {
        'totalTransfers': 4,
        'totalTransferredIn': 100,
        'totalTransferredOut': 60,
        'netTransferAmount': 40,
      });

      expect(analytics.totalTransfers, 4);
      expect(analytics.netTransferAmount, 40);
    });
  });
}
