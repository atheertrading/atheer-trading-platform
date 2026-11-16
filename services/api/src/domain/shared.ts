export class DomainError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = "DomainError";
  }
}

export type RoundingMode = "half-up" | "half-even" | "toward-zero";

const pow10 = (power: number): bigint => {
  if (!Number.isInteger(power) || power < 0 || power > 1000) {
    throw new DomainError("INVALID_SCALE", "Decimal scale is outside the supported range.");
  }
  return 10n ** BigInt(power);
};

/** Exact base-10 decimal backed by an integer coefficient. No binary floating point is used. */
export class Decimal {
  private constructor(
    private readonly coefficient: bigint,
    readonly scale: number,
  ) { Object.freeze(this); }

  static parse(value: string | Decimal): Decimal {
    if (value instanceof Decimal) return value;
    if (typeof value !== "string" || !/^-?(?:0|[1-9]\d*)(?:\.\d+)?$/.test(value)) {
      throw new DomainError("INVALID_DECIMAL", `Invalid decimal value: ${String(value)}`);
    }
    const negative = value.startsWith("-");
    const unsigned = negative ? value.slice(1) : value;
    const [whole, fraction = ""] = unsigned.split(".");
    let coefficient = BigInt(`${whole}${fraction}`);
    if (negative) coefficient = -coefficient;
    return Decimal.fromParts(coefficient, fraction.length);
  }

  static zero(): Decimal { return new Decimal(0n, 0); }

  private static fromParts(coefficient: bigint, scale: number): Decimal {
    if (!Number.isInteger(scale) || scale < 0 || scale > 1000) {
      throw new DomainError("INVALID_SCALE", "Decimal scale is invalid.");
    }
    let c = coefficient;
    let s = scale;
    while (s > 0 && c % 10n === 0n) { c /= 10n; s -= 1; }
    return new Decimal(c, s);
  }

  get isZero(): boolean { return this.coefficient === 0n; }
  get isPositive(): boolean { return this.coefficient > 0n; }
  get isNegative(): boolean { return this.coefficient < 0n; }
  get isNonNegative(): boolean { return this.coefficient >= 0n; }

  add(other: Decimal): Decimal {
    const scale = Math.max(this.scale, other.scale);
    return Decimal.fromParts(
      this.coefficient * pow10(scale - this.scale) + other.coefficient * pow10(scale - other.scale),
      scale,
    );
  }

  subtract(other: Decimal): Decimal { return this.add(other.negate()); }
  multiply(other: Decimal): Decimal {
    return Decimal.fromParts(this.coefficient * other.coefficient, this.scale + other.scale);
  }
  negate(): Decimal { return Decimal.fromParts(-this.coefficient, this.scale); }
  abs(): Decimal { return this.isNegative ? this.negate() : this; }

  compare(other: Decimal): number {
    const scale = Math.max(this.scale, other.scale);
    const left = this.coefficient * pow10(scale - this.scale);
    const right = other.coefficient * pow10(scale - other.scale);
    return left < right ? -1 : left > right ? 1 : 0;
  }

  quantize(targetScale: number, mode: RoundingMode): Decimal {
    if (!Number.isInteger(targetScale) || targetScale < 0 || targetScale > 1000) {
      throw new DomainError("INVALID_SCALE", "Target scale is invalid.");
    }
    if (targetScale >= this.scale) {
      return Decimal.fromParts(this.coefficient * pow10(targetScale - this.scale), targetScale);
    }
    const divisor = pow10(this.scale - targetScale);
    let quotient = this.coefficient / divisor;
    const remainder = this.coefficient % divisor;
    if (remainder !== 0n) {
      if (mode === "half-up") {
        if ((remainder < 0n ? -remainder : remainder) * 2n >= divisor) quotient += this.isNegative ? -1n : 1n;
      } else if (mode === "half-even") {
        const twice = (remainder < 0n ? -remainder : remainder) * 2n;
        if (twice > divisor || (twice === divisor && quotient % 2n !== 0n)) {
          quotient += this.isNegative ? -1n : 1n;
        }
      } else if (mode !== "toward-zero") {
        throw new DomainError("INVALID_ROUNDING_MODE", "Unsupported rounding mode.");
      }
    }
    return Decimal.fromParts(quotient, targetScale);
  }

