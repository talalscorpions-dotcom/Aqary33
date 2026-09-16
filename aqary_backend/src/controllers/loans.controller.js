// Full Architecture Plan, Section 7 — Loan Calculator.
// BR-LOAN-01 through BR-LOAN-04: one calculation function shared by the
// standalone module and the inline listing widget, so a figure shown on
// a listing always matches what the standalone module would compute.

// Static comparative rates — replace with real bank data or an admin-
// managed table before launch. No live bank integration in this phase
// (BR-LOAN-02).
const BANK_RATES = [
  { bank: "Bank Muscat", annualRatePct: 5.49 },
  { bank: "Oman Arab Bank", annualRatePct: 5.65 },
  { bank: "National Bank of Oman", annualRatePct: 5.75 },
  { bank: "Sohar International", annualRatePct: 5.60 },
];

/**
 * Standard amortization formula:
 *   M = P * r(1+r)^n / ((1+r)^n - 1)
 * where P = principal, r = monthly interest rate, n = number of payments.
 */
function calculateMonthlyPayment(principal, annualRatePct, tenureYears) {
  const r = annualRatePct / 100 / 12;
  const n = tenureYears * 12;
  if (r === 0) return principal / n;
  const monthly = (principal * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
  return Math.round(monthly * 1000) / 1000; // OMR uses 3 decimal places (baisa)
}

/**
 * GET /loans/estimate?amount=&tenure=&downPayment=
 * Used both by the standalone Loan Calculator screen and the on-listing
 * widget (BR-LOAN-03) — same endpoint, same math, every time.
 */
function estimate(req, res) {
  const amount = Number(req.query.amount);
  const tenure = Number(req.query.tenure) || 25;
  const downPayment = Number(req.query.downPayment) || 0;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: "amount is required and must be greater than 0." });
  }
  const principal = amount - downPayment;
  if (principal <= 0) {
    return res.status(400).json({ error: "downPayment must be less than the loan amount." });
  }

  const estimates = BANK_RATES.map((b) => ({
    bank: b.bank,
    annualRatePct: b.annualRatePct,
    monthlyPaymentOmr: calculateMonthlyPayment(principal, b.annualRatePct, tenure),
  }));

  const lowestFirst = [...estimates].sort((a, b) => a.monthlyPaymentOmr - b.monthlyPaymentOmr);

  return res.json({
    principal,
    tenureYears: tenure,
    downPayment,
    estimates: lowestFirst,
    headlineEstimateOmr: lowestFirst[0].monthlyPaymentOmr, // shown on the listing widget
  });
}

module.exports = { estimate, calculateMonthlyPayment, BANK_RATES };
