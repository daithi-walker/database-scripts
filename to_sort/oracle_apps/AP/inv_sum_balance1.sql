PACKAGE BODY inv_sum_balance1 IS


PROCEDURE COMPUTE_UNPAID_AMOUNT IS
  l_prepayment_amount      number := :balance.prepay_amount;
  l_base_prepayment_amount number := :balance.base_prepay_amount;
  l_unpaid_amount          number;
  l_base_unpaid_amount     number;
  l_invoice_count          number;

BEGIN


    -- Compute amount due
    -- Do not include unpaid prepayments.

    -- Bug 1690514. Using the payment cross rate if the invoice currency code is same
    -- as the base currency code to calculate the unpaid amount.

    -- bug 2900877 added rounding logic

    

    -- Compute amount due
    :balance.unpaid_amount       := l_unpaid_amount;
    :balance.base_unpaid_amount  := l_base_unpaid_amount;
    :balance.invoice_count       := l_invoice_count;

    -- Subtract prepayments to arrive at unpaid amount
    :balance.base_balance_owed := l_base_unpaid_amount - l_base_prepayment_amount;
    :balance.balance_owed      := l_unpaid_amount - l_prepayment_amount;

END COMPUTE_UNPAID_AMOUNT;


END;