  divide(other: Decimal, targetScale: number, mode: RoundingMode): Decimal {
    if (other.isZero) throw new DomainError("DIVISION_BY_ZERO", "Cannot divide by zero.");
    if (!Number.isInteger(targetScale) || targetScale < 0 || targetScale > 1000) {
      throw new DomainError("INVALID_SCALE", "Target scale is invalid.");
    }
    const exponent = targetScale + other.scale - this.scale;
    const numerator = exponent >= 0 ? this.coefficient * pow10(exponent) : this.coefficient;
    const denominator = exponent >= 0 ? other.coefficient : other.coefficient * pow10(-exponent);
    let quotient = numerator / denominator;
    const remainder = numerator % denominator;
    if (remainder !== 0n) {
      const sign = (numerator < 0n) !== (denominator < 0n) ? -1n : 1n;
      if (mode === "half-up") {
        if ((remainder < 0n ? -remainder : remainder) * 2n >= (denominator < 0n ? -denominator : denominator)) quotient += sign;
      } else if (mode === "half-even") {
        const twice = (remainder < 0n ? -remainder : remainder) * 2n;
        if (twice > (denominator < 0n ? -denominator : denominator) || (twice === (denominator < 0n ? -denominator : denominator) && quotient % 2n !== 0n)) quotient += sign;
      } else if (mode !== "toward-zero") {
        throw new DomainError("INVALID_ROUNDING_MODE", "Unsupported rounding mode.");
      }
    }
    return Decimal.fromParts(quotient, targetScale);
  }

  toString(): string {
    const negative = this.coefficient < 0n;
    const digits = (negative ? -this.coefficient : this.coefficient).toString();
    if (this.scale === 0) return `${negative ? "-" : ""}${digits}`;
    const padded = digits.padStart(this.scale + 1, "0");
    const split = padded.length - this.scale;
    return `${negative ? "-" : ""}${padded.slice(0, split)}.${padded.slice(split)}`;
  }

  toJSON(): string { return this.toString(); }
}

export type Currency = string & { readonly __currency: unique symbol };

export function currency(value: string): Currency {
  const normalized = value.toUpperCase();
  if (!/^[A-Z]{3}$/.test(normalized)) throw new DomainError("INVALID_CURRENCY", "Currency must be a three-letter ISO code.");
  return normalized as Currency;
}

export class Money {
  readonly amount: Decimal;
  readonly currency: Currency;

  constructor(amount: Decimal | string, currencyCode: Currency | string) {
    this.amount = Decimal.parse(amount);
    this.currency = currency(currencyCode);
    Object.freeze(this);
  }

  add(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.amount.add(other.amount), this.currency);
  }
  subtract(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.amount.subtract(other.amount), this.currency);
  }
  private assertSameCurrency(other: Money): void {
    if (this.currency !== other.currency) throw new DomainError("CURRENCY_MISMATCH", "Money arithmetic requires matching currencies.");
  }
  toJSON(): { amount: string; currency: string } { return { amount: this.amount.toString(), currency: this.currency }; }
}

export class UtcTimestamp {
  private constructor(readonly epochMilliseconds: number) { Object.freeze(this); }
  static fromEpochMilliseconds(value: number): UtcTimestamp {
    if (!Number.isSafeInteger(value) || value < 0) throw new DomainError("INVALID_TIMESTAMP", "Timestamp must be a non-negative safe integer in milliseconds.");
    return new UtcTimestamp(value);
  }
  static fromISO(value: string): UtcTimestamp {
    if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value)) {
      throw new DomainError("INVALID_TIMESTAMP", "Timestamp must be an ISO-8601 UTC value ending in Z.");
    }
    const epoch = Date.parse(value);
    if (!Number.isFinite(epoch)) throw new DomainError("INVALID_TIMESTAMP", "Timestamp is invalid.");
    return UtcTimestamp.fromEpochMilliseconds(epoch);
  }
  toISOString(): string { return new Date(this.epochMilliseconds).toISOString(); }
  isBefore(other: UtcTimestamp): boolean { return this.epochMilliseconds < other.epochMilliseconds; }
  isAfter(other: UtcTimestamp): boolean { return this.epochMilliseconds > other.epochMilliseconds; }
  ageMillisecondsAt(now: UtcTimestamp): number { return now.epochMilliseconds - this.epochMilliseconds; }
}

export function requiredText(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) throw new DomainError("INVALID_TEXT", `${label} must not be empty.`);
  return normalized;
}
