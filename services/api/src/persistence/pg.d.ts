declare module "pg" {
  export interface QueryResult<Row extends Record<string, unknown> = Record<string, unknown>> {
    readonly rows: Row[];
    readonly rowCount: number | null;
  }
  export interface PoolClient {
    query<Row extends Record<string, unknown> = Record<string, unknown>>(
      text: string,
      values?: readonly unknown[],
    ): Promise<QueryResult<Row>>;
    release(error?: Error | boolean): void;
  }
  export class Pool {
    constructor(config?: {
      readonly connectionString?: string;
      readonly max?: number;
      readonly idleTimeoutMillis?: number;
      readonly connectionTimeoutMillis?: number;
    });
    connect(): Promise<PoolClient>;
    query<Row extends Record<string, unknown> = Record<string, unknown>>(
      text: string,
      values?: readonly unknown[],
    ): Promise<QueryResult<Row>>;
    end(): Promise<void>;
  }
}
